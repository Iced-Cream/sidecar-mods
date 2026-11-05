/* The companion's store client (Storage phase, 2026-11-04; design.md "The store link"): the Pi's generic record store
 * (host-link 51 STORE, sidecar-firmware core/kv/kv.h) and its parameter-lock service (51 ops 10..15, core/locks) for
 * any mod on the Rytm. Included by sidecar.c, one translation unit.
 *
 * Two core-ar2 fields (approved 2026-11-04), declared in mod.toml [elek] storage:
 *   sc_proj  32 bits, project scope   the project's ID: names its folder of records on the Pi. Given at the first
 *                                     ev_project that finds it 0 (CREATE NEW, a project saved without the companion);
 *                                     SAVE PROJECT AS copies it, so the two projects then share one folder (records
 *                                     are versions and never overwritten, so neither loses a record; a KEEP would)
 *   sc_phand 16 bits, pattern scope   a record handle for each pattern (0 none), for mods that keep a pattern's data
 *   sc_khand 16 bits, kit scope       the current kit's record, one section per mod (rec.c)
 *                                     on the Pi (the lock tables); copy and paste of a pattern carry it (core)
 *
 * The link (all F0 7D 52 54 51 01 <op> ... F7, kv.h has the codec):
 *   HELLO <project 5>  at each USB port-up and project change, tried 3 times 2 s apart while unanswered, and once
 *                      more when a host message arrives while unanswered (a Sidecar that came up late). The Pi's
 *                      HELLO answer opens the link: sc_link_epoch() bumps, and the Pi has forgotten every lock set, so
 *                      a mod declares its sets again when the epoch changes. The step clock (clock.c) runs while open.
 *   READ / WRITE       one request at a time from a queue of SC_NQ, sent from ev_tick; answers in the MIDI task
 *                      (sc_store_host, the router's direct entry for 51), the callback in the next ev_tick. A request
 *                      waits while the link is closed; once sent it times out after SC_TIMEOUT ticks.
 *   NAME <project 5> <len> <name>   the project's name (16 bytes at 0x407c89d3, as 0021 read it [measured there:
 *                      follows LOAD and SAVE AS NEW]), polled each tick: sent once the link opens (each new epoch)
 *                      and when it changes and has held SC_NAME_STABLE ticks. The Pi keeps it for its log and pages.
 *   lock ops 10..15    sc_link_send queues a whole op (the Pi answers none): sent in order, before the requests.
 *   route ops 20..23   the Pi's audio route (sidecar-firmware core/route, the audio route phase 2026-11-04): queued
 *                      and sent as the lock ops. The Pi answers ROUTE / MOVE with 60 ROUTED <seq> <owner> <point> or
 *                      61 REFUSED <seq> <owner> <code>; the companion keeps the last SC_NR answers for
 *                      sc_route_result(owner, seq). A point's gain is lock target 64 (param = the point).
 *   DSP ops 30..32     the Pi's library of blocks (sidecar-firmware core/dsp, the send FX phase 2026-11-05): queued and
 *                      sent as the lock ops. PLACE's answer, 70 PLACED <seq> <owner> <slot> or 71 REFUSED <seq> <owner>
 *                      <code>, kept with the route's for sc_dsp_result(owner, seq); INFO's 72 TEXT is not kept.
 * The cache: SC_NC records of up to SC_CMAX bytes, by (scope, handle), filled by every read and write that fits. A
 * handle names one version that never changes, so a cached record is never stale: a read that hits it needs no Pi.
 *
 * Threads: the requests, the cache and the sends belong to the UI task (ev_tick, and the mods' calls from it); the
 * MIDI task writes only the answer fields of the request in flight (scl.cur) and the link words, state word last. */
#include "analog-rytm-mk2/store.h"

