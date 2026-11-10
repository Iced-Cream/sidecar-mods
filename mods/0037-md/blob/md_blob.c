/* MD, the Sidecar's MD drum voice as a shipped blob (SCX, sidecar-firmware core/code/scx.h): the upstream Sidecar's
 * built-in MD (trigcondition/sidecar-firmware core/md, plugins/mdkit/mdk.c with MDK_FAM_MD, MIT) over mdkit's 30
 * Machinedrum voices (soejrd/mdkit, CC0 1.0): FM BD SD XT CP RS CB HH CY, PI BD SD MT ML MA RS RC CC HH, TRX BD SD XT
 * CP RS CB CH OH CY MA CL XC B2. One mono voice; mdk.c's own state, resampler (mdkit's 44.1 kHz to 48 kHz), TYPE
 * fades and tails run unchanged, compiled into this file as upstream compiles its built-in. The Rytm's MD machine (its voice mod, a
 * client of the companion's voice service) places one per physical voice; the companion sends its trigs (midi(): src
 * 0x7F, 0x90 note vel) and its knobs (params 0..9, the knob words >> 2: value x 64), in core's order (H first, then
 * A..G, then page 2):
 *   0 LEV  output trim (level = LEV / 127)        1 TYP  the voice: 30 zones over every ENGINE's TYPEs, in the order above
 *   2..7   the TYPE's controls 1..6               8, 9 (page 2) its controls 7, 8
 * Upstream's Rytm page splits the voice into ENGINE (3 zones) and TYPE (that ENGINE's zones); TYP picks the same set in
 * one knob and the blob hands mdk.c the ENGINE and TYPE values whose zones name it (MD-BUILTIN.md's lo(z, n)).
 * The note is ignored (pitch is the TYPE's PTCH control); the velocity is the hit's level; a release does nothing (the
 * voice's own decay), as upstream. Output: the voice on both of its slot outputs. */
#include <stddef.h>
#include <stdint.h>
#include <string.h>

#include "scx.h"

/* the glue as upstream's built-in (its MDKit/mdk_builtin.c): compiled here, so its state's size is known */
#define MDK_FAM_MD 1
#define MDK_BUILTIN 1
#define RMP_NATIVE 1
#define rmp_entry mdk_builtin_entry
#include "glue/mdk.c"

enum { kN = 10, kSets = 30, kBlock = 12 };
static const struct scx_param kParams[kN] = {{"LEV", 100 * 64}, {"TYP", 0},       {"C1", 64 * 64}, {"C2", 64 * 64},
                                             {"C3", 64 * 64},   {"C4", 64 * 64}, {"C5", 64 * 64}, {"C6", 64 * 64},
                                             {"C7", 64 * 64},   {"C8", 64 * 64}};
static const unsigned char kCount[3] = {8, 9, 13}, kBase[3] = {0, 8, 17};   /* families.h's MDK_ENGINES */

typedef struct {
  float k[kN];   /* the knobs, 0..127.98 */
  float p[16];   /* upstream's P1..P16 in MD's layout: P1..P8 the controls, P9 ENGINE, P10 TYPE, P11 LEV */
  mdk md;        /* mdk.c's state */
} State;

static int lo(int z, int n) { return (z * 128 + n - 1) / n; }   /* the lowest value of zone z of n */

static void to_md(State *s) {
  int v = (int)s->k[1];
  v = v < 0 ? 0 : v > 127 ? 127 : v;
  int set = (v * kSets) >> 7, e = set >= kBase[2] ? 2 : set >= kBase[1] ? 1 : 0;
  for (int c = 0; c < 6; ++c) s->p[c] = s->k[2 + c];
  s->p[6] = s->k[8];
  s->p[7] = s->k[9];
  s->p[8] = (float)lo(e, 3);
  s->p[9] = (float)lo(set - kBase[e], kCount[e]);
  s->p[10] = s->k[0];
  md_params(&s->md, s->p);
}

static void *make(void *mem) {
  State *s = (State *)mem;   /* zeroed by the engine */
  for (int k = 0; k < kN; ++k) s->k[k] = kParams[k].def / 64.0f;
  md_voice_init(&s->md);
  to_md(s);
  return s;
}

static void set_param(void *st, int param, int value14) {
  State *s = (State *)st;
  if (param < 0 || param >= kN) return;
  s->k[param] = value14 / 64.0f;
  to_md(s);
}

static void midi(void *st, int src, int status, int d1, int d2) {
  State *s = (State *)st;
  if (src != 0x7F) return;   /* the Rytm's trigs only */
  if ((status & 0xF0) == 0x90 && d2) md_note_on(&s->md, (float)d1, d2 / 127.0f);
}

static void process(void *st, const struct scx_io *io) {
  State *s = (State *)st;
  if (!io->sout[0]) return;
  for (int done = 0; done < io->frames; done += kBlock) {   /* upstream renders 12 at a time (its max_block 24) */
    int n = io->frames - done < kBlock ? io->frames - done : kBlock;
    md_render(&s->md, io->sout[0] + done, n);
  }
  if (io->sout[1]) memcpy(io->sout[1], io->sout[0], (size_t)io->frames * sizeof(float));
}

static const struct scx_block kBlockDesc = {SCX_ABI, "MD", kN, kParams, sizeof(State), make, process, set_param, midi, 0};

__attribute__((visibility("default"))) const struct scx_block *scx_entry(void) { return &kBlockDesc; }
