/* teensy-drive (mod 0023): the Sidecar's card as a folder SIDECAR in the Rytm's own file browser (design.md).
 * A client of the companion (sidecar-core) on core-ar2 0.13, in elekloader's area (2026-11-10).
 *
 * The browser fills a folder through readdir(dir handle, record) and asks node functions about each entry's id
 * [measured, OS 1.73; design.md; addresses here are OS 1.74's]. Card ids are 0x7E000000 | kind << 23 |
 * folder << 12 | entry (kind 1: a file); folder 0 is SIDECAR itself. Wrapped (registry detours; core-ar2 has no
 * +Drive calls, so these stay the mod's own, see design.md "On the companion"):
 *   readdir  0x4007c0b4  card folders served here; after the +Drive root's last entry, one more: SIDECAR
 *   resolve  0x40080504  card ids -> a fake node (bit 0 of byte 0: folder), outside the node cache
 *   exists   0x400807d2  card ids exist
 *   size     0x40080910, 0x400808b6  card files: their size
 * and the guards (milestone 4): id -> path, a reference's check, the load, mkdir, a new root entry, CREATE DIR,
 * LOAD TO PROJ's file reference. Nothing here writes to the card, the +Drive or the Rytm's sample memory.
 *
 * The listing comes from the Pi's card browse service (sidecar-firmware core/browse):
 *   Rytm -> Pi  F0 7D 52 54 0D <folder hi> <lo> F7           core_midi_try_send (core-ar2 0.11)
 *   Pi -> Rytm  F0 7D 52 54 0E <folder hi lo> <parent hi lo> <first hi lo> <total hi lo>
 *               { <kind> <id hi lo> <size 4 x 7 bits, high first> <name length> <name> } F7
 * kind 1: a subfolder (id: its folder number), 0: a file (id: its position). 0E reaches td_sysex through the
 * companion's router (mod.toml [[sidecar.cmds]], handler: the table entry points at it directly).
 *
 * The wait: the browser fills a folder in one go (readdir until the end, in the UI task). The first readdir of a
 * card folder asks for it and sleeps in 10 ms steps (stock's sleep_us, 0x40098c84: a DMA-timer wait that blocks
 * only the calling task [measured, rytm-emu]) until the answer is complete, at most ~400 ms from the ask. The
 * root's listing asks for SIDECAR's at once (td_prefetch), so entering it usually finds the answer cached. A host
 * that did not answer within a wait is not waited for again for 60 s; with the USB port down nothing is asked and
 * nothing waited for. Time is counted in ev_tick calls (about 20 Hz), the mod's own clock.
 *
 * LOAD TO PROJ on card files adds them to the project's sample pool on the Pi (the Pi's sample service through the
 * companion's sc_sample_add_ref, 2026-11-10; td_ref below); DSP SAMPLE plays the pool. Gone with the move: ext's
 * old pool (0F, the project name 10, the slot list's pool 12/13/14, td_pool_tab for ext's user slots).
 */
#include <stdint.h>
#ifdef TD_HOST
int core_midi_try_send(int len, const unsigned char *msg);
int core_usb_midi_up(void);
#else
#include "analog-rytm-mk2/moments.h"
#endif
/* sidecar-core companion/samples.c (pi-voices 10dce29): 51 3D SADDB, a file of the Pi's browse listing into the
   project's sample pool on the Pi; -1 when the link is closed or its queue full */
extern int32_t sc_sample_add_ref(uint32_t owner, uint32_t folder, uint32_t file);
#define TD_OWNER 0x23                 /* the Pi ops' owner byte */
#define POOL_MARK 0x7E504F4Fu         /* "~POO": a reference the load guard counts as loaded */

#define TID 0x7E000000u
#define IS_TID(id) (((uint32_t)(id) & 0xFF000000u) == TID)
#define FILE_BIT 0x00800000u
#define ROOT_ID 2u                    /* the +Drive root's id [measured] */
#define DONE_MARK 0x7E7E7E7Eu         /* dir handle +12: SIDECAR already given */

struct dirh { uint32_t id, block, offset, index; };
struct rec {                          /* the browser's entry record [measured] */
  uint32_t id;
  uint16_t type;                      /* 1 folder, 0 file */
  uint16_t pad;
  uint32_t parent, pos0, pos1;
  char name[256];
};
/* A node, full size [review, 2026-10-08]: the filesystem reads past the first 16 bytes (+16, the extent count at
   +30), so the fake ones are 128 zeroed bytes. */
