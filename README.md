# Sidecar | Expander: Rytm mods

> **`dev` is the development branch: unstable, not a release.** It carries the 0.4.0 line and needs matching builds of
> both repos; flash at your own risk; keep your 0.3.1 firmware for rollback. Use `main` for a release. Pull requests go to
> `dev` (see CONTRIBUTING.md).

## What's in this snapshot (since 0.3.2)

Rytm side only (0.3.2 had no Rytm change, so this is since the Rytm firmware 0.3.1). Pair it with the `dev` branch of
[sidecar-firmware](https://github.com/trigcondition/sidecar-firmware), which lists the Pi side. "Hardware" means run on a
real Rytm, on a test build from this source (`tools/build_rui.sh`, removed 2026-11-07 with the mods it built; `make release` packs the same source as one module,
so its bytes differ); "emulator" means the emulator suites and the flash rehearsal, on that test build. The `make release`
image has had neither.

- **MD page:** machine 42 is the built-in MD, with its own page and labels from the Sidecar. 0021 now lives in elekloader's area. Hardware.
- **Preset browser for JUNO and 6-OP FM:** on knob A of SRC. Hardware.
- **DSP SAMPLE:** SMP's picker on knob A, MIX default 0, the playhead on the page the Sidecar draws. MIX and playhead: hardware. Picker: emulator.
- **Longer enum lists:** a list knob holds 36 names, 16 before. Emulator.
- **MIDI machine:** machine 50, out of the Rytm's DIN port or the Sidecar's USB ports. DIN tested in the emulator; USB unverified on hardware.
- **Arpeggiator:** the settings live in the sound, UP + FLTR opens its page. Hardware OK on FM.

Not in this snapshot: **master FX**.

`make release` builds version 0.4.0 here. The hashes in the README's release section below are 0.3.1's.

## About

The source of the Analog Rytm MKII OS mods that Sidecar | Expander uses: the patch sources, the symbol map, the
allocation registry and the build that turns your own stock OS 1.74 `.syx` into a modded one.

This branch ports the tree from OS 1.73 to OS 1.74 with the same behaviour (`tools/port_os.py` moved every firmware
address; each build differs from its 1.73 build only by moved addresses), on elekloader's core-ar2 0.1 port for 1.74
(`13fa795`). Design notes and research files (`*.md`) keep the 1.73 addresses they were written with. Not yet run
in the emulator or on a unit. The releases below (0.3.1, `rui1027d`) are OS 1.73 builds: build
them from their tags with a 1.73 stock file.

This branch is a development snapshot on top of the **Rytm firmware 0.3.1**, released with **Sidecar 0.3.1** (Raspberry Pi 4B and
Pi 5), a fix release: send FX values now follow a kit switch. It is one elekloader module, `rytm-sidecar-0.3.1.elemod`, used with elekloader's `core-0.1.elemod` on OS 1.73.
Build the `.syx` from your own stock file on elekloader's page or command line, or in the browser patcher (build
`rel0-3-1`); both give the same file.

> **Sidecar Mini (Teensy 4.1) is phased out.** It is frozen at 0.1.0, with its Rytm build `rui1027d` (below): no new
> features. The 0.1.0 release stays downloadable.