STORE_FIELD(sc_proj);
STORE_FIELD(sc_phand);
#ifdef SC_HOST                         /* a PC's pointers want 8 */
#define SC_BSS __attribute__((section(".bss")))
#else
#define SC_BSS __attribute__((section(".bss"), aligned(4)))
#endif
static void sc_kit_tick(void);       /* rec.c: the kit and pattern records (sidecar.c includes it after this file) */
static void sc_kit_project(void);

#define SC_NQ       4
#define SC_NC       4
#define SC_CMAX     256
#define SC_CHUNK    112                /* raw bytes a WRITE chunk (128 on the wire), kv::kChunk */
#define SC_TIMEOUT  60                 /* ticks (ev_tick, 20..30 Hz): 2..3 s */
#define SC_HELLO_EVERY 45
#define SC_HELLO_TRIES 3
#define SC_LQ       512                /* bytes of queued lock ops */
#define SC_LMAX     120                /* the longest lock op body */
#define SC_NR       16                 /* route answers kept (60 / 61) */
#define SC_ROUTE_PENDING (-256)
#ifndef PORT_STATE                     /* the USB MIDI sender's words (fxin.c's until the FX return left, 2026-11-04) */
typedef void (*send_fn)(int32_t n, const uint8_t *m);
typedef int32_t (*trylock_fn)(void *m);
typedef void (*unlock_fn)(void *m);
#define MIDI_SEND   ((send_fn)0x400029e0u)
#define MIDI_MUTEX  ((void *)0x42f67a28u)
#define MUTEX_TRY   ((trylock_fn)0x4000119cu)      /* never pends: 1 taken, 0 not now */
#define MUTEX_GIVE  ((unlock_fn)0x400011eeu)
#define PORT_STATE  (*(volatile uint32_t *)0x413db254u)   /* 1: the USB port configured */
#define TX_LEVEL    (*(volatile int32_t *)0x413db258u)    /* the sender spins while level + n > 4091 */
#define USB_POOL    (*(const volatile uint32_t *const volatile *)0x413db390u)   /* free requests, next at +52 */
#endif
#ifndef SC_TXSX                        /* the firmware's words (test/: the host test gives its own) */
#define SC_TXSX     (*(const volatile uint32_t *)0x413db244u)   /* the sender's SysEx state: a stock dump under way */
#define SC_RAND_A   (*(volatile uint32_t *)0xfc07000cu)         /* DTCN0, the bus-clock count */
#define SC_RAND_B   (*(const volatile uint32_t *)0x419ca2acu)   /* the audio block counter */
#define SC_PAT(p)   ((void *)(0x407dd8e3u + 85760u * (uint32_t)(p)))   /* live pattern p (core-ar2's pattern item) */
#define SC_NAME     ((const volatile uint8_t *)0x407c89d3u)     /* the project's name, 16 bytes (0021's PROJECT_NAME) */
#endif
#define SC_NAME_STABLE 10              /* ticks a changed name must hold before it goes (a name being typed) */

enum { RQ_FREE = 0, RQ_QUEUED, RQ_SENT, RQ_DONE };
enum { OP_HELLO = 0x00, OP_READ = 0x01, OP_WRITE = 0x02, OP_NAME = 0x04, OP_ACK = 0x40, OP_DATA = 0x41, OP_WRITTEN = 0x42,
       OP_ROUTED = 0x60, OP_REFUSED = 0x61, OP_PLACED = 0x70, OP_DSP_REFUSED = 0x71, OP_TEXT = 0x72, OP_STATUS = 0x7f };
#define ST_TIMEOUT 0x7e                /* the companion's own: no answer */

typedef void (*sc_store_cb)(int32_t status, int32_t n, uint32_t handle, void *ctx);

struct sc_req {
  volatile uint32_t state;
  uint8_t op, scope, seq, pad;
  uint32_t handle;                     /* READ: asked; WRITE: the answer */
  uint8_t *buf;                        /* READ: where to */
  const uint8_t *src;                  /* WRITE: from (the caller keeps it until the callback) */
  uint32_t n, cap, sent;               /* WRITE: n bytes, sent so far; READ: cap */
  volatile uint32_t got, total, status;
  uint32_t t0;
  sc_store_cb cb;
  void *ctx;
};

