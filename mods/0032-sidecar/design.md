# 0032-sidecar: the Sidecar companion

Status: **built** (core-ar2 0.9, 2026-11-03): router (with the FX return, since taken out) passed the emulator gate and T111 [hw]. The store link
and the step clock (Storage phase, 2026-11-04) are [code] only: compiled for the Rytm (GCC 13.3 from Ubuntu, so stub.s
differs from a GCC 16.2 one), and their logic passes test/ against the Pi's own services [host]; no release build, no
emulator run yet.

## What it is

The one mod every Sidecar client mod goes through on the Rytm (companion phase, decided 2026-11-01 and 2026-11-03).
It owns the host link: every SysEx message the USB host (the Sidecar) sends the Rytm reaches the stock SysEx router's
entry, and the companion takes it there first.

- **The router.** A jmp at the router's entry (0x40083dd8, the MIDI task; registry patches 0x40083dd8 / 0x40083dda)
  goes to `sc_router`. A message `F0 7D 52 54 <cmd> ... F7` of 7 bytes or more is always taken; any other message goes
  on to stock with the two displaced instructions redone. A taken message goes to the entry of the table `sc_cmds`
  whose range holds `<cmd>`; a command no entry holds is dropped (as 0022's router dropped it).
- **The table.** `sc_cmds` is an elekloader collection (entry size 12): `{first, last, flags, pad, magic, box}`.
  Each mod lists its commands in its `mod.toml` as `[[sidecar.cmds]]`; tools/build.py turns them into contributions
  (a symbol in an area mod becomes a relocation; a cave mod's symbol or a fixed address its linked address) and
  refuses a build in which two ranges overlap or a client is enabled without the companion. Flags bit 0
  (`SC_DIRECT`): `box` is the handler, called for every command in the range. Otherwise `box` is a two-word mailbox
  `{magic, handler}` the mod writes when it is ready, and the handler is called only while the mailbox holds the
  entry's magic (0022's rule for its fixed mailboxes). A handler is `int f(const uint8_t *data, int32_t len)`, run in
  the MIDI task, never waiting.
- **No FX return** since 2026-11-04 (decided: take it out for now, a generic audio route later): the command 26 / 27,
  its two Overbridge-input jsr operands and the mix report 50 (fxin.c, fx-return.md, once mod 0030) are in git history
  only. The router and table did not change; the Pi's generic engine already drops 26, 27 and 50.
- **The store link** (store.c, the Storage phase, decided 2026-11-04): a client for the Pi's generic record store and
  parameter-lock service (host-link 51; sidecar-firmware core/kv/kv.h and core/locks/locks.h), for any mod on the
  Rytm. Below.
- **The step clock** (clock.c, with the param `clock`): the Rytm's steps as 2C / 2D for the Pi's core/clock. Below.

## The store link

Two core-ar2 fields, approved 2026-11-04 (the only core resources the companion claims):

| field | scope | bits | holds |
|---|---|---|---|
| `sc_proj` | project | 32 | the project's ID, which names its folder of records on the Pi (`/.rytm/store/<id>/`). Given at the first `ev_project` that finds it 0 (CREATE NEW, a project saved without the companion). SAVE PROJECT AS copies it: the two projects then share a folder. Records are versions and are never overwritten, so neither loses one; a KEEP from one would drop the other's, so the companion sends no KEEP (decided 2026-11-04: deferred). Without KEEP a project's folder only grows, up to kv's 1024 records, after which writes are refused (status 3, full); a later KEEP needs a save hook in core-ar2 (core has only a load event) and its own ID per saved copy |
| `sc_phand` | pattern | 16 | a record handle per pattern (0 none), for a mod that keeps a pattern's data on the Pi (a lock table). Copy and paste of a pattern carry it (core) |

The session: at every USB port-up and project change the companion sends `51 01 00 HELLO <project 5>`, up to 3 times
2 s apart while unanswered, and once more when any host message arrives while unanswered (a Sidecar that came up
late). The project's name (16 bytes at 0x407c89d3, 0021's poll [measured there]) follows as `51 01 04 NAME <project 5>
<len> <name>` once the link opens, and again when it changes and holds 10 ticks (decided 2026-11-04: the name rides 51
with its ID instead of the separate 10; the Pi keeps it for its log, /status and web page). The Pi's answer (`51 01 40`) opens the link, and `sc_link_epoch()` takes a new value (never 0; 0 while closed).
The Pi forgets every lock set at a HELLO, so a mod declares its sets again whenever the epoch changes. An answer to the
HELLO before a project change does not open the new project's link. The port going down closes it; a request that was
in flight goes again after the next HELLO.

