// mods/0025-sendfx/test/test_sendfx.cpp - SEND FX (sfx.c) through the companion (mods/0032-sidecar, built for a PC by
// its test/companion_host.c) against the Pi's own services from sidecar-firmware: the record store (core/kv), the lock
// service (core/locks, its sink as the engine's locks_bind: the route's gains and the processor slots' params), the
// audio route (core/route) and the DSP library (core/dsp, core/proc). A router does what the Pi's kv::link::from_host
// does, and the Pi's answers reach the companion through sc_store_host. Then audio: an SD hit through the graph.
//   make -C mods/0025-sendfx/test FIRMWARE=<sidecar-firmware checkout>
#include <math.h>
#include <stdio.h>
#include <string.h>
#include <sys/mman.h>

#include <map>
#include <string>
#include <vector>

#include "dsp/dsp.h"
#include "kv/kv.h"
#include "locks/locks.h"
#include "proc/proc.h"
#include "route/route.h"

using namespace core;

static int g_fail = 0;
#define CHECK(c) do { if (!(c)) { printf("FAIL %s:%d: %s\n", __FILE__, __LINE__, #c); ++g_fail; } } while (0)

extern "C" {
extern volatile uint32_t h_port_state;
extern const volatile uint32_t* h_pool;
extern uint8_t h_name[16];
extern uint8_t h_kit_index[4];
extern uint32_t h_khand_v[128];
int sc_store_host(const uint8_t* d, int32_t len);
void sc_store_tick(void* ctrl);
void sc_project_ev(int32_t how, uint32_t dropped);
uint32_t sc_link_epoch(void);
uint32_t sc_kit_gen(void);
int32_t sc_kit_get(uint32_t mod, uint8_t* buf, uint32_t cap);
void sfx_tick(void* ctrl);
uint32_t sfx_diag(int32_t k);
int32_t h_track = 1;                                    // the selected track (SFX_TRACK)
// the pages' entries, as core would call them
struct ctext { void* obj; int32_t id; int32_t value; char* buf; };
struct cparam { int32_t first, last; int (*get)(int32_t, int32_t*); int (*delta)(void*, int32_t, int32_t, int32_t); int (*text)(ctext*); };
extern const cparam sfx_params;
struct cplock { int32_t first, last; int (*get)(int32_t, int32_t, int32_t); int (*turn)(int32_t, int32_t, int32_t, int32_t);
                int (*set)(int32_t, int32_t, int32_t, int32_t); int (*clear)(int32_t, int32_t, int32_t); };
extern const cplock sfx_locks;                          // core-ar2 0.10's core_param_locks entry
extern volatile int8_t h_pat_idx;
uint32_t sc_pattern_handle(int32_t p);
}

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
static std::vector<std::vector<uint8_t>> g_answers;
static MemBackend g_mem;
static kv::Store g_store(&g_mem);
static void svc_out(const uint8_t* m, int n) { g_answers.emplace_back(m, m + n); }
static kv::Service g_svc(&g_store, svc_out);
static std::map<int, int> g_ops;                        // the lock / route / dsp ops the Pi took, by op
static void lock_sink(int slot, int param, int v) {     // as locks_bind
  if (slot == route::kTarget) route::set_gain(param, v);
  else proc::set_param(slot, param, v);
}

extern "C" void h_midi_send(int32_t n, const uint8_t* m) {
  if (n < 7 || m[4] != kv::kCmd) return;
  ++g_ops[m[6]];
  if (locks::is_lock_op(m[6])) { locks::sysex(m, n); return; }
  if (route::is_route_op(m[6]) || dsp::is_dsp_op(m[6])) {
    if (route::is_route_op(m[6])) route::sysex(m, n); else dsp::sysex(m, n);
    uint8_t a[32];
    for (int an; (an = route::take_answer(a, sizeof a)) > 0;) g_answers.emplace_back(a, a + an);
    for (int an; (an = dsp::take_answer(a, sizeof a)) > 0;) g_answers.emplace_back(a, a + an);
    return;
  }
  if (m[6] == kv::kOpName) return;
  if (m[6] == kv::kOpHello) locks::reset(), route::reset(), dsp::reset();
  g_svc.sysex(m, n);
}

