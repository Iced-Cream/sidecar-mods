/* mods/0032-sidecar/rec.c - the item records every mod shares: the current kit's (the send FX phase; the kit handle
 * claim approved 2026-11-05) and the playing pattern's (the pattern handle approved 2026-11-04). Included by sidecar.c
 * after store.c, whose requests and sc_phand it uses.
 *
 *   sc_khand 16 bits, kit scope   the kit's record on the Pi (kv scope 1), 0 none
 *   sc_phand 16 bits, pattern     the pattern's record on the Pi (kv scope 3), 0 none (store.c declares it)
 *
 * A handle travels with its item (copy, paste, save, reload), so a copied kit or pattern names the same record version
 * until either copy changes: a write is always a new version, and only the item it was for takes the new handle.
 *
 * A record: one section per mod, <mod hi> <mod lo> <len hi> <len lo> <len bytes>, mod = the mod's number (25 for
 * 0025-sendfx), in any order; the kit's SC_KMAX bytes in all, the pattern's SC_PMAX. The companion keeps the current
 * item's record in RAM: read when the item (its index) or its handle changes, at a project load, and once at the first
 * link. A mod reads its section with sc_kit_get / sc_pat_get and replaces it with sc_kit_put / sc_pat_put; the
 * companion then writes the whole record as a new version and sets the new handle in the item it was read for, even if
 * the current item changed meanwhile. sc_kit_gen() / sc_pat_gen() change each time a record is loaded (0 while none
 * is): a mod reads its section again when it changes. sc_pat_index() is the pattern the record is for (-1 none).
 *
 * The kit's record is written at the next tick after a put (its mods wait for the turns to stop themselves); the
 * pattern's SC_PQUIET ticks after the last, or at once when another pattern starts playing, before its record loads.
 *
 * The pattern is the one playing (stock edits the playing pattern: a trig held, a knob turned, core-ar2's lock calls).
 * When it changes, the new one's record is read from the Pi, so a mod's first steps after a switch may still play the
 * old pattern's data until it arrives [I].
 *
 * Threads: all of it in the UI task (ev_tick and the mods' calls from it); the callbacks come from sc_store_tick. */
STORE_FIELD(sc_khand);

#ifndef SC_KIT_INDEX                   /* core-ar2's words for the current kit (its lock.c, midi.c) */
#define SC_KIT_INDEX ((const volatile uint8_t *)0x405c8f20u + 0x19d3f7)   /* 32 bits, big-endian, 0..127 */
#define SC_KIT(k)   ((void *)(0x412558e3u + 2531u * (uint32_t)(k)))       /* the live kit k */
#endif
#ifndef SC_PAT_NOW
#define SC_PAT_NOW  (*(const volatile int8_t *)0x405c8d04u)   /* the playing pattern (clock.c's CK_PAT) */
#endif
#define SC_KMAX     256                /* the kit record's bytes */
#define SC_PMAX     1536               /* the pattern record's bytes */
#define SC_RRETRY   90                 /* ticks before a failed read is tried again */
#define SC_RHEAD    4                  /* a section's head: mod 2, len 2 */
#define SC_PQUIET   12                 /* ticks a changed pattern record waits for more changes before it is written
                                          (a knob turned with a trig held changes it each detent); a switch to another
                                          pattern writes it at once */

enum { R_NONE = 0, R_READING, R_READY, R_FAILED };

struct sc_rec {
  uint32_t scope, max, quiet;         /* quiet: ticks after the last put before the write */
  uint32_t (*now)(void);               /* the current item's index, 0xffffffff none */
  uint32_t (*hget)(uint32_t i);        /* item i's handle */
  void (*hset)(uint32_t i, uint32_t h);
  uint32_t state, idx, handle;         /* the copy is of item idx whose handle was handle */
  uint32_t gen, gens;                  /* gen: 0, or the number of the load the copy is from */
  uint32_t n, dirty, writing, widx, ridx, rhandle, failed_t, project, put_t;
  uint8_t *d, *r, *w;
  uint32_t loads, writes, errors, full;   /* diagnostics */
};

static uint32_t sc_kit_now(void) {
  const volatile uint8_t *p = SC_KIT_INDEX;
  uint32_t k = (uint32_t)p[0] << 24 | (uint32_t)p[1] << 16 | (uint32_t)p[2] << 8 | p[3];
  return k < 128 ? k : 0xffffffffu;
}
static uint32_t sc_kit_hget(uint32_t k) { return core_store_get(STORE(sc_khand), SC_KIT(k), 0); }
static void sc_kit_hset(uint32_t k, uint32_t h) { core_store_set(STORE(sc_khand), SC_KIT(k), 0, h); }
static uint32_t sc_pat_now(void) { int32_t p = SC_PAT_NOW; return p >= 0 && p < 128 ? (uint32_t)p : 0xffffffffu; }
static uint32_t sc_pat_hget(uint32_t p) { return sc_pattern_handle((int32_t)p); }
static void sc_pat_hset(uint32_t p, uint32_t h) { sc_set_pattern_handle((int32_t)p, h); }