static struct {
  struct sc_req q[SC_NQ];
  uint32_t qh, qt;                     /* q[qt % SC_NQ] in flight or next */
  struct sc_req *volatile cur;         /* the one sent (the MIDI task's) */
  volatile uint32_t epoch;             /* 0 closed; bumped by each HELLO answer */
  volatile uint32_t acked;             /* a HELLO answer arrived (MIDI task) */
  volatile uint32_t host_msg;          /* a host message arrived (sc_sysex) */
  volatile uint32_t records;           /* the Pi's records in this project, from its HELLO answer */
  uint32_t proj, rand, gen, opened, hello_owed, tries, hello_t, ticks, was_up, seq, txsx_n, cn;
  struct { uint32_t used, scope, handle, n; uint8_t d[SC_CMAX]; } c[SC_NC];
  uint8_t name[16], name_sent[16];     /* the stock name as last polled; as last sent */
  uint32_t name_stable, name_owed, name_epoch, names;
  uint8_t lq[SC_LQ];                   /* lock ops: {len, body...} */
  uint32_t lh, lt;
  struct { volatile uint32_t key; volatile int32_t res; } r[SC_NR];   /* route answers: key = 1 << 16 | owner << 8 | seq */
  volatile uint32_t rn;                /* answers written (MIDI task) */
  uint32_t hellos, acks, reqs, done, errors, timeouts, hits, lock_ops, lock_drops, bad;   /* diagnostics */
} scl SC_BSS;

/* ---- sending (the UI task; never waits): 0029's try_send, sized, and never inside a stock SysEx dump (it would
   land inside it), unless the dump's flag has stayed set for 2 s (a dump cut by a cable pull) */
static int32_t sc_send(const uint8_t *m, int32_t n) {
  const volatile uint32_t *h;
  int32_t k;
  if (PORT_STATE != 1) return 0;
  if (SC_TXSX && scl.txsx_n < SC_TIMEOUT) return 0;
  if (!MUTEX_TRY(MIDI_MUTEX)) return 0;
  h = USB_POOL;
  for (k = 0; k < 4 && h; ++k) h = (const volatile uint32_t *)h[13];
  if (TX_LEVEL + n > 4091 || k < 4) {
    MUTEX_GIVE(MIDI_MUTEX);
    return 0;
  }
  MIDI_SEND(n, m);
  MUTEX_GIVE(MIDI_MUTEX);
  return 1;
}

static uint8_t *sc_head(uint8_t *m, uint8_t op) {
  m[0] = 0xf0; m[1] = 0x7d; m[2] = 0x52; m[3] = 0x54; m[4] = 0x51; m[5] = 0x01; m[6] = op;
  return m + 7;
}
static void sc_h3(uint8_t *b, uint32_t h) { b[0] = (uint8_t)(h >> 14 & 3); b[1] = (uint8_t)(h >> 7 & 0x7f); b[2] = (uint8_t)(h & 0x7f); }
static void sc_14(uint8_t *b, uint32_t v) { b[0] = (uint8_t)(v >> 7 & 0x7f); b[1] = (uint8_t)(v & 0x7f); }

static int32_t sc_pack7(const uint8_t *in, int32_t n, uint8_t *out) {
  int32_t o = 0, i, j;
  for (i = 0; i < n; i += 7) {
    int32_t g = n - i < 7 ? n - i : 7;
    uint8_t hi = 0;
    for (j = 0; j < g; ++j) hi |= (uint8_t)((in[i + j] >> 7) << j);
    out[o++] = hi;
    for (j = 0; j < g; ++j) out[o++] = in[i + j] & 0x7f;
  }
  return o;
}

