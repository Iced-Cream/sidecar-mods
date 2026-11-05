/* mods/0025-sendfx/sfx.c - SEND FX 1 and 2 on the Sidecar (the send FX phase, 2026-11-05), a client of the companion
 * (mod 0032). The effects are graphs of the Pi's DSP library (sidecar-firmware core/dsp): this mod keeps the table of
 * which blocks make each TYPE, places them in the Pi's processor slots, joins them with the Pi's audio route and sets
 * their params through the Pi's lock service. The Pi knows "a DELAY in slot 3", never what CHORUS is. design.md.
 *
 * Per session (each new sc_link_epoch: the Pi forgot everything at the HELLO), for each FX whose TYPE is not OFF:
 *   1. PLACE its blocks (30, any free slot), wait for the slots (sc_dsp_result);
 *   2. ROUTE: a chain point per channel between two blocks, the return (the last block's output onto OUT 2/3, PRE,
 *      or OUT 0/1, POST: P1), and the sends: each voice stem (IN 2..9) into the first block's L and R, at the gain of
 *      the first track that plays the voice; at most SFX_INFLIGHT asked at once (the companion keeps 16 answers);
 *   3. the lock sets: one per (track, FX) on the send points (target 64 = the route's gains, params = the voice's L
 *      and R points), one per block on its params (track 12, the FX track), each with its bases.
 * A TYPE change frees the FX's slots (the Pi fades their points out and closes them), drops its sets and builds the
 * new graph. A base change (a send, P2..P5) is one BASE op; P1 re-aims the return points (MOVE).
 *
 * The values (the kit's, one section of the companion's kit record, mod number 25, SFX_SEC bytes):
 *   [2t + f]   track t's (0..11) send to FX f, 0..127      [24 + 6f + k]  FX f: TYPE, P1 (0 PRE, 1 POST), P2..P5 0..127
 * written back SFX_DEBOUNCE ticks after the last turn.
 *
 * P-locks (decided 2026-11-05: Pi locks with the mod's own entry): with a trig held, stock's lock calls for these knobs
 * come to sfx_locks (core-ar2 0.11 core_param_locks) with the track and the step. A lock is a LOCK op in the knob's
 * set on the Pi, and an entry in the mod's section of the playing pattern's record (the companion's, mod number 25):
 *   [0] 1 (the layout), then {<key> <step> <value 0..127>} x n   key 2t + f: track t's send to FX f (on its track),
 *                                                                key 24 + 4f + j: FX f's P(2 + j) (on the FX track)
 * TYPE and ROUTE take no lock. When the pattern's record loads (another pattern plays, a project load) and when an
 * FX's sets are declared, the FX's sets are cleared on the Pi and its locks sent again (SFX_LOCKS_TICK ops a tick).
 *
 * Pages (core-ar2 0.4 core_pages): AMPLITUDE 2 behind AMP on a voice track (A SFX1, B SFX2), SEND FX 1 behind DELAY
 * and SEND FX 2 behind REVERB on the FX track (A TYPE, B ROUTE, C..F P2..P5).
 *
 * Threads: everything in the UI task (ev_tick and the pages' calls). */
#include <stdint.h>

#include "analog-rytm-mk2/pages.h"

/* the companion's (mods/0032-sidecar/design.md) */
extern int32_t sc_link_send(const uint8_t *body, int32_t n);
extern int32_t sc_route_result(uint32_t owner, uint32_t seq);
extern int32_t sc_dsp_result(uint32_t owner, uint32_t seq);
extern uint32_t sc_link_epoch(void);
extern uint32_t sc_kit_gen(void);
extern int32_t sc_kit_get(uint32_t mod, uint8_t *buf, uint32_t cap);
extern int32_t sc_kit_put(uint32_t mod, const uint8_t *src, uint32_t n);
extern uint32_t sc_pat_gen(void);
extern int32_t sc_pat_index(void);
extern int32_t sc_pat_get(uint32_t mod, uint8_t *buf, uint32_t cap);
extern int32_t sc_pat_put(uint32_t mod, const uint8_t *src, uint32_t n);

#ifndef SFX_TRACK                      /* the selected track, 0..12 (12 the FX track): core-ar2's words (its rows.c) */
#define SFX_APP ((uint32_t (*)(void))0x4017fa0au)
#define SFX_APP_TRACKS ((uint32_t (*)(uint32_t))0x400ae492u)
#define SFX_CURRENT_TRACK ((int32_t (*)(uint32_t))0x400b693eu)
#define SFX_TRACK() SFX_CURRENT_TRACK(SFX_APP_TRACKS(SFX_APP()))
#endif

#define SFX_MOD      25                /* the kit record's section */
#define SFX_OWNER    0x25              /* the route's and the DSP library's owner byte */
#define SFX_NFX      2
#define SFX_NTRACK   12
#define SFX_NVOICE   8
#define SFX_NB       2                 /* blocks in a graph, at most */
#define SFX_SEC      36
#define SFX_INFLIGHT 12                /* route ops waiting for an answer, at most */
#define SFX_TIMEOUT  90                /* ticks without an answer: the session is given up until the next */
#define SFX_DEBOUNCE 12                /* ticks after the last turn before the kit's section is written */
#define SFX_SET_SEND 8                 /* lock sets 8..31: (track t, FX f) = 8 + 2t + f */
#define SFX_SET_P    0                 /* lock sets 0..3: FX f's block b = 2f + b */
#define SFX_FXTRACK  12
#define SFX_TARGET_ROUTE 64            /* sidecar-firmware core/route kTarget */
#define SFX_UNITY    8192
#define SFX_LMAX     300               /* locks in a pattern, at most (3 bytes each in the pattern's record) */
#define SFX_KEY_P    24                /* lock keys 24..31: FX f's P(2 + j) = 24 + 4f + j */
#define SFX_LOCKS_TICK 24              /* lock ops sent again per tick, at most (the companion queues 512 bytes) */

