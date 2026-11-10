// DAISYSP, the Sidecar's DAISYSP voice as a shipped blob (SCX, sidecar-firmware core/code/scx.h): a physical model
// struck by its own exciter or by one of the Rytm's voices. Its models are Mutable Instruments Plaits' physical
// modelling (MIT, (c) Emilie Gillet: modal voice, string voice, modal resonator), the code DaisySP's own modal / string
// / resonator voices are ports of. The Rytm's DAISYSP machine (its voice mod, a client of the companion's voice
// service) places one per physical voice; the companion sends its trigs (midi(): src 0x7F, 0x90 note vel), its knobs
// (params 0..7, the machine's knob words >> 2) and, for INP's voices, routes that voice's Overbridge stem onto this
// block's input L.
//   0 LEV  output level, 0..127 (unity at 100)
//   1 ENG  the model: MODAL STRING RESON in three zones (value x 3 / 128), ext's pick (2026-10-09)
//   2 STR  structure   3 BRI brightness   4 DMP damping   (0..127 -> 0..1)
//   5 INP  the exciter, 11 zones (value x 11 / 128): INT (the model's own), NAT (the track's own machine: not yet,
//          plays as INT), NOISE (a noise burst on each trig), then BD SD RS/CP BT LT MT/HT CH/OH CY/CB (the input L)
//   6 EXC  the exciter's gain, 0..127 (unity at 64); INT: the strike's accent
//   7 TUN  semitones from 64, added to the trig's note
// Output: the resonance on both of its slot outputs (the voice service routes L onto the voice's Overbridge input).
#include <stddef.h>
#include <stdint.h>
#include <string.h>

#include <new>

#include "plaits/dsp/dsp.h"
#include "plaits/dsp/physical_modelling/modal_voice.h"
#include "plaits/dsp/physical_modelling/resonator.h"
#include "plaits/dsp/physical_modelling/string.h"
#include "plaits/dsp/physical_modelling/string_voice.h"
#include "scx.h"
#include "stmlib/dsp/units.h"
#include "stmlib/utils/buffer_allocator.h"
#include "stmlib/utils/random.h"

namespace {
enum { kModal = 0, kString, kReson };
enum { kInt = 0, kNat, kNoise };   // INP zones; 3.. the voices

constexpr int kFrames = plaits::kMaxBlockSize;

struct State {
  plaits::ModalVoice modal;      // MODAL, INT
  plaits::StringVoice string;    // STRING, INT
  plaits::Resonator reson;       // RESON, and MODAL with an outside exciter
  plaits::String ext_string;     // STRING with an outside exciter
  float knob[8];                 // 0..127.98
  float note;
  float accent;
  bool trig;
  float burst;                   // NOISE / RESON INT: what is left of the burst's envelope
  int last_eng, last_inp;
  char shared[2 * 1280 * sizeof(float) + 64];
};

const scx_param kParams[8] = {{"LEV", 100 * 64}, {"ENG", 0},      {"STR", 64 * 64}, {"BRI", 64 * 64},
                              {"DMP", 64 * 64},  {"INP", 0},      {"EXC", 64 * 64}, {"TUN", 64 * 64}};

void* make(void* mem) {
  State* s = new (mem) State();
  stmlib::BufferAllocator allocator(s->shared, sizeof s->shared);
  s->modal.Init();
  s->string.Init(&allocator);
  s->reson.Init(0.015f, plaits::kMaxNumModes);
  s->ext_string.Init(&allocator);
  for (int k = 0; k < 8; ++k) s->knob[k] = kParams[k].def / 64.0f;
  s->note = 48.0f;
  s->accent = 0.8f;
  s->last_eng = s->last_inp = -1;
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
  s->accent = d2 / 127.0f;
  s->trig = true;
}

inline float unit(float v) { return v <= 0.0f ? 0.0f : v >= 127.0f ? 1.0f : v / 127.0f; }
inline int zone(float v, int n) {
  int z = (int)(v * n / 128.0f);
  return z < 0 ? 0 : z >= n ? n - 1 : z;
}

void process(void* st, const scx_io* io) {
  State* s = static_cast<State*>(st);
  if (!io->sout[0]) return;
  const int eng = zone(s->knob[1], 3);
  int inp = zone(s->knob[5], 11);
  if (inp == kNat) inp = kInt;                 // NAT needs the track's own machine on the voice (core-ar2: not yet)
  if (eng != s->last_eng || inp != s->last_inp) {   // a new model or exciter starts from silence
    s->string.Reset();
    s->ext_string.Reset();
    s->reson.Init(eng == kReson ? 0.25f : 0.015f, plaits::kMaxNumModes);
    s->burst = 0.0f;
    s->last_eng = eng, s->last_inp = inp;
  }
  float f0 = plaits::a0 * 0.25f * stmlib::SemitonesToRatio(s->note + (s->knob[7] - 64.0f) - 9.0f);
  if (f0 > 0.25f) f0 = 0.25f;
  const float str = unit(s->knob[2]), bri = unit(s->knob[3]), dmp = unit(s->knob[4]);
  const float exc = s->knob[6] / 64.0f;
  const float gain = s->knob[0] / 100.0f;
  const float nonlin = str < 0.24f ? (str - 0.24f) * 4.166f : (str > 0.26f ? (str - 0.26f) * 1.35135f : 0.0f);
  float temp[kFrames], out[kFrames], aux[kFrames];
  for (int done = 0; done < io->frames;) {
    int n = io->frames - done;
    if (n > kFrames) n = kFrames;
    const bool trig = s->trig;
    s->trig = false;
    memset(out, 0, sizeof out);
    memset(aux, 0, sizeof aux);
    if (inp == kInt && eng != kReson) {
      const float accent = s->accent * (exc > 1.0f ? 1.0f : exc);
      if (eng == kModal)
        s->modal.Render(false, trig, accent, f0, str, bri, dmp, temp, out, aux, n);
      else
        s->string.Render(false, trig, accent, f0, str, bri, dmp, temp, out, aux, n);
    } else {
      // the exciter: the input, or a burst (NOISE: 30 ms of noise; RESON INT: a 1 ms click)
      if (trig && inp <= kNoise) s->burst = s->accent;
      const float fall = inp == kNoise ? 0.9993f : 0.98f;
      for (int i = 0; i < n; ++i) {
        float x;
        if (inp > kNoise) {
          const float* in = io->sin[0];
          x = in ? in[done + i] : 0.0f;
        } else {
          x = (2.0f * stmlib::Random::GetFloat() - 1.0f) * s->burst * 0.25f;
          s->burst *= fall;
        }
        temp[i] = x * exc;
      }
      if (eng == kString)
        s->ext_string.Process(f0, nonlin, bri, dmp, temp, out, n);
      else
        s->reson.Process(f0, str, bri, dmp, temp, out, n);
    }
    for (int i = 0; i < n; ++i) {
      float y = out[i] * gain * (eng == kModal ? 0.6f : 1.0f);   // MODAL rings the loudest
      y = y > 1.0f ? 1.0f : y < -1.0f ? -1.0f : y;
      io->sout[0][done + i] = y;
      if (io->sout[1]) io->sout[1][done + i] = y;
    }
    done += n;
  }
}

void link_reset(void* st) { static_cast<State*>(st)->trig = false; }

const scx_block kBlock = {SCX_ABI, "DAISYSP", 8, kParams, sizeof(State), make, process, set_param, midi, link_reset};
}  // namespace

extern "C" __attribute__((visibility("default"))) const scx_block* scx_entry(void) { return &kBlock; }