/* sc_sysex (sidecar.c): any host message */
static void sc_heard(void) { scl.host_msg = 1; }

/* ---- the project ID */
static uint32_t sc_new_id(void) {
  uint32_t x = scl.rand ^ SC_RAND_A ^ SC_RAND_B ^ 0x9e3779b9u;
  x ^= x << 13; x ^= x >> 17; x ^= x << 5;
  scl.rand = x;
  return x ? x : 1;
}

/* ev_project (core-ar2): the project's ID (a new one if it has none), and a HELLO for it */
void sc_project_ev(int32_t how, uint32_t dropped);
void sc_project_ev(int32_t how, uint32_t dropped) {
  uint32_t id = core_store_get(STORE(sc_proj), 0, 0);
  (void)how; (void)dropped;
  if (!id) {
    id = sc_new_id();
    core_store_set(STORE(sc_proj), 0, 0, id);
  }
  scl.proj = id;
  sc_kit_project();
  scl.epoch = 0;                       /* closed until the Pi has opened this project */
  scl.hello_owed = 1;
  scl.tries = 0;
}

/* ---- the answers: the router's direct entry for 51, the MIDI task */
static uint32_t sc_get_h(const uint8_t *b) { return b[0] > 3 ? 0x10000u : ((uint32_t)b[0] << 14 | (uint32_t)b[1] << 7 | b[2]); }
static uint32_t sc_get_14(const uint8_t *b) { return (uint32_t)b[0] << 7 | b[1]; }

static void sc_finish(struct sc_req *r, uint32_t st) {
  r->status = st;
  scl.cur = 0;
  r->state = RQ_DONE;
}

int sc_store_host(const uint8_t *d, int32_t len);
int sc_store_host(const uint8_t *d, int32_t len) {
  const uint8_t *b = d + 7;
  int32_t bn = len - 8, i;
  struct sc_req *r = scl.cur;
  if (len < 8 || d[5] != 0x01 || d[len - 1] != 0xf7) { scl.bad++; return 1; }
  switch (d[6]) {
    case OP_ACK:                       /* 40 <version> <records 2> */
      if (bn < 3) break;
      scl.records = sc_get_14(b + 1);
      scl.acked = 1;
      return 1;
    case OP_DATA: {                    /* 41 <seq> <scope> <handle 3> <total 2> <offset 2> <data> */
      uint32_t total, off, o, hi = 0;
      if (bn < 9 || !r || r->op != OP_READ || b[0] != r->seq) break;
      total = sc_get_14(b + 5);
      off = sc_get_14(b + 7);
      if (total > r->cap) { sc_finish(r, 6); return 1; }   /* kv kTooBig: the caller's buffer */
      if (off != r->got) { sc_finish(r, 5); return 1; }
      o = off;
      for (i = 9; i < bn; ++i) {       /* 7-in-8 groups: a byte of high bits, then up to 7 */
        int32_t j = (i - 9) % 8;
        if (j == 0) { hi = b[i]; continue; }
        if (o >= total) { sc_finish(r, 5); return 1; }
        r->buf[o++] = (uint8_t)(b[i] | ((hi >> (j - 1) & 1) << 7));
      }
      r->got = o;
      r->total = total;
      if (o >= total) sc_finish(r, 0);
      return 1;
    }
    case OP_WRITTEN:                   /* 42 <seq> <scope> <handle 3> */
      if (bn < 5 || !r || r->op != OP_WRITE || b[0] != r->seq) break;
      r->handle = sc_get_h(b + 2);
      sc_finish(r, 0);
      return 1;
    case OP_ROUTED:                    /* 60 <seq> <owner> <point> */
    case OP_REFUSED:                   /* 61 <seq> <owner> <code> */
    case OP_PLACED:                    /* 70 <seq> <owner> <slot> */
    case OP_DSP_REFUSED: {             /* 71 <seq> <owner> <code> */
      uint32_t i2, ok = d[6] == OP_ROUTED || d[6] == OP_PLACED;
      if (bn < 3) break;
      i2 = scl.rn % SC_NR;
      scl.r[i2].key = 0;
      scl.r[i2].res = ok ? (int32_t)b[2] : -(int32_t)(b[2] ? b[2] : 5);
      scl.r[i2].key = (d[6] >= OP_PLACED ? 2u : 1u) << 16 | (uint32_t)b[1] << 8 | b[0];   /* the key last: the UI task reads it first */
      scl.rn++;
      return 1;
    }
    case OP_TEXT:                      /* 72 TEXT (an answer to INFO): not kept, the library is fixed per Pi engine */
      return 1;
    case OP_STATUS:                    /* 7F <seq | 7F> <code> */
      if (bn < 2) break;
      if (r && (b[0] == r->seq || b[0] == 0x7f)) sc_finish(r, b[1] ? b[1] : 5);
      else scl.errors++;
      return 1;
  }
  scl.bad++;
  return 1;
}