// ---- the render side, as pi/engine/audio_return.cpp runs a block
static float g_in[12][64], g_out[12][64], g_si[route::kSlotChans][64], g_so[route::kSlotChans][64];
static void render(int n = 64) {
  static float* si[route::kSlotChans];
  static float* so[route::kSlotChans];
  for (int k = 0; k < route::kSlotChans; ++k) si[k] = g_si[k], so[k] = g_so[k];
  proc::Block b{};
  for (int c = 0; c < 12; ++c) b.in[c] = g_in[c], b.out[c] = g_out[c];
  memset(g_out, 0, sizeof g_out);
  memset(g_si, 0, sizeof g_si);
  memset(g_so, 0, sizeof g_so);
  b.frames = n;
  route::process_in(b.in, b.out, si, n);
  proc::begin();
  uint8_t order[route::kSlots];
  route::order(order);
  for (int i = 0; i < route::kSlots; ++i) {
    proc::run(order[i], b, si, so);
    route::process_slot(order[i], so, b.out, si, n);
  }
  proc::end();
  route::end_block(n);
}

static void tick(int n = 1) {                           // ev_tick: the companion, then the mod; answers in between
  for (int i = 0; i < n; ++i) {
    sc_store_tick(nullptr);
    sfx_tick(nullptr);
    auto a = g_answers;
    g_answers.clear();
    for (auto& m : a) sc_store_host(m.data(), (int)m.size());
    render();                                           // the Pi keeps playing (fades, the dsp's releases)
    dsp::poll();
  }
}
static int turn(int id, int steps) { return sfx_params.delta(nullptr, id, steps * 256, 0); }
static int val(int id) { int32_t v = -1; sfx_params.get(id, &v); return v >> 8; }
static std::string text(int id) {
  char b[16] = {0};
  ctext t = {nullptr, id, val(id) << 8, b};
  sfx_params.text(&t);
  return b;
}
static int slots_of(const char* name) {
  int k = 0;
  for (int i = 0; i < dsp::kSlots; ++i) k += dsp::slot(i).state == dsp::kPlacedState && !strcmp(dsp::slot(i).block, name);
  return k;
}
static int points(int src_lo, int src_hi, int dst_lo, int dst_hi) {
  int k = 0;
  for (int i = 0; i < route::kPoints; ++i) {
    route::Point p = route::point(i);
    k += p.open && p.owner == 0x25 && p.src >= src_lo && p.src <= src_hi && p.dst >= dst_lo && p.dst <= dst_hi;
  }
  return k;
}

