# 0033-plaits: PLAITS on the Sidecar's generic engine (design and status, 2026-11-10)

The first of ext's voices (0021-ext, a 1.73 mod with fixed addresses and the old Pi engine's voices) moved onto core-ar2
0.13 and the companion's services, as Connor's plan for ext asks (2026-11-07): each voice group its own client mod,
the shared plumbing in the companion. Tags: [code] read in source; [test] a host test; [emu-qemu] run under
qemu-aarch64 user mode; [I] reasoned, not shown.

## What the user sees

PLAITS (PLTS) in every track's machine list, slot 44 (BD TEST's). Its SRC page:

| knob | label | range | default | to the blob |
|---|---|---|---|---|
| A | ENG | 0..127 | 0 | the model: 17 zones (value x 17 / 128) |
| B | HRM | 0..127 | 64 | harmonics |
| C | TIM | 0..127 | 64 | timbre |
| D | MOR | 0..127 | 64 | morph |
| E | DEC | 0..127 | 64 | decay |
| F | LPG | 0..127 | 64 | LPG colour |
| G | TUN | 32..96, centred | 64 | semitones added to the trig's note |
| H | LEV | 0..127 | 100 | output level (unity at 100) |

ENG's zones are ext's curated pick (design.md of 0021, "Curated models"): VA VCF, PHASE DIST, WAVE TERRAIN, STRING
MACH, CHIPTUNE, VA, WAVESHAPE, 2-OP FM, GRANULAR, HARMONIC, WAVETABLE, CHORDS, SPEECH, SWARM, PARTICLE, STRING,
MODAL (Plaits engines 0, 1, 5..16, 18..20; the 6-OP FM, NOISE and the drums are not offered).

## How it works

- **Rytm** (plaits.c): one `core_machines` entry, slot 44, home -1, every voice; its engine is the companion's
  `sc_voice_engine` (sidecar-core companion/voice.c, design.md "Pi voices"): DISABLE, then the voice's trigs (TRIG
  37 with the eight knob words) and knob changes (PARAM 38) to its Pi block from the audio interrupt. The knobs are
  BD TEST's records (sound indices 9..16), so stock stores, p-locks and slides them: no core claim but the slot.
- **Blob** (blob/plaits_blob.cc, built by blob/build.sh from Mutable's eurorack at 08460a6): one Plaits voice per
  slot, mono, written to both slot outputs. Params 0..7 = the knob words >> 2 (value x 64). A trig (src 0x7F, 0x90)
  sets the note and fires Plaits' trigger on the next render. 200 KB; its writable part (stmlib's Random seed) on its
  own 64 KB unit (SCX_F_DATA, `--writable`).
- **Shipping**: the blob is this mod's `.payload` (core-ar2 0.11 payloads), contributed to the companion's `sc_code`
  with owner 0x44; the companion offers it at each link epoch, and the voice service PLACEs it once the Pi has it.

## Limits

- Slot 44's records have no LFO, velocity or aftertouch destination (core-ar2 0.13 leaves +0x24 at 0 on the TEST
  records) [code, core-ar2 README]: the LFO can't reach PLAITS's knobs.
- ENG shows a number, not the model's name (a value text through core_params is a follow-up).
- The note is the engine's pitch argument's integer part; on 1.74 its format is [I] (ext measured 16.16 on 1.73).
- No release (0.13's latch reports trigs only); PLAITS rings out on its own decay and the voice's amp envelope.
- Page 2 (ext's TMD MMD FM AUX / FIN VEL GLD VOL on SMPL) is not carried over.

## Tests

- Companion: `make -C companion/test` in sidecar-core (test_voice: placement, routing, trigs with their knobs, PARAM,
  re-placement) [test].
- Pi + blob: `make -C core test-aarch64 SCX_TGAIN=... SCX_VOICE=<blob/build/plaits.scx>` in sidecar-firmware
  (pi-voices): shipped, placed, routed onto BD's input, silent before a trig, sounding on it, finite in all 17 zones
  [emu-qemu].
- Not yet: a build with core 0.13 and the companion (needs the stock file), the emulator gate, a unit run.
