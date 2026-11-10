// 6-OP FM, the Sidecar's 6-OP FM voice as a shipped blob (SCX, sidecar-firmware core/code/scx.h): the upstream Sidecar's
// rytm::FmMachine (trigcondition/sidecar-firmware sim/plaits/fm_machine.h, GPL-2.0) on Mutable Instruments Plaits'
// six-op engine (MIT, (c) Emilie Gillet), one mono voice playing one DX7 voice at a time. The Rytm's 6-OP FM machine (its
// voice mod, a client of the companion's voice service) places one per physical voice; the companion sends its trigs
// (midi(): src 0x7F, 0x90 note vel; 0x80 the release once the Rytm sends one) and its knobs (params 0..7, the machine's
// knob words >> 2: value x 64 + the fraction's top 6 bits), in core's order (LEV first, then A..G):
//   0 LEV  output level, 0..127 (unity at 127, as upstream's)
//   1 PAT  the voice: Plaits' 96 ROM voices (its three DX7 banks), value 0..95, 96..127 the last; picked at a trig
//   2 TIM  the modulators' levels (64 = the voice as stored)      3 MOR  the envelopes' rates (64 = as stored)
//   4 DEC  Plaits' LPG after the voice, its decay; 127 leaves the LPG out (the voice's own envelopes)
//   5 LPG  the LPG's colour      6 TUN  semitones from 64, added to the trig's note
//   7 LEN  the gate: 127 held until the release (or the next trig), lower 20 ms x 2^(LEN / 14)
// Upstream's P1..P8 are PAT TIM MOR DEC LPG TUN LEV LEN: set_param maps the order, FmMachine is unchanged.
// What upstream adds around it and this blob does not: the project's FM list from the card (PAT steps through the
// ROM voices only) and the chord / poly layer.
// Output: the voice on both of its slot outputs (the voice service routes L onto the voice's Overbridge input).
#include <stddef.h>
#include <stdint.h>
#include <string.h>

#include <new>

#include "fm_machine.h"
#include "plaits/dsp/voice.h"
#include "plaits/resources.h"
#include "scx.h"
#include "stmlib/utils/buffer_allocator.h"

namespace {
constexpr int kN = 8;
constexpr int kRomVoices = 96;
const scx_param kParams[kN] = {{"LEV", 100 * 64}, {"PAT", 0},       {"TIM", 64 * 64}, {"MOR", 64 * 64},
                               {"DEC", 127 * 64}, {"LPG", 64 * 64}, {"TUN", 64 * 64}, {"LEN", 64 * 64}};
// blob param k -> upstream's P index (PAT TIM MOR DEC LPG TUN LEV LEN)
const uint8_t kToP[kN] = {6, 0, 1, 2, 3, 4, 5, 7};

struct State {
  plaits::Voice voice;
  plaits::Patch patch;
  plaits::Modulations mod;
  rytm::FmMachine fm;
  float p[8];   // upstream's P1..P8, 0..127.98
  int pat;      // the ROM voice loaded (-1 none)
  float out[plaits::kMaxBlockSize];
  uint8_t stage[rytm::FmMachine::kStageBytes];
  char shared[32768];
};

const uint8_t* rom_voice(int e) {
  const uint8_t* bank = e < 32 ? plaits::syx_bank_0 : e < 64 ? plaits::syx_bank_1 : plaits::syx_bank_2;
  return bank + 128 * (e % 32);
}

// PAT at a trig (upstream's fm_select with an empty list): a sounding note is never cut by a PAT move between trigs
void select(State* s) {
  int e = (int)s->p[0];
  e = e < 0 ? 0 : e >= kRomVoices ? kRomVoices - 1 : e;
  if (e == s->pat) return;
  s->pat = e;
  s->fm.SetVoice(rom_voice(e));
}

void* make(void* mem) {
  State* s = new (mem) State();
  stmlib::BufferAllocator allocator(s->shared, sizeof s->shared);
  s->voice.Init(&allocator);
  memset(&s->patch, 0, sizeof s->patch);
  memset(&s->mod, 0, sizeof s->mod);
  s->fm.Init();
  for (int k = 0; k < kN; ++k) s->p[kToP[k]] = kParams[k].def / 64.0f;
  s->fm.SetKnobs(s->p);
  s->pat = -1;
  select(s);
  return s;
}

void set_param(void* st, int param, int value14) {
  State* s = static_cast<State*>(st);
  if (param < 0 || param >= kN) return;
  s->p[kToP[param]] = value14 / 64.0f;
  s->fm.SetKnobs(s->p);
}

void midi(void* st, int src, int status, int d1, int d2) {
  State* s = static_cast<State*>(st);
  if (src != 0x7F) return;   // the Rytm's trigs only
  if ((status & 0xF0) == 0x90 && d2) {
    select(s);
    s->fm.NoteOn((float)d1, d2 / 127.0f);
  } else if ((status & 0xF0) == 0x80 || (status & 0xF0) == 0x90) {
    s->fm.NoteOff();
  }
}

void process(void* st, const scx_io* io) {
  State* s = static_cast<State*>(st);
  if (!io->sout[0]) return;
  for (int done = 0; done < io->frames;) {
    int n = io->frames - done;
    if (n > (int)plaits::kMaxBlockSize) n = plaits::kMaxBlockSize;
    s->fm.Render(&s->voice, &s->patch, &s->mod, s->stage, s->out, n);
    for (int i = 0; i < n; ++i) {
      io->sout[0][done + i] = s->out[i];
      if (io->sout[1]) io->sout[1][done + i] = s->out[i];
    }
    done += n;
  }
}

void link_reset(void* st) { static_cast<State*>(st)->fm.NoteOff(); }

const scx_block kBlock = {SCX_ABI, "FM", kN, kParams, sizeof(State), make, process, set_param, midi, link_reset};
}  // namespace

// clang turns fm_machine.h's memcmp(..) == 0 into bcmp, which the engine does not export: the blob's own, on memcmp
extern "C" __attribute__((visibility("hidden"))) int bcmp(const void* a, const void* b, size_t n) { return memcmp(a, b, n); }

extern "C" __attribute__((visibility("default"))) const scx_block* scx_entry(void) { return &kBlock; }