struct node { uint8_t b0, b1; uint16_t pad; uint32_t f4, f8, f12; uint8_t rest[112]; };

#define kCap 512
#ifndef SLEEP_US
#define SLEEP_US ((void (*)(uint32_t))0x40098c84u)   /* stock 1.74; core-ar2 0.13 has no wait call */
#endif

struct tentry { uint8_t kind, pad; uint16_t id; uint32_t size; char name[24]; };   /* 32 B */
struct tcache {
  uint16_t folder, parent, total, received;
  uint8_t valid, failed, pad[2];     /* failed: the host did not answer the last wait */
  uint32_t t_ask, t_fail;            /* td_now at the last 0D sent / at the last wait that got no answer */
};
#define TICKS_WAIT 8u                 /* 400 ms: the longest the UI waits for one listing */
#define TICKS_GIVE_UP 1200u           /* 60 s: after a wait with no answer the UI does not wait again */
#define TICKS_REASK 20u               /* 1 s: re-ask at most this often while given up */
#define STEPS_PER_TICK 5u             /* 10 ms sleeps in a 50 ms tick */

int td_sysex(const uint8_t *d, int32_t len);
void td_tick(void);

#ifdef TD_HOST                        /* test/host_test.c: a PC build of the C, without the m68k entries */
#define TD_BSS
#else
#define TD_BSS __attribute__((section(".bss"), aligned(4)))
#endif
struct tcache td_cache TD_BSS;
static struct tentry td_ents[kCap] TD_BSS;   /* 16 KB in the area */
static volatile uint32_t td_now TD_BSS;      /* ev_tick calls */

static const char td_dot[] = ".";
static const char td_dotdot[] = "..";
const char td_teensy[] = "SIDECAR";   /* the folder's name (1021: was TEENSY); td_tname refuses it as a real root entry */

/* +1 bit 0: write-protected - DELETE, RENAME, MOVE answer "WRITE PROTECTED". */
struct node td_dir_node = {1, 1, 0, 0, 0, 0, {0}};
/* A file node as the browser wants it [measured]: +12 bit 0 set (else the row draws a bar instead of the size),
   +1 bit 1 = size at +8 held, +1 bit 0 set (write-protected; else YES does not tick the file). */
struct node td_file_node = {0, 3, 0, 0, 0, 1, {0}};

int32_t td_readdir_stock(struct dirh *, struct rec *);
void *td_resolve_stock(uint32_t);
int32_t td_exists_stock(uint32_t);
int32_t td_size_stock(uint32_t);
int32_t td_count_stock(uint32_t);

void td_tick(void) { td_now = td_now + 1; }

static void td_name(char *dst, const char *src) {
  int i;
  for (i = 0; i < 255 && src[i]; ++i) dst[i] = src[i];
  dst[i] = 0;
}

static void td_fill(struct rec *r, uint32_t id, uint16_t type, uint32_t parent, const char *name) {
  r->id = id;
  r->type = type;
  r->parent = parent;
  r->pos0 = r->pos1 = 0;
  td_name(r->name, name);
}

static uint32_t td_file_size(uint32_t id) {
  struct tcache *c = &td_cache;
  uint32_t f = (id >> 12) & 0x3ff, e = id & 0xfff, k;
  if (!c->valid || c->folder != f) return 0;
  for (k = 0; k < c->received && k < kCap; ++k)
    if (td_ents[k].kind == 0 && td_ents[k].id == e) return td_ents[k].size;
  return 0;
}

/* Folder f asked for: the cache emptied for it, 0D out (never waits; a busy sender drops the ask, the wait then
   gives up as for a silent host). */
void td_ask(uint32_t f, uint32_t now) __attribute__((noinline));
void td_ask(uint32_t f, uint32_t now) {
  struct tcache *c = &td_cache;
  uint8_t m[8] = {0xf0, 0x7d, 0x52, 0x54, 0x0d, (uint8_t)((f >> 7) & 0x7f), (uint8_t)(f & 0x7f), 0xf7};
  c->valid = 0;
  c->folder = (uint16_t)f;
  c->received = 0;
  c->total = 0xffff;
  c->t_ask = now;
  core_midi_try_send(8, m);
}