/* page and knob ids (core_pages / core_params): none stock's, none another mod's in the build */
#define SFX_PAGE_AMP2 16
#define SFX_PAGE_FX1  17
#define SFX_PAGE_FX2  18
#define SFX_ID_SEND   560              /* 560 SFX1, 561 SFX2; core-ar2 takes ids from 555 */
#define SFX_ID_FX     562              /* FX f's knob k (0 TYPE, 1 ROUTE, 2..5 P2..P5): 562 + 6f + k */
#define SFX_ID_LAST   573

/* the track -> voice (stem) map: BD SD RS CP BT LT MT HT CH OH CY CB share 8 voices */
static const uint8_t sfx_voice[SFX_NTRACK] = {0, 1, 2, 2, 3, 4, 5, 5, 6, 6, 7, 7};

/* ---- the TYPE table: graphs of library blocks ---- */
struct sfx_blk { char name[8]; uint8_t n; uint16_t p[8]; };              /* the block and its bases */
struct sfx_pmap { uint8_t b, p; uint16_t lo, hi; };                       /* P2..P5: block b's param p, lo..hi */
struct sfx_graph { char label[8]; uint8_t nb; struct sfx_blk b[SFX_NB]; struct sfx_pmap pm[4]; };

/* DELAY TIME (14 bits, exponential 0.05 ms .. 2 s): 5700 ~ 2 ms, 8200 ~ 7.5 ms, 11000 ~ 62 ms, 14000 ~ 470 ms */
static const struct sfx_graph sfx_types[] = {
  {"OFF", 0, {{"", 0, {0}}}, {{0, 0, 0, 0}}},
  {"CHORUS", 1, {{"DELAY", 8, {8200, 1500, 16383, 0, 0, 3000, 5000, 12000}}},
   {{0, 0, 7000, 9800}, {0, 5, 0, 16383}, {0, 6, 2000, 9000}, {0, 7, 0, 16383}}},
  {"COMB", 1, {{"DELAY", 8, {5700, 12000, 12000, 0, 0, 0, 6000, 0}}},
   {{0, 0, 3000, 8200}, {0, 1, 4000, 16000}, {0, 2, 4000, 16383}, {0, 3, 0, 9000}}},
  {"CRUSH", 1, {{"SHAPER", 5, {0, 0, 6000, 9000, 8192}}},
   {{0, 1, 0, 16383}, {0, 2, 0, 16383}, {0, 3, 0, 16383}, {0, 4, 0, 16383}}},
  {"RINGMOD", 1, {{"MOD", 5, {0, 9000, 16383, 0, 0}}},
   {{0, 1, 4000, 14000}, {0, 2, 0, 16383}, {0, 3, 0, 16383}, {0, 4, 0, 16383}}},
  {"ECHO", 2, {{"DELAY", 8, {13000, 7000, 12000, 1000, 0, 500, 4000, 0}}, {"FILTER", 4, {0, 11000, 3000, 0}}},
   {{0, 0, 10500, 15500}, {0, 1, 0, 15000}, {1, 1, 4000, 16383}, {0, 7, 0, 16383}}},
};
#define SFX_NTYPES ((int32_t)(sizeof sfx_types / sizeof sfx_types[0]))

/* ---- state ---- */
enum { J_IDLE = 0, J_FREE, J_PLACE, J_WAIT_PLACE, J_ROUTE, J_SETS, J_FAILED };
enum { PT_CHAIN = 0, PT_RET = 2, PT_SEND = 4, PT_N = 4 + 2 * SFX_NVOICE };   /* a graph's points: chain L R, return L R, sends */

struct sfx_fx {
  uint8_t job, built_type, nslot, placed;
  int8_t slot[SFX_NB];
  uint8_t seq[SFX_NB];                 /* PLACE's */
  int16_t pt[PT_N];                    /* the route's points, -1 none */
  uint8_t pseq[PT_N], asked[PT_N];     /* ROUTE's seq, asked and not answered */
  uint8_t next;                        /* the next point to ask */
  uint8_t ret_dirty, set_n;
  uint8_t lk_owed, lk_clear;           /* the locks want sending again: lk_clear sets still to CLEAR, then from lk_next */
  uint16_t lk_next;
  uint32_t t0;
};