int main() {
  setvbuf(stdout, nullptr, _IONBF, 0);
  alignas(64) static uint8_t arena[dsp::kSlots * dsp::kSlotBytes];
  CHECK(dsp::begin(arena, sizeof arena));
  uint32_t* pool = (uint32_t*)mmap(nullptr, 4096, PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANONYMOUS | MAP_32BIT, -1, 0);
  for (int i = 0; i < 4; ++i) pool[14 * i + 13] = i < 3 ? (uint32_t)(uintptr_t)(pool + 14 * (i + 1)) : 0;
  h_pool = pool;
  locks::set_sink(lock_sink);
  memcpy(h_name, "SENDFX\0\0\0\0\0\0\0\0\0\0", 16);

  // ---- the link opens; kit 0 has no record: the defaults (FX 1 ECHO = DELAY + FILTER, FX 2 CHORUS = DELAY)
  h_port_state = 1;
  sc_project_ev(1, 0);
  tick(30);
  CHECK(sc_link_epoch() != 0 && sc_kit_gen() != 0 && sfx_diag(5) == 0 && sfx_diag(6) == 0 && sfx_diag(2) == 0);
  CHECK(slots_of("DELAY") == 2 && slots_of("FILTER") == 1);
  CHECK(points(2, 9, 12, 43) == 32);                    // 8 stems x L R into each FX's first block
  CHECK(points(12, 43, 12, 43) == 2);                   // ECHO's chain
  CHECK(points(12, 43, 2, 3) == 4);                     // both returns on MAIN FX (PRE)
  for (int s = 8; s < 32; ++s) CHECK(locks::declared(s));
  CHECK(locks::declared(0) && locks::declared(1) && locks::declared(2) && !locks::declared(3));
  CHECK(text(562) == "ECHO" && text(568) == "CHORUS" && text(563) == "PRE" && text(564) == "64");

  // ---- a send: SD (track 1) to FX 1 at full; the gain reaches SD's points into FX 1 at once (a base, no lock)
  h_track = 1;
  CHECK(val(560) == 0 && turn(560, 127) && val(560) == 127);
  tick(2);
  int sd_l = -1;
  for (int i = 0; i < route::kPoints; ++i) {
    route::Point p = route::point(i);
    if (p.open && p.owner == 0x25 && p.src == 3 && p.dst >= 12 && p.gain == 8192) { sd_l = i; break; }
  }
  CHECK(sd_l >= 0);
  // audio: an SD hit comes back on MAIN FX L as ECHO's repeat, not straight away
  for (int k = 0; k < 40; ++k) render();                 // the gains' ramps
  memset(g_in, 0, sizeof g_in);
  g_in[3][0] = 0.5f;
  float early = 0, late = 0;
  for (int b = 0; b < 600; ++b) {                        // 0.8 s
    render();
    g_in[3][0] = 0;
    for (int f = 0; f < 64; ++f) {
      float a = fabsf(g_out[2][f]);
      if (b < 4) early = fmaxf(early, a); else late = fmaxf(late, a);
      CHECK(isfinite(g_out[2][f]));
    }
  }
  CHECK(early < 1e-4f && late > 0.01f);
  printf("echo: early %.6f, repeat peak %.4f\n", early, late);

  // ---- P1 POST: the returns move onto MAIN
  CHECK(turn(563, 1) && text(563) == "POST");
  tick(3);
  CHECK(points(12, 43, 0, 1) == 2 && points(12, 43, 2, 3) == 2);

  // ---- TYPE: FX 2 CHORUS -> CRUSH (DELAY freed, a SHAPER placed, its sets again)
  CHECK(turn(568, 2) && text(568) == "CRUSH");
  tick(30);
  CHECK(slots_of("DELAY") == 1 && slots_of("SHAPER") == 1 && slots_of("FILTER") == 1);
  CHECK(points(2, 9, 12, 43) == 32 && points(12, 43, 2, 3) == 2);
  // ---- P2 of FX 2 (SHAPER DRIVE) is a base of its block's set
  CHECK(turn(570, 63) && val(570) == 127);
  tick(2);
  CHECK(locks::value(2, 1) == 16383);                    // set 2 = FX 2's block 0, param 1 DRIVE, full

  // ---- the kit's section written after the debounce, and read back after another kit and this one again
  tick(20);
  uint8_t sec[64];
  CHECK(sc_kit_get(25, sec, sizeof sec) == 36 && sec[2] == 127 && sec[24] == 5 && sec[25] == 1 && sec[30] == 3);
  uint32_t h0 = h_khand_v[0];
  CHECK(h0 != 0);
  h_kit_index[3] = 4;                                    // kit 4: no record, the defaults: FX 2 back to CHORUS
  tick(30);
  CHECK(text(568) == "CHORUS" && val(560) == 0 && slots_of("SHAPER") == 0 && slots_of("DELAY") == 2);
  h_kit_index[3] = 0;
  tick(30);
  CHECK(text(568) == "CRUSH" && text(563) == "POST" && val(560) == 127 && slots_of("SHAPER") == 1);
  CHECK(points(12, 43, 0, 1) == 2);

  // ---- p-locks (part 2): a trig held on the FX track, step 3, FX 1's P2 (ECHO's TIME: block 0, param 0) turned up 10
  const uint16_t kNone = locks::kNone;
  auto echo_time = [](int v) { return 10500 + (5000 * v + 63) / 127; };
  CHECK(sfx_locks.get(564, 12, 3) == -1);
  CHECK(sfx_locks.turn(564, 12, 3, 10 * 256) == 74 << 8 && sfx_locks.get(564, 12, 3) == 74 << 8);   // from the knob's 64
  tick();                                               // the op goes out at the companion's next tick
  CHECK(locks::lock_at(0, 3, 0) == echo_time(74) && val(564) == 64);    // a lock on the Pi; the knob's own value kept
  CHECK(sfx_locks.turn(564, 12, 3, 256) == 75 << 8);
  tick();
  CHECK(locks::lock_at(0, 3, 0) == echo_time(75));
  CHECK(sfx_locks.turn(562, 12, 3, 256) == -1 && sfx_locks.turn(563, 12, 3, 256) == -1);   // TYPE, ROUTE: no lock
  CHECK(sfx_locks.turn(564, 1, 3, 256) == -1 && sfx_locks.turn(560, 12, 3, 256) == -1);    // off their tracks
  // a send lock: SD (track 1) to FX 1 off on step 5 (its base is full): both of SD's points into FX 1
  CHECK(sfx_locks.turn(560, 1, 5, -127 * 256) == 0);
  tick();
  CHECK(locks::lock_at(10, 5, 0) == 0 && locks::lock_at(10, 5, 1) == 0 && locks::lock_at(10, 4, 0) == kNone);
  CHECK(sfx_diag(7) == 2);
  // the pattern's record written once the turns stop
  int8_t p0 = h_pat_idx;
  tick(20);
  uint32_t ph = sc_pattern_handle(p0);
  CHECK(ph != 0);
  // another pattern plays: it has no locks, so the Pi's sets are cleared
  h_pat_idx = 3;
  tick(10);
  CHECK(sfx_diag(7) == 0 && locks::lock_at(0, 3, 0) == kNone && locks::lock_at(10, 5, 0) == kNone);
  CHECK(sfx_locks.turn(566, 12, 7, 256) == 65 << 8);   // FX 1's P4 (FILTER's cutoff, block 1) in this one
  tick();
  CHECK(locks::lock_at(1, 7, 1) != kNone);
  // back to the first (its record read from the Pi): its locks again, the other's gone
  h_pat_idx = p0;
  tick(20);
  CHECK(sc_pattern_handle(3) != 0 && sc_pattern_handle(p0) == ph);
  CHECK(sfx_diag(7) == 2 && locks::lock_at(0, 3, 0) == echo_time(75) && locks::lock_at(10, 5, 0) == 0);
  CHECK(locks::lock_at(1, 7, 1) == kNone);
  // a lock cleared (stock's clear call)
  CHECK(sfx_locks.clear(564, 12, 3) == 1);
  tick();
  CHECK(locks::lock_at(0, 3, 0) == kNone && sfx_locks.get(564, 12, 3) == -1);
  CHECK(sfx_diag(7) == 1 && sfx_diag(9) == 0);
  tick(20);

  // ---- a new session (the Pi restarted): everything asked again, the pattern's locks too
  sc_project_ev(1, 0);
  tick(40);
  CHECK(locks::lock_at(10, 5, 0) == 0 && locks::lock_at(10, 5, 1) == 0 && sfx_diag(7) == 1);
  CHECK(slots_of("SHAPER") == 1 && slots_of("DELAY") == 1 && slots_of("FILTER") == 1 && points(2, 9, 12, 43) == 32);
  CHECK(route::stats().open == 32 + 2 + 2 * 2);

  CHECK(sfx_diag(2) == 0 && sfx_diag(5) == 0 && sfx_diag(6) == 0);   // nothing refused, both FX built
  printf("ops: SET %d BASE %d LOCK %d CLEAR %d DROP %d ROUTE %d MOVE %d GAIN %d PLACE %d FREE %d\n", g_ops[0x10],
         g_ops[0x11], g_ops[0x12], g_ops[0x13], g_ops[0x15], g_ops[0x20], g_ops[0x21], g_ops[0x23], g_ops[0x30], g_ops[0x31]);
  printf(g_fail ? "test_sendfx: %d FAILED\n" : "test_sendfx: PASS\n", g_fail);
  return g_fail != 0;
}