/* The root read has SIDECAR in it: ask for SIDECAR's own listing now, without waiting. */
static void td_prefetch(void) {
  struct tcache *c = &td_cache;
  uint32_t now = td_now;
  if (!core_usb_midi_up() || (c->failed && now - c->t_fail < TICKS_GIVE_UP)) return;
  if (c->folder == 0 && (c->valid || (c->total == 0xffff && now - c->t_ask < TICKS_WAIT))) return;   /* given, or asked just now */
  td_ask(0, now);
}

/* The listing of folder f in the cache: asked for (unless asked already) and waited on - 10 ms steps, at most
   TICKS_WAIT from the ask - unless complete. A host that has not answered within the wait is not waited for again
   for TICKS_GIVE_UP: the folder shows empty at once (re-asked at most once a second, so a late host fills the
   cache for the next visit). The port down: nothing asked, nothing waited for. */
static void td_ensure(uint32_t f) {
  struct tcache *c = &td_cache;
  uint32_t now = td_now, k;
  if (c->valid && c->folder == f && c->received >= c->total) return;
  if (!core_usb_midi_up()) {
    if (c->folder != f) { c->valid = 0; c->folder = (uint16_t)f; c->received = 0; c->total = 0; }
    return;
  }
  if (c->failed && now - c->t_fail < TICKS_GIVE_UP) {
    if (now - c->t_ask > TICKS_REASK || c->folder != f) td_ask(f, now);
    return;
  }
  if (c->folder != f || c->valid || c->total != 0xffff) td_ask(f, now);   /* else asked already (td_prefetch) */
  for (k = (now - c->t_ask) * STEPS_PER_TICK; k < TICKS_WAIT * STEPS_PER_TICK; ++k) {
    SLEEP_US(10000);
    if (c->valid && c->folder == f && c->received >= c->total) return;
  }
  c->failed = 1;
  c->t_fail = td_now;
  c->total = 0;                       /* nothing asked and waited for any more */
}

/* One entry of card folder f at position i: ".", "..", then the cached subfolders and files, as the Pi listed them. */
static int32_t td_serve(struct dirh *d, struct rec *r) {
  struct tcache *c = &td_cache;
  uint32_t f = d->id & 0x3ff, i = d->index;
  d->index = i + 1;
  if (i == 0) {
    td_ensure(f);
    td_fill(r, d->id, 1, d->id, td_dot);
    return 1;
  }
  if (i == 1) {
    td_fill(r, (f && c->valid && c->folder == f) ? TID | c->parent : ROOT_ID, 1, d->id, td_dotdot);
    return 1;
  }
  i -= 2;
  if (!c->valid || c->folder != f || i >= c->received || i >= kCap) return 0;
  {
    struct tentry *e = &td_ents[i];
    char nm[25];
    int k;
    for (k = 0; k < 24 && e->name[k]; ++k) nm[k] = e->name[k];
    nm[k] = 0;
    if (e->kind) td_fill(r, TID | (e->id & 0x3ff), 1, d->id, nm);
    else td_fill(r, TID | FILE_BIT | f << 12 | (e->id & 0xfff), 0, d->id, nm);
  }
  return 1;
}

/* 0E from the Pi (the companion's router, MIDI task): entries into the cache. */
int td_sysex(const uint8_t *d, int32_t len) {
  struct tcache *c = &td_cache;
  uint32_t f, first, total, k;
  int32_t p;
  if (len < 14 || d[4] != 0x0e) return 0;
  f = (uint32_t)d[5] << 7 | d[6];
  first = (uint32_t)d[9] << 7 | d[10];
  total = (uint32_t)d[11] << 7 | d[12];
  if (f != c->folder) return 1;              /* not the folder being read */
  c->parent = (uint16_t)(((uint32_t)d[7] << 7 | d[8]) & 0x3ff);
  c->failed = 0;
  c->total = (uint16_t)(total < kCap ? total : kCap);
  for (p = 13, k = first; p + 8 <= len - 1; ++k) {
    struct tentry *e;
    uint32_t n, j;
    if (k >= kCap) break;
    e = &td_ents[k];
    e->kind = d[p];
    e->id = (uint16_t)((uint32_t)d[p + 1] << 7 | d[p + 2]);
    e->size = (uint32_t)d[p + 3] << 21 | (uint32_t)d[p + 4] << 14 | (uint32_t)d[p + 5] << 7 | d[p + 6];
    n = d[p + 7];
    p += 8;
    for (j = 0; j < n && j < 23 && p + (int32_t)j < len - 1; ++j) e->name[j] = (char)d[p + j];
    e->name[j] = 0;
    p += n;
    if (k + 1 > c->received) c->received = (uint16_t)(k + 1);
  }
  c->valid = 1;
  return 1;
}