The API (all from the UI task, `ev_tick` or what it calls; the callbacks come from the companion's `ev_tick`):

```c
typedef void (*sc_store_cb)(int32_t status, int32_t n, uint32_t handle, void *ctx);
int32_t sc_store_read(int32_t scope, uint32_t handle, uint8_t *buf, uint32_t cap, sc_store_cb cb, void *ctx);
int32_t sc_store_write(int32_t scope, const uint8_t *src, uint32_t n, sc_store_cb cb, void *ctx);  /* src kept until cb */
int32_t sc_link_send(const uint8_t *body, int32_t n);   /* a lock op 10..15 or a route op 20..23, whole; 0 while closed */
int32_t sc_route_result(uint32_t owner, uint32_t seq);   /* the Pi's answer to ROUTE / MOVE: point, -code, -256 none yet */
uint32_t sc_link_epoch(void), sc_project_id(void);
uint32_t sc_pattern_handle(int32_t p);                   /* live pattern 0..127 */
void sc_set_pattern_handle(int32_t p, uint32_t h);
```

- Requests queue (4 at most; 0 when full) and go one at a time; a request waits while the link is closed, and once
  sent it times out after 60 ticks (status 0x7E). Status is kv::Status otherwise (0 ok, 1 missing, 6 too big, ...).
- A write gets a new handle, never 0 (handles are versions). Up to 4 messages a tick: a 4 KB record is 37 chunks.
- The cache: 4 records of up to 256 bytes by (scope, handle), filled by each read and write that fits. A handle names
  a version that never changes, so a cached record is never stale and a read that hits it needs no Pi.
- Answers arrive in the MIDI task through the router's direct entry for 51 (`sc_store_host`); it writes only the
  request in flight and the link's words.
- The audio route (the audio route phase, decided 2026-11-04: "ROUTE op + lockable gains"; sidecar-firmware
  core/route/route.h). A mod sends `20 ROUTE <seq> <owner> <src> <dst> <gain 2>` through `sc_link_send`: one Rytm IN
  channel (2-9 the voice stems, 10-11 AUDIO IN; never MAIN) added onto one OUT channel (0-1 MAIN, 2-3 MAIN FX, 4-11 the
  voice inputs) at a gain (8192 unity). The Pi hands out the point and answers `60 ROUTED <seq> <owner> <point>` or
  `61 REFUSED <seq> <owner> <code>` (3 full, 5 bad, 7 loop); the companion keeps the last 16 for `sc_route_result`,
  cleared at each new epoch and when the port goes down. `21 MOVE`, `22 UNROUTE`, `23 GAIN` as the header says. A
  point's gain is lock target 4 (param = the point): a lock set on it plays the gain per step. The Pi closes every point
  at a HELLO, so a mod asks again when the epoch changes, as it declares its lock sets. The owner byte is the mod's own
  (storetest 0x31); the Pi checks it on MOVE / UNROUTE / GAIN.
- Sending never waits (0029's try_send rules), and never lands inside a stock SysEx dump unless its flag has stayed set 2 s.

## The step clock

With `clock = 1` (the release's, Makefile `RELEASE_ARGS`), the companion takes 0026's seq-link sites (1032): trig_fire's
entry and the sequencer clock's exit (registry). A build with 0026 `screen=0` and `clock=1` is refused (both claim the
hosts). While the store link is open and the port is configured it sends, as sim/protocol.py's "Sidecar sequencer":

- `2C 01 <blk4> <n> {<track> <step> <len> <speed> <flags>} x n`: the steps that started in one audio block, all 13
  tracks (the FX track is 12), 5 bytes a tick (0026's had 4; the Pi's parser takes either). Flags bit 0: the step holds
  a note trig; bit 1: a trigless lock trig. From the step's trig word (TrackPattern + 2 x step: bit 0 trig, bit 2
  lock), or for a euclidean track its map (+0x2d1) [code, re/symbols.toml; to measure]. Mutes are not looked at.
- `2D 01 01 <state> <blk4>` TRANSPORT at link-up and on each change; `2D 01 03 <from> <to> <blk4>` SWITCH when the new
  pattern's first step starts (0026 1042's jump handling: a re-schedule call is no step).