/* ---- the requests (the UI task) */
static struct sc_req *sc_new(uint8_t op, int32_t scope, sc_store_cb cb, void *ctx) {
  struct sc_req *r;
  if (scl.qh - scl.qt >= SC_NQ || scope < 0 || scope > 7) return 0;
  r = &scl.q[scl.qh % SC_NQ];
  r->op = op; r->scope = (uint8_t)scope; r->cb = cb; r->ctx = ctx;
  r->got = 0; r->total = 0; r->status = 0; r->sent = 0; r->handle = 0;
  r->state = RQ_QUEUED;
  scl.qh++;
  scl.reqs++;
  return r;
}

/* the record (scope 0..7, handle 1..0xffff) into buf (cap bytes); cb(status, bytes, handle, ctx) from ev_tick. 0: the
   queue is full (try again) */
int32_t sc_store_read(int32_t scope, uint32_t handle, uint8_t *buf, uint32_t cap, sc_store_cb cb, void *ctx) {
  struct sc_req *r;
  if (!handle || handle > 0xffff || cap > 4096) return 0;
  r = sc_new(OP_READ, scope, cb, ctx);
  if (!r) return 0;
  r->handle = handle; r->buf = buf; r->cap = cap;
  return 1;
}

/* a new record (n bytes, at most 4096; src kept until the callback): cb(status, n, its new handle, ctx) */
int32_t sc_store_write(int32_t scope, const uint8_t *src, uint32_t n, sc_store_cb cb, void *ctx) {
  struct sc_req *r;
  if (n > 4096) return 0;
  r = sc_new(OP_WRITE, scope, cb, ctx);
  if (!r) return 0;
  r->src = src; r->n = n;
  return 1;
}

/* a lock op for the Pi's lock service (body = <op 10..15> <args>), a route op for its audio route (<op 20..23> <args>)
   or a DSP op for its library of blocks (<op 30..32> <args>), 7-bit bytes; 0: the link is closed or the queue full.
   The Pi forgets every set, closes every route point and frees every DSP slot at each HELLO: declare them again when
   sc_link_epoch() changes. */
int32_t sc_link_send(const uint8_t *body, int32_t n) {
  int32_t i;
  if (!scl.epoch || n < 1 || n > SC_LMAX ||
      !((body[0] >= 0x10 && body[0] <= 0x15) || (body[0] >= 0x20 && body[0] <= 0x23) || (body[0] >= 0x30 && body[0] <= 0x32)))
    return 0;
  if (SC_LQ - (scl.lh - scl.lt) < (uint32_t)n + 1) { scl.lock_drops++; return 0; }
  for (i = 0; i < n; ++i) if (body[i] & 0x80) return 0;
  scl.lq[scl.lh++ % SC_LQ] = (uint8_t)n;
  for (i = 0; i < n; ++i) scl.lq[scl.lh++ % SC_LQ] = body[i];
  return 1;
}