static struct {
  uint32_t epoch, kgen, ticks, seq, kit_t, kit_owed, loaded;
  uint8_t v[SFX_SEC];                  /* the kit's values */
  struct sfx_fx fx[SFX_NFX];
  uint32_t send_dirty;                 /* bit 2t + f: track t's send to FX f wants a BASE */
  uint8_t p_dirty[SFX_NFX];            /* bit b: block b's bases */
  int32_t acc[SFX_ID_LAST - SFX_ID_SEND + 1];
  uint32_t pgen;                       /* the pattern record's load the locks are from */
  uint16_t ln;                         /* locks in lk */
  uint8_t lk[SFX_LMAX][3];             /* the playing pattern's locks: key, step, value */
  uint32_t ops, drops, refused, sessions, rebuilds, locks_sent, locks_full;   /* diagnostics */
} sfx __attribute__((section(".bss"), aligned(4)));

static uint8_t *sfx_fxv(int32_t f) { return &sfx.v[24 + 6 * f]; }
static const struct sfx_graph *sfx_graph(int32_t f) {
  uint8_t t = sfx_fxv(f)[0];
  return &sfx_types[t < SFX_NTYPES ? t : 0];
}

static void sfx_defaults(void) {
  int32_t i;
  for (i = 0; i < SFX_SEC; ++i) sfx.v[i] = 0;
  for (i = 0; i < SFX_NFX; ++i) {
    uint8_t *x = sfx_fxv(i);
    x[0] = i ? 1 : 5;                  /* FX 1 ECHO, FX 2 CHORUS */
    x[2] = x[3] = x[4] = x[5] = 64;
  }
}

static uint32_t sfx_gain(uint32_t v) { return v >= 127 ? SFX_UNITY : (v * v * SFX_UNITY + 127 * 127 / 2) / (127 * 127); }
static uint32_t sfx_pval(const struct sfx_pmap *m, uint32_t v) { return m->lo + ((uint32_t)(m->hi - m->lo) * v + 63) / 127; }

/* a block's base for param p: the TYPE's, or P2..P5's mapping */
static uint32_t sfx_base(int32_t f, int32_t b, int32_t p) {
  const struct sfx_graph *g = sfx_graph(f);
  int32_t k;
  for (k = 0; k < 4; ++k)
    if (g->pm[k].b == b && g->pm[k].p == p && g->pm[k].hi) return sfx_pval(&g->pm[k], sfx_fxv(f)[2 + k]);
  return g->b[b].p[p];
}

static int32_t sfx_op(const uint8_t *b, int32_t n) {
  if (!sc_link_send(b, n)) { sfx.drops++; return 0; }
  sfx.ops++;
  return 1;
}
static uint8_t sfx_seq(void) { return (uint8_t)(sfx.seq++ & 0x7f); }

/* ---- the p-locks ---- */
static int32_t sfx_key_fx(int32_t key) { return key < SFX_KEY_P ? key & 1 : (key - SFX_KEY_P) / 4; }

/* the lock's set on the Pi, its first param and how many (a send's L and R points), and the value for v; 0: none (a
   P with no mapping in this TYPE, the FX not built) */
static int32_t sfx_lock_target(int32_t key, uint32_t v, uint8_t *set, uint8_t *param, int32_t *n, uint32_t *val) {
  int32_t f = sfx_key_fx(key);
  const struct sfx_fx *x = &sfx.fx[f];
  if (key < SFX_KEY_P) {
    int32_t t = key >> 1, vo = sfx_voice[t];
    int16_t l = x->pt[PT_SEND + 2 * vo], r = x->pt[PT_SEND + 2 * vo + 1];
    if (l < 0) return 0;
    *set = (uint8_t)(SFX_SET_SEND + key); *param = 0; *n = r == l + 1 ? 2 : 1; *val = sfx_gain(v);
    return 1;
  } else {
    const struct sfx_pmap *m = &sfx_graph(f)->pm[(key - SFX_KEY_P) & 3];
    if (!m->hi || m->b >= x->nslot) return 0;
    *set = (uint8_t)(SFX_SET_P + 2 * f + m->b); *param = m->p; *n = 1; *val = sfx_pval(m, v);
    return 1;
  }
}

/* LOCK (or CLEAR with clear) the step on the Pi, if the FX's sets are there; 0: the queue is full */
static int32_t sfx_lock_send(int32_t key, int32_t step, uint32_t v, int32_t clear) {
  uint8_t set, param;
  int32_t n, i;
  uint32_t val;
  if (sfx.fx[sfx_key_fx(key)].job != J_IDLE || !sfx_lock_target(key, v, &set, &param, &n, &val)) return 1;
  for (i = 0; i < n; ++i) {
    uint8_t b[6] = {0x12, set, (uint8_t)step, (uint8_t)(param + i), (uint8_t)(val >> 7), (uint8_t)(val & 0x7f)};
    uint8_t c[4] = {0x13, set, (uint8_t)step, (uint8_t)(param + i)};
    if (!(clear ? sfx_op(c, 4) : sfx_op(b, 6))) return 0;
  }
  sfx.locks_sent++;
  return 1;
}

static int32_t sfx_lock_find(int32_t key, int32_t step) {
  int32_t i;
  for (i = 0; i < sfx.ln; ++i) if (sfx.lk[i][0] == key && sfx.lk[i][1] == step) return i;
  return -1;
}

/* the section: the layout byte, then the entries */
static void sfx_locks_save(void) {
  static uint8_t b[1 + 3 * SFX_LMAX] __attribute__((section(".bss")));
  int32_t i;
  b[0] = 1;
  for (i = 0; i < sfx.ln; ++i) { b[1 + 3 * i] = sfx.lk[i][0]; b[2 + 3 * i] = sfx.lk[i][1]; b[3 + 3 * i] = sfx.lk[i][2]; }
  sc_pat_put(SFX_MOD, b, sfx.ln ? 1 + 3 * (uint32_t)sfx.ln : 0);
}

