# Installing the Sidecar mods from the elekloader web page

The Sidecar's mods for the Analog Rytm MKII come as [elekloader](https://github.com/irpina/elekloader) modules. You
build your own firmware file from them in the web page at <https://irpina.github.io/elekloader/>, on your own computer,
from the stock OS file you download from Elektron. Then you flash that file like any OS update.

This is for **OS 1.74 only**, on **core-ar2 0.9**. Read the whole page once before you start, the recovery section
included.

This is a development snapshot of the companion phase (decided 2026-11-03), not a release: see "Status".

## What you need

| file | what | sha256 (development snapshot, not a release) |
|---|---|---|
| `Analog-Rytm_MKII_OS1.74.syx` | the stock OS 1.74, from Elektron's support site | `cb0f99d620edde994fb860c0e79cc2464e427d06882828cfdfb00fc53700e123` |
| `core-0.9-os1.74.elemod` | elekloader's core-ar2 0.9 for OS 1.74: the boot copier and hook bus every elekloader mod builds on | `ea2c2a633de79d602c250258ee0c3f223f84a3b4e5ee3509c7366402a002bf12` |
| `sidecar-0.4.0.elemod` | the Sidecar companion: the host link on the Rytm | `6499327acfe31dc54af94dde39d30517b1963075191fd68e693532d4302f6d1f` |
| `rytm-sidecar-0.4.0.elemod` | the Sidecar's remote screen, which needs the companion | `3d2688f382e8dfa7cb300f8121caab6f06a9524f40c6b61601a847d2e87d8129` |

The three `.elemod` files are published together, with `SHA256SUMS`, `LICENSE`, `NOTICE`, `TOOLCHAIN.txt` and the
source of elekloader (`elekloader-9f72fb0-src.tar.gz`). Check every hash before you use them.

What they do:

- **The companion** (`sidecar`, mods/0032-sidecar) takes every SysEx message the Sidecar sends the Rytm (F0 7D 52 54
  ...) before the Rytm's own handling, and passes each command to the mod that registered it in its table. Its own
  service is the FX return: on the Sidecar's request (off at every boot), Overbridge channels 10/11 carry the Rytm's
  delay + reverb return instead of AUDIO IN, and it reports each voice stem's pan and routing to the Sidecar.
- **The remote screen** (`rytm-sidecar`, mods/0026-remote-ui built with `screen=1`): TRK + YES shows pages the
  Sidecar draws on the Rytm's screen, with the keys and knobs the page asks for going to the Sidecar, the connect
  splash, and the trig LEDs while a page is open. Nothing else: the Sidecar features that needed their own Rytm
  reports (the sequencer link, project-slot and kit reports, chords, the arpeggiator, the source lists, DIN MIDI) are
  left out of this snapshot.

Not in this snapshot: the Sidecar machines (0021, 0014), the send FX (0025, 0029) and the TEENSY drive (0023), which
need core storage or machine slots and wait for the Storage phase; the looper (0022), dropped. Projects made under
those mods' earlier builds load, but their tracks on Sidecar machines show DISABLE (`docs/FLASHING.md`, "Projects
saved under the mods, on stock").

You also need, for flashing, Elektron Transfer (USB), or C6 / Transfer's legacy mode and a DIN MIDI interface (for the
recovery route).

## Before the first time: back up, and prove recovery

1. Back up every project, sound and sample with Transfer.
2. Make sure the recovery route works on your unit: one full DIN reflash of stock 1.74 through the STARTUP menu
   (below). `docs/FLASHING.md` stage S0 says why: the USB route needs a firmware that boots.
3. Use a scratch project for the first session under the mods.

## Build the firmware in the web page

1. Open <https://irpina.github.io/elekloader/>.
2. Choose your stock firmware: `Analog-Rytm_MKII_OS1.74.syx`. The page knows it by its hash.
3. Add your own mods: `core-0.9-os1.74.elemod`, `sidecar-0.4.0.elemod` and `rytm-sidecar-0.4.0.elemod`. Use this
   core file, not one the page lists: our hash was made with it.
4. Tick `rytm-sidecar`. Ticking it ticks what it requires: the companion and the core. The check should say there are
   no conflicts.
5. **Set the version to `1.74`.** The page's default for the Rytm is `2.0a`. **Never flash a build whose version is
   not 1.74.** A 2.0a build has the same MAIN OS, but the unit then reports OS 2.0a, and going back to stock 1.74
   from there is untested: the OS carries "Downgrade not possible" and the bootstrap a VERSION CHECK
   (`docs/FLASHING.md`, "Downgrades"), so either route, USB or the STARTUP menu, may refuse it.
6. Build, and download the `.syx`. With version 1.74 its sha256 is
   `fa72d3f10e547dccae6efee4d0ccdea7dd82eef5e217dcb6e2e27f69967e25e4`, as built from this branch. If yours differs, do not flash it: see the next section.

### If your file's sha256 differs

The page builds with whatever elekloader commit it runs today. Our hash was made and checked with elekloader at
`9f72fb0`. A later packer or linker can give another file. To see the page's commit: the page's footer names it, and
<https://irpina.github.io/elekloader/build.json> says it (`"commit"`). If the page has moved and your hash differs,
build with the command line at the pinned commit instead:

    git clone https://github.com/irpina/elekloader && cd elekloader
    git checkout 9f72fb05bd3baeacdf04af00dc2d1357abf96134
    python3 -m elekloader.patch --stock Analog-Rytm_MKII_OS1.74.syx --mod core-0.9-os1.74.elemod \
        --mod sidecar-0.4.0.elemod --mod rytm-sidecar-0.4.0.elemod --out sidecar.syx --version 1.74

