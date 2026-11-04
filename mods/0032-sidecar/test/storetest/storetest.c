/* SPDX-License-Identifier: GPL-2.0-or-later */
/* sidecar-storetest: a test client of the Sidecar companion's store link (sidecar-mods mods/0032-sidecar store.c,
 * the Storage phase, 2026-11-04). Test builds only, never a release. It does what a mod that keeps data on the Pi
 * does, once each session (each time the companion's sc_link_epoch() changes: a project loaded, the Sidecar back):
 *
 *   0 LOCKS   declares lock set 7 (track 1, processor slot 3, parameters 0..1), their base values (100, 200) and two
 *             locks (step 1: parameter 0 = 1000, step 9: parameter 1 = 3000); the Pi plays them on the step clock
 *             while the pattern runs (its /status locks.values grows by 4 a loop of 16 steps)
 *   1 WRITE   a record of 600 bytes (6 WRITE chunks, too big for the companion's cache): its new handle
 *   2 READ    that record read back from the Pi, compared byte for byte
 *   3 SMALL   a 16-byte record written and read back (the read is served from the companion's cache)
 *   4 PRIOR   the record the previous session wrote, by pattern 1's handle (sc_phand, kept with the project when it
 *             is saved): read and checked. No handle yet: no box (a project that never ran the test)
 *   5 DONE    every step answered; pattern 1's handle now names this session's record
 *
 * The screen's bottom right (y counts from the bottom edge): one box a step at x 92 + 6 i; a full 4 x 5 box is a pass,
 * a 4 x 1 line a fail, nothing still waiting. Left of them, one pixel per session so far (up to 16), at x 70..85.
 * The results also stay in st_res / st_bad / st_sessions / st_status[] for a memory read. */
#include <stdint.h>

typedef void (*fillrect_t)(void *bmp, int x0, int y0, int x1, int y1, int colour);
#define FILLRECT ((fillrect_t)FILLRECT_AT)

/* the companion's exports (store.c) */
typedef void (*sc_store_cb)(int32_t status, int32_t n, uint32_t handle, void *ctx);
extern int32_t sc_store_read(int32_t scope, uint32_t handle, uint8_t *buf, uint32_t cap, sc_store_cb cb, void *ctx);
extern int32_t sc_store_write(int32_t scope, const uint8_t *src, uint32_t n, sc_store_cb cb, void *ctx);
extern int32_t sc_link_send(const uint8_t *body, int32_t n);
extern uint32_t sc_link_epoch(void);
extern uint32_t sc_project_id(void);
extern uint32_t sc_pattern_handle(int32_t p);
extern void sc_set_pattern_handle(int32_t p, uint32_t h);

#define SCOPE_PATTERN 3                /* kv.h: 0 project, 1 kit, 2 sound, 3 pattern */
#define BIG 600
#define SMALL 16
#define MAGIC 0x53545631u              /* "STV1" */

enum { S_LOCKS, S_WRITE, S_READ, S_SMALL, S_PRIOR, S_DONE, S_N };

volatile uint32_t st_res, st_bad, st_sessions, st_epoch;
volatile int32_t st_status[S_N];       /* each step's last status (0 ok; kv::Status codes; 0x7e timeout; -1 compare) */
static uint32_t st_step, st_wait, st_h_big, st_h_small, st_h_prior, st_shown = 0xffffffffu;
static uint8_t st_big[BIG], st_back[BIG], st_small[SMALL], st_small_back[SMALL], st_prior[BIG];
static volatile int32_t st_cb_status, st_cb_n;
static volatile uint32_t st_cb_handle, st_cb_done;
static uint32_t st_tag;                /* the request in flight: an answer to an older one (a session ago) is ignored */

static void st_cb(int32_t status, int32_t n, uint32_t handle, void *ctx) {
  if ((uint32_t)ctx != st_tag) return;
  st_cb_status = status; st_cb_n = n; st_cb_handle = handle; st_cb_done = 1;
}

static void pass(int s) { st_res |= 1u << s; st_bad &= ~(1u << s); st_status[s] = 0; }
static void fail(int s, int32_t why) { st_bad |= 1u << s; st_res &= ~(1u << s); st_status[s] = why; }

static void put32(uint8_t *p, uint32_t v) { p[0] = v >> 24; p[1] = v >> 16; p[2] = v >> 8; p[3] = v; }
static uint32_t get32(const uint8_t *p) { return (uint32_t)p[0] << 24 | (uint32_t)p[1] << 16 | (uint32_t)p[2] << 8 | p[3]; }

/* a record: magic, project, session, then bytes that depend on all three */
static void fill(uint8_t *d, uint32_t n, uint32_t session) {
  uint32_t i, p = sc_project_id();
  put32(d, MAGIC); put32(d + 4, p); put32(d + 8, session);
  for (i = 12; i < n; ++i) d[i] = (uint8_t)(i * 7 + session * 13 + (p >> (i & 24)));
}
static int same(const uint8_t *a, const uint8_t *b, uint32_t n) {
  uint32_t i;
  for (i = 0; i < n; ++i) if (a[i] != b[i]) return 0;
  return 1;
}
/* a record the test wrote (any session of this project): its own bytes again */
static int valid(const uint8_t *d, uint32_t n) {
  static uint8_t want[BIG];
  if (n != BIG || get32(d) != MAGIC || get32(d + 4) != sc_project_id()) return 0;
  fill(want, BIG, get32(d + 8));
  return same(d, want, BIG);
}