/* the playing pattern's record (re)loaded: its locks, sent again for every FX */
static void sfx_locks_loaded(void) {
  static uint8_t b[1 + 3 * SFX_LMAX] __attribute__((section(".bss")));
  int32_t n = sc_pat_get(SFX_MOD, b, sizeof b), i, f;
  sfx.ln = 0;
  if (n > 1 && b[0] == 1)
    for (i = 0; 1 + 3 * i + 2 < n && sfx.ln < SFX_LMAX; ++i) {
      uint8_t k = b[1 + 3 * i], st = b[2 + 3 * i], v = b[3 + 3 * i];
      if (k < SFX_KEY_P + 4 * SFX_NFX && st < 64 && v <= 127) {
        sfx.lk[sfx.ln][0] = k; sfx.lk[sfx.ln][1] = st; sfx.lk[sfx.ln][2] = v; sfx.ln++;
      }
    }
  for (f = 0; f < SFX_NFX; ++f) { sfx.fx[f].lk_owed = 1; sfx.fx[f].lk_clear = 0; sfx.fx[f].lk_next = 0; }
}

/* FX f's locks again (its sets just declared, or another pattern): CLEAR 7F 7F on each of its sets, then every LOCK */
static void sfx_locks_flush(int32_t f) {
  struct sfx_fx *x = &sfx.fx[f];
  int32_t budget = SFX_LOCKS_TICK, nsets = x->nslot + SFX_NTRACK;
  if (!x->lk_owed || x->job != J_IDLE) return;
  while (x->lk_clear < nsets && budget > 0) {
    int32_t s = x->lk_clear;
    uint8_t set = (uint8_t)(s < x->nslot ? SFX_SET_P + 2 * f + s : SFX_SET_SEND + 2 * (s - x->nslot) + f);
    uint8_t c[4] = {0x13, set, 0x7f, 0x7f};
    if (!sfx_op(c, 4)) return;
    x->lk_clear++;
    budget--;
  }
  while (x->lk_next < sfx.ln && budget > 0) {
    const uint8_t *e = sfx.lk[x->lk_next];
    if (sfx_key_fx(e[0]) == f) {
      if (!sfx_lock_send(e[0], e[1], e[2], 0)) return;
      budget -= 2;
    }
    x->lk_next++;
  }
  if (x->lk_clear >= nsets && x->lk_next >= sfx.ln) x->lk_owed = 0;
}

/* the knob's lock key on track t, or -1 (TYPE, ROUTE; a send off a voice track, a P off the FX track) */
static int32_t sfx_key(int32_t id, int32_t t) {
  if (id < SFX_ID_SEND || id > SFX_ID_LAST) return -1;
  if (id < SFX_ID_FX) return t >= 0 && t < SFX_NTRACK ? 2 * t + (id - SFX_ID_SEND) : -1;
  id -= SFX_ID_FX;
  if (t != SFX_FXTRACK || id % 6 < 2) return -1;
  return SFX_KEY_P + 4 * (id / 6) + (id % 6 - 2);
}
/* the knob's value without a lock */
static uint32_t sfx_key_base(int32_t key) {
  return key < SFX_KEY_P ? sfx.v[key] : sfx_fxv((key - SFX_KEY_P) / 4)[2 + (key - SFX_KEY_P) % 4];
}

/* step's lock of id on track t (8.8), or -1 */
static int sfx_lock_get(int32_t id, int32_t t, int32_t step) {
  int32_t key = sfx_key(id, t), i;
  if (key < 0 || sc_pat_index() < 0) return -1;
  i = sfx_lock_find(key, step);
  return i < 0 ? -1 : (int)sfx.lk[i][2] << 8;
}

/* set (or, v < 0, clear) step's lock of key: 1 */
static int32_t sfx_lock_put(int32_t key, int32_t step, int32_t v) {
  int32_t i = sfx_lock_find(key, step);
  if (v < 0) {
    if (i < 0) return 1;
    sfx.lk[i][0] = sfx.lk[sfx.ln - 1][0]; sfx.lk[i][1] = sfx.lk[sfx.ln - 1][1]; sfx.lk[i][2] = sfx.lk[sfx.ln - 1][2];
    sfx.ln--;
    sfx_lock_send(key, step, 0, 1);
  } else {
    if (i < 0) {
      if (sfx.ln >= SFX_LMAX) { sfx.locks_full++; return 0; }
      i = sfx.ln++;
      sfx.lk[i][0] = (uint8_t)key; sfx.lk[i][1] = (uint8_t)step;
    }
    sfx.lk[i][2] = (uint8_t)v;
    sfx_lock_send(key, step, (uint32_t)v, 0);
  }
  sfx_locks_save();
  return 1;
}