and check that `sidecar.syx` has the sha256 above.

Never share the `.syx` you built: it contains Elektron's firmware. Share the `.elemod` files instead.

## Flash it

**Normal route, Elektron Transfer over USB:** connect and power on; Transfer > CONNECTION, MIDI IN and OUT set to the
Rytm; drag the `.syx` onto Transfer's DROP area; press `[YES]` on the Rytm. It restarts by itself. This route runs
inside the firmware, so it needs a firmware that boots.

**Or C6** (or Transfer's legacy mode) over DIN MIDI, through the STARTUP menu's OS UPGRADE: the steps of the
recovery route below, with your built `.syx` in place of the stock one. Slower (16 minutes or more), but it works
whatever firmware the unit has.

After an OS upgrade the Rytm may also upgrade its bootstrap on the first restart. Do not turn the power off then.

## Recovery

If the Rytm does not boot after flashing, the STARTUP menu still works: our builds and elekloader never change the
bootstrap (section 2), and the release check (below) checks that byte for byte.

1. Hold `[FUNC]` while you power on. The STARTUP menu comes up.
2. Press `[TRIG 4]`: OS UPGRADE.
3. Send the **stock** `Analog-Rytm_MKII_OS1.74.syx` over **DIN MIDI** (Transfer > CONNECTION, "LEGACY OS UPGRADE
   mode", or C6). USB does not work in this menu. It takes about 16 minutes or more.

The web page shows the same steps before every download.

## What you cannot do yet

- **Use an older core.** Both Sidecar modules ask for core-ar2 0.9 or newer; elekloader refuses them with an older
  core (*"... needs core 0.9 or newer"*). A newer core is allowed by the format but untested: use 0.9, by its hash.
- **Mix it with other people's mods.** elekloader combines mods only if they touch none of the same bytes. The
  Sidecar modules patch four places outside the core's own (the SysEx router's entry, two Overbridge-input calls, the
  panel link's writer), so other core 0.9 mods may combine with them. Untested.
- **Use it on OS 1.73.** These modules are made for 1.74's addresses; elekloader refuses them with a 1.73 stock file.
  For 1.73, build release 0.3.1 from its tag.

## Status

The companion phase's first build (decided 2026-11-03): the Sidecar's mods moved from core-ar2 0.1 to 0.9, the
companion took the host link from 0022 and the FX return from 0030, and the remote screen was cut to 30..3F. Built and
checked in the cloud only: `make release` (with `tools/verify.py`) and `make release-check` pass. Not yet run in the
emulator or on a unit; until they have, treat it as untested. Before a unit run it must pass the emulator's flash and
boot and a capture comparison of the host traffic against the 0.1 build (byte-identical, but for the traffic of the
features left out).

## Source and licence

The mods are GPL-2.0-or-later (`LICENSE`, `NOTICE`). `make setup` then `make release` builds the three `.elemod`
files from this branch, byte for byte with the toolchain in `TOOLCHAIN.txt` (GNU binutils 2.47 `m68k-elf-as` for our
code; Ubuntu's `gcc-m68k-linux-gnu` 13 for the core, whose C is pre-C23, as upstream builds it; another version may
give other bytes). `NOTICE` names the exact elekloader commit: the core is core-ar2 0.9 for OS 1.74 built unchanged
from elekloader's `mods/core-ar2` at `9f72fb0`, with elekloader's builder at the same commit; the source is in the
release folder beside the files.

## For maintainers: the release

    make release          # build/release/<VERSION>/: the three elemods, elekloader's source archive, TOOLCHAIN.txt, LICENSE, NOTICE, SHA256SUMS
    make release-check    # those files only, through upstream's code

- The version is set in one place, `VERSION`. The set and its params are `RELEASE_MODS` / `RELEASE_ARGS` in the
  Makefile. `tools/build.py --elek-bundle` writes the companion as its own elemod (`sidecar`) and one elemod for every
  other enabled mod (`rytm-sidecar`), which requires it; without `--elek-bundle`, one per mod
  (`rytm-<id>-<tag>.elemod`), each with `requires` for the mods it needs.
- `make release` runs `tools/verify.py` on the build, as every build: every changed byte must be claimed by our
  registry or be one of the core's own sites as its elemod gives them.
- `make release-check` (`tools/release_check.py`) takes only the published files and the stock `.syx`:
  - `elekloader.lint`, `patch --check` and `patch --out`;
  - the web page's own module (`web/bridge.py`, run in CPython in place of the page's Pyodide): add the three files,
    tick, check, build with version 1.74 and with the page's default;
  - each image's MAIN OS must be the release build's byte for byte, sections 1/2/5/8 stock, the bootstrap at its
    pinned sha256;
  - the CLI's and the web page's 1.74 builds must be build.py's `.syx` (the one the suites run), the core its pinned
    sha256, and this guide's four hashes the release's;
  - the bundle must be refused without a core, without the companion, and with core-ar2 0.1 (built from upstream's
    `13fa795`).
- Then boot the image in the emulator and run the suites: `tools/emu/us_base.sh <tag>`, then
  `build/suites/run.sh -j 4 <tag>` (with `RYTM_EMU` and `RYTM_TEENSY` set). The image the web page builds with version
  1.74 is the same file as `build/Analog-Rytm_MKII_OS1.74_<tag>.syx`, so the suites run on exactly what a user
  flashes.
- A mod that takes host commands registers them in its `mod.toml` (`[[sidecar.cmds]]`); build.py refuses a build in
  which two ranges overlap or the companion is missing, and a bundle that lacks a mod one of its members needs.
