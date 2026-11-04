// mods/0032-sidecar/test/test_companion.cpp - the companion's store client and step clock (store.c, clock.c, built for a
// PC by companion_host.c) against the Pi's own services from sidecar-firmware: the record store (core/kv: Store,
// Service over a store in memory), the lock service (core/locks) and the step clock's parser (core/clock). Every
// message the companion sends goes through a router that does what the Pi's kv::link::from_host does (a lock op to
// the locks, a HELLO resetting them, the rest to the store), and the store's answers come back through
// sc_store_host, as the companion's router would call it.
//   make -C mods/0032-sidecar/test FIRMWARE=<sidecar-firmware checkout>
#include <stdio.h>
#include <string.h>
#include <sys/mman.h>

#include <algorithm>
#include <map>
#include <string>
#include <vector>

#include "clock/clock.h"
#include "kv/kv.h"
#include "locks/locks.h"

extern "C" {
extern volatile uint32_t h_port_state, h_play, h_blk, h_txsx;
extern volatile int8_t h_pat_idx;
extern uint8_t h_speed[13], h_prev[13], h_patd[85760], h_name[16];
extern const volatile uint32_t* h_pool;
typedef void (*sc_store_cb)(int32_t status, int32_t n, uint32_t handle, void* ctx);
int sc_store_host(const uint8_t* d, int32_t len);
void sc_store_tick(void* ctrl);
void sc_project_ev(int32_t how, uint32_t dropped);
int32_t sc_store_read(int32_t scope, uint32_t handle, uint8_t* buf, uint32_t cap, sc_store_cb cb, void* ctx);
int32_t sc_store_write(int32_t scope, const uint8_t* src, uint32_t n, sc_store_cb cb, void* ctx);
int32_t sc_link_send(const uint8_t* body, int32_t n);
uint32_t sc_link_epoch(void);
uint32_t sc_project_id(void);
uint32_t sc_pattern_handle(int32_t p);
void sc_set_pattern_handle(int32_t p, uint32_t h);
void sc_fire(int32_t t, int32_t p, int32_t step);
void sc_end(void);
uint32_t h_proj_value(void);
void h_proj_reset(void);
uint32_t h_ck_drops(void);
uint32_t h_scl_hits(void);
uint32_t h_scl_hellos(void);
uint32_t h_scl_timeouts(void);
// storetest/storetest.c, the test client (built with h_fillrect for its FILLRECT)
void st_tick(void* ctrl);
void st_draw(void* bmp, void* ctrl);
extern volatile uint32_t st_res, st_bad, st_sessions;
extern volatile int32_t st_status[6];
}
static bool g_st_on = false;                            // the test client ticks after the companion
static uint8_t g_ctrl[64];
static int g_rects = 0;
extern "C" void h_fillrect(void*, int, int, int, int, int) { ++g_rects; }

static int g_fail = 0;
#define CHECK(c) do { if (!(c)) { printf("FAIL %s:%d: %s\n", __FILE__, __LINE__, #c); ++g_fail; } } while (0)

using namespace core;

struct MemBackend : kv::Backend {
  std::map<std::string, std::vector<uint8_t>> files;
  bool write_atomic(const char* p, const uint8_t* d, uint32_t n) override { files[p] = std::vector<uint8_t>(d, d + n); return true; }
  int read(const char* p, uint8_t* d, uint32_t cap) override {
    auto it = files.find(p);
    if (it == files.end()) return -1;
    uint32_t n = (uint32_t)it->second.size() < cap ? (uint32_t)it->second.size() : cap;
    if (n) memcpy(d, it->second.data(), n);
    return (int)n;
  }
  bool remove(const char* p) override { return files.erase(p) == 1; }
  bool list(const char* dir, void (*each)(const char*, void*), void* ctx) override {
    std::string pre = std::string(dir) + "/";
    for (auto& f : files)
      if (f.first.compare(0, pre.size(), pre) == 0) each(f.first.c_str() + pre.size(), ctx);
    return true;
  }
};