/* the knob turned with step's trig held: the new lock (8.8), from the knob's value on the first turn; -1 none */
static int sfx_lock_turn(int32_t id, int32_t t, int32_t step, int32_t delta) {
  int32_t key = sfx_key(id, t), i, v, steps;
  if (key < 0 || sc_pat_index() < 0) return -1;
  i = sfx_lock_find(key, step);
  v = i < 0 ? (int32_t)sfx_key_base(key) : sfx.lk[i][2];
  sfx.acc[id - SFX_ID_SEND] += delta;
  steps = sfx.acc[id - SFX_ID_SEND] / 256;
  sfx.acc[id - SFX_ID_SEND] -= steps * 256;
  v += steps;
  v = v < 0 ? 0 : v > 127 ? 127 : v;
  if (!sfx_lock_put(key, step, v)) return -1;
  return v << 8;
}
static int sfx_lock_set(int32_t id, int32_t t, int32_t step, int32_t value) {
  int32_t key = sfx_key(id, t), v = value >> 8;
  if (key < 0 || sc_pat_index() < 0) return 0;
  return sfx_lock_put(key, step, v < 0 ? 0 : v > 127 ? 127 : v);
}
static int sfx_lock_clear(int32_t id, int32_t t, int32_t step) {
  int32_t key = sfx_key(id, t);
  if (key < 0 || sc_pat_index() < 0) return 0;
  return sfx_lock_put(key, step, -1);
}

/* the point's src and dst */
static void sfx_ends(int32_t f, int32_t k, uint8_t *src, uint8_t *dst) {
  const struct sfx_fx *x = &sfx.fx[f];
  int32_t last = x->nslot - 1, c = k & 1;
  if (k < PT_RET) { *src = (uint8_t)(12 + 2 * x->slot[0] + c); *dst = (uint8_t)(12 + 2 * x->slot[1] + c); }
  else if (k < PT_SEND) { *src = (uint8_t)(12 + 2 * x->slot[last] + c); *dst = (uint8_t)((sfx_fxv(f)[1] ? 0 : 2) + c); }
  else { *src = (uint8_t)(2 + (k - PT_SEND) / 2); *dst = (uint8_t)(12 + 2 * x->slot[0] + c); }
}
/* a point's gain when it opens: unity for the graph's own, the voice's first track's send */
static uint32_t sfx_open_gain(int32_t f, int32_t k) {
  int32_t t, v = (k - PT_SEND) / 2;
  if (k < PT_SEND) return SFX_UNITY;
  for (t = 0; t < SFX_NTRACK; ++t) if (sfx_voice[t] == v) return sfx_gain(sfx.v[2 * t + f]);
  return 0;
}
static int32_t sfx_wanted(int32_t f, int32_t k) { return k >= PT_RET || sfx.fx[f].nslot > 1; }

/* ---- the jobs ---- */
static void sfx_reset_fx(int32_t f) {
  struct sfx_fx *x = &sfx.fx[f];
  int32_t i;
  x->nslot = 0; x->placed = 0; x->built_type = 0; x->next = 0; x->ret_dirty = 0; x->set_n = 0;
  for (i = 0; i < SFX_NB; ++i) x->slot[i] = -1;
  for (i = 0; i < PT_N; ++i) { x->pt[i] = -1; x->asked[i] = 0; }
  x->job = sfx_graph(f)->nb ? J_PLACE : J_IDLE;
  x->t0 = sfx.ticks;
}

/* FREE the FX's slots (their points fade and close) and drop its sets */
static void sfx_to_free(int32_t f) { sfx.fx[f].job = J_FREE; sfx.fx[f].set_n = 0; }
static int32_t sfx_free(int32_t f) {
  struct sfx_fx *x = &sfx.fx[f];
  int32_t i;
  if (x->job != J_FREE) return 1;
  for (i = 0; i < x->nslot; ++i) {
    uint8_t b[3] = {0x31, SFX_OWNER, (uint8_t)x->slot[i]};
    uint8_t d[2] = {0x15, (uint8_t)(SFX_SET_P + 2 * f + i)};
    if (x->slot[i] < 0) continue;
    if (!sfx_op(b, 3) || !sfx_op(d, 2)) return 0;
    x->slot[i] = -1;
  }
  while (x->set_n < SFX_NTRACK) {      /* the send sets (dropping one never declared does nothing) */
    uint8_t d[2] = {0x15, (uint8_t)(SFX_SET_SEND + 2 * x->set_n + f)};
    if (!sfx_op(d, 2)) return 0;
    x->set_n++;
  }
  return 1;
}

static void sfx_place(int32_t f) {
  struct sfx_fx *x = &sfx.fx[f];
  const struct sfx_graph *g = sfx_graph(f);
  int32_t i, j;
  for (i = x->placed; i < g->nb; ++i) {   /* from the first not sent yet (a PLACE twice would fill two slots) */
    uint8_t b[4 + 8];
    int32_t n = 4;
    x->seq[i] = sfx_seq();
    b[0] = 0x30; b[1] = x->seq[i]; b[2] = SFX_OWNER; b[3] = 0x7f;
    for (j = 0; j < 8 && g->b[i].name[j]; ++j) b[n++] = (uint8_t)g->b[i].name[j];
    if (!sfx_op(b, n)) return;         /* the rest next tick */
    x->placed = (uint8_t)(i + 1);
  }
  x->nslot = g->nb;
  x->built_type = sfx_fxv(f)[0];
  x->job = J_WAIT_PLACE;
  x->t0 = sfx.ticks;
}

