// PLAITS, the Sidecar's PLAITS voice as a shipped blob (SCX, sidecar-firmware core/code/scx.h): Mutable Instruments
// Plaits (MIT, (c) Emilie Gillet) as one mono voice. The Rytm's PLAITS machine (its voice mod, a client of the
// companion's voice service) places one per physical voice; the companion sends its trigs (midi(): src 0x7F, 0x90
// note vel) and its knobs (params 0..7, the machine's knob words >> 2: value x 64 + the fraction's top 6 bits).
//   0 LEV  output level, 0..127 (unity at 100)
//   1 ENG  the model: 17 zones (value x 17 / 128) over Plaits' engines, ext's curated pick (2026-10-09)
//   2 HRM  harmonics   3 TIM timbre   4 MOR morph   5 DEC decay   6 LPG lpg colour   (0..127 -> 0..1)
//   7 TUN  semitones from 64, added to the trig's note
// Page 2 (the companion's voice page 2, the sound's values after the eight knob words; 2026-11-10):
//   8 TMD  timbre's modulation by the internal envelope, bipolar from 64   9 MMD morph's, the same
//  10 FM   the pitch's modulation by the internal envelope, bipolar from 64
//  11 AUX  the output's mix of Plaits' AUX (the model's second output): 0 OUT only, 127 AUX only
//  12 FIN  cents from 64 (+-100 over the range)
//  13 VEL  how much the trig's velocity sets the level: 0 none, 127 all
//  14 GLD  glide from the last note: 0 none, 127 about 2 s
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
  float knob[15];     // 0..127.98
  float note, glide_note, vel;
  bool trig;
  char shared[32768];
};

constexpr int kN = 15;
const scx_param kParams[kN] = {{"LEV", 100 * 64}, {"ENG", 0},      {"HRM", 64 * 64}, {"TIM", 64 * 64},
                               {"MOR", 64 * 64},  {"DEC", 64 * 64}, {"LPG", 64 * 64}, {"TUN", 64 * 64},
                               {"TMD", 64 * 64},  {"MMD", 64 * 64}, {"FM", 64 * 64},  {"AUX", 0},
                               {"FIN", 64 * 64},  {"VEL", 0},       {"GLD", 0}};

void* make(void* mem) {
  State* s = new (mem) State();
  stmlib::BufferAllocator allocator(s->shared, sizeof s->shared);
  s->voice.Init(&allocator);
  memset(&s->patch, 0, sizeof s->patch);
  memset(&s->mod, 0, sizeof s->mod);
  for (int k = 0; k < kN; ++k) s->knob[k] = kParams[k].def / 64.0f;
  s->note = s->glide_note = 48.0f;
  s->vel = 127.0f;
  s->mod.trigger_patched = true;
  return s;
}

void set_param(void* st, int param, int value14) {
  State* s = static_cast<State*>(st);
  if (param >= 0 && param < kN) s->knob[param] = value14 / 64.0f;
}

void midi(void* st, int src, int status, int d1, int d2) {
  State* s = static_cast<State*>(st);
  if (src != 0x7F || (status & 0xF0) != 0x90 || !d2) return;   // the Rytm's trigs only
  s->note = (float)d1;
  s->vel = (float)d2;
  s->trig = true;
}

inline float unit(float v) { return v <= 0.0f ? 0.0f : v >= 127.0f ? 1.0f : v / 127.0f; }
inline float bipolar(float v) { float x = (v - 64.0f) / 63.0f; return x < -1.0f ? -1.0f : x > 1.0f ? 1.0f : x; }

void process(void* st, const scx_io* io) {
  State* s = static_cast<State*>(st);
  if (!io->sout[0]) return;
  int zone = (int)(s->knob[1] * 17.0f / 128.0f);
  s->patch.engine = kModels[zone < 0 ? 0 : zone > 16 ? 16 : zone];
  // glide: the played note follows the trig's, a one-pole slew per block (GLD 127: ~2 s to 1/e at 1500 blocks/s)
  const float g = unit(s->knob[14]);
  if (g <= 0.0f) s->glide_note = s->note;
  else s->glide_note += (s->note - s->glide_note) * (1.0f / (1.0f + g * g * 3000.0f));
  s->patch.note = s->glide_note + (s->knob[7] - 64.0f) + (s->knob[12] - 64.0f) / 64.0f;
  s->patch.timbre_modulation_amount = bipolar(s->knob[8]);
  s->patch.morph_modulation_amount = bipolar(s->knob[9]);
  s->patch.frequency_modulation_amount = bipolar(s->knob[10]);
  s->patch.harmonics = unit(s->knob[2]);
  s->patch.timbre = unit(s->knob[3]);
  s->patch.morph = unit(s->knob[4]);
  s->patch.decay = unit(s->knob[5]);
  s->patch.lpg_colour = unit(s->knob[6]);
  const float vamt = unit(s->knob[13]);
  const float gain = s->knob[0] / (100.0f * 32768.0f) * (1.0f - vamt * (1.0f - s->vel / 127.0f));
  const float aux = unit(s->knob[11]);
  plaits::Voice::Frame f[plaits::kMaxBlockSize];
  for (int done = 0; done < io->frames;) {
    int n = io->frames - done;
    if (n > (int)plaits::kMaxBlockSize) n = plaits::kMaxBlockSize;
    s->mod.trigger = s->trig ? 1.0f : 0.0f;
    s->trig = false;
    s->voice.Render(s->patch, s->mod, f, n);
    for (int i = 0; i < n; ++i) {
      float y = ((float)f[i].out * (1.0f - aux) + (float)f[i].aux * aux) * gain;
      io->sout[0][done + i] = y;
      if (io->sout[1]) io->sout[1][done + i] = y;
    }
    done += n;
  }
}

void link_reset(void* st) { static_cast<State*>(st)->trig = false; }

const scx_block kBlock = {SCX_ABI, "PLAITS", kN, kParams, sizeof(State), make, process, set_param, midi, link_reset};
}  // namespace

extern "C" __attribute__((visibility("default"))) const scx_block* scx_entry(void) { return &kBlock; }
