/* The companion's step clock (Storage phase, 2026-11-04; design.md "The step clock"): the Rytm's sequencer steps for
 * the Pi's generic services (its core/clock; the Pi-side parameter locks play on it). Included by sidecar.c, one
 * translation unit. The sites are gated on the mod's param `clock` (registry: trig_fire's entry and the sequencer
 * clock's exit, the sites 0026 used for its seq link 1032, which a build with 0026 screen=0 still claims: the build
 * refuses the two together); without them nothing here runs.
 *
 * Rytm -> host, as sim/protocol.py's "Sidecar sequencer" defines them, while the store link is up (the Pi answered the
 * companion's STORE HELLO, store.c) and the USB port is configured:
 *   2C 01 <blk4> <n> {<track> <step> <len> <speed> <flags>} x n   the steps that started in one audio block, all 13
 *       tracks (the FX track is 12); flags bit 0: the step holds a note trig, bit 1: a trigless lock trig. 0026's 2C
 *       carried 4 bytes a tick and only its seq tracks; the Pi takes either (a tick's size from the message's length).
 *   2D 01 01 <0 stop 1 play 2 pause> <blk4>   TRANSPORT, on a change
 *   2D 01 03 <from> <to> <blk4>               SWITCH: the new pattern's first step started in that block
 *   2D 01 02 <now> <queued 7F none>           PATTERN: the playing pattern and the one queued after it, at link-up and
 *                                             on a change (as 0026's 1033: until the SWITCH the old one still plays)
 *   2D 01 07 <t hi> <t mid> <t lo>            TEMPO: BPM x 120 in 21 bits, at link-up and on a change
 * blk4: the audio block counter (1500 a second) as 4 x 7 bits, MSB first.
 *
 * Where the steps come from (0026 1032, measured there [rytm-emu, 2026-10-20]): trig_fire (0x4009aa28, (track,
 * pattern, step, slot)) is called once per track per step, trig or not, for all 13 tracks, from the sequencer clock
 * (0x4009b0b4, a software interrupt at level 2), one step ahead: the step starting now is the byte 0x405c8cea + t.
 * sc_fire queues it; the clock's exit (0x4009c00a, 203 calls a second at 127 BPM, stopped or playing) sends what is
 * queued, under 0021's interrupt rules (no task holds the USB MIDI mutex, the sender not inside a SysEx, the ring
 * under 3800, 2 free requests) at IPL 5; else the next exit tries again (5 ms at 127 BPM). A full queue drops and
 * counts. A pattern jump's re-schedule call (DIRECT / TEMP JUMP: the same starting step again with the new pattern)
 * is no step (0026 1042).
 *
 * The flags [code, re/symbols.toml; not yet measured]: the step's trig word, TrackPattern + 2 x step (a BE word; bit 0
 * TRIG_BIT_TRIG, bit 2 TRIG_BIT_LOCK: a trigless trig); a track in euclidean mode (+0x2ca == 1, as trig_fire tests it)
 * has its trigs where its map (+0x2d1, 64 bytes, -1 none) holds one. Mutes are not looked at: a muted track's trig
 * still says so. The FX track's speed byte (0x405c8d25 + 12) is read as the voice tracks' are [I, to measure]. */

#ifndef CK_PLAY                        /* the firmware's words (test/: the host test gives its own) */
#define CK_PLAY      (*(const volatile uint32_t *)0x405c8c90u)
#define CK_PAT       (*(const volatile int8_t *)0x405c8d04u)
#define CK_SPEED(t)  (((const volatile uint8_t *)0x405c8d25u)[t])
#define CK_PREV(t)   (((const volatile uint8_t *)0x405c8ceau)[t])   /* the step starting now (cur - 1) [measured] */
#define CK_BLK       (*(const volatile uint32_t *)0x419ca2acu)
#define CK_PATD(p)   ((const volatile uint8_t *)(0x407dd8e3u + 85760u * (uint32_t)(p)))   /* as trig_fire's base */
#define CK_SENDER    (*(const volatile uint32_t *)0x42f67a28u)  /* the USB MIDI mutex's owner (0: free) */
#define CK_SYSEX     (*(const volatile uint32_t *)0x413db244u)  /* the sender's SysEx state (0021's SYSEX_STATE) */
#define CK_TIMER     (*(volatile uint32_t *)0xfc07000cu)        /* DTCN0, the OS's free-running bus-clock count */
#define CK_NEXT      ((const volatile uint8_t *)0x412f3e91u)    /* BE word: the pattern queued after this one (0026's
                                                                   SQ_NEXT [measured there]) */
