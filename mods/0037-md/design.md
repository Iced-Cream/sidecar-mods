# 0037-md: MD on the Sidecar's generic engine (design and status, 2026-11-10)

Upstream's built-in MD (trigcondition/sidecar-firmware dev 39808ae, voice flag 0x40, in place of DIGIDRUM since
2026-10-29; ext's machine 42; upstream docs/MD-BUILTIN.md) as a Pi blob, for a voice mod that is a client of the
companion's voice service. Tags: [code] read in source; [emu-qemu] run under qemu-aarch64 user mode; [I] reasoned.

**Status: the blob only.** The Rytm side waits for the machine slots (decided 2026-11-10: hold the Rytm side until
core ask 8 settles the slots). Without mod.toml the build skips this folder.

## Why a blob

mdkit's 30 voices are ports of the Machinedrum's own code (FM, PI physical models, TRX); the DSP library has nothing
like them, and only the code plays them exactly.

## The blob (blob/md_blob.c, built by blob/build.sh)

- mdkit (CC0) as upstream vendors it, compiled through upstream's glue (plugins/mdkit/mdk.c, MIT) exactly as
  upstream's core/engines/setup_engines.sh builds the built-in MD: MDK_FAM_MD, MDK_BUILTIN, the PI cymbals' delay
  memory windowed by patch_pi.py. The glue's state, 44.1-to-48 kHz resampler, TYPE fade and tail run unchanged;
  rendered in upstream's 12-sample blocks. 530 KB (mdkit's tables), no writable globals.
- Params 0..9 in core's knob order (knob 0 is H): LEV, TYP, C1..C6, then page 2's C7, C8.
  - TYP is one knob over all 30 sets (FM BD SD XT CP RS CB HH CY, PI BD SD MT ML MA RS RC CC HH, TRX BD SD XT CP RS
    CB CH OH CY MA CL XC B2; zone = value x 30 / 128). Upstream's Rytm page has ENGINE and TYPE as two knobs; the
    blob hands mdk.c the ENGINE and TYPE values whose zones name the same set, so what plays is upstream's.
  - A Rytm page: A TYP, B..G controls 1..6, H LEV; page 2 (the companion's page 19) controls 7, 8. Their labels
    follow the set: upstream's plugins/mdkit/md_tables.h has every set's short labels (4 characters), MIT, to copy
    into the Rytm mod.
- The velocity is the hit's level; the note is ignored (PTCH is a control); a release does nothing, as upstream.

## Payload room (2026-11-11)

Packed with elekloader's aplib (the main OS's packer), the payloads are PLAITS 138 KB, DAISYSP 72 KB, JUNO 10 KB,
6-OP FM 140 KB, MD 287 KB: 648 KB for the five, against the OS file's flash budget of about 1 MB with core alone
(ADAPTING.md "Payloads"; the 5 MB DDR area is not the limit) [code: packed here, not linked]. A build with all of them,
the companion and DSP SAMPLE is the real check; if it is short, 6-OP FM and PLAITS carry the same Plaits code twice
(one blob could serve both) and MD -Os saves 28 KB.

## Not carried over (gaps)

- Upstream's DIGIDRUM migration (old sounds with DIGIDRUM's page): no stored sounds exist on this machine yet.
- The Rytm side's per-set labels need a label function on the machine's own records (core_param_locks on record ids)
  [I: to check in core-ar2 0.13].

## Tests

- `make -C core test-aarch64 SCX_TGAIN=... SCX_MD=<blob/build/md.scx>` in sidecar-firmware (branch
  juno-md-fm-voices): shipped, placed, routed, silent before a trig; each of the 30 sets sounds on a trig (peaks
  0.09..0.92) and is silent 2 s later, all finite; a TYP p-locked on the trig sounds at once [emu-qemu].
- Not yet: the Rytm side, the emulator gate, a unit run, a listening check against upstream.