int32_t td_readdir(struct dirh *d, struct rec *r) {
  int32_t got;
  if (!d || !r) return -1;
  if (IS_TID(d->id)) return td_serve(d, r);
  if (d->id == ROOT_ID && d->index == DONE_MARK) return 0;
  got = td_readdir_stock(d, r);
  if (got == 0 && d->id == ROOT_ID) {           /* an error (< 0) stays one */
    td_fill(r, TID, 1, ROOT_ID, td_teensy);
    d->index = DONE_MARK;
    td_prefetch();
    return 1;
  }
  return got;
}

void *td_resolve(uint32_t id) {
  if (IS_TID(id)) {
    if (id & FILE_BIT) {
      td_file_node.f4 = td_file_node.f8 = td_file_size(id);
      return &td_file_node;
    }
    return &td_dir_node;
  }
  return td_resolve_stock(id);
}

int32_t td_exists(uint32_t id) {
  if (IS_TID(id)) return 1;
  return td_exists_stock(id);
}

int32_t td_size(uint32_t id) {
  if (IS_TID(id)) return (id & FILE_BIT) ? (int32_t)td_file_size(id) : -1;
  return td_size_stock(id);
}

int32_t td_count(uint32_t id) {
  if (IS_TID(id)) return (id & FILE_BIT) ? (int32_t)td_file_size(id) : -1;
  return td_count_stock(id);
}

/* LOAD TO PROJ's job (the lambda at 0x400ea77c [1.73]) asks 0x4007e698(model, index) for each ticked entry's
   16-byte file reference; its one call site comes here (registry patch, not the function: the browser calls it per
   visible row). A card file goes into the project's sample pool on the Pi (the companion's sample client, 51 3D
   SADDB by this listing's folder number and file id; the Pi reads the file's whole name itself) and gets a marked
   reference, which the load guard (td_load_entry) counts as loaded without touching the Rytm's sample memory: the
   job's "N SAMPLES LOADED" counts the adds sent. The Pi's answer (index, or full / no file) is the companion's
   (sc_sample_result); DSP SAMPLE shows the pool by name. With the link closed or its queue full the reference holds
   only the id and the guard refuses it: nothing counted. 0: not a card file, stock's. */
uint32_t td_adds TD_BSS, td_add_fails TD_BSS;   /* SADDB sent / not sent (link closed, queue full) */
/* CREATE DIR diagnostics (T247: no ERROR box on the unit, ERROR on the emulator): guard calls, the folder path's
   pointer and first 4 bytes, mkdir's result */
uint32_t td_mk_calls TD_BSS, td_mk_ptr TD_BSS, td_mk_head TD_BSS, td_mk_ret TD_BSS;
int32_t td_ref(uint32_t *out, const uint8_t *model, int32_t index) {
  const uint8_t *begin = *(const uint8_t *const *)(model + 260);
  const uint8_t *end = *(const uint8_t *const *)(model + 264);
  const struct rec *r;
  uint32_t id;
  if (index < 0 || begin + 8 * index >= end) return 0;
  r = *(const struct rec *const *)(begin + 8 * index);
  if (!r || !IS_TID(r->id) || !(r->id & FILE_BIT)) return 0;
  id = r->id;
  out[0] = id;
  out[1] = id;
  out[2] = out[3] = 0;
  if (sc_sample_add_ref(TD_OWNER, (id >> 12) & 0x3ff, id & 0xfff) >= 0) {
    out[0] = POOL_MARK;
    ++td_adds;
  } else {
    ++td_add_fails;
  }
  return 1;
}

