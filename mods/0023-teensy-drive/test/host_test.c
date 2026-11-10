/* teensy-drive's C on a PC (no m68k entries): the listing cache, the wait and the root's extra entry.
 *   cc -DTD_HOST -I.. host_test.c -o /tmp/td_host && /tmp/td_host      (make -C test) */
#include <stdio.h>
#include <string.h>
#include <stdint.h>

static int sent, usb_up = 1, sleeps, answer_after = -1, stock_root_left;
static uint8_t last[16];
int core_midi_try_send(int len, const unsigned char *m) { memcpy(last, m, len < 16 ? len : 16); ++sent; return 1; }
int core_usb_midi_up(void) { return usb_up; }
int32_t sc_sample_add_ref(uint32_t owner, uint32_t folder, uint32_t file) { (void)owner; (void)folder; (void)file; return 1; }
static void fake_answer(void);
static void host_sleep(uint32_t us) { (void)us; if (++sleeps == answer_after) fake_answer(); }
#define SLEEP_US host_sleep
#include "../teensy_drive.c"

/* the stock entries the C calls */
int32_t td_readdir_stock(struct dirh *d, struct rec *r) {
  (void)d;
  if (stock_root_left <= 0) return 0;
  --stock_root_left; r->id = 0x01000000; strcpy(r->name, "Factory"); return 1;
}
void *td_resolve_stock(uint32_t id) { (void)id; return 0; }
int32_t td_exists_stock(uint32_t id) { (void)id; return 0; }
int32_t td_size_stock(uint32_t id) { (void)id; return 7; }
int32_t td_count_stock(uint32_t id) { (void)id; return 7; }

static int fails;
#define CHECK(c, ...) do { if (c) printf("ok   "); else { printf("FAIL "); ++fails; } printf(__VA_ARGS__); printf("\n"); } while (0)

static int listing(uint8_t *b, int f, int parent, int first, int total, int n, const int *kind, const int *id,
                   const int *size, const char *const *name) {
  int p = 0, i;
  b[p++] = 0xf0; b[p++] = 0x7d; b[p++] = 0x52; b[p++] = 0x54; b[p++] = 0x0e;
  int v[4] = {f, parent, first, total};
  for (i = 0; i < 4; ++i) { b[p++] = (v[i] >> 7) & 0x7f; b[p++] = v[i] & 0x7f; }
  for (i = 0; i < n; ++i) {
    int L = (int)strlen(name[i]);
    b[p++] = kind[i]; b[p++] = (id[i] >> 7) & 0x7f; b[p++] = id[i] & 0x7f;
    b[p++] = (size[i] >> 21) & 0x7f; b[p++] = (size[i] >> 14) & 0x7f; b[p++] = (size[i] >> 7) & 0x7f; b[p++] = size[i] & 0x7f;
    b[p++] = L; memcpy(b + p, name[i], L); p += L;
  }
  b[p++] = 0xf7;
  return p;
}
static void fake_answer(void) {
  static const int k[2] = {1, 0}, id[2] = {1, 1}, sz[2] = {0, 3000};
  static const char *const nm[2] = {"Drums", "Kick"};
  uint8_t b[128];
  int n = listing(b, 0, 0, 0, 2, 2, k, id, sz, nm);
  td_sysex(b, n);
}

static int read_root(struct rec *out, int max) {
  struct dirh d = {ROOT_ID, 0, 0, 0};
  int n = 0;
  stock_root_left = 2;
  while (n < max && td_readdir(&d, &out[n]) > 0) ++n;
  return n;
}
static int read_folder(uint32_t f, struct rec *out, int max) {
  struct dirh d = {TID | f, 0, 0, 0};
  int n = 0;
  while (n < max && td_readdir(&d, &out[n]) > 0) ++n;
  return n;
}

int main(void) {
  static struct rec r[16];
  int n;

  /* 1 the root: stock's entries, then SIDECAR, and the prefetch's 0D 0 */
  n = read_root(r, 16);
  CHECK(n == 3 && r[2].id == TID && !strcmp(r[2].name, "SIDECAR"), "root lists stock's 2 then SIDECAR (%d)", n);
  CHECK(sent == 1 && last[4] == 0x0d && last[5] == 0 && last[6] == 0, "the root read asks for folder 0 at once");

  /* 2 the answer arrives before entering: no sleep, entries served */
  fake_answer();
  sleeps = 0;
  n = read_folder(0, r, 16);
  CHECK(n == 4 && sleeps == 0, "SIDECAR: . .. Drums Kick, no wait (%d entries, %d sleeps)", n, sleeps);
  CHECK(r[2].type == 1 && r[2].id == (TID | 1) && !strcmp(r[2].name, "Drums"), "Drums a folder, id 0x7E000001");
  CHECK(r[3].type == 0 && r[3].id == (TID | FILE_BIT | 1) && td_size(r[3].id) == 3000, "Kick a file of 3000 B");
  CHECK(td_size(5) == 7 && td_exists(TID | 9) == 1, "+Drive ids go to stock, card ids exist");
  CHECK(((struct node *)td_resolve(r[3].id))->f8 == 3000 && ((struct node *)td_resolve(TID))->b0 == 1,
        "fake nodes: the file's size, the folder bit");

  /* 3 a silent host: one wait of 400 ms (40 x 10 ms), then given up: no wait again for 60 s */
  sent = 0; sleeps = 0;
  n = read_folder(1, r, 16);
  CHECK(sent == 1 && last[4] == 0x0d && last[6] == 1, "Drums asked once");
  CHECK(sleeps == 40 && n == 2 && td_cache.failed, "silent host: 40 sleeps (400 ms), . and .. only, failed");
  sleeps = 0;
  n = read_folder(1, r, 16);
  CHECK(sleeps == 0 && n == 2, "given up: entering again does not wait (%d sleeps)", sleeps);
  for (int i = 0; i < 25; ++i) td_tick();
  sent = 0;
  read_folder(1, r, 16);
  CHECK(sent == 1 && sleeps == 0, "after a second it re-asks, still without waiting");

  /* 4 a host that answers during the wait */
  for (int i = 0; i < 1300; ++i) td_tick();
  memset(&td_cache, 0, sizeof td_cache);
  td_cache.folder = 7;
  sleeps = 0; answer_after = 3;
  n = read_folder(0, r, 16);
  CHECK(sleeps == 3 && n == 4, "an answer after 30 ms ends the wait (%d sleeps, %d entries)", sleeps, n);
  answer_after = -1;

  /* 5 the port down: nothing asked, nothing waited for */
  usb_up = 0; sent = 0; sleeps = 0;
  n = read_folder(5, r, 16);
  CHECK(sent == 0 && sleeps == 0 && n == 2, "port down: no ask, no wait, empty folder");
  n = read_root(r, 16);
  CHECK(sent == 0 && n == 3, "port down: SIDECAR still listed, no prefetch");
  usb_up = 1;

  /* 6 a listing for another folder is ignored; a short message too */
  {
    uint8_t b[8] = {0xf0, 0x7d, 0x52, 0x54, 0x0e, 0, 0, 0xf7};
    CHECK(td_sysex(b, 8) == 0, "a short 0E is refused");
  }

  /* td_ref (LOAD TO PROJ) reads the browser model's 32-bit pointers: covered in the emulator, not here */

  printf(fails ? "%d FAILED\n" : "ALL PASS\n", fails);
  return fails != 0;
}