static void sfx_wait_place(int32_t f) {
  struct sfx_fx *x = &sfx.fx[f];
  int32_t i, got = 0;
  for (i = 0; i < x->nslot; ++i) {
    int32_t r = x->slot[i] >= 0 ? x->slot[i] : sc_dsp_result(SFX_OWNER, x->seq[i]);
    if (r == -256) continue;
    if (r < 0) { sfx.refused++; x->job = J_FAILED; x->t0 = sfx.ticks; return; }
    x->slot[i] = (int8_t)r;
    got++;
  }
  if (got == x->nslot) { x->job = J_ROUTE; x->next = 0; x->t0 = sfx.ticks; }
}

static void sfx_route(int32_t f) {
  struct sfx_fx *x = &sfx.fx[f];
  int32_t k, inflight = 0;
  for (k = 0; k < PT_N; ++k) {         /* the answers */
    int32_t r;
    if (!x->asked[k]) continue;
    r = sc_route_result(SFX_OWNER, x->pseq[k]);
    if (r == -256) { inflight++; continue; }
    x->asked[k] = 0;
    if (r < 0) { sfx.refused++; x->job = J_FAILED; x->t0 = sfx.ticks; return; }
    x->pt[k] = (int16_t)r;
    x->t0 = sfx.ticks;
  }
  while (x->next < PT_N && inflight < SFX_INFLIGHT) {   /* in order, so a voice's L and R come out adjacent */
    uint8_t b[7], src, dst;
    uint32_t g;
    k = x->next;
    if (!sfx_wanted(f, k)) { x->next++; continue; }
    sfx_ends(f, k, &src, &dst);
    g = sfx_open_gain(f, k);
    x->pseq[k] = sfx_seq();
    b[0] = 0x20; b[1] = x->pseq[k]; b[2] = SFX_OWNER; b[3] = src; b[4] = dst; b[5] = (uint8_t)(g >> 7); b[6] = (uint8_t)(g & 0x7f);
    if (!sfx_op(b, 7)) return;
    x->asked[k] = 1;
    x->next++;
    inflight++;
  }
  if (x->next >= PT_N && !inflight) { x->job = J_SETS; x->set_n = 0; }
}

/* the sets: a block's (on the FX track), then each track's send set on its voice's points */
static void sfx_sets(int32_t f) {
  struct sfx_fx *x = &sfx.fx[f];
  while (x->set_n < x->nslot + SFX_NTRACK) {
    int32_t s = x->set_n;
    if (s < x->nslot) {
      const struct sfx_blk *bk = &sfx_graph(f)->b[s];
      uint8_t set = (uint8_t)(SFX_SET_P + 2 * f + s);
      uint8_t d[6] = {0x10, set, SFX_FXTRACK, (uint8_t)x->slot[s], 0, bk->n};
      if (!sfx_op(d, 6)) return;
      sfx.p_dirty[f] |= (uint8_t)(1u << s);
    } else {
      int32_t t = s - x->nslot, v = sfx_voice[t];
      int16_t l = x->pt[PT_SEND + 2 * v], r = x->pt[PT_SEND + 2 * v + 1];
      uint8_t n = (uint8_t)(r == l + 1 ? 2 : 1);    /* not adjacent: the set has L; R follows with GAIN (sfx_flush) */
      uint8_t d[6] = {0x10, (uint8_t)(SFX_SET_SEND + 2 * t + f), (uint8_t)t, SFX_TARGET_ROUTE, (uint8_t)l, n};
      if (!sfx_op(d, 6)) return;
      sfx.send_dirty |= 1u << (2 * t + f);
    }
    x->set_n++;
  }
  x->job = J_IDLE;
  x->lk_owed = 1; x->lk_clear = 0; x->lk_next = 0;   /* the sets are new on the Pi: its locks again */
}

/* the bases owed: one BASE (and a GAIN for a lone R point) per dirty send, a block's whole set, the return's MOVE */
static void sfx_flush(void) {
  int32_t f, t, b, p;
  for (f = 0; f < SFX_NFX; ++f) {
    struct sfx_fx *x = &sfx.fx[f];
    if (x->job != J_IDLE || !x->nslot) continue;
    for (b = 0; b < x->nslot; ++b) {
      uint8_t d[4 + 16];
      int32_t n = sfx_graph(f)->b[b].n;
      if (!(sfx.p_dirty[f] & 1u << b)) continue;
      d[0] = 0x11; d[1] = (uint8_t)(SFX_SET_P + 2 * f + b); d[2] = 0; d[3] = (uint8_t)n;
      for (p = 0; p < n; ++p) { uint32_t v = sfx_base(f, b, p); d[4 + 2 * p] = (uint8_t)(v >> 7); d[5 + 2 * p] = (uint8_t)(v & 0x7f); }
      if (!sfx_op(d, 4 + 2 * n)) return;
      sfx.p_dirty[f] &= (uint8_t)~(1u << b);
    }
    for (t = 0; t < SFX_NTRACK; ++t) {
      int32_t v = sfx_voice[t];
      int16_t l = x->pt[PT_SEND + 2 * v], r = x->pt[PT_SEND + 2 * v + 1];
      uint32_t g = sfx_gain(sfx.v[2 * t + f]);
      uint8_t d[8] = {0x11, (uint8_t)(SFX_SET_SEND + 2 * t + f), 0, (uint8_t)(r == l + 1 ? 2 : 1),
                      (uint8_t)(g >> 7), (uint8_t)(g & 0x7f), (uint8_t)(g >> 7), (uint8_t)(g & 0x7f)};
      if (!(sfx.send_dirty & 1u << (2 * t + f))) continue;
      if (!sfx_op(d, r == l + 1 ? 8 : 6)) return;
      if (r != l + 1 && r >= 0) {
        uint8_t q[5] = {0x23, SFX_OWNER, (uint8_t)r, (uint8_t)(g >> 7), (uint8_t)(g & 0x7f)};
        if (!sfx_op(q, 5)) return;
      }
      sfx.send_dirty &= ~(1u << (2 * t + f));
    }
    if (x->ret_dirty) {
      int32_t c;
      for (c = 0; c < 2; ++c) {
        uint8_t m[6], src, dst;
        sfx_ends(f, PT_RET + c, &src, &dst);
        m[0] = 0x21; m[1] = sfx_seq(); m[2] = SFX_OWNER; m[3] = (uint8_t)x->pt[PT_RET + c]; m[4] = src; m[5] = dst;
        if (x->pt[PT_RET + c] >= 0 && !sfx_op(m, 6)) return;
      }
      x->ret_dirty = 0;
    }
  }
}