static int lock_op(const uint8_t *b, int32_t n) { return sc_link_send(b, n) != 0; }

static void start(void) {
  uint8_t set[6] = {0x10, 7, 0, 3, 0, 2};                              /* SET 7: track 1, slot 3, params 0..1 */
  uint8_t base[8] = {0x11, 7, 0, 2, 100 >> 7, 100 & 0x7f, 200 >> 7, 200 & 0x7f};
  uint8_t l1[6] = {0x12, 7, 0, 0, 1000 >> 7, 1000 & 0x7f};            /* step 1, param 0 */
  uint8_t l2[6] = {0x12, 7, 8, 1, 3000 >> 7, 3000 & 0x7f};            /* step 9, param 1 */
  int ok = lock_op(set, 6) && lock_op(base, 8) && lock_op(l1, 6) && lock_op(l2, 6);
  if (ok) pass(S_LOCKS); else fail(S_LOCKS, -2);
  st_h_prior = sc_pattern_handle(0);
  fill(st_big, BIG, st_sessions);
  st_step = S_WRITE;
  st_wait = 0;
}

/* ev_tick (core-ar2), after the companion's (order 76): one step at a time, each started once its last answered */
void st_tick(void *ctrl);
void st_tick(void *ctrl) {
  uint32_t e = sc_link_epoch(), shown;
  if (e && e != st_epoch) {            /* a new session: run the steps again */
    st_epoch = e;
    st_sessions++;
    st_res = 0; st_bad = 0;
    start();
  }
  if (st_step && st_step < S_DONE) {
    if (st_wait && !st_cb_done) goto draw;
    if (st_wait) {                     /* the step's answer */
      int32_t s = st_cb_status;
      st_wait = 0; st_cb_done = 0;
      switch (st_step) {
        case S_WRITE:
          if (s == 0 && st_cb_handle) { st_h_big = st_cb_handle; pass(S_WRITE); st_step = S_READ; }
          else { fail(S_WRITE, s); fail(S_READ, -3); st_step = S_SMALL; }
          break;
        case S_READ:
          if (s == 0 && st_cb_n == BIG && same(st_back, st_big, BIG)) pass(S_READ); else fail(S_READ, s ? s : -1);
          st_step = S_SMALL;
          break;
        case S_SMALL:
          if (!st_h_small) {           /* the write's answer: now read it */
            if (s == 0 && st_cb_handle) { st_h_small = st_cb_handle; goto issue; }
            fail(S_SMALL, s);
          } else if (s == 0 && st_cb_n == SMALL && same(st_small_back, st_small, SMALL)) pass(S_SMALL);
          else fail(S_SMALL, s ? s : -1);
          st_step = S_PRIOR;
          break;
        case S_PRIOR:
          if (s == 0 && valid(st_prior, (uint32_t)st_cb_n)) pass(S_PRIOR); else fail(S_PRIOR, s ? s : -1);
          st_step = S_DONE;
          break;
      }
    }
  issue:
    if (!st_wait) {
      int32_t q = 1;
      void *tag = (void *)++st_tag;
      st_cb_done = 0;
      switch (st_step) {
        case S_WRITE: q = sc_store_write(SCOPE_PATTERN, st_big, BIG, st_cb, tag); break;
        case S_READ: q = sc_store_read(SCOPE_PATTERN, st_h_big, st_back, BIG, st_cb, tag); break;
        case S_SMALL:
          if (!st_h_small) { fill(st_small, SMALL, st_sessions); q = sc_store_write(SCOPE_PATTERN, st_small, SMALL, st_cb, tag); }
          else q = sc_store_read(SCOPE_PATTERN, st_h_small, st_small_back, SMALL, st_cb, tag);
          break;
        case S_PRIOR:
          if (!st_h_prior) { st_step = S_DONE; q = 0; break; }      /* no earlier record: nothing to check */
          q = sc_store_read(SCOPE_PATTERN, st_h_prior, st_prior, BIG, st_cb, tag);
          break;
      }
      if (q && st_step < S_DONE) st_wait = 1;
    }
    if (st_step == S_DONE) {
      if (st_h_big) sc_set_pattern_handle(0, st_h_big);
      st_h_small = 0;
      if (!(st_bad & ((1u << S_DONE) - 1))) pass(S_DONE); else fail(S_DONE, -4);
    }
  }
draw:
  shown = st_res ^ st_bad << 8 ^ st_sessions << 16;
  if (shown != st_shown) {             /* the screen redrawn only when what it shows changed (store-check's rule) */
    st_shown = shown;
    *((volatile unsigned char *)ctrl + 0x20) = 1;
  }
}

/* ev_draw (core-ar2): the boxes */
void st_draw(void *bmp, void *ctrl);
void st_draw(void *bmp, void *ctrl) {
  int i, n = st_sessions > 16 ? 16 : (int)st_sessions;
  (void)ctrl;
  FILLRECT(bmp, 68, 0, 127, 5, 0);
  for (i = 0; i < n; ++i) FILLRECT(bmp, 70 + i, 0, 70 + i, 0, 1);
  for (i = 0; i < S_N; ++i) {
    int x = 92 + 6 * i;
    if (st_res & 1u << i) FILLRECT(bmp, x, 0, x + 3, 4, 1);
    else if (st_bad & 1u << i) FILLRECT(bmp, x, 0, x + 3, 0, 1);
  }
}