#define CK_TEMPO     (*(const volatile uint32_t *)0x40287ffcu)  /* BPM x 120 (0026's SQ_TEMPO [measured there]) */
#endif
#define CK_TRACKS    13
#define CK_NQ        32
#define CK_PER_MSG   14                 /* ticks a 2C at most (one block holds at most 13, and a speed change 1 more) */
#define CK_TRK       917                /* a live TrackPattern */

struct ck_tick { uint32_t blk; uint8_t t, step, len, spd, flags; };
static struct {
  struct ck_tick q[CK_NQ];             /* step ticks not sent yet: q[qt % CK_NQ] .. q[(qh - 1) % CK_NQ] */
  volatile uint32_t qh, qt;
  uint8_t ev[6][16];                   /* 2D 01 / 02 / 03 / 07, whole messages (ev_n of them) */
  uint8_t ev_len[6];
  uint32_t ev_n;
  uint32_t init, last_play, last_pat, sw_from, jumped, lvalid, was_on, rep_pat, rep_next, rep_tempo;
  uint8_t lprev[CK_TRACKS], lpat[CK_TRACKS];
  uint32_t fires, queued, sent2c, sentev, drops, ev_drops, busy, rescheds, ends, isr_max;   /* diagnostics */
} ck __attribute__((section(".bss"), aligned(4)));

#ifndef SC_HOST
static uint32_t ck_ipl_raise(uint32_t lvl) {   /* the old SR; the mask raised to lvl (0x0500 / 0x0700) if lower */
  uint32_t sr, n;
  __asm__ volatile("move.w %%sr,%0" : "=d"(sr));
  sr &= 0xffff;
  if ((sr & 0x0700) < lvl) {
    n = (sr & ~0x0700u) | lvl;
    __asm__ volatile("move.w %0,%%sr" : : "d"(n) : "memory");
  }
  return sr;
}
static void ck_ipl_restore(uint32_t sr) {
  __asm__ volatile("move.w %0,%%sr" : : "d"(sr) : "memory");
}
#else
static uint32_t ck_ipl_raise(uint32_t lvl) { (void)lvl; return 0; }
static void ck_ipl_restore(uint32_t sr) { (void)sr; }
#endif

static uint8_t *ck_blk4(uint8_t *o, uint32_t b) {
  o[0] = (uint8_t)(b >> 21 & 0x7f); o[1] = (uint8_t)(b >> 14 & 0x7f); o[2] = (uint8_t)(b >> 7 & 0x7f);
  o[3] = (uint8_t)(b & 0x7f);
  return o + 4;
}

static uint8_t ck_cap(uint32_t v) { return (uint8_t)(v > 127 ? 127 : v); }

/* the length the step wraps at: the track's (+0x2c5) when the pattern's scale mode byte (+85689) is 1 (per track),
   else the pattern's (+85683, a word) [code: trig_fire 0x4009aac6, the step loop] */
static uint8_t ck_len(const volatile uint8_t *d, int32_t t) {
  if (d[85689] == 1) return ck_cap(d[CK_TRK * t + 0x2c5]);
  return ck_cap((uint32_t)d[85683] << 8 | d[85684]);
}

/* the step's flags: bit 0 a note trig, bit 1 a trigless lock trig (the trig word's bits 0 and 2) */
static uint8_t ck_flags(const volatile uint8_t *d, int32_t t, uint32_t step) {
  const volatile uint8_t *k = d + CK_TRK * t;
  uint32_t w = (uint32_t)k[2 * step] << 8 | k[2 * step + 1];
  if (k[0x2ca] == 1) return (int8_t)k[0x2d1 + step] >= 0;   /* euclidean: the map's steps are its trigs */
  if (w & 4) return 2;
  return w & 1;
}

static int32_t ck_on(void) { return PORT_STATE == 1 && scl.epoch != 0; }

/* a 2D without a block: PATTERN, TEMPO */
static void ck_report(uint8_t kind, const uint8_t *a, int32_t n) {
  uint8_t *m, *o;
  int32_t i;
  if (ck.ev_n >= 6) { ck.ev_drops++; return; }
  m = o = ck.ev[ck.ev_n];
  *o++ = 0xf0; *o++ = 0x7d; *o++ = 0x52; *o++ = 0x54; *o++ = 0x2d; *o++ = 0x01; *o++ = kind;
  for (i = 0; i < n; ++i) *o++ = a[i] & 0x7f;
  *o++ = 0xf7;
  ck.ev_len[ck.ev_n++] = (uint8_t)(o - m);
}