/* the kit's values in place (a load, or a reload of the record): a changed TYPE builds again, the rest is bases */
static void sfx_kit_loaded(void) {
  uint8_t old[SFX_SEC];
  int32_t i, f, n;
  for (i = 0; i < SFX_SEC; ++i) old[i] = sfx.v[i];
  n = sc_kit_get(SFX_MOD, sfx.v, SFX_SEC);
  if (n != SFX_SEC) sfx_defaults();     /* none yet (or another layout): the defaults, written at the first turn */
  for (i = 0; i < SFX_SEC; ++i) if (sfx.v[i] > 127) sfx.v[i] = 127;
  for (f = 0; f < SFX_NFX; ++f) if (sfx_fxv(f)[0] >= SFX_NTYPES) sfx_fxv(f)[0] = 0;
  sfx.kit_owed = 0;
  sfx.loaded = 1;
  for (f = 0; f < SFX_NFX; ++f) {
    struct sfx_fx *x = &sfx.fx[f];
    if (sfx_fxv(f)[0] != x->built_type || x->job == J_FAILED) { sfx_to_free(f); continue; }
    if (sfx_fxv(f)[1] != old[25 + 6 * f]) x->ret_dirty = 1;
    sfx.p_dirty[f] = 3;
  }
  sfx.send_dirty = 0xffffffu;
}

/* ev_tick (after the companion's, order 76) */
void sfx_tick(void *ctrl);
void sfx_tick(void *ctrl) {
  uint32_t e = sc_link_epoch(), g = sc_kit_gen(), pg = sc_pat_gen();
  int32_t f;
  (void)ctrl;
  sfx.ticks++;
  if (g && g != sfx.kgen) { sfx.kgen = g; sfx_kit_loaded(); }
  if (pg && pg != sfx.pgen) { sfx.pgen = pg; sfx_locks_loaded(); }
  if (!sfx.loaded) return;
  if (e != sfx.epoch) {                /* a new session (or the link closed): the Pi has nothing of ours */
    sfx.epoch = e;
    if (e) sfx.sessions++;
    for (f = 0; f < SFX_NFX; ++f) sfx_reset_fx(f);
  }
  if (!e) return;
  for (f = 0; f < SFX_NFX; ++f) {
    struct sfx_fx *x = &sfx.fx[f];
    if ((x->job == J_WAIT_PLACE || x->job == J_ROUTE) && sfx.ticks - x->t0 > SFX_TIMEOUT) { x->job = J_FAILED; x->t0 = sfx.ticks; }
    switch (x->job) {
      case J_FREE:
        if (sfx_free(f)) { sfx.rebuilds++; sfx_reset_fx(f); }
        break;
      case J_PLACE: sfx_place(f); break;
      case J_WAIT_PLACE: sfx_wait_place(f); break;
      case J_ROUTE:                    /* one FX at a time: the companion keeps only the last 16 answers */
        if (f && sfx.fx[0].job == J_ROUTE) break;
        sfx_route(f);
        break;
      case J_SETS: sfx_sets(f); break;
      case J_FAILED:                   /* again after a while: FREE takes every point that reached the Pi with it */
        if (sfx.ticks - x->t0 > SFX_TIMEOUT) sfx_to_free(f);
        break;
      default: break;
    }
  }
  sfx_flush();
  for (f = 0; f < SFX_NFX; ++f) sfx_locks_flush(f);
  if (sfx.kit_owed && sfx.ticks - sfx.kit_t >= SFX_DEBOUNCE && sc_kit_put(SFX_MOD, sfx.v, SFX_SEC)) sfx.kit_owed = 0;
}

/* ---- the pages ---- */
static int32_t sfx_track(void) { int32_t t = SFX_TRACK(); return t >= 0 && t <= 12 ? t : -1; }