// ---- the Pi
static std::vector<std::vector<uint8_t>> g_rytm_out;   // everything the companion sent, in order
static std::vector<std::vector<uint8_t>> g_answers;
static std::vector<std::string> g_names;            // the NAMEs the Pi got    // the store's answers, not yet given to the companion
static bool g_pi_deaf = false;                          // the Pi takes nothing (a timeout)
static MemBackend g_mem;
static kv::Store g_store(&g_mem);
static void svc_out(const uint8_t* m, int n) { g_answers.emplace_back(m, m + n); }
static kv::Service g_svc(&g_store, svc_out);
static std::vector<clock::Tick> g_ticks;
static void on_tick(const clock::Tick& t) { g_ticks.push_back(t); locks::tick(t.track, t.step, t.extra & 1); }
static void lock_sink(int, int, int) {}
static std::vector<uint8_t> g_kinds;
static void on_state(const clock::State& s) { g_kinds.push_back(s.kind); }

extern "C" void h_midi_send(int32_t n, const uint8_t* m) {
  g_rytm_out.emplace_back(m, m + n);
  if (g_pi_deaf || n < 6) return;
  if (m[4] == kv::kCmd) {                              // as kv::link::from_host
    if (locks::is_lock_op(m[6])) { locks::sysex(m, n); return; }
    if (m[6] == kv::kOpName) { g_names.emplace_back((const char*)m + 13, (size_t)m[12]); return; }   // the control core's
    if (m[6] == kv::kOpHello) locks::reset();
    g_svc.sysex(m, n);
  } else if (m[4] == clock::kTickCmd || m[4] == clock::kStateCmd) {
    clock::sysex(m, n);
  }
}
static int deliver() {                                 // the Pi's answers reach the companion's router (MIDI task)
  int k = 0;
  auto a = g_answers;
  g_answers.clear();
  for (auto& m : a) { sc_store_host(m.data(), (int)m.size()); ++k; }
  return k;
}
static void tick(int n = 1) {                          // ev_tick, the answers in between
  for (int i = 0; i < n; ++i) { sc_store_tick(nullptr); if (g_st_on) st_tick(g_ctrl); deliver(); }
}
static int sent(uint8_t cmd, uint8_t op = 0xFF) {
  int k = 0;
  for (auto& m : g_rytm_out) k += m.size() > 6 && m[4] == cmd && (op == 0xFF || m[6] == op);
  return k;
}

struct Res { int calls = 0; int32_t st = -1, n = -1; uint32_t h = 0; };
static void cb(int32_t st, int32_t n, uint32_t h, void* ctx) {
  Res* r = (Res*)ctx;
  ++r->calls, r->st = st, r->n = n, r->h = h;
}