static uint8_t sck_buf[3][SC_KMAX] SC_BSS, scp_buf[3][SC_PMAX] SC_BSS;
static struct sc_rec sck SC_BSS, scp SC_BSS;

static void sc_rec_init(void) {
  if (sck.d) return;
  sck.scope = 1; sck.max = SC_KMAX; sck.now = sc_kit_now; sck.hget = sc_kit_hget; sck.hset = sc_kit_hset;
  sck.d = sck_buf[0]; sck.r = sck_buf[1]; sck.w = sck_buf[2];
  scp.scope = 3; scp.max = SC_PMAX; scp.quiet = SC_PQUIET; scp.now = sc_pat_now; scp.hget = sc_pat_hget; scp.hset = sc_pat_hset;
  scp.d = scp_buf[0]; scp.r = scp_buf[1]; scp.w = scp_buf[2];
}

/* the offset of mod's section in d[0..n), or -1 */
static int32_t sc_rec_find(const uint8_t *d, uint32_t n, uint32_t mod) {
  uint32_t o = 0;
  while (o + SC_RHEAD <= n) {
    uint32_t len = (uint32_t)d[o + 2] << 8 | d[o + 3];
    if (o + SC_RHEAD + len > n) break;
    if (((uint32_t)d[o] << 8 | d[o + 1]) == mod) return (int32_t)o;
    o += SC_RHEAD + len;
  }
  return -1;
}

static int32_t sc_rec_get(struct sc_rec *s, uint32_t mod, uint8_t *buf, uint32_t cap) {
  int32_t o;
  uint32_t n, i;
  if (s->state != R_READY) return -1;
  o = sc_rec_find(s->d, s->n, mod & 0xffff);
  if (o < 0) return 0;
  n = (uint32_t)s->d[o + 2] << 8 | s->d[o + 3];
  if (n > cap) n = cap;
  for (i = 0; i < n; ++i) buf[i] = s->d[(uint32_t)o + SC_RHEAD + i];
  return (int32_t)n;
}

/* the others' sections as they were into w, then mod's new one at the end; the record is then w */
static int32_t sc_rec_put(struct sc_rec *s, uint32_t mod, const uint8_t *src, uint32_t n) {
  uint32_t o = 0, m = 0, i;
  if (s->state != R_READY) return 0;
  mod &= 0xffff;
  if (n && s->n + SC_RHEAD + n > s->max) {   /* might not fit even without mod's old section: count it exactly */
    int32_t at = sc_rec_find(s->d, s->n, mod);
    uint32_t old = at < 0 ? 0 : SC_RHEAD + ((uint32_t)s->d[at + 2] << 8 | s->d[at + 3]);
    if (s->n - old + SC_RHEAD + n > s->max) { s->full++; return 0; }
  }
  /* in place: drop mod's section by moving the rest down, then append */
  while (o + SC_RHEAD <= s->n) {
    uint32_t len = SC_RHEAD + ((uint32_t)s->d[o + 2] << 8 | s->d[o + 3]);
    if (o + len > s->n) break;
    if (((uint32_t)s->d[o] << 8 | s->d[o + 1]) != mod) {
      if (m != o) for (i = 0; i < len; ++i) s->d[m + i] = s->d[o + i];
      m += len;
    }
    o += len;
  }
  if (n) {
    s->d[m] = (uint8_t)(mod >> 8); s->d[m + 1] = (uint8_t)mod;
    s->d[m + 2] = (uint8_t)(n >> 8); s->d[m + 3] = (uint8_t)n;
    for (i = 0; i < n; ++i) s->d[m + SC_RHEAD + i] = src[i];
    m += SC_RHEAD + n;
  }
  s->n = m;
  s->dirty = 1;
  s->put_t = scl.ticks;
  return 1;
}

static void sc_rec_read_cb(int32_t st, int32_t n, uint32_t h, void *ctx) {
  struct sc_rec *s = (struct sc_rec *)ctx;
  uint32_t i;
  (void)h;
  if (s->state != R_READING) return;
  if (s->ridx != s->idx || s->rhandle != s->handle || s->project != scl.proj) { s->state = R_NONE; return; }   /* moved on */
  if (st == 1) n = 0;                  /* the Pi has no such record (cleared): an empty one */
  else if (st) { s->state = R_FAILED; s->failed_t = scl.ticks; s->errors++; return; }
  for (i = 0; i < (uint32_t)n && i < s->max; ++i) s->d[i] = s->r[i];
  s->n = (uint32_t)n < s->max ? (uint32_t)n : s->max;
  s->gen = ++s->gens ? s->gens : ++s->gens;
  s->state = R_READY;
  s->loads++;
}