- Release (the two `.elemod` files, `SHA256SUMS`, `LICENSE`, `NOTICE`, the source of elekloader's parts):
  <https://github.com/trigcondition/sidecar-mods/releases/tag/v0.3.1>; install: `docs/ELEKLOADER.md`
- The older builds (`rui1027d`, `sfx1021`, for Sidecar 0.1.0, Sidecar Mini 0.1.0 and Sidecar 0.2.0) and install guides:
  <https://github.com/trigcondition/sidecar-expander/releases>
- Documentation and the browser patcher: <https://trigcondition.github.io/sidecar-expander/>
- The Sidecar engine: [sidecar-firmware](https://github.com/trigcondition/sidecar-firmware), its 0.3.1 release:
  <https://github.com/trigcondition/sidecar-firmware/releases/tag/v0.3.1>

> **Unofficial, experimental software.** Not affiliated with, endorsed by or supported by Elektron. No Elektron
> firmware, and nothing extracted from it, is in this repository: you supply the stock `.syx` yourself. Flashing a
> modded OS is at your own risk; read `docs/HAZARDS.md` and `docs/FLASHING.md` first.

Every build starts from the pinned stock image and rebuilds from source. The
`.syx` is an artifact; the patch sources, the symbol map and the allocation
registry are the project.

## Layout

| path | what |
|---|---|
| `stock/` | checksum of the pinned stock firmware, which you supply. Never written to. |
| `re/` | cumulative reverse-engineering knowledge: `symbols.toml`, subsystem notes, Ghidra bootstrap |
| `mods/NNNN-slug/` | one modification: manifest, stub source, design rationale |
| `requirements.txt` | empty since 2026-11-07 (its packages were for tools that left with their mods) |
| `registry/` | `allocations.toml` - every claim on cave space and detour sites |
| `tools/` | build, layout validation, verification, symbol generation, cave scan |
| `vendor/` | code that is **executed**, fetched by `make setup` (see `NOTICE`): elektron-firmware-tool (MIT); elekloader for every build with the companion and the release (GPL-2.0-or-later); the companion itself, sidecar-core (GPL-2.0-or-later, its own repository since 2026-11-05) |
| `docs/` | user manual, flashing, hazards |
| `build/` | artifacts, gitignored |

## Build

Prerequisites:

- Python 3.11 or newer (build and verify use only the standard library)
- `git`, `make` and a C compiler, for the vendored container tool
- `m68k-elf-binutils` (`brew install m68k-elf-binutils` on macOS)
- a Ghidra install, only for `make ghidra`

The stock firmware is not included. Download Analog Rytm MKII OS 1.74 from
Elektron's support site and place the `.syx` at
`stock/Analog-Rytm_MKII_OS1.74.syx`. The build refuses any file whose checksum
differs from `stock/SHA256SUMS`.

    make setup     # venv + Python deps, clone and build the vendor tool at its pinned commit
    make verify    # build + assert the result

Produces `build/Analog-Rytm_MKII_OS1.74_<tag>.syx`, the only delivery format this
device has - there is no CF-card `.bin` equivalent. See `docs/FLASHING.md` to install it.

Build a subset for hardware bisection:

    .venv/bin/python tools/build.py --mods 0032-sidecar 0025-sendfx

## The release (0.3.1)

The Sidecar mods as one elekloader module, `rytm-sidecar-<VERSION>.elemod`, with elekloader's core 0.1 beside it
(`VERSION`, `docs/ELEKLOADER.md`). From a clean checkout at tag `v0.3.1`, after `make setup` and with the stock file in
`stock/`:

    make release          # build/release/0.3.1/: the two .elemod files, LICENSE, NOTICE, TOOLCHAIN.txt, the
                          # source of elekloader's parts, SHA256SUMS
    make release-check    # the published files through elekloader's command line and web page code path

`make release-check` takes only the published files and the stock `.syx` through elekloader's command line and its web
page's code path: MAIN OS must come out as the release build's, the other sections stock.

With the toolchain `TOOLCHAIN.txt` names, `core-0.1.elemod` has sha256
`33de51c098ab0ecd9cc57e9dfc3efa3d95f8133b1f4a4e6abd80d5fdba2dd825` and `rytm-sidecar-0.3.1.elemod`
`e451fd6001f28d7cb0e9a05d46c712b49d1688c8873714d43f4ec1b786aaae5c`, the released files; the `.syx` elekloader
builds from them (version 1.73) has sha256 `a203db27201aabbdaa285ccb7c40a168075206c0ce91477671fcfae729c3df3c`.

## The Sidecar build `rui1027d` (Sidecar 0.1.0, Sidecar Mini 0.1.0, Sidecar 0.2.0)

The patch build released with Sidecar 0.1.0 and kept for 0.2.0 (the browser patcher's older build); Sidecar Mini, frozen
at 0.1.0, stays on it. From a clean checkout, after `make setup`
and with the stock file in `stock/`:

    .venv/bin/python tools/symbols.py
    .venv/bin/python tools/build.py --tag rui1027 \
      --mods 0014-hidden-machines 0021-ext 0022-looper 0023-teensy-drive 0025-sendfx-report \
             0027-elekloader 0028-elek-hello 0029-sendfx-ui 0026-remote-ui 0030-fx-in \
      --param 0014-hidden-machines:variants=0 --param 0014-hidden-machines:funcgen=0 \
      --param 0014-hidden-machines:test=0 --param slots=1 --param 0022-looper:keys=0 --param 0022-looper:sfx=1 \
      --area-elek 0022-looper --area-elek 0025-sendfx-report --param 0022-looper:rui=1 --param 0022-looper:fxin=1
    .venv/bin/python tools/verify.py --tag rui1027

`build/Analog-Rytm_MKII_OS1.73_rui1027.syx` then has MAIN OS sha256
`613a952fe2eff4eda5022b2180dad82ed1beaa0341bbdf154671dd26536f689a` and file sha256
`4843848805c0e08b3cf7c69bf5b68ca7e1453bb643d351709bdad9f59468dce8`, the same bytes as the released
`Analog-Rytm_MKII_OS1.73_rui1027d.syx`.

## The container

Unpacks and repacks with the vendored tool, all checksums verified, five sections:

| id | name | size | load base | we touch it |
|---|---|---|---|---|
| 5 | meta | 15 B raw | - | no |
| 2 | bootstrap | 42,302 | 0x07020000 | **no** - see `docs/HAZARDS.md` |
| 1 | FPGA | 149,516 | 0x00000000 | no |
| 3 | MAIN OS | 3,005,432 | 0x40000400 | yes, this is the whole project |
| 8 | ? | 159,948 | 0x00000000 | no |

MAIN OS is ColdFire big-endian, as on the Octatrack, but it is a C++ build with its
Itanium-ABI symbol names left in (`ParameterPageView::changeParameterLockValue`,
`AnalogRytm::logicalParamID_t`, `Kit::updateMirror`). Most of the map can be recovered
by demangling rather than by guessing.

Section 8 is new in 1.73, little-endian ARM Thumb rather than ColdFire, and carries
`{"version": "1.00E", "release": "0018"}`. 1.73's only listed improvement is
"[MKII] Added Outbox 8 configuration support", so it is almost certainly the Outbox 8's
own firmware riding along - inferred, not proven.

`make verify` asserts that sections 5, 2, 1 and 8 come back out of our rebuilt `.syx`
byte-identical to stock, so a mistake can only ever reach MAIN OS.

## Mods

Since 2026-11-07 the tree keeps only the mods planned as sidecar-core clients, plus hidden-machines (kept as it was).
Each folder's `mod.toml` and `design.md` say more:

| id | name | what |
|---|---|---|
| 0014 | hidden-machines | the hidden machines the firmware carries but never lists (kept as it was; not a client) |
| 0021 | ext | external voice machines on every track, for the USB host (the Sidecar); to become a client on the DSP library |
| 0022 | looper | looper mode; to become a client on a generic loop block |
| 0023 | teensy-drive | the Sidecar's SD card as the SIDECAR folder in the Rytm's sample browser (the name dates from Sidecar Mini); to become a client of the engine's browse service |
| 0025 | sendfx | SEND FX 1 and 2 as graphs of the Pi's DSP library: a sidecar-core client |
| 0033 | plaits | Mutable Instruments Plaits as machine slot 44, played by the Pi: ext's first voice as its own sidecar-core client (the companion's voice service; its Pi blob in blob/) |
| 0032 | sidecar | the companion, built from its own repository sidecar-core (vendor/sidecar-core, pinned in the Makefile; mods/0032-sidecar/mod.toml is its entry here) |

Left the tree on 2026-11-07 (in git history): shared (0000), lfo-rnd (0004), comp-preview (0006), filter-hz (0008),
main-rms (0009), kit-ab (0010), slice-loop (0012), voice-dac (0013), dmach (0020), the older stand-alone mods;
sendfx-report (the older 0025) and sendfx-ui (0029), replaced by sendfx; remote-ui (0026), whose screen and step
clock are companion services now; elek-hello (0028), a test mod. ext still names sendfx-ui and remote-ui in its 1.73-era
build until it is rebuilt as a client. elekloader (0027) was folded into the companion on 2026-11-04 and fx-in (0030)
removed the same day. 0031-remote-keys was never published here. Their entries in `registry/allocations.toml` and
`re/symbols.toml` are kept as a record; `tools/layout.py` checks only the claims of mods in this tree.

Status ladder: `re-only` -> `built` -> `hardware-verified`, plus `retracted`.
Only `hardware-verified` counts.

## Adding a mod

1. Add any new addresses to `re/symbols.toml` with an honest `status`.
2. Claim cave space and detour sites in `registry/allocations.toml`, recording the
   stock bytes at each detour host in `expect`. A mod may hold several cave claims,
   each naming the `section` it holds (`.text` by default): the pools are separate
   regions of the image and can never merge, so anything larger than the biggest
   free run has to be split, and the split belongs in the registry rather than
   being implied by sizes.
3. Write `mods/NNNN-slug/{mod.toml,stub.s,design.md}`.
4. `make verify`, then flash that mod alone.
5. Before you commit, `python3 tools/hash_expect.py --image build/stock_mainos.bin`: it turns each `expect` into
   `expect_len` + `expect_sha256`, and a `replace` that copies stock bytes (a parameter record, say) into
   `replace_from = <address>`, so no stock bytes reach the repository. The build reads them from your stock image
   and checks the hash.

The `expect` bytes are the load-bearing guard: if an address is wrong or two mods
collide, the build aborts instead of quietly patching the wrong place.

Before the first mod ships, the cave pool has to be earned: `make cavescan` reports
the candidates, `registry/allocations.toml` explains why the current one was chosen,
and it stays `status = "candidate"` until it has been proven untouched at runtime on
hardware. octatrack-mods inherited a pool it had not checked and lost a round trip to
it.