int main() {
  setvbuf(stdout, nullptr, _IONBF, 0);
  // a free-request chain below 4 GB (the sender walks it as 32-bit words)
  uint32_t* pool = (uint32_t*)mmap(nullptr, 4096, PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANONYMOUS | MAP_32BIT, -1, 0);
  for (int i = 0; i < 4; ++i) pool[14 * i + 13] = i < 3 ? (uint32_t)(uintptr_t)(pool + 14 * (i + 1)) : 0;
  h_pool = pool;
  clock::on_tick(on_tick);
  locks::set_sink(lock_sink);
  clock::on_state(on_state);

  // ---- the project ID: given at the first ev_project, kept in the project field; a HELLO for it at port-up
  memcpy(h_name, "PROJ1\0\0\0\0\0\0\0\0\0\0\0", 16);
  h_port_state = 0;
  sc_project_ev(1, 0);
  uint32_t id = sc_project_id();
  CHECK(id != 0 && h_proj_value() == id);
  sc_project_ev(1, 0);
  CHECK(sc_project_id() == id);                         // loaded again: the same ID
  tick();
  CHECK(sent(0x51) == 0);                              // the port down: nothing
  h_port_state = 1;
  tick();
  CHECK(sent(0x51, kv::kOpHello) == 1 && sc_link_epoch() == 0);   // the answer opens it at the next tick
  tick();
  CHECK(sc_link_epoch() != 0);
  const auto& hm = *std::find_if(g_rytm_out.rbegin(), g_rytm_out.rend(), [](const std::vector<uint8_t>& m) { return m[6] == kv::kOpHello; });
  CHECK(hm.size() == 13 && (((uint32_t)hm[7] << 28 | (uint32_t)hm[8] << 21 | hm[9] << 14 | hm[10] << 7 | hm[11]) == id));
  CHECK(g_store.project() == id);
  uint32_t epoch = sc_link_epoch();
  // the name: once the link is open (the HELLO's answer), then only a change that held 10 ticks
  tick();
  CHECK(g_names.size() == 1 && g_names[0] == "PROJ1");
  const auto& nm = *std::find_if(g_rytm_out.rbegin(), g_rytm_out.rend(), [](const std::vector<uint8_t>& m) { return m[6] == kv::kOpName; });
  CHECK(nm.size() == 7 + 6 + 5 + 1 && (((uint32_t)nm[7] << 28 | (uint32_t)nm[8] << 21 | nm[9] << 14 | nm[10] << 7 | nm[11]) == id));
  h_name[4] = '2';                                      // typed: PROJ2
  tick(5);
  h_name[4] = '3';
  tick(5);
  CHECK(g_names.size() == 1);
  tick(10);
  CHECK(g_names.size() == 2 && g_names[1] == "PROJ3");
  tick(30);
  CHECK(g_names.size() == 2);

  // ---- a write of 300 bytes (3 chunks), read back (too big for the cache: from the Pi)
  uint8_t big[300], back[512];
  for (int i = 0; i < 300; ++i) big[i] = (uint8_t)(i * 7 + 3);
  Res w1, r1;
  CHECK(sc_store_write(3, big, 300, cb, &w1));
  tick(3);
  CHECK(w1.calls == 1 && w1.st == 0 && w1.n == 300 && w1.h == 1);
  CHECK(sent(0x51, kv::kOpWrite) == 3);
  CHECK(sc_store_read(3, 1, back, sizeof back, cb, &r1));
  size_t before = g_rytm_out.size();
  tick(2);
  CHECK(r1.calls == 1 && r1.st == 0 && r1.n == 300 && memcmp(back, big, 300) == 0);
  CHECK(g_rytm_out.size() == before + 1);               // one READ out, three DATA back

  // ---- a small record: cached at its write, so its read needs no Pi
  uint8_t small[10] = {1, 2, 3, 4, 5, 6, 7, 8, 9, 200}, sb[16] = {0};
  Res w2, r2;
  CHECK(sc_store_write(1, small, 10, cb, &w2));
  tick(2);
  CHECK(w2.st == 0 && w2.h == 2);
  before = g_rytm_out.size();
  CHECK(sc_store_read(1, 2, sb, sizeof sb, cb, &r2));
  tick(2);
  CHECK(r2.st == 0 && r2.n == 10 && memcmp(sb, small, 10) == 0 && g_rytm_out.size() == before && h_scl_hits() == 1);
  // a cap too small for the record: refused (kv kTooBig), from the cache too
  Res r3;
  CHECK(sc_store_read(1, 2, sb, 4, cb, &r3));
  tick(2);
  CHECK(r3.calls == 1 && r3.st == 6);
  // an empty record
  Res w0;
  CHECK(sc_store_write(2, small, 0, cb, &w0));
  tick(2);
  CHECK(w0.calls == 1 && w0.st == 0 && w0.h == 3);

  // ---- a missing handle: the Pi's STATUS (kMissing)
  Res r4;
  CHECK(sc_store_read(3, 99, back, sizeof back, cb, &r4));
  tick(2);
  CHECK(r4.calls == 1 && r4.st == kv::kMissing);

  // ---- the queue: 4 at most
  Res q[5];
  for (int i = 0; i < 4; ++i) CHECK(sc_store_read(3, 1, back, sizeof back, cb, &q[i]));
  CHECK(!sc_store_read(3, 1, back, sizeof back, cb, &q[4]));
  tick(12);
  CHECK(q[0].st == 0 && q[3].st == 0 && q[3].n == 300);

  // ---- a Pi that does not answer: a timeout (and the next request still goes)
  g_pi_deaf = true;
  Res r5;
  CHECK(sc_store_read(3, 1, back, sizeof back, cb, &r5));
  tick(70);
  CHECK(r5.calls == 1 && r5.st == 0x7E && h_scl_timeouts() == 1);
  g_pi_deaf = false;

  // ---- lock ops: declared on the Pi, played by the Pi's clock (the companion's 2C)
  uint8_t set[] = {locks::kSet, 0, 12, 1, 4, 2};
  uint8_t lock[] = {locks::kLock, 0, 3, 1, 0, 99};
  uint8_t bad[] = {0x01, 0};
  CHECK(sc_link_send(set, sizeof set) && sc_link_send(lock, sizeof lock));
  CHECK(!sc_link_send(bad, sizeof bad));                // a store op is not a lock op
  tick();
  CHECK(locks::declared(0) && locks::lock_at(0, 3, 1) == 99);

  // ---- the step clock: all 13 tracks, the trig flags
  h_patd[85689] = 0;                                    // the pattern's length for every track: 16
  h_patd[85683] = 0, h_patd[85684] = 16;
  h_patd[917 * 12 + 2 * 3 + 1] = 0x01;                  // the FX track's step 3: a note trig
  h_patd[917 * 0 + 2 * 3 + 1] = 0x05;                   // BD's step 3: a trigless lock trig (bits 0 and 2)
  h_patd[917 * 5 + 0x2ca] = 1;                          // track 5 euclidean, step 3 on its map
  memset(h_patd + 917 * 5 + 0x2d1, 0xFF, 64);
  h_patd[917 * 5 + 0x2d1 + 3] = 0;
  for (int t = 0; t < 13; ++t) h_speed[t] = 2, h_prev[t] = 3;
  h_play = 0, h_pat_idx = 0;
  sc_end();                                             // the link is up: TRANSPORT as it is (stopped)
  CHECK(sent(0x2D) == 1 && clock::transport() == clock::kStop);
  h_play = 1;
  h_blk = 2000;
  for (int t = 0; t < 13; ++t) sc_fire(t, 0, 4);
  sc_end();
  CHECK(sent(0x2D) == 2 && clock::transport() == clock::kPlay);
  CHECK(sent(0x2C) == 1 && g_ticks.size() == 13);
  auto tm = std::find_if(g_rytm_out.rbegin(), g_rytm_out.rend(), [](const std::vector<uint8_t>& m) { return m[4] == 0x2C; });
  CHECK(tm != g_rytm_out.rend() && tm->size() == 6 + 4 + 1 + 5 * 13 + 1 && (*tm)[10] == 13);
  uint8_t flags[13] = {0};
  for (auto& t : g_ticks) {
    flags[t.track] = t.extra;
    CHECK(t.step == 3 && t.len == 16 && t.speed == 2);
  }
  CHECK(flags[12] == 1 && flags[0] == 2 && flags[5] == 1 && flags[1] == 0);
  // the lock on the FX track's step 3 reached the Pi's locks (its slot 1, parameter 5: the set's P1)
  CHECK(locks::value(0, 1) == 99);
  // a pattern jump's re-schedule (the same step, another pattern) is no tick
  g_ticks.clear();
  for (int t = 0; t < 13; ++t) sc_fire(t, 1, 4);
  sc_end();
  CHECK(g_ticks.empty());
  // a full queue drops and counts
  for (int i = 0; i < 40; ++i) h_prev[0] = (uint8_t)(i & 15), sc_fire(0, 1, 0);
  CHECK(h_ck_drops() > 0);
  sc_end();

  // ---- the pattern handle: per live pattern
  sc_set_pattern_handle(7, 0x1234);
  CHECK(sc_pattern_handle(7) == 0x1234 && sc_pattern_handle(8) == 0 && sc_pattern_handle(200) == 0);

  // ---- a project change: closed, a HELLO for the new one, the Pi's locks reset, a new epoch
  h_proj_reset();                                        // CREATE NEW: the field reads 0
  sc_project_ev(0, 0);
  CHECK(sc_link_epoch() == 0 && sc_project_id() != id && sc_project_id() != 0);
  CHECK(!sc_link_send(set, sizeof set));                // closed: the mod declares again at the new epoch
  tick(2);
  CHECK(sc_link_epoch() != 0 && sc_link_epoch() != epoch && !locks::declared(0));
  CHECK(g_store.project() == sc_project_id());
  tick();
  CHECK(g_names.size() == 3 && g_names[2] == "PROJ3");     // a new session: the name again (with the new ID)

  // ---- an answer to the HELLO before a project change does not open the new project's link
  sc_project_ev(1, 0);                                  // reloaded (the same ID): a HELLO owed
  sc_store_tick(nullptr);                               // HELLO out; its answer held
  auto held = g_answers;
  CHECK(held.size() == 1);
  g_answers.clear();
  h_proj_reset();
  sc_project_ev(0, 0);                                  // and another project before the answer came
  for (auto& m : held) sc_store_host(m.data(), (int)m.size());
  sc_store_tick(nullptr);                               // the stale answer seen; the new HELLO out
  CHECK(sc_link_epoch() == 0);
  tick(2);
  CHECK(sc_link_epoch() != 0 && g_store.project() == sc_project_id());

  // ---- the port goes down mid-request: the request goes again after the next HELLO
  g_pi_deaf = true;
  Res r6;
  CHECK(sc_store_write(4, small, 10, cb, &r6));
  tick();
  h_port_state = 0;
  tick();
  CHECK(sc_link_epoch() == 0 && r6.calls == 0);
  g_pi_deaf = false;
  h_port_state = 1;
  tick(3);
  CHECK(r6.calls == 1 && r6.st == 0 && r6.h == 1);
  // nothing ticks while the link is closed
  h_port_state = 0;
  tick();
  size_t n2c = sent(0x2C);
  for (int t = 0; t < 13; ++t) h_prev[t] = 5, sc_fire(t, 1, 6);
  sc_end();
  CHECK(sent(0x2C) == (int)n2c);

  // ---- the test client (storetest/): each session declares its lock set, writes 600 bytes and reads them back, a
  // small record through the cache, then the previous session's record by pattern 1's handle
  h_port_state = 1;
  sc_set_pattern_handle(0, 0);
  g_st_on = true;
  tick(3);                                              // the link back open: session 1
  CHECK(st_sessions == 1);
  tick(40);
  enum { S_LOCKS, S_WRITE, S_READ, S_SMALL, S_PRIOR, S_DONE };
  CHECK(st_res == (1u << S_LOCKS | 1u << S_WRITE | 1u << S_READ | 1u << S_SMALL | 1u << S_DONE) && st_bad == 0);
  CHECK(locks::declared(7) && locks::lock_at(7, 0, 0) == 1000 && locks::lock_at(7, 8, 1) == 3000);
  uint32_t h1 = sc_pattern_handle(0);
  CHECK(h1 != 0);
  g_ctrl[0x20] = 0;
  st_draw(nullptr, g_ctrl);
  CHECK(g_rects == 1 + 1 + 5);                          // the clear, one session pixel, five boxes
  // session 2 (the project loaded again, or SAVE AS: the same ID): the first session's record read back
  sc_project_ev(1, 0);
  tick(3);
  CHECK(st_sessions == 2);
  tick(40);
  CHECK(st_res == 0x3f && st_bad == 0);
  CHECK(sc_pattern_handle(0) != h1);
  // a deaf Pi mid-session: the step times out and shows as failed; the next session runs again
  sc_project_ev(1, 0);
  tick(3);
  g_pi_deaf = true;
  tick(80);
  CHECK(st_sessions == 3 && (st_bad & 1u << S_WRITE) && st_status[S_WRITE] == 0x7e);
  g_pi_deaf = false;
  g_st_on = false;
  h_port_state = 0;                                     // closed again, as the next part starts
  tick();

  // ---- no Pi at all: three HELLOs 2 s apart, then quiet until a host message or the port comes up again
  h_port_state = 1;
  g_pi_deaf = true;
  uint32_t hellos = h_scl_hellos();
  tick(400);
  CHECK(h_scl_hellos() == hellos + 3 && sc_link_epoch() == 0);

  printf(g_fail ? "test_companion: %d FAILED\n" : "test_companion: PASS\n", g_fail);
  return g_fail ? 1 : 0;
}
