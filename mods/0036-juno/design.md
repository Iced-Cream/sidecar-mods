# 0036-juno: JUNO on the Sidecar's generic engine (design and status, 2026-11-10)

Upstream's JUNO voice (trigcondition/sidecar-firmware dev 39808ae, voice flag 0x08; ext's machine 41) as a Pi blob,
for a voice mod that is a client of the companion's voice service, as PLAITS (0033) and DAISYSP (0034). Tags: [code]
read in source; [emu-qemu] run under qemu-aarch64 user mode; [I] reasoned, not shown.

**Status: the blob only.** The Rytm side waits for the machine slots (decided 2026-11-10: hold the Rytm side until
core ask 8 settles the slots). Without mod.toml the build skips this folder.

## Why a blob

The DSP library has no oscillator, envelope or ladder with the 106's curves; upstream's juno::Voice (DCO with PolyBLEP,
HPF, ZDF ladder, ADSR, BBD-style chorus, AMY's slider curves) plays it exactly only as its own code.

## The blob (blob/juno_blob.cc, built by blob/build.sh)

- Upstream's `juno::Voice` (sim/juno/juno_voice.h) and its 128 factory patches (juno_patches.h, from AMY, MIT),
  unchanged, rendered in upstream's 12-sample blocks. 25 KB, no writable globals.
- Params 0..7 in core's knob order (knob 0 is H): LEN PAT CUT RES ENV ATK DEC REL, mapped onto upstream's P1..P8
  (PAT CUT RES ENV ATK DEC REL LEN). A Rytm page: A PAT, B CUT, C RES, D ENV, E ATK, F DEC, G REL, H LEN; no level
  knob (the patch's VCA LEVEL, as upstream; the voice's amp page sets the track's level).
- CUT..REL are absolute slider values. A new PAT plays the patch's own six until the Rytm's CUT..REL move, then all
  six follow the knobs (upstream's hold in core/voices.cpp). Upstream's host also writes the patch's values onto the
  Rytm's knobs (its message 15); here that write-back is the Rytm mod's and needs core ask 14 (a mod sets a sound's
  knob value). Until then the knobs show their old values while the patch's own play.
- Trigs: 0x90 note vel is NoteOn; 0x80 (TRIG kind 1) is the release.
- LEN default 64 (~0.5 s gate). Upstream's is 127 (follow the note), which holds until the next trig without the
  Rytm's note-offs (core ask 10); back to 127 once they exist.

## Not carried over (gaps)

- The project's JUNO list from the card (PAT steps through the factory patches only).
- PAT's value text: the factory names A11..B88 are 3 characters and can be computed on the Rytm (bank A/B, 1..8, 1..8).
- The knob write-back on a PAT change (core ask 14) and LEN 127's note-offs (core ask 10).
- Upstream's chord / poly layer.

## Tests

- `make -C core test-aarch64 SCX_TGAIN=... SCX_JUNO=<blob/build/juno.scx>` in sidecar-firmware (branch
  juno-md-fm-voices): shipped, placed, routed, silent before a trig; each of the 128 factory patches sounds on a trig
  (peaks 0.025..1.10: upstream's own levels, some above 1), all finite; A14 held with LEN 127 sustains and is silent
  2 s after the release [emu-qemu]. The hold is [code] only (no test turns a knob after a PAT change yet).
- Not yet: the Rytm side, the emulator gate, a unit run, a listening check against upstream.