- `2D 01 02 <now> <queued, 7F none>` PATTERN and `2D 01 07 <t hi> <t mid> <t lo>` TEMPO (BPM x 120, 21 bits) at
  link-up and on each change (added 2026-11-04 after T115, where the Pi's clock.pattern stayed -1 and bpm 0). The
  words are 0026's (SQ_NEXT 0x412f3e91, SQ_TEMPO 0x40287ffc, measured there); while a switch is pending the old
  pattern is reported playing and the new one queued, as 0026's 1033 did.

The FX track's speed byte (0x405c8d25 + 12) is read as the voice tracks' are [I: the array's width is not measured].

## Rules it carries

- The Pi engine stays generic: no engine part exists for one Rytm mod. A client registers commands here only for a
  service the engine offers to any mod.
- Core resources: the companion claims two core-ar2 fields, `sc_proj` (project, 32 bits) and `sc_phand` (pattern, 16
  bits), approved 2026-11-04; nothing else of core's shared resources (lock codes, machine slots, pages, CCs). Its
  event subscriptions are `ev_tick` order 76 and `ev_project` order 50. Any later claim needs the owner's OK
  first.
- Host traffic is unchanged by the move from 0022's router to this table: the gate is a capture comparison against the
  build before it, byte-identical but for the traffic of features left out of the build.
- The store link and the step clock add host traffic (51 HELLO at port-up, 2C / 2D while playing with the link open);
  the gate for them is the same capture comparison, every kept command byte-identical and the new ones as above;
  27 and 50 are gone with the FX return (tools/emu/cap_emu.py's KEPT set needs that change at the next run).

## Tests

`make -C mods/0032-sidecar/test FIRMWARE=<sidecar-firmware>` builds store.c and clock.c for a PC (test/companion_host.c
gives the firmware's words) and runs them against the Pi's own core/kv, core/locks and core/clock: the HELLO and the
epoch, a 3-chunk write and its read, the cache, a missing handle, the queue's limit, a timeout, lock ops reaching the
Pi's lock service and played by the companion's own 2C, the 13 tracks' trig flags, a jump's re-schedule, a full tick
queue, a project change (and a stale HELLO answer), the port going down mid-request, no Pi at all. ASan and UBSan.

`test/storetest/` is a test client of the store link: a separate elekloader mod (`sidecar-storetest`, requires
`sidecar`) for test builds only, never in a release. Each session it declares lock set 7 (track 1, slot 3, two
parameters, a lock on steps 1 and 9), writes a 600-byte record and reads it back from the Pi, writes and reads a small
one (served by the cache), and reads the previous session's record by pattern 1's handle (a reload or SAVE AS shares
the folder). Since the audio route phase it also asks for two route points, the SD stem onto MAIN L and MAIN R at gain
0, and declares lock sets 5 and 6 on them (track 1, target 4): unity on steps 1 and 9, so the Pi's copy of SD is heard
on those steps only (box at x 86). Boxes at the screen's bottom right show each step; the Pi's /status `kv` and `locks` members show the
same from its side. The host test runs it too (three sessions: first, second with the earlier record, a deaf Pi).
Build it with elekloader's SDK (`python -m elekloader.sdk.build mods/0032-sidecar/test/storetest --stock <1.74 .syx>`).

## Clients in the core 0.9 build

| mod | commands | entry |
|---|---|---|
| 0032-sidecar (itself) | 51 | direct: `sc_store_host` |
| 0026-remote-ui, `screen=1` | 30..3F | mailbox `rui_mbox`, magic `RUIP` |

0026 without `screen` also registers 28, 2E..2F, 45..48, 4A and 4F; 0021 15..1D (15..17 without slots), 0023 0E and
14, 0029 21..22 and 24. None of those are in the core 0.9 build (Storage phase).
