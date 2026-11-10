/* Mod 0033 - PLAITS: Mutable Instruments Plaits as a Rytm machine played by the Sidecar's Pi (2026-11-10). The first
 * of ext's voices (sidecar-mods 0021) as its own mod: machine slot 44 (BD TEST) through core-ar2 0.13's core_machines,
 * a client of the companion's voice service (sidecar-core voice.c), its sound the PLAITS blob (blob/, shipped as this
 * mod's payload through the companion's sc_code). design.md.
 *
 * The engine is the companion's: stock's DISABLE engine (the voice plays its Overbridge input through its filter,
 * overdrive and amp) and the voice's trigs and knob words to its Pi block. The knobs are ordinary machine knobs
 * (sound indices 9..16 of BD TEST's records), so stock stores, p-locks and slides them; their words go to the blob as
 * params 0..7 (LEV, then A..G). */
#include <stdint.h>

#include "analog-rytm-mk2/machines.h"
#include "analog-rytm-mk2/pages.h"

struct sc_voice {          /* sidecar-core companion/voice.c */
  uint8_t owner, nknobs, ships, mod;
  const char *block;
  int32_t (*input)(const uint16_t *blk, int32_t voice);   /* none: PLAITS takes no input */
  const uint8_t *words;                                   /* none: param k = word k */
  const struct core_page *page2;                          /* page 2 behind SRC (the companion's page id 19) */
  const uint8_t *p2def;
  uint8_t p2n, pad2[3];
};
void sc_voice_engine(const struct sc_voice *d, int32_t v, void *frame, uint16_t *blk, int32_t pitch);
int32_t sc_voice_p2_get(const struct sc_voice *d, int32_t k, int32_t *value);
int32_t sc_voice_p2_turn(const struct sc_voice *d, int32_t k, int32_t delta);

#define PL_OWNER 0x44      /* the Pi ops' owner byte and the blob's sc_code owner */
#define PL_MOD   33        /* the mod's number: page 2's section of the companion's sound record */

/* Page 2 (2026-11-10, behind SRC): seven values of the sound, the blob's params 8..14 (blob/plaits_blob.cc), on this
 * mod's own knob ids (core-ar2 0.13 "knobs": 7, mod.toml). Laid out as ext's page 2: TMD MMD FM AUX / FIN VEL GLD. */
CORE_KNOBS;
#define PL_P2N 7
static const uint8_t pl_p2def[PL_P2N] = {64, 64, 64, 0, 64, 0, 0};
static const char *const pl_p2lab[PL_P2N] = {"TMD", "MMD", "FM", "AUX", "FIN", "VEL", "GLD"};
static const char *const pl_p2name[PL_P2N] = {"Timbre Mod", "Morph Mod", "Freq Mod", "Aux Mix", "Fine Tune",
                                              "Velocity", "Glide"};
static const uint8_t pl_p2bip[PL_P2N] = {1, 1, 1, 0, 1, 0, 0};   /* shown from -64 */
const struct core_page pl_page2 = {19, "PLAITS PAGE 2",
                                   {CORE_KNOB(0), CORE_KNOB(1), CORE_KNOB(2), CORE_KNOB(3), CORE_KNOB(4), CORE_KNOB(5),
                                    CORE_KNOB(6), 0}};

static const struct sc_voice pl_voice = {PL_OWNER, 8, 1, PL_MOD, "PLAITS", 0, 0, &pl_page2, pl_p2def, PL_P2N, {0, 0, 0}};

static void pl_engine(int32_t v, void *frame, uint16_t *blk, int32_t pitch) {
  sc_voice_engine(&pl_voice, v, frame, blk, pitch);
}

/* core_machines' entry: slot 44 on every voice; knob 0 is LEV (H), then A..G */
const struct core_machine pl_machine = {
  44, pl_engine, -1, 0xff, 0, "PLAITS", "PLTS",
  {
    {"Level", "LEV", 0, 127, 100, 0},
    {"Engine", "ENG", 0, 127, 0, 0},
    {"Harmonics", "HRM", 0, 127, 64, 0},
    {"Timbre", "TIM", 0, 127, 64, 0},
    {"Morph", "MOR", 0, 127, 64, 0},
    {"Decay", "DEC", 0, 127, 64, 0},
    {"LPG Colour", "LPG", 0, 127, 64, 0},
    {"Tune", "TUN", 32, 96, 64, 1},
  }};