#ifndef TD_HOST
/* The stock functions' first instructions, re-emitted, then back in. */
__asm__(
    "  .pushsection .td,\"ax\"\n"
    "  .align 2\n"
    "  .globl td_readdir_entry\n"
    "td_readdir_entry:\n"
    "  jmp td_readdir\n"
    "  .globl td_readdir_stock\n"
    "td_readdir_stock:\n"
    "  lea %sp@(-24),%sp\n"
    "  moveml %d2-%d5/%a2-%a3,%sp@\n"
    "  jmp 0x4007c0bc\n"
    "  .globl td_resolve_entry\n"
    "td_resolve_entry:\n"
    "  jmp td_resolve\n"
    "  .globl td_resolve_stock\n"
    "td_resolve_stock:\n"
    "  lea %sp@(-16),%sp\n"
    "  moveml %d2-%d3/%a2-%a3,%sp@\n"
    "  jmp 0x4008050c\n"
    "  .globl td_exists_entry\n"
    "td_exists_entry:\n"
    "  jmp td_exists\n"
    "  .globl td_exists_stock\n"
    "td_exists_stock:\n"
    "  movel %d2,%sp@-\n"
    "  movel %sp@(8),%d1\n"
    "  jmp 0x400807d8\n"
    "  .globl td_size_entry\n"
    "td_size_entry:\n"
    "  jmp td_size\n"
    "  .globl td_size_stock\n"
    "td_size_stock:\n"
    "  lea %sp@(-32),%sp\n"
    "  moveml %d2-%d5/%a2,%sp@\n"
    "  jmp 0x40080918\n"
    /* No real folder or file named TEENSY (any case) in the +Drive's root: it
       would list as a second TEENSY beside the Teensy's (review MEDIUM 6;
       Transfer's mkdir /TEENSY/x made one, as on stock). td_tname(a0 = a name):
       d0 = -1 (flags set) when it is TEENSY ended by 0 or '/', else 0. */
    "td_tname:\n"
    "  lea td_teensy,%a1\n"
    "1:\n"
    "  moveb %a1@+,%d1\n"
    "  jeq 2f\n"
    "  moveb %a0@+,%d0\n"
    "  oril #0x20,%d0\n"
    "  oril #0x20,%d1\n"
    "  cmpb %d1,%d0\n"
    "  jeq 1b\n"
    "3:\n"
    "  moveq #0,%d0\n"
    "  rts\n"
    "2:\n"
    "  moveb %a0@,%d0\n"
    "  jeq 4f\n"
    "  cmpib #47,%d0\n"
    "  jne 3b\n"
    "4:\n"
    "  moveq #-1,%d0\n"
    "  rts\n"
    /* 0x4007b41c(parent, name, node, ..) -> 0, -1: every new entry in a folder
       (mkdir, file create, rename, move): none named TEENSY in the root (id 2) */
    "  .globl td_link_entry\n"
    "td_link_entry:\n"
    "  moveq #2,%d0\n"
    "  cmpl %sp@(4),%d0\n"
    "  jne 5f\n"
    "  moveal %sp@(8),%a0\n"
    "  bsr td_tname\n"
    "  jne 6f\n"
    "5:\n"
    "  lea %sp@(-56),%sp\n"
    "  moveml %d2-%d7/%a2-%fp,%sp@\n"
    "  jmp 0x4007b424\n"
    /* 0x4007c1dc(path) -> 0, -1: mkdir. Refused for /TEENSY and anything under
       it: Transfer's mkdir makes each level in turn, and stock mkdir reads the
       name at a stale offset when the parent is missing [measured: stock 1.73,
       mkdir /factory/x/y, a wild read at 0x4007c23e] */
    "  .globl td_mkdir_entry\n"
    "td_mkdir_entry:\n"
    "  movel %sp@(4),%d0\n"
    "  jeq 7f\n"
    "  moveal %d0,%a0\n"
    "  moveb %a0@+,%d0\n"
    "  cmpib #47,%d0\n"
    "  jne 7f\n"
    "  bsr td_tname\n"
    "  jeq 7f\n"
    "6:\n"
    "  moveq #-1,%d0\n"
    "  rts\n"
    "7:\n"
    "  linkw %fp,#-24\n"
    "  moveml %d2-%d3/%a2-%a3,%sp@\n"
    "  jmp 0x4007c1e4\n"
    "  .globl td_count_entry\n"
    "td_count_entry:\n"
    "  jmp td_count\n"
    "  .globl td_count_stock\n"
    "td_count_stock:\n"
    "  movel %a2,%sp@-\n"
    "  movel %d2,%sp@-\n"
    "  tstl 0x41843c70\n"
    "  jmp 0x400808c0\n"
    /* 0x4007e698(model, index), the reference returned through a0: Teensy files
       get a marked one (td_ref), the rest stock's */
    "  .globl td_ref_entry\n"
    "td_ref_entry:\n"
    "  movel %a0,%sp@-\n"
    "  movel %sp@(12),%sp@-\n"
    "  movel %sp@(12),%sp@-\n"
    "  movel %sp@(8),%sp@-\n"
    "  jsr td_ref\n"
    "  lea %sp@(12),%sp\n"
    "  moveal %sp@+,%a0\n"
    "  tstl %d0\n"
    "  jeq 1f\n"
    "  movel %a0,%d0\n"
    "  rts\n"
    "1:\n"
    "  linkw %fp,#-16\n"
    "  moveal %fp@(8),%a1\n"
    "  jmp 0x4007e6a0\n"
    "  .popsection\n"
    "  .pushsection .td3,\"ax\"\n"
    "  .align 2\n"
    /* 0x4007c640(id, .., buffer) -> path or 0 */
    "  .globl td_path_entry\n"
    "td_path_entry:\n"
    "  movel %sp@(4),%d0\n"
    "  andil #0xFF000000,%d0\n"
    "  cmpil #0x7E000000,%d0\n"
    "  jne 1f\n"
    "  moveq #0,%d0\n"
    "  rts\n"
    "1:\n"
    "  lea %sp@(-324),%sp\n"
    "  moveml %d2-%d7/%a2-%fp,%sp@\n"
    "  jmp 0x4007c648\n"
    /* 0x40080060(&ref, out) -> 1..4 found, -1 not */
    "  .globl td_check_entry\n"
    "td_check_entry:\n"
    "  movel %sp@(4),%d0\n"
    "  jeq 1f\n"
    "  moveal %d0,%a0\n"
    "  movel %a0@,%d0\n"
    "  andil #0xFF000000,%d0\n"
    "  cmpil #0x7E000000,%d0\n"
    "  jne 1f\n"
    "  moveq #-1,%d0\n"
    "  rts\n"
    "1:\n"
    "  lea %sp@(-24),%sp\n"
    "  moveml %d2/%a2-%fp,%sp@\n"
    "  jmp 0x40080068\n"
    /* CREATE DIR (invoker 0x400ea5b6): mkdir(path) -> 0 made. a4 is the
       invoker's, its +4 the folder's path */
    "  .globl td_mkdir_guard\n"
    "td_mkdir_guard:\n"
    "  addql #1,td_mk_calls\n"
    "  clrl td_mk_head\n"
    "  movel %a4@(4),%d0\n"
    "  movel %d0,td_mk_ptr\n"
    "  jeq 1f\n"
    "  moveal %d0,%a0\n"
    "  lea td_mk_head,%a1\n"
    "  moveb %a0@,%a1@\n"
    "  jeq 1f\n"
    "  moveb %a0@(1),%a1@(1)\n"
    "  jeq 2f\n"
    "  moveb %a0@(2),%a1@(2)\n"
    "  jeq 2f\n"
    "  moveb %a0@(3),%a1@(3)\n"
    "  jra 2f\n"
    "1:\n"
    "  moveq #-1,%d0\n"
    "  movel %d0,td_mk_ret\n"
    "  rts\n"
    "2:\n"
    "  movel %sp@(4),%sp@-\n"
    "  jsr 0x4007c1dc\n"
    "  addql #4,%sp\n"
    "  movel %d0,td_mk_ret\n"
    "  rts\n"
    "  .popsection\n");

__asm__(
    "  .pushsection .td3,\"ax\"\n"
    "  .align 2\n"
    /* 0x400b719a(manager, &ref, slot): a marked reference (td_ref's, added to the Pi's pool) counts as loaded (1);
       another card reference fails (0) before the stock code copies it into the slot */
    "  .globl td_load_entry\n"
    "td_load_entry:\n"
    "  moveal %sp@(8),%a0\n"
    "  movel %a0@,%d0\n"
    "  cmpil #0x7E504F4F,%d0\n"
    "  jne 2f\n"
    "  moveq #1,%d0\n"
    "  rts\n"
    "2:\n"
    "  andil #0xFF000000,%d0\n"
    "  cmpil #0x7E000000,%d0\n"
    "  jne 3f\n"
    "  moveq #0,%d0\n"
    "  rts\n"
    "3:\n"
    "  linkw %fp,#-28\n"
    "  moveml %d2-%d4/%a2,%sp@\n"
    "  jmp 0x400b71a2\n"
    "  .popsection\n");
#endif /* TD_HOST */