/* PATTERN and TEMPO when they changed since they were last reported (force: at link-up) */
static void ck_reports(uint32_t pt, uint32_t force) {
  uint8_t a[3];
  uint32_t nx = (uint32_t)CK_NEXT[0] << 8 | CK_NEXT[1], now = pt, tempo = CK_TEMPO & 0x1fffff;
  if (ck.sw_from & 0x100) { nx = pt; now = ck.sw_from & 0x7f; }   /* switching: the old one plays until its 03 */
  nx = nx < 128 && nx != now ? nx : 0x7f;
  if (force || now != ck.rep_pat || nx != ck.rep_next) {
    a[0] = (uint8_t)now; a[1] = (uint8_t)nx;
    ck_report(0x02, a, 2);
    ck.rep_pat = now; ck.rep_next = nx;
  }
  if (force || tempo != ck.rep_tempo) {
    a[0] = (uint8_t)(tempo >> 14); a[1] = (uint8_t)(tempo >> 7); a[2] = (uint8_t)tempo;
    ck_report(0x07, a, 3);
    ck.rep_tempo = tempo;
  }
}

static void ck_event(uint8_t kind, uint8_t a, uint8_t b, int32_t nargs, uint32_t blk) {
  uint8_t *m, *o;
  if (ck.ev_n >= 6) { ck.ev_drops++; return; }
  m = o = ck.ev[ck.ev_n];
  *o++ = 0xf0; *o++ = 0x7d; *o++ = 0x52; *o++ = 0x54; *o++ = 0x2d; *o++ = 0x01; *o++ = kind; *o++ = a;
  if (nargs > 1) *o++ = b;
  o = ck_blk4(o, blk);
  *o++ = 0xf7;
  ck.ev_len[ck.ev_n++] = (uint8_t)(o - m);
}

/* trig_fire's detour (C half), the sequencer interrupt: one track's step, called one step ahead (the step that starts
   now is the byte before, CK_PREV); with play 0 / 2 too (STOP's reset): only while playing. */
void sc_fire(int32_t t, int32_t p, int32_t step);
void sc_fire(int32_t t, int32_t p, int32_t step) {
  uint32_t pv, dup = 0, sr;
  const volatile uint8_t *d;
  ck.fires++;
  (void)step;
  if (t < 0 || t >= CK_TRACKS) return;
  if (CK_PLAY != 1) { ck.lvalid = 0; ck.jumped = 0; return; }
  pv = CK_PREV(t);
  if ((ck.lvalid >> t & 1) && pv == ck.lprev[t] && (uint32_t)p != ck.lpat[t]) {   /* a jump's re-schedule */
    dup = 1;
    ck.rescheds++;
    ck.jumped = 1;
  }
  ck.lprev[t] = (uint8_t)pv; ck.lpat[t] = (uint8_t)p; ck.lvalid |= 1u << t;
  if ((ck.sw_from & 0x100) && !dup && (pv == 0 || ck.jumped)) {   /* the new pattern's first step */
    if (ck.was_on) ck_event(0x03, (uint8_t)(ck.sw_from & 0x7f), (uint8_t)ck.last_pat, 2, CK_BLK);
    ck.sw_from = 0;
    ck.jumped = 0;
  }
  if (dup || pv > 63 || !ck.was_on) return;
  d = CK_PATD(p & 127);
  sr = ck_ipl_raise(0x0700);
  if (ck.qh - ck.qt >= CK_NQ) ck.drops++;
  else {
    struct ck_tick *e = &ck.q[ck.qh % CK_NQ];
    e->blk = CK_BLK; e->t = (uint8_t)t; e->step = (uint8_t)pv; e->len = ck_len(d, t); e->spd = CK_SPEED(t);
    e->flags = ck_flags(d, t, pv);
    ck.qh++;
    ck.queued++;
  }
  ck_ipl_restore(sr);
}

/* 1 sent (the sequencer interrupt, level 2: 0021's rules, at IPL 5 so a sender in the audio interrupt cannot cut in) */
static int32_t ck_send(const uint8_t *m, int32_t n) {
  uint32_t sr;
  int32_t ok = 0, k;
  const volatile uint32_t *h;
  if (PORT_STATE != 1) return 0;
  sr = ck_ipl_raise(0x0500);
  if (CK_SENDER == 0 && CK_SYSEX == 0 && TX_LEVEL + n <= 3800) {
    h = USB_POOL;
    for (k = 0; k < 2 && h; ++k) h = (const volatile uint32_t *)h[13];
    if (k == 2) {
      MIDI_SEND(n, m);
      ok = 1;
    }
  }
  ck_ipl_restore(sr);
  if (!ok) ck.busy++;
  return ok;
}