/* the Pi's answer to the route op (ROUTE / MOVE) sent with this owner and seq: the point 0..15, -code (3 full, 5 bad,
   7 loop), or SC_ROUTE_PENDING (-256) while none came (the last SC_NR answers are kept; a seq reused within them gives
   the newest) */
static int32_t sc_result(uint32_t kind, uint32_t owner, uint32_t seq) {
  uint32_t key = kind << 16 | (owner & 0x7f) << 8 | (seq & 0x7f), n = scl.rn, i;
  for (i = 0; i < SC_NR && i < n; ++i) {
    uint32_t j = (n - 1 - i) % SC_NR;
    if (scl.r[j].key == key) return scl.r[j].res;
  }
  return SC_ROUTE_PENDING;
}
int32_t sc_route_result(uint32_t owner, uint32_t seq);
int32_t sc_route_result(uint32_t owner, uint32_t seq) { return sc_result(1, owner, seq); }

/* the Pi's answer to the DSP op PLACE sent with this owner and seq: the slot 0..15, -code (3 full, 5 bad, 9 unknown
   block), or SC_ROUTE_PENDING (-256) while none came (kept with the route's answers, the last SC_NR of both) */
int32_t sc_dsp_result(uint32_t owner, uint32_t seq);
int32_t sc_dsp_result(uint32_t owner, uint32_t seq) { return sc_result(2, owner, seq); }

uint32_t sc_link_epoch(void) { return scl.epoch; }
uint32_t sc_project_id(void) { return scl.proj; }

/* the pattern handle of live pattern p (0..127) */
uint32_t sc_pattern_handle(int32_t p) { return p < 0 || p > 127 ? 0 : core_store_get(STORE(sc_phand), SC_PAT(p), 0); }
void sc_set_pattern_handle(int32_t p, uint32_t h) {
  if (p >= 0 && p <= 127) core_store_set(STORE(sc_phand), SC_PAT(p), 0, h & 0xffff);
}

static int32_t sc_cache_find(uint32_t scope, uint32_t h) {
  int32_t i;
  for (i = 0; i < SC_NC; ++i)
    if (scl.c[i].used && scl.c[i].scope == scope && scl.c[i].handle == h) return i;
  return -1;
}
static void sc_cache_put(uint32_t scope, uint32_t h, const uint8_t *d, uint32_t n) {
  int32_t i = sc_cache_find(scope, h);
  uint32_t k;
  if (n > SC_CMAX || !h) return;
  if (i < 0) { i = (int32_t)(scl.cn++ % SC_NC); }
  scl.c[i].used = 1; scl.c[i].scope = scope; scl.c[i].handle = h; scl.c[i].n = n;
  for (k = 0; k < n; ++k) scl.c[i].d[k] = d[k];
}

