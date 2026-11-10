// PLAITS, the Sidecar's PLAITS voice as a shipped blob (SCX, sidecar-firmware core/code/scx.h): Mutable Instruments
// Plaits (MIT, (c) Emilie Gillet) as one mono voice. The Rytm's PLAITS machine (its voice mod, a client of the
// companion's voice service) places one per physical voice; the companion sends its trigs (midi(): src 0x7F, 0x90
// note vel) and its knobs (params 0..7, the machine's knob words >> 2: value x 64 + the fraction's top 6 bits).
//   0 LEV  output level, 0..127 (unity at 100)
//   1 ENG  the model: 17 zones (value x 17 / 128) over Plaits' engines, ext's curated pick (2026-10-09)
//   2 HRM  harmonics   3 TIM timbre   4 MOR morph   5 DEC decay   6 LPG lpg colour   (0..127 -> 0..1)
//   7 TUN  semitones from 64, added to the trig's note
// Output: the voice on both of its slot outputs (the voice service routes L onto the voice's Overbridge input).
#include <stddef.h>
#include <stdint.h>
#include <string.h>

#include <new>

#include "plaits/dsp/voice.h"
#include "scx.h"
#include "stmlib/utils/buffer_allocator.h"

namespace {
const uint8_t kModels[17] = {0, 1, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 18, 19, 20};

struct State {
  plaits::Voice voice;
  plaits::Patch patch;
  plaits::Modulations mod;
  float knob[8];      // 0..127.98
  float note;
  bool trig;
  char shared[32768];
};

const scx_param kParams[8] = {{"LEV", 100 * 64}, {"ENG", 0},      {"HRM", 64 * 64}, {"TIM", 64 * 64},
                              {"MOR", 64 * 64},  {"DEC", 64 * 64}, {"LPG", 64 * 64}, {"TUN", 64 * 64}};

void* make(void* mem) {
  State* s = new (mem) State();
  stmlib::BufferAllocator allocator(s->shared, sizeof s->shared);
  s->voice.Init(&allocator);
  memset(&s->patch, 0, sizeof s->patch);
  memset(&s->mod, 0, sizeof s->mod);
  for (int k = 0; k < 8; ++k) s->knob[k] = kParams[k].def / 64.0f;
  s->note = 48.0f;
  s->mod.trigger_patched = true;
  return s;
}

void set_param(void* st, int param, int value14) {
  State* s = static_cast<State*>(st);
  if (param >= 0 && param < 8) s->knob[param] = value14 / 64.0f;
}

void midi(void* st, int src, int status, int d1, int d2) {
  State* s = static_cast<State*>(st);
  if (src != 0x7F || (status & 0xF0) != 0x90 || !d2) return;   // the Rytm's trigs only
  s->note = (float)d1;
  s->trig = true;
}

inline float unit(float v) { return v <= 0.0f ? 0.0f : v >= 127.0f ? 1.0f : v / 127.0f; }

void process(void* st, const scx_io* io) {
  State* s = static_cast<State*>(st);
  if (!io->sout[0]) return;
  int zone = (int)(s->knob[1] * 17.0f / 128.0f);
  s->patch.engine = kModels[zone < 0 ? 0 : zone > 16 ? 16 : zone];
  s->patch.note = s->note + (s->knob[7] - 64.0f);
  s->patch.harmonics = unit(s->knob[2]);
  s->patch.timbre = unit(s->knob[3]);
  s->patch.morph = unit(s->knob[4]);
  s->patch.decay = unit(s->knob[5]);
  s->patch.lpg_colour = unit(s->knob[6]);
  const float gain = s->knob[0] / (100.0f * 32768.0f);
  plaits::Voice::Frame f[plaits::kMaxBlockSize];
  for (int done = 0; done < io->frames;) {
    int n = io->frames - done;
    if (n > (int)plaits::kMaxBlockSize) n = plaits::kMaxBlockSize;
    s->mod.trigger = s->trig ? 1.0f : 0.0f;
    s->trig = false;
    s->voice.Render(s->patch, s->mod, f, n);
    for (int i = 0; i < n; ++i) {
      float y = f[i].out * gain;
      io->sout[0][done + i] = y;
      if (io->sout[1]) io->sout[1][done + i] = y;
    }
    done += n;
  }
}

void link_reset(void* st) { static_cast<State*>(st)->trig = false; }

const scx_block kBlock = {SCX_ABI, "PLAITS", 8, kParams, sizeof(State), make, process, set_param, midi, link_reset};
}  // namespace

extern "C" __attribute__((visibility("default"))) const scx_block* scx_entry(void) { return &kBlock; }
