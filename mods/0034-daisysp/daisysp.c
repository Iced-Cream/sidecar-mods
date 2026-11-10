/* Mod 0034 - DAISYSP: a physical model (MODAL, STRING, RESON) as a Rytm machine played by the Sidecar's Pi, struck by
 * its own exciter, a noise burst or another of the Rytm's voices (2026-11-10). The second of ext's voices
 * (sidecar-mods 0021) as its own mod: machine slot 51 (CY TEST) through core-ar2 0.13's core_machines, a client of the
 * companion's voice service (sidecar-core voice.c) with an input, its sound the DAISYSP blob (blob/, shipped as this
 * mod's payload through the companion's sc_code). design.md.
 *
 * The engine is the companion's: stock's DISABLE engine (the voice plays its Overbridge input through its filter,
 * overdrive and amp), the voice's trigs and knob words to its Pi block, and INP's voice stem onto the block's input.
 * The knobs are CY TEST's records (sound indices 9..16), so stock stores, p-locks and slides them; their words go to
 * the blob as params 0..7 (LEV, then A..G). */
#include <stdint.h>

#include "analog-rytm-mk2/machines.h"
#include "analog-rytm-mk2/pages.h"

struct sc_voice {          /* sidecar-core companion/voice.c */
  uint8_t owner, nknobs, ships, pad;
  const char *block;
  int32_t (*input)(const uint16_t *blk, int32_t voice);
};
void sc_voice_engine(const struct sc_voice *d, int32_t v, void *frame, uint16_t *blk, int32_t pitch);

#define DS_OWNER 0x51      /* the Pi ops' owner byte and the blob's sc_code owner */
#define DS_INP_ZONES 11    /* INT NAT NOISE, then the eight voices */

/* INP's zone of a value 0..127, as the blob decodes it */
static int32_t ds_zone(int32_t v, int32_t n) { int32_t z = v * n / 128; return z < 0 ? 0 : z >= n ? n - 1 : z; }

/* the block's input: INP's voices are the Overbridge stems BD SD RS/CP BT LT MT/HT CH/OH CY/CB, IN 2..9 */
static int32_t ds_input(const uint16_t *blk, int32_t voice) {
  int32_t z = ds_zone(blk[5] >> 8, DS_INP_ZONES);
  (void)voice;
  return z >= 3 ? z - 1 : -1;
}

static const struct sc_voice ds_voice = {DS_OWNER, 8, 1, 0, "DAISYSP", ds_input};

static void ds_engine(int32_t v, void *frame, uint16_t *blk, int32_t pitch) {
  sc_voice_engine(&ds_voice, v, frame, blk, pitch);
}

/* core_machines' entry: slot 51 on every voice; knob 0 is LEV (H), then A..G */
const struct core_machine ds_machine = {
  51, ds_engine, -1, 0xff, 0, "DAISYSP", "DSP",
  {
    {"Level", "LEV", 0, 127, 100, 0},
    {"Engine", "ENG", 0, 127, 0, 0},
    {"Structure", "STR", 0, 127, 64, 0},
    {"Brightness", "BRI", 0, 127, 64, 0},
    {"Damping", "DMP", 0, 127, 64, 0},
    {"Input", "INP", 0, 127, 0, 0},
    {"Excite", "EXC", 0, 127, 64, 0},
    {"Tune", "TUN", 32, 96, 64, 1},
  }};

/* ENG's and INP's value texts: names in place of stock's numbers, at most 4 characters. CY TEST's records are
 * 449..456 (sound indices 9..16): ENG (index 10) is 450, INP (index 14) 454. get and turn stay stock's. */
#define DS_ENG_ID 450
#define DS_INP_ID 454
static const char *const ds_models[3] = {"MODL", "STRG", "RESN"};
static const char *const ds_inputs[DS_INP_ZONES] = {"INT", "NAT", "NOIS", "BD", "SD", "RS", "BT", "LT", "MT", "CH", "CY"};

static int ds_text(struct core_text *t) {
  int32_t v = t->value >> 8;
  const char *s;
  char *b = t->buf;
  if (t->id == DS_ENG_ID) s = ds_models[ds_zone(v, 3)];
  else if (t->id == DS_INP_ID) s = ds_inputs[ds_zone(v, DS_INP_ZONES)];
  else return CORE_TEXT_PASS;
  while (*s) *b++ = *s++;
  *b = 0;
  return CORE_TEXT_DONE;
}

const struct core_param ds_params = {DS_ENG_ID, DS_INP_ID, 0, 0, ds_text};