static void sc_rec_write_cb(int32_t st, int32_t n, uint32_t h, void *ctx) {
  struct sc_rec *s = (struct sc_rec *)ctx;
  (void)n;
  s->writing = 0;
  if (st || !h) { s->errors++; if (s->widx == s->idx) s->dirty = 1; return; }   /* the next tick tries again */
  s->hset(s->widx, h & 0xffff);
  if (s->widx == s->idx) s->handle = h & 0xffff;
  s->writes++;
}

/* ev_tick, from sc_store_tick: writes owed, then a load when the current item or its handle changed */
static void sc_rec_tick(struct sc_rec *s) {
  uint32_t k = s->now(), h;
  if (s->dirty && !s->writing && s->state == R_READY &&   /* first what was changed, for the item it belongs to */
      (k != s->idx || scl.ticks - s->put_t >= s->quiet)) {
    uint32_t i;
    for (i = 0; i < s->n; ++i) s->w[i] = s->d[i];
    if (sc_store_write((int32_t)s->scope, s->w, s->n, sc_rec_write_cb, s)) { s->dirty = 0; s->writing = 1; s->widx = s->idx; }
    return;
  }
  if (s->dirty || k >= 128) return;
  h = s->hget(k);
  if (s->state == R_READING) return;
  if (s->state == R_FAILED && scl.ticks - s->failed_t < SC_RRETRY && k == s->idx && h == s->handle) return;
  if (s->state == R_READY && k == s->idx && h == s->handle && s->project == scl.proj) return;
  if (!scl.proj) return;
  s->idx = k; s->handle = h; s->project = scl.proj;
  s->state = R_NONE;
  if (!h) {                            /* no record yet: an empty one */
    s->n = 0;
    s->gen = ++s->gens ? s->gens : ++s->gens;
    s->state = R_READY;
    s->loads++;
    return;
  }
  if (!scl.epoch) return;              /* read once the Pi has the project open (a queued read would wait for it) */
  s->ridx = k; s->rhandle = h;
  if (sc_store_read((int32_t)s->scope, h, s->r, s->max, sc_rec_read_cb, s)) s->state = R_READING;
}

static void sc_kit_tick(void) { sc_rec_init(); sc_rec_tick(&sck); sc_rec_tick(&scp); }

/* ev_project, from sc_project_ev: every kit and pattern is the loaded project's now */
static void sc_kit_project(void) {
  sc_rec_init();
  if (sck.state != R_READING) sck.state = R_NONE;
  if (scp.state != R_READING) scp.state = R_NONE;
  sck.dirty = scp.dirty = 0;
}

/* ---- the mods' calls ---- */

/* the current kit's handle (0: none, or no current kit) */
uint32_t sc_kit_handle(void);
uint32_t sc_kit_handle(void) { uint32_t k = sc_kit_now(); return k < 128 ? sc_kit_hget(k) : 0; }
uint32_t sc_kit_gen(void);
uint32_t sc_kit_gen(void) { return sck.state == R_READY ? sck.gen : 0; }
/* mod's section of the current kit's record into buf: its length (0: none yet), or -1 while no record is loaded */
int32_t sc_kit_get(uint32_t mod, uint8_t *buf, uint32_t cap);
int32_t sc_kit_get(uint32_t mod, uint8_t *buf, uint32_t cap) { sc_rec_init(); return sc_rec_get(&sck, mod, buf, cap); }
/* replace mod's section (n bytes; 0 removes it): 1, written as a new version soon; 0 while no record is loaded or when
   the record would pass SC_KMAX */
int32_t sc_kit_put(uint32_t mod, const uint8_t *src, uint32_t n);
int32_t sc_kit_put(uint32_t mod, const uint8_t *src, uint32_t n) { sc_rec_init(); return sc_rec_put(&sck, mod, src, n); }

/* the same for the playing pattern's record (SC_PMAX bytes) */
uint32_t sc_pat_handle(void);
uint32_t sc_pat_handle(void) { uint32_t p = sc_pat_now(); return p < 128 ? sc_pat_hget(p) : 0; }
uint32_t sc_pat_gen(void);
uint32_t sc_pat_gen(void) { return scp.state == R_READY ? scp.gen : 0; }
int32_t sc_pat_index(void);
int32_t sc_pat_index(void) { return scp.state == R_READY ? (int32_t)scp.idx : -1; }
int32_t sc_pat_get(uint32_t mod, uint8_t *buf, uint32_t cap);
int32_t sc_pat_get(uint32_t mod, uint8_t *buf, uint32_t cap) { sc_rec_init(); return sc_rec_get(&scp, mod, buf, cap); }
int32_t sc_pat_put(uint32_t mod, const uint8_t *src, uint32_t n);
int32_t sc_pat_put(uint32_t mod, const uint8_t *src, uint32_t n) { sc_rec_init(); return sc_rec_put(&scp, mod, src, n); }