/* the next step of the request at the queue's head: 1 sent something */
static int32_t sc_step(struct sc_req *r) {
  uint8_t m[8 + 10 + SC_CHUNK + SC_CHUNK / 7 + 2], *o;
  if (r->state == RQ_QUEUED && r->op == OP_READ) {
    int32_t i = sc_cache_find(r->scope, r->handle);
    if (i >= 0) {                      /* a version never changes: the cached bytes are the record */
      uint32_t k, n = scl.c[i].n;
      if (n > r->cap) { r->status = 6; r->state = RQ_DONE; return 0; }
      for (k = 0; k < n; ++k) r->buf[k] = scl.c[i].d[k];
      r->got = r->total = n; r->status = 0;
      r->state = RQ_DONE;
      scl.hits++;
      return 0;
    }
  }
  if (!scl.epoch) return 0;
  if (r->state == RQ_QUEUED) {
    r->seq = (uint8_t)(scl.seq++ % 0x7e + 1);
    r->t0 = scl.ticks;
    r->sent = 0;
    r->got = 0;
    if (r->op == OP_READ) {
      o = sc_head(m, OP_READ);
      o[0] = r->seq; o[1] = r->scope; sc_h3(o + 2, r->handle); o[5] = 0xf7;
      r->state = RQ_SENT;              /* before the send: the answer may come at once */
      scl.cur = r;
      if (!sc_send(m, 13)) { scl.cur = 0; r->state = RQ_QUEUED; return 0; }
      return 1;
    }
    r->state = RQ_SENT;
    scl.cur = r;
  }
  if (r->state == RQ_SENT && r->op == OP_WRITE && (r->sent < r->n || (r->n == 0 && !r->got))) {
    uint32_t c = r->n - r->sent < SC_CHUNK ? r->n - r->sent : SC_CHUNK;
    int32_t len;
    o = sc_head(m, OP_WRITE);
    o[0] = r->seq; o[1] = r->scope; sc_14(o + 2, r->n); sc_14(o + 4, r->sent);
    len = 6 + sc_pack7(r->src + r->sent, (int32_t)c, o + 6);
    o[len] = 0xf7;
    if (!sc_send(m, 7 + len + 1)) return 0;
    r->sent += c;
    if (r->n == 0) r->got = 1;         /* the empty record's one chunk */
    r->t0 = scl.ticks;
    return 1;
  }
  return 0;
}

