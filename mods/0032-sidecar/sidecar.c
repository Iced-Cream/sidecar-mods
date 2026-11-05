/*
 * 0032-sidecar: the Sidecar companion (rytm-mods docs: mods/0032-sidecar/design.md).
 *
 * It owns the host link's SysEx on the Rytm: every message from the USB host is taken at the SysEx
 * router's entry (0x40083dd8: data, len, interface; the MIDI task) before stock routes it, as 0022's
 * router took it until the companion phase. A message F0 7D 52 54 <cmd> ... F7 (7 bytes or more) is
 * always taken; it goes to the mod that registered <cmd> in the table sc_cmds, which the linker builds
 * from the mods' contributions (mod.toml [[sidecar.cmds]], tools/build.py). Any other message goes on
 * to stock, unchanged.
 *
 * An entry is 12 bytes: first and last command, flags, a pad byte, a magic word and a pointer.
 *   - flags bit 0 (SC_DIRECT): the pointer is the handler, called for every command in the range.
 *   - otherwise the pointer is the mod's mailbox, two words {magic, handler} the mod writes when it is
 *     ready (its first ev_tick, usually): the handler is called only while the mailbox holds the entry's
 *     magic, as 0022's fixed-address mailboxes were "live when the magic is there".
 * A handler is int f(const uint8_t *data, int32_t len), run in the MIDI task; its result is ignored.
 * Ranges do not overlap (build.py refuses it). The table ends with a zero entry.
 *
 * The companion's own services, in the same table: the store link (51: the Pi's records and parameter locks for any
 * mod, the project's ID, name and a handle per pattern), store.c; and the step clock (2C / 2D, with the param
 * `clock`), clock.c (the Storage phase, 2026-11-04; design.md). Included at the end. The FX return (26 / 27, fxin.c,
 * once 0030) and its mix report (50) left on 2026-11-04 (decided: a generic audio route later).
 */
#include <stdint.h>

struct sc_cmd {
  uint8_t first, last, flags, pad;
  uint32_t magic;
  const volatile uint32_t *box;
};
#define SC_DIRECT 1

typedef int (*sc_fn)(const uint8_t *d, int32_t len);

extern const struct sc_cmd sc_cmds[];
static void sc_heard(void);   /* store.c */

/* Host SysEx: 1 when taken. */
int sc_sysex(const uint8_t *d, int32_t len) {
  const struct sc_cmd *e;
  uint8_t c;
  if (len < 7 || d[0] != 0xf0 || d[1] != 0x7d || d[2] != 0x52 || d[3] != 0x54) return 0;
  c = d[4];
  sc_heard();
  for (e = sc_cmds; e->box; ++e) {
    if (c < e->first || c > e->last) continue;
    if (e->flags & SC_DIRECT) ((sc_fn)e->box)(d, len);
    else if (e->box[0] == e->magic) ((sc_fn)e->box[1])(d, len);
    break;
  }
  return 1;
}

/* The router's entry (its first two instructions, 6 bytes): jmp.l sc_router
   (registry patches). Taken: return to the router's caller; else redo the two instructions and go on. */
__asm__(
    "  .text\n"
    "  .align 2\n"
    "  .globl sc_router\n"
    "sc_router:\n"
    "  movel %sp@(8),%sp@-\n"
    "  movel %sp@(8),%sp@-\n"
    "  jsr sc_sysex\n"
    "  addql #8,%sp\n"
    "  tstl %d0\n"
    "  jeq 1f\n"
    "  rts\n"
    "1:\n"
    "  lea %sp@(-16),%sp\n"
    "  moveml %d2-%d3/%a2-%a3,%sp@\n"
    "  jmp 0x40083de0\n");

#include "store.c"
#include "rec.c"
#include "clock.c"
