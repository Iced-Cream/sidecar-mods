# 0038-fm: 6-OP FM on the Sidecar's generic engine (design and status, 2026-11-10)

Upstream's 6-OP FM voice (trigcondition/sidecar-firmware dev 39808ae, voice flag 0x48; ext's machine 40) as a Pi
blob, for a voice mod that is a client of the companion's voice service, as PLAITS (0033) and DAISYSP (0034). Tags:
[code] read in source; [emu-qemu] run under qemu-aarch64 user mode; [I] reasoned, not shown.

**Status: the blob only.** The Rytm side (machine entry, stub, mod.toml) waits for the machine slots (decided
2026-11-10: hold the Rytm side until core ask 8 settles the slots). Without mod.toml the build skips this folder.

## Why a blob

The DSP library (sidecar-firmware core/dsp) has DELAY, FILTER, SHAPER, MOD and WIDTH: no oscillator, no FM operator.
Upstream's voice is Plaits' six-op engine with its own wrapper; only the code itself plays it exactly.

## The blob (blob/fm_blob.cc, built by blob/build.sh)

- Upstream's `rytm::FmMachine` (sim/plaits/fm_machine.h) unchanged, on Plaits (eurorack 08460a6) patched as
  upstream's teensy/setup_plaits_lib.sh patches it for the Pi: a voice load unpacks only the voice into patch 0 or 1
  (the previous note rings out, no click on a PAT change) and the operators' NEON path. Sources fetched by
  tools/sidecar_upstream.sh at the pinned commit; never committed.
- Params 0..7 in core's knob order (knob 0 is H): LEV PAT TIM MOR DEC LPG TUN LEN, mapped onto upstream's P1..P8
  (PAT TIM MOR DEC LPG TUN LEV LEN). A Rytm page: A PAT, B TIM, C MOR, D DEC, E LPG, F TUN, G LEN, H LEV; no page 2.
- PAT picks one of Plaits' 96 ROM voices (its three DX7 banks; 96..127 the last), at a trig only, as upstream.
- Trigs: 0x90 note vel is NoteOn; 0x80 (TRIG kind 1) is the release.
- Defaults: LEV 100, PAT 0, TIM MOR LPG TUN 64, DEC 127 (no LPG), LEN 64 (~0.5 s gate). Upstream's LEN default is
  127 (follow the note), which drones without the Rytm's note-offs (core ask 10); back to 127 once they exist.
- 200 KB; the six-op hand-over pointers and stmlib's Random seed on their own 64 KB writable unit (SCX_F_DATA). One
  render thread runs every slot (core/proc), so those globals are not shared between cores.

## Not carried over (gaps)

- The project's FM list from the card (/DX7 banks, LOAD TO PROJ, names on PAT): needs a card/library service; PAT plays
  the ROM voices only.
- PAT's value text (the voice's name): 10-character names; the Rytm side can show the number, or the names from the
  ROM banks' bytes 118..127 if the text fits.
- LEN 127 needs the Rytm's note-offs (core ask 10).
- Upstream's chord / poly layer.

## Tests

- `make -C core test-aarch64 SCX_TGAIN=... SCX_FM=<blob/build/fm.scx>` in sidecar-firmware (branch
  juno-md-fm-voices): shipped, placed, routed, silent before a trig; each of the 96 ROM voices sounds on a trig (peaks
  0.35..1.00), all finite; voice 0 held with LEN 127 sustains and is gone 1.5 s after the release [emu-qemu].
- Not yet: the Rytm side, the emulator gate, a unit run, a listening check against upstream.