/* the value behind a knob id, and its range */
static uint8_t *sfx_val(int32_t id, int32_t *max) {
  int32_t t;
  if (id < SFX_ID_SEND || id > SFX_ID_LAST) return 0;
  if (id < SFX_ID_FX) {
    t = sfx_track();
    if (t < 0 || t >= SFX_NTRACK) return 0;
    *max = 127;
    return &sfx.v[2 * t + (id - SFX_ID_SEND)];
  }
  id -= SFX_ID_FX;
  *max = id % 6 == 0 ? SFX_NTYPES - 1 : id % 6 == 1 ? 1 : 127;
  return &sfx_fxv(id / 6)[id % 6];
}

static int sfx_get(int32_t id, int32_t *value) {
  int32_t max;
  uint8_t *v = sfx_val(id, &max);
  if (!v) return 0;
  *value = (int32_t)*v << 8;
  return 1;
}

static int sfx_delta(void *view, int32_t id, int32_t delta, int32_t func) {
  int32_t max, steps, nv;
  uint8_t *v = sfx_val(id, &max);
  (void)view;
  if (!v) return 0;
  if (func) delta *= 8;                /* FUNC: coarse */
  sfx.acc[id - SFX_ID_SEND] += delta;
  steps = sfx.acc[id - SFX_ID_SEND] / 256;
  if (!steps) return 1;
  sfx.acc[id - SFX_ID_SEND] -= steps * 256;
  nv = (int32_t)*v + steps;
  nv = nv < 0 ? 0 : nv > max ? max : nv;
  if (nv == *v) return 1;
  *v = (uint8_t)nv;
  if (id < SFX_ID_FX) {
    int32_t t = sfx_track(), f = id - SFX_ID_SEND;
    sfx.send_dirty |= 1u << (2 * t + f);
  } else {
    int32_t f = (id - SFX_ID_FX) / 6, k = (id - SFX_ID_FX) % 6;
    if (k == 0) sfx_to_free(f);                    /* TYPE: the new graph */
    else if (k == 1) sfx.fx[f].ret_dirty = 1;      /* ROUTE: PRE / POST */
    else sfx.p_dirty[f] = 3;
  }
  sfx.kit_owed = 1;
  sfx.kit_t = sfx.ticks;
  return 1;
}

static int sfx_text(struct core_text *t) {
  int32_t id = t->id, k, i;
  const char *s;
  if (id < SFX_ID_SEND || id > SFX_ID_LAST) return CORE_TEXT_PASS;
  k = id < SFX_ID_FX ? 2 : (id - SFX_ID_FX) % 6;
  i = t->value >> 8;
  if (id < SFX_ID_FX || k > 1) {       /* a number */
    char d[4];
    int32_t n = 0, j = 0;
    if (i < 0) i = 0;
    do { d[n++] = (char)('0' + i % 10); i /= 10; } while (i && n < 3);
    while (n) t->buf[j++] = d[--n];
    t->buf[j] = 0;
    return CORE_TEXT_DONE;
  }
  if (k == 0) s = sfx_types[i >= 0 && i < SFX_NTYPES ? i : 0].label;
  else s = i ? "POST" : "PRE";
  for (i = 0; s[i]; ++i) t->buf[i] = s[i];
  t->buf[i] = 0;
  return CORE_TEXT_DONE;
}

const struct core_page sfx_page_amp2 = {SFX_PAGE_AMP2, "AMPLITUDE 2", {SFX_ID_SEND, SFX_ID_SEND + 1, 0, 0, 0, 0, 0, 0}};
const struct core_page sfx_page_fx1 = {SFX_PAGE_FX1, "SEND FX 1", {562, 563, 564, 565, 566, 567, 0, 0}};
const struct core_page sfx_page_fx2 = {SFX_PAGE_FX2, "SEND FX 2", {568, 569, 570, 571, 572, 573, 0, 0}};
const struct core_param sfx_params = {SFX_ID_SEND, SFX_ID_LAST, sfx_get, sfx_delta, sfx_text};
const struct core_param_lock sfx_locks = {SFX_ID_SEND, SFX_ID_LAST, sfx_lock_get, sfx_lock_turn, sfx_lock_set, sfx_lock_clear};
static int32_t sfx_on_voice(void *view) { int32_t t = sfx_track(); (void)view; return t >= 0 && t < SFX_NTRACK; }
const struct core_view_page sfx_view_amp2 = {CORE_VIEW_AMP, SFX_PAGE_AMP2, sfx_on_voice};
const struct core_view_page sfx_view_fx1 = {CORE_VIEW_DELAY, SFX_PAGE_FX1, 0};
const struct core_view_page sfx_view_fx2 = {CORE_VIEW_REVERB, SFX_PAGE_FX2, 0};

/* diagnostics (tests; a later status page): 0 ops, 1 drops, 2 refused, 3 sessions, 4 rebuilds, 5 + f FX f's job, 7 locks
   in the pattern, 8 locks sent, 9 locks refused (full) */
uint32_t sfx_diag(int32_t k);
uint32_t sfx_diag(int32_t k) {
  switch (k) {
    case 0: return sfx.ops;
    case 1: return sfx.drops;
    case 2: return sfx.refused;
    case 3: return sfx.sessions;
    case 4: return sfx.rebuilds;
    case 5: case 6: return sfx.fx[k - 5].job;
    case 7: return sfx.ln;
    case 8: return sfx.locks_sent;
    case 9: return sfx.locks_full;
    default: return 0;
  }
}
