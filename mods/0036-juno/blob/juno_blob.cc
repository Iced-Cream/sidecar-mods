// JUNO, the Sidecar's Juno-106 voice as a shipped blob (SCX, sidecar-firmware core/code/scx.h): the upstream Sidecar's
// juno::Voice (trigcondition/sidecar-firmware sim/juno/juno_voice.h, GPL-2.0; signal path and curves after AMY's
// Juno-106 model, its 128 factory patches as the 106's 18 sysex bytes, shorepine/amy juno.py, MIT), one mono voice. The
// Rytm's JUNO machine (its voice mod, a client of the companion's voice service) places one per physical voice; the
// companion sends its trigs (midi(): src 0x7F, 0x90 note vel; 0x80 the release once the Rytm sends one) and its knobs
// (params 0..7, the machine's knob words >> 2: value x 64), in core's order (H first, then A..G):
//   0 LEN  the gate: 127 held until the release (or the next trig), lower 20 ms x 2^(LEN / 14)
//   1 PAT  the factory patch 0..127 (A11..B88)
//   2 CUT  3 RES  4 ENV  5 ATK  6 DEC  7 REL   the patch's VCF FREQ, RES, ENV, A, D and R sliders, absolute 0..127
// Upstream's P1..P8 are PAT CUT RES ENV ATK DEC REL LEN: set_param maps the order, juno::Voice is unchanged.
//
// A new PAT plays the patch's own six sliders until the Rytm's CUT..REL move (upstream's hold, core/voices.cpp
// juno_select): upstream's host also writes the patch's values back onto the Rytm's knobs (its message 15); on the
// generic engine that write-back is the Rytm mod's (core ask 14, a knob value set by a mod), so until then the knobs
// keep showing what they were while the patch's own values play, and the first turn of any of the six hands all six
// to the knobs, as upstream does when the knobs move before the write-back lands.
// Not here: the project's JUNO list from the card (PAT picks the factory patches only) and the chord / poly layer.
// Output: the voice on both of its slot outputs (the voice service routes L onto the voice's Overbridge input).
#include <stddef.h>
#include <stdint.h>
#include <string.h>

#include <new>

#include "juno_voice.h"
#include "scx.h"

namespace {
constexpr int kN = 8;
const scx_param kParams[kN] = {{"LEN", 64 * 64}, {"PAT", 0},       {"CUT", 64 * 64}, {"RES", 64 * 64},
                               {"ENV", 64 * 64},  {"ATK", 64 * 64}, {"DEC", 64 * 64}, {"REL", 64 * 64}};
const uint8_t kToP[kN] = {7, 0, 1, 2, 3, 4, 5, 6};   // blob param -> upstream's P index
const int kJunoByte[6] = {5, 6, 7, 11, 12, 14};      // CUT..REL: the patch's bytes (upstream's kJunoByte)
constexpr int kBlock = 12;                           // upstream renders 12-sample blocks (its kSub-stepped envelope)

struct State {
  juno::Voice voice;
  float p[8];        // upstream's P1..P8 as the Rytm sends them, 0..127.98
  int pat;           // the patch the hold belongs to (-1 none)
  bool holding;      // the patch's own six play, not the knobs'
  float from[6];     // the knobs' six when the patch was picked
  float hold[6];     // the patch's six
};

int pat_of(const float* p) {
  int v = (int)p[0];
  return v < 0 ? 0 : v > 127 ? 127 : v;
}

// the knobs to the voice: the patch's six while holding (upstream's juno_select)
void apply(State* s) {
  int pat = pat_of(s->p);
  if (pat != s->pat) {
    s->pat = pat;
    for (int i = 0; i < 6; ++i) s->hold[i] = juno::kPatches[pat].b[kJunoByte[i]] & 0x7f, s->from[i] = s->p[1 + i];
    s->holding = true;
  }
  float k[8];
  memcpy(k, s->p, sizeof k);
  if (s->holding) {
    bool same = true, moved = false;
    for (int i = 0; i < 6; ++i) {
      same = same && (int)s->p[1 + i] == (int)s->hold[i];
      moved = moved || s->p[1 + i] != s->from[i];
    }
    if (same || moved) s->holding = false;
    else for (int i = 0; i < 6; ++i) k[1 + i] = s->hold[i];
  }
  s->voice.SetKnobs(k);
}

void* make(void* mem) {
  State* s = new (mem) State();
  s->voice.Init(48000.0f);
  for (int k = 0; k < kN; ++k) s->p[kToP[k]] = kParams[k].def / 64.0f;
  s->pat = -1;
  apply(s);
  return s;
}

void set_param(void* st, int param, int value14) {
  State* s = static_cast<State*>(st);
  if (param < 0 || param >= kN) return;
  s->p[kToP[param]] = value14 / 64.0f;
  apply(s);
}

void midi(void* st, int src, int status, int d1, int d2) {
  State* s = static_cast<State*>(st);
  if (src != 0x7F) return;   // the Rytm's trigs only
  if ((status & 0xF0) == 0x90 && d2) s->voice.NoteOn((float)d1, d2 / 127.0f);
  else if ((status & 0xF0) == 0x80 || (status & 0xF0) == 0x90) s->voice.NoteOff();
}

void process(void* st, const scx_io* io) {
  State* s = static_cast<State*>(st);
  if (!io->sout[0]) return;
  for (int done = 0; done < io->frames; done += kBlock) {
    int n = io->frames - done < kBlock ? io->frames - done : kBlock;
    s->voice.Render(io->sout[0] + done, n);
  }
  if (io->sout[1]) memcpy(io->sout[1], io->sout[0], io->frames * sizeof(float));
}

void link_reset(void* st) { static_cast<State*>(st)->voice.NoteOff(); }

const scx_block kBlock_ = {SCX_ABI, "JUNO", kN, kParams, sizeof(State), make, process, set_param, midi, link_reset};
}  // namespace

extern "C" __attribute__((visibility("default"))) const scx_block* scx_entry(void) { return &kBlock_; }