/* ev_tick (order 76): the HELLO, the lock ops, the requests, the callbacks */
void sc_store_tick(void *ctrl);
void sc_store_tick(void *ctrl) {
  int32_t up = PORT_STATE == 1, k;
  (void)ctrl;
  scl.ticks++;
  scl.txsx_n = SC_TXSX ? scl.txsx_n + 1 : 0;   /* ticks the stock dump flag has stayed set */
  if (!scl.proj) scl.proj = core_store_get(STORE(sc_proj), 0, 0);
  if (up && !scl.was_up) { scl.hello_owed = 1; scl.tries = 0; }
  if (!up && scl.was_up) {             /* the host left: closed; what was sent goes again after the next HELLO */
    struct sc_req *r = scl.cur;
    scl.epoch = 0;
    scl.lt = scl.lh;
    scl.cur = 0;
    for (k = 0; k < SC_NR; ++k) scl.r[k].key = 0;   /* the Pi's points are gone with the session */
    if (r && r->state == RQ_SENT) r->state = RQ_QUEUED;
  }
  scl.was_up = (uint32_t)up;
  if (scl.acked) {                     /* the Pi opened the project (not an answer to the HELLO before a project change) */
    scl.acked = 0;
    scl.acks++;
  }
  if (scl.acks != scl.opened && (scl.opened = scl.acks, !(scl.hello_owed && scl.tries == 0))) {
    scl.hello_owed = 0;
    scl.gen = scl.gen + 1 ? scl.gen + 1 : 1;   /* a new epoch after each HELLO, never 0 */
    for (k = 0; k < SC_NR; ++k) scl.r[k].key = 0;   /* route answers of the last session (no route op went since) */
    scl.epoch = scl.gen;
  }
  if (scl.host_msg) {                  /* a host speaks while unanswered: ask again */
    scl.host_msg = 0;
    if (!scl.epoch && !scl.hello_owed && scl.proj) { scl.hello_owed = 1; scl.tries = SC_HELLO_TRIES - 1; }
  }
  if (up && scl.hello_owed && scl.proj && scl.tries < SC_HELLO_TRIES &&
      (scl.tries == 0 || scl.ticks - scl.hello_t >= SC_HELLO_EVERY)) {
    uint8_t m[13], *o = sc_head(m, OP_HELLO);
    uint32_t p = scl.proj;
    o[0] = (uint8_t)(p >> 28 & 0x0f); o[1] = (uint8_t)(p >> 21 & 0x7f); o[2] = (uint8_t)(p >> 14 & 0x7f);
    o[3] = (uint8_t)(p >> 7 & 0x7f); o[4] = (uint8_t)(p & 0x7f); o[5] = 0xf7;
    if (sc_send(m, 13)) { scl.tries++; scl.hello_t = scl.ticks; scl.hellos++; }
    if (scl.tries >= SC_HELLO_TRIES) scl.hello_owed = 0;
  }
  {                                    /* the name: polled; owed at a new epoch and after a change that held */
    uint32_t i, same = 1;
    for (i = 0; i < 16; ++i) {
      uint8_t c = SC_NAME[i];
      if (c != scl.name[i]) { scl.name[i] = c; same = 0; }
    }
    if (!same) scl.name_stable = 0;
    else if (scl.name_stable < SC_NAME_STABLE) scl.name_stable++;
    if (scl.epoch && scl.epoch != scl.name_epoch) scl.name_owed = 1;
    if (scl.name_stable >= SC_NAME_STABLE)
      for (i = 0; i < 16; ++i) if (scl.name[i] != scl.name_sent[i]) scl.name_owed = 1;
  }
  if (scl.epoch && scl.name_owed) {
    uint8_t m[8 + 6 + 16], *o = sc_head(m, OP_NAME);
    uint32_t p = scl.proj, n = 0, i;
    o[0] = (uint8_t)(p >> 28 & 0x0f); o[1] = (uint8_t)(p >> 21 & 0x7f); o[2] = (uint8_t)(p >> 14 & 0x7f);
    o[3] = (uint8_t)(p >> 7 & 0x7f); o[4] = (uint8_t)(p & 0x7f);
    while (n < 16 && scl.name[n]) { o[6 + n] = scl.name[n] & 0x7f; n++; }
    o[5] = (uint8_t)n;
    o[6 + n] = 0xf7;
    if (sc_send(m, (int32_t)(7 + 6 + n + 1))) {
      for (i = 0; i < 16; ++i) scl.name_sent[i] = scl.name[i];
      scl.name_owed = 0;
      scl.name_epoch = scl.epoch;
      scl.names++;
    }
  }
  while (scl.epoch && scl.lt != scl.lh) {   /* the lock ops, in order */
    uint8_t m[8 + SC_LMAX], *o = sc_head(m, scl.lq[(scl.lt + 1) % SC_LQ]);
    int32_t n = scl.lq[scl.lt % SC_LQ], i;
    for (i = 1; i < n; ++i) o[i - 1] = scl.lq[(scl.lt + 1 + i) % SC_LQ];
    o[n - 1] = 0xf7;
    if (!sc_send(m, 7 + n)) break;
    scl.lt += (uint32_t)n + 1;
    scl.lock_ops++;
  }
  for (k = 0; k < 4 && scl.qt != scl.qh; ++k) {   /* the head request: up to 4 messages a tick */
    struct sc_req *r = &scl.q[scl.qt % SC_NQ];
    if (r->state == RQ_SENT && scl.ticks - r->t0 > SC_TIMEOUT) { scl.cur = 0; r->status = ST_TIMEOUT; r->state = RQ_DONE; }
    if (r->state == RQ_DONE) {
      uint32_t st = r->status, n = r->op == OP_READ ? r->got : r->n;
      if (st == 0 && r->op == OP_READ) sc_cache_put(r->scope, r->handle, r->buf, n);
      if (st == 0 && r->op == OP_WRITE) sc_cache_put(r->scope, r->handle, r->src, n);
      if (st == ST_TIMEOUT) scl.timeouts++;
      else if (st) scl.errors++;
      scl.done++;
      r->state = RQ_FREE;
      scl.qt++;
      if (r->cb) r->cb((int32_t)st, (int32_t)n, r->handle, r->ctx);
      continue;
    }
    if (!sc_step(r)) break;
  }
  sc_kit_tick();
}
