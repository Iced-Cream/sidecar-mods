/* mods/0032-sidecar/test/companion_host.c - the companion's store client and step clock (store.c, clock.c) built for a
 * PC: the firmware's words become this file's variables, the USB MIDI sender a function the test catches. Nothing
 * else of the mod is here (the router, the FX return): the test calls sc_store_host itself, as the router would. */
#include <stdint.h>
#include <stddef.h>

#define SC_HOST 1

/* fxin.c's sender words */
volatile uint32_t h_port_state = 1;
volatile int32_t h_tx_level = 0;
const volatile uint32_t *h_pool;      /* a chain of free USB requests (+52 the next), below 4 GB */
void h_midi_send(int32_t n, const uint8_t *m);
#define PORT_STATE  h_port_state
#define TX_LEVEL    h_tx_level
#define USB_POOL    h_pool
#define MIDI_SEND   h_midi_send
#define MIDI_MUTEX  ((void *)0)
#define MUTEX_TRY(m) 1
#define MUTEX_GIVE(m) ((void)0)

/* store.c's */
volatile uint32_t h_txsx, h_timer = 12345, h_blk = 1000;
#define SC_TXSX     h_txsx
#define SC_RAND_A   h_timer
#define SC_RAND_B   h_blk
#define SC_PAT(p)   ((void *)(uintptr_t)(0x1000u + (uint32_t)(p)))
uint8_t h_name[16];
#define SC_NAME     h_name

/* clock.c's */
volatile uint32_t h_play;
volatile int8_t h_pat_idx;
uint8_t h_speed[13], h_prev[13];
uint8_t h_patd[85760];
#define CK_PLAY      h_play
#define CK_PAT       h_pat_idx
#define SC_PAT_NOW   h_pat_idx
#define CK_SPEED(t)  (h_speed[t])
#define CK_PREV(t)   (h_prev[t])
#define CK_BLK       h_blk
#define CK_PATD(p)   ((const volatile uint8_t *)h_patd)
#define CK_SENDER    0u
#define CK_SYSEX     0u
#define CK_TIMER     h_timer
uint8_t h_next[2] = {0, 0x7f};
volatile uint32_t h_tempo = 120 * 120;
#define CK_NEXT      ((const volatile uint8_t *)h_next)
#define CK_TEMPO     h_tempo

/* the current kit (core-ar2's words): its index, big-endian; live kit k at 0x2000 + k */
uint8_t h_kit_index[4];
#define SC_KIT_INDEX h_kit_index
#define SC_KIT(k)   ((void *)(uintptr_t)(0x2000u + (uint32_t)(k)))

/* core-ar2's store: one value per (field, item) */
char sc_proj[1], sc_phand[1], sc_khand[1];
static uint32_t h_proj_v, h_phand_v[128];
uint32_t h_khand_v[128];
unsigned core_store_get(unsigned field, void *item, int index) {
  (void)index;
  if (field == (unsigned)(uintptr_t)sc_proj) return h_proj_v;
  if (field == (unsigned)(uintptr_t)sc_phand) return h_phand_v[((uintptr_t)item - 0x1000u) & 127];
  if (field == (unsigned)(uintptr_t)sc_khand) return h_khand_v[((uintptr_t)item - 0x2000u) & 127];
  return 0;
}
void core_store_set(unsigned field, void *item, int index, unsigned v) {
  (void)index;
  if (field == (unsigned)(uintptr_t)sc_proj) h_proj_v = v;
  if (field == (unsigned)(uintptr_t)sc_phand) h_phand_v[((uintptr_t)item - 0x1000u) & 127] = v;
  if (field == (unsigned)(uintptr_t)sc_khand) h_khand_v[((uintptr_t)item - 0x2000u) & 127] = v;
}
void core_project_edited(void) {}
uint32_t h_proj_value(void) { return h_proj_v; }
void h_proj_reset(void) { h_proj_v = 0; }

#include "../store.c"
#include "../rec.c"
#include "../clock.c"

/* what the test reads of the mod's state */
uint32_t h_ck_drops(void) { return ck.drops; }
uint32_t h_scl_hits(void) { return scl.hits; }
uint32_t h_scl_hellos(void) { return scl.hellos; }
uint32_t h_scl_timeouts(void) { return scl.timeouts; }