/* ENG's value text: the model's name in place of stock's number. BD TEST's records are 408..415 (sound indices
 * 9..16), so ENG (index 10) is 409. The blob maps value v to zone v * 17 / 128 (blob/plaits_blob.cc); get and delta
 * stay stock's. */
#define PL_ENG_ID 409
/* at most 4 characters, as stock's own value texts (VA VCF, PHASE DIST, WAVE TERRAIN, STRING MACHINE, CHIPTUNE, VA,
 * WAVESHAPER, 2-OP FM, GRANULAR, HARMONIC, WAVETABLE, CHORDS, SPEECH, SWARM, PARTICLE, STRING, MODAL) */
static const char *const pl_models[17] = {
  "VCF", "PHAS", "TERR", "SMCH", "CHIP", "VA", "SHAP", "FM2", "GRAN",
  "HARM", "WTBL", "CHRD", "SPCH", "SWRM", "PART", "STRG", "MODL"};

static int pl_text(struct core_text *t) {
  if (t->id != PL_ENG_ID) return CORE_TEXT_PASS;
  int32_t v = t->value >> 8;
  if (v < 0) v = 0;
  if (v > 127) v = 127;
  const char *s = pl_models[v * 17 / 128];
  char *b = t->buf;
  while (*s) *b++ = *s++;
  *b = 0;
  return CORE_TEXT_DONE;
}

const struct core_param pl_params = {PL_ENG_ID, PL_ENG_ID, 0, 0, pl_text};

/* page 2's knobs: values through the companion (the current track's sound), labels, texts, dials */
static int pl_p2get(int32_t id, int32_t *value) { return sc_voice_p2_get(&pl_voice, id - CORE_KNOB(0), value); }
static int pl_p2delta(void *view, int32_t id, int32_t delta, int32_t func) {
  (void)view;
  (void)func;
  int32_t k = id - CORE_KNOB(0);
  /* in a register: GCC 13 -mcpu=5475 turns the sibling call's argument into sub.l #__knobs,8(%sp), which ColdFire
     has no form of (the assembler refuses it) */
  __asm__("" : "+d"(k));
  return sc_voice_p2_turn(&pl_voice, k, delta);
}
static int pl_p2text(struct core_text *t) {
  int32_t k = t->id - CORE_KNOB(0), v = t->value >> 8, n = 0;
  char d[4], *b = t->buf;
  if (k < 0 || k >= PL_P2N) return CORE_TEXT_PASS;
  if (pl_p2bip[k]) {
    v -= 64;
    if (v < 0) *b++ = '-', v = -v;
    else if (v > 0) *b++ = '+';
  }
  do d[n++] = (char)('0' + v % 10), v /= 10; while (v && n < 3);
  while (n) *b++ = d[--n];
  *b = 0;
  return CORE_TEXT_DONE;
}
const struct core_param pl_p2params = {CORE_KNOB(0), CORE_KNOB(PL_P2N - 1), pl_p2get, pl_p2delta, pl_p2text};
static const char *pl_p2label(int32_t id) {
  int32_t k = id - CORE_KNOB(0);
  return k >= 0 && k < PL_P2N ? pl_p2lab[k] : 0;
}
static const char *pl_p2long(int32_t id) {
  int32_t k = id - CORE_KNOB(0);
  return k >= 0 && k < PL_P2N ? pl_p2name[k] : 0;
}
const struct core_param_lock pl_p2names = {CORE_KNOB(0), CORE_KNOB(PL_P2N - 1), 0, 0, 0, 0, pl_p2label, pl_p2long};
/* dials: stock's SMPL FIN (record 40, a centred dial) for the bipolar ones, BD TEST's LEV (408) for the rest; 0..127 */
#define PL_LOOK(a, b, r) {CORE_KNOB(a), CORE_KNOB(b), r, 0, 0, 127 << 8}
const struct core_knob_look pl_look0 = PL_LOOK(0, 2, 40);
const struct core_knob_look pl_look1 = PL_LOOK(3, 3, 408);
const struct core_knob_look pl_look2 = PL_LOOK(4, 4, 40);
const struct core_knob_look pl_look3 = PL_LOOK(5, 6, 408);
