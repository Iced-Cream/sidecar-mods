# 0032-sidecar: the Sidecar companion

Status: **built** (core-ar2 0.9, 2026-11-03), cloud checks only (`make release`, `make release-check`). Not yet run in
the emulator or on a unit.

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
- **The FX return** (fxin.c, until 2026-11-03 mod 0030-fx-in; fx-return.md): the companion's own command 26 (a
  direct entry), the two Overbridge-input jsr operands, an `ev_tick` at order 75 for the 27 answers and the mix
  report 50. Folded in because audio routing over the link is a generic service, not one feature's.

## Rules it carries

- The Pi engine stays generic: no engine part exists for one Rytm mod. A client registers commands here only for a
  service the engine offers to any mod.
- Core resources: the companion claims none of core-ar2's shared resources (storage, lock codes, machine slots,
  pages, CCs). Its event subscription is `ev_tick` order 75. Any later claim needs the owner's OK first.
- Host traffic is unchanged by the move from 0022's router to this table: the gate is a capture comparison against the
  build before it, byte-identical but for the traffic of features left out of the build.

## Clients in the core 0.9 build

| mod | commands | entry |
|---|---|---|
| 0032-sidecar (itself) | 26 | direct: `fxin_host` |
| 0026-remote-ui, `screen=1` | 30..3F | mailbox `rui_mbox`, magic `RUIP` |

0026 without `screen` also registers 28, 2E..2F, 45..48, 4A and 4F; 0021 15..1D (15..17 without slots), 0023 0E and
14, 0029 21..22 and 24. None of those are in the core 0.9 build (Storage phase).