/* the clock's exit (C half), every sequencer clock call (96 PPQN), at the clock's own level */
void sc_end(void);
void sc_end(void) {
  uint32_t pl = CK_PLAY, pt = (uint32_t)CK_PAT & 0x7f, blk = CK_BLK, t0 = CK_TIMER, dt, on = ck_on();
  int32_t i;
  ck.ends++;
  if (pl > 2) pl = 0;
  if (!ck.init) { ck.last_play = pl; ck.last_pat = pt; ck.init = 1; }
  if (on && !ck.was_on) {              /* the link came up: the transport as it is, nothing queued from before */
    ck.qt = ck.qh;
    ck.ev_n = 0;
    ck_event(0x01, (uint8_t)pl, 0, 1, blk);
    ck_reports(pt, 1);
  }
  if (!on) { ck.ev_n = 0; ck.qt = ck.qh; ck.sw_from = 0; }
  ck.was_on = on;
  if (on) {
    if (pl != ck.last_play) ck_event(0x01, (uint8_t)pl, 0, 1, blk);
    if (pt != ck.last_pat) {           /* written a step ahead: 03 at the new pattern's step 0 (sc_fire); stopped: now */
      if (pl == 1) ck.sw_from = 0x100 | ck.last_pat;
      else ck_event(0x03, (uint8_t)ck.last_pat, (uint8_t)pt, 2, blk);
    }
    if (pl != 1 && (ck.sw_from & 0x100)) {   /* stopped before that step: the switch is done now */
      ck_event(0x03, (uint8_t)(ck.sw_from & 0x7f), (uint8_t)pt, 2, blk);
      ck.sw_from = 0;
    }
    ck_reports(pt, 0);
  }
  ck.last_play = pl;
  ck.last_pat = pt;
  while (ck.ev_n) {                    /* the 2D first, in order */
    if (!ck_send(ck.ev[0], ck.ev_len[0])) return;
    ck.sentev++;
    for (i = 1; i < (int32_t)ck.ev_n; ++i) {
      int32_t k;
      for (k = 0; k < 16; ++k) ck.ev[i - 1][k] = ck.ev[i][k];
      ck.ev_len[i - 1] = ck.ev_len[i];
    }
    ck.ev_n--;
  }
  while (ck.qh != ck.qt) {             /* then the ticks, a message per audio block */
    uint8_t m[6 + 4 + 1 + 5 * CK_PER_MSG + 1], *o = m + 6;
    const struct ck_tick *e = &ck.q[ck.qt % CK_NQ];
    uint32_t b = e->blk, k = 0;
    m[0] = 0xf0; m[1] = 0x7d; m[2] = 0x52; m[3] = 0x54; m[4] = 0x2c; m[5] = 0x01;
    o = ck_blk4(o, b);
    o++;                               /* n */
    while (ck.qt + k != ck.qh && k < CK_PER_MSG && ck.q[(ck.qt + k) % CK_NQ].blk == b) {
      e = &ck.q[(ck.qt + k) % CK_NQ];
      *o++ = e->t; *o++ = e->step; *o++ = e->len; *o++ = e->spd; *o++ = e->flags;
      k++;
    }
    m[10] = (uint8_t)k;
    *o++ = 0xf7;
    if (!ck_send(m, (int32_t)(o - m))) break;
    ck.qt += k;
    ck.sent2c++;
  }
  dt = CK_TIMER - t0;
  if (dt > ck.isr_max) ck.isr_max = dt;
}

#ifndef SC_HOST
/* the detours (registry, gate `clock`): trig_fire's entry (8 B, two instructions) and the clock's
   exit (8 B, two instructions, then the rte at 0x4009c012), each pair re-emitted after the C half */
__asm__(
    "  .text\n"
    "  .globl sc_fire_det, sc_end_det\n"
    "  .align 2\n"
    "sc_fire_det:\n"
    "  move.l 12(%sp),-(%sp)\n"
    "  move.l 12(%sp),-(%sp)\n"
    "  move.l 12(%sp),-(%sp)\n"
    "  jsr sc_fire\n"
    "  lea 12(%sp),%sp\n"
    "  lea -88(%sp),%sp\n"
    "  move.l 96(%sp),%d0\n"
    "  jmp 0x4009aa30\n"
    "  .align 2\n"
    "sc_end_det:\n"
    "  jsr sc_end\n"
    "  movem.l (%sp),%d0-%fp\n"
    "  lea 76(%sp),%sp\n"
    "  jmp 0x4009c012\n");
#endif
