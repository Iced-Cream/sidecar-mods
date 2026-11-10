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
  uint8_t owner, nknobs, ships, mod;
  const char *block;
  int32_t (*input)(const uint16_t *blk, int32_t voice);
  const uint8_t *words;    /* none: param k = word k */
  const struct core_page *page2;                          /* page 2 behind SRC (the companion's page id 19) */
  const uint8_t *p2def;
  uint8_t p2n, pad2[3];
};
void sc_voice_engine(const struct sc_voice *d, int32_t v, void *frame, uint16_t *blk, int32_t pitch);
int32_t sc_voice_p2_get(const struct sc_voice *d, int32_t k, int32_t *value);
int32_t sc_voice_p2_turn(const struct sc_voice *d, int32_t k, int32_t delta);
const char *sc_sample_name(int32_t index);   /* sidecar-core companion/samples.c */
int32_t sc_sample_state(int32_t index);

#define DS_OWNER 0x45      /* the Pi ops' owner byte */

static const uint8_t dss_words[6] = {0, 1, 2, 3, 6, 7};   /* LEV SMP TUN STA, END LOP */
/* Page 2 (2026-11-10, behind SRC): 2 values of the sound after the block's knob params, on this mod's own knob ids
 * (core-ar2 0.13 "knobs": 2, mod.toml), through the companion's voice page (its page id 19). */
CORE_KNOBS;
#define DSS_P2N 2
static const uint8_t dss_p2def[2] = {64, 0};
static const char *const dss_p2lab[2] = {"FIN", "VEL"};
static const char *const dss_p2name[2] = {"Fine Tune", "Velocity"};
static const uint8_t dss_p2bip[2] = {1, 0};   /* shown from -64 */
const struct core_page dss_page2 = {19, "DSP SAMPLE 2", {CORE_KNOB(0), CORE_KNOB(1), 0, 0, 0, 0, 0, 0}};

static const struct sc_voice dss_voice = {DS_OWNER, 6, 0, 35, "SAMPLE", 0, dss_words, &dss_page2, dss_p2def, DSS_P2N, {0, 0, 0}};

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
#define DSS_END_ID 420     /* sound index 15 */
#define DSS_LOP_ID 421     /* sound index 16 */
#define DSS_TEXT 7         /* characters shown (ext measured about 7 on the knob) */

/* a number as text, unsigned (stock's text for SD TEST's records is signed about 64) */
static int32_t dss_num(char *b, int32_t v) {
  char d[4];
  int32_t n = 0, k = 0;
  if (v < 0) v = 0;
  do d[n++] = (char)('0' + v % 10), v /= 10; while (v && n < 3);
  while (n) b[k++] = d[--n];
  b[k] = 0;
  return k;
}

static int dss_text(struct core_text *t) {
  int32_t v = t->value >> 8, k = 0, st;
  const char *s;
  char *b = t->buf;
  /* (PV13A's emulator gate, 2026-11-10: END's record drew ERR, LOP's 000, SMP's number signed) */
  if (t->id == DSS_END_ID) { dss_num(b, v); return CORE_TEXT_DONE; }
  if (t->id == DSS_LOP_ID) { s = v ? "ON" : "OFF"; while (*s) b[k++] = *s++; b[k] = 0; return CORE_TEXT_DONE; }
  if (t->id != DSS_SMP_ID) return CORE_TEXT_PASS;
  if (v <= 0) s = "OFF";
  else {
    s = sc_sample_name(v - 1);
    st = sc_sample_state(v - 1);
    if (!s || !s[0]) { dss_num(b, v); return CORE_TEXT_DONE; }   /* unknown or an empty entry: the number */
    if (st == 4 || st == 5) b[k++] = '!';
  }
  while (*s && *s != '.' && k < DSS_TEXT) b[k++] = *s++;
  b[k] = 0;
  return CORE_TEXT_DONE;
}

const struct core_param dss_params = {DSS_SMP_ID, DSS_LOP_ID, 0, 0, dss_text};   /* 418, 419: passed */

/* page 2's knobs: values through the companion (the current track's sound), labels, texts, dials */
static int dss_p2get(int32_t id, int32_t *value) { return sc_voice_p2_get(&dss_voice, id - CORE_KNOB(0), value); }
static int dss_p2delta(void *view, int32_t id, int32_t delta, int32_t func) {
  (void)view;
  (void)func;
  int32_t k = id - CORE_KNOB(0);
  /* in a register: GCC 13 -mcpu=5475 turns the sibling call's argument into sub.l #__knobs,8(%sp), which ColdFire
     has no form of (the assembler refuses it) */
  __asm__("" : "+d"(k));
  return sc_voice_p2_turn(&dss_voice, k, delta);
}
static int dss_p2text(struct core_text *t) {
  int32_t k = t->id - CORE_KNOB(0), v = t->value >> 8, n = 0;
  char d[4], *b = t->buf;
  if (k < 0 || k >= DSS_P2N) return CORE_TEXT_PASS;
  if (dss_p2bip[k]) {
    v -= 64;
    if (v < 0) *b++ = '-', v = -v;
    else if (v > 0) *b++ = '+';
  }
  do d[n++] = (char)('0' + v % 10), v /= 10; while (v && n < 3);
  while (n) *b++ = d[--n];
  *b = 0;
  return CORE_TEXT_DONE;
}
const struct core_param dss_p2params = {CORE_KNOB(0), CORE_KNOB(DSS_P2N - 1), dss_p2get, dss_p2delta, dss_p2text};
static const char *dss_p2label(int32_t id) {
  int32_t k = id - CORE_KNOB(0);
  return k >= 0 && k < DSS_P2N ? dss_p2lab[k] : 0;
}
static const char *dss_p2long(int32_t id) {
  int32_t k = id - CORE_KNOB(0);
  return k >= 0 && k < DSS_P2N ? dss_p2name[k] : 0;
}
const struct core_param_lock dss_p2names = {CORE_KNOB(0), CORE_KNOB(DSS_P2N - 1), 0, 0, 0, 0, dss_p2label, dss_p2long};
/* dials: stock's SMPL FIN (record 40, a centred dial) for the bipolar ones, BD TEST's LEV (408) for the rest; 0..127 */
const struct core_knob_look dss_look0 = {CORE_KNOB(0), CORE_KNOB(0), 40, 0, 0, 127 << 8};
const struct core_knob_look dss_look1 = {CORE_KNOB(1), CORE_KNOB(1), 408, 0, 0, 127 << 8};
