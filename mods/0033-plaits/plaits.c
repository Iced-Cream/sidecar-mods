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

struct sc_voice {          /* sidecar-core companion/voice.c */
  uint8_t owner, nknobs, ships, pad;
  const char *block;
};
void sc_voice_engine(const struct sc_voice *d, int32_t v, void *frame, uint16_t *blk, int32_t pitch);

#define PL_OWNER 0x44      /* the Pi ops' owner byte and the blob's sc_code owner */

static const struct sc_voice pl_voice = {PL_OWNER, 8, 1, 0, "PLAITS"};

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
