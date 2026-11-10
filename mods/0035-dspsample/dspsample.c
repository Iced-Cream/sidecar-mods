/* Mod 0035 - DSP SAMPLE: a sample player as a Rytm machine played by the Sidecar's Pi (2026-11-10). The third of ext's
 * voices (sidecar-mods 0021) as its own mod: machine slot 45 (SD TEST) through core-ar2 0.13's core_machines, a client
 * of the companion's voice service and sample client (sidecar-core voice.c, samples.c); its sound the Pi's DSP library
 * block SAMPLE, playing an entry of the project's sample pool (sidecar-firmware core/samples). Nothing shipped.
 * design.md.
 *
 * The engine is the companion's: stock's DISABLE engine (the voice plays its Overbridge input through its filter,
 * overdrive and amp), the voice's trigs and knob words to its SAMPLE block. SD TEST has records for sound indices
 * 9..12, 15, 16 only, so the knobs are LEV SMP TUN STA, END LOP, and the voice service sends words 0..3, 6, 7 as
 * SAMPLE's params 0..5. Stock stores, p-locks and slides them. */
#include <stdint.h>

#include "analog-rytm-mk2/machines.h"
#include "analog-rytm-mk2/pages.h"

struct sc_voice {          /* sidecar-core companion/voice.c */
  uint8_t owner, nknobs, ships, pad;
  const char *block;
  int32_t (*input)(const uint16_t *blk, int32_t voice);
  const uint8_t *words;
};
void sc_voice_engine(const struct sc_voice *d, int32_t v, void *frame, uint16_t *blk, int32_t pitch);
const char *sc_sample_name(int32_t index);   /* sidecar-core companion/samples.c */
int32_t sc_sample_state(int32_t index);

#define DS_OWNER 0x45      /* the Pi ops' owner byte */

static const uint8_t dss_words[6] = {0, 1, 2, 3, 6, 7};   /* LEV SMP TUN STA, END LOP */
static const struct sc_voice dss_voice = {DS_OWNER, 6, 0, 0, "SAMPLE", 0, dss_words};

static void dss_engine(int32_t v, void *frame, uint16_t *blk, int32_t pitch) {
  sc_voice_engine(&dss_voice, v, frame, blk, pitch);
}

/* core_machines' entry: slot 45 on every voice; knob 0 is LEV (H), then A..G; SD TEST has no records for 4 and 5 */
const struct core_machine dss_machine = {
  45, dss_engine, -1, 0xff, 0, "DSP SAMPLE", "DSPS",
  {
    {"Level", "LEV", 0, 127, 100, 0},
    {"Sample", "SMP", 0, 127, 0, 0},
    {"Tune", "TUN", 40, 88, 64, 1},
    {"Start", "STA", 0, 127, 0, 0},
    {0, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0},
    {"End", "END", 0, 127, 127, 0},
    {"Loop", "LOP", 0, 1, 0, 0},
  }};

/* SMP's value text: the pool entry's file name (OFF at 0; the number while the name is not known yet, "!" before it
 * when the Pi could not load it). SD TEST's records are 416..419 (sound indices 9..12), 420 / 421 (15, 16): SMP
 * (index 10) is 417. get and turn stay stock's. */
#define DSS_SMP_ID 417
#define DSS_TEXT 7         /* characters shown (ext measured about 7 on the knob) */

static int dss_text(struct core_text *t) {
  int32_t v = t->value >> 8, k = 0, st;
  const char *s;
  char *b = t->buf;
  if (t->id != DSS_SMP_ID) return CORE_TEXT_PASS;
  if (v <= 0) s = "OFF";
  else {
    s = sc_sample_name(v - 1);
    st = sc_sample_state(v - 1);
    if (!s || !s[0]) return CORE_TEXT_STOCK;     /* unknown or an empty entry: the number */
    if (st == 4 || st == 5) b[k++] = '!';
  }
  while (*s && *s != '.' && k < DSS_TEXT) b[k++] = *s++;
  b[k] = 0;
  return CORE_TEXT_DONE;
}

const struct core_param dss_params = {DSS_SMP_ID, DSS_SMP_ID, 0, 0, dss_text};
