# 0034-daisysp: DAISYSP on the Sidecar's generic engine (design and status, 2026-11-10)

The second of ext's voices (0021-ext, design.md "PLAITS and DAISYSP", "DAISYSP's INP", "NAT and NOISE") moved onto
core-ar2 0.13 and the companion's services, as its own client mod (Connor's plan, 2026-11-07). Tags: [code] read in
source; [test] a host test; [emu-qemu] run under qemu-aarch64 user mode; [I] reasoned, not shown.

## What the user sees

DAISYSP (DSP) in every track's machine list, slot 51 (CY TEST's). Its SRC page:

| knob | label | range | default | to the blob |
|---|---|---|---|---|
| A | ENG | 0..127 | 0 | the model, 3 zones: MODL STRG RESN (shown by name) |
| B | STR | 0..127 | 64 | structure (MODAL / RESON: the modes' spread; STRING: its non-linearity) |
| C | BRI | 0..127 | 64 | brightness |
| D | DMP | 0..127 | 64 | damping |
| E | INP | 0..127 | 0 | the exciter, 11 zones: INT NAT NOIS BD SD RS BT LT MT CH CY (shown by name) |
| F | EXC | 0..127 | 64 | the exciter's gain (unity at 64); INT: caps the strike's accent |
| G | TUN | 32..96, centred | 64 | semitones added to the trig's note |
| H | LEV | 0..127 | 100 | output level (unity at 100) |

Zones and order are ext's (ENG MODAL STRING RESON after DRIP went; INP's eleven zones), so a sound saved with ext's
DAISYSP on slot 51 keeps its meaning, except LEV, which core puts first (sound index 9).

- **INT**: the model's own exciter: Plaits' modal voice's mallet (MODAL), its string voice's noise pluck (STRING), a
  1 ms noise click (RESON), on each trig, its accent the trig's velocity.
- **NOISE**: a noise burst on each trig (about 30 ms), into the model. ext ran stock's UT NOISE on the voice for it;
  here it is the blob's own, so it needs no stock engine [I: close enough in use; not compared by ear].
- **BD..CY**: that voice's Overbridge stem (before its volume, as measured on ext in rytm-emu) rings the model: the
  companion's voice service routes the stem onto the block's input L. The DAISYSP track's own voice is refused by the
  Pi as a loop (the stem carries what the Pi returns to it): no input, and silent unless trigged on INT.
- **NAT**: plays as INT for now (see "Gaps").

## How it works

- **Rytm** (daisysp.c): one `core_machines` entry, slot 51, home -1, every voice; its engine is the companion's
  `sc_voice_engine` with an `input` function: INP's zone 3..10 is Overbridge IN 2..9 (the stems in track order), the
  rest none. A `core_params` text entry on records 450..454 names ENG (450) and INP (454); get and turn stay stock's.
- **Companion** (sidecar-core pi-voices ce50175, voice.c "Input"): the second point, stem onto the block's input L,
  kept by ev_tick (ROUTE, UNROUTE + ROUTE on a change, UNROUTE for none; a refused one is not asked again until INP
  changes). Generic: any voice machine may name an IN channel, AUDIO IN 10/11 included.
- **Blob** (blob/daisysp_blob.cc, built by blob/build.sh from Mutable's eurorack at 08460a6, only
  plaits/dsp/physical_modelling and stmlib): ModalVoice and StringVoice for INT, Resonator (position 0.015 for MODAL,
  0.25 for RESON) and String for an outside exciter. A new ENG or INP resets the model. 132 KB, deterministic; its
  writable part (stmlib's Random seed) on its own 64 KB unit (SCX_F_DATA).
- **Shipping**: the blob is this mod's `.payload`, contributed to the companion's `sc_code` with owner 0x51.

The name stays ext's, DAISYSP, though the code is Plaits' own: DaisySP's modal, string and resonator voices are ports
of these Plaits classes, and ext's host ran DaisySP's.

## Gaps it found

- **NAT needs any stock machine's engine and its defaults** (core-ar2): ext's NAT ran the track's default machine (BD
  HARD on BD, SD HARD on SD, CH on CH, ...) on the voice instead of DISABLE, with a parameter block from that machine's
  record defaults, so the voice sounds as itself and excites the model. 0.13 exports five stock engines
  (`CORE_ENGINE_BD_CLASSIC`, `_SD_CLASSIC`, `_BT_CLASSIC`, `_XT_CLASSIC`, `_DISABLE`), not the default machine of
  each track nor its records' defaults. Proposed to the core-needs list (thread "Collate core updates Sidecar needs").
- **NAT also needs a loop** (sidecar-firmware route): with NAT the voice's own stem is the exciter and the resonance
  goes back into that voice (ext's OUT = VOICE, kept from running away by FB). The Pi's route refuses a point that
  closes a loop ("feedback lives inside a block"). NAT can work without it only with the resonance on MAIN (ext's
  OUT = MAIN), which needs a second output point and a knob for it.
- **Page 2 (ext's EXCITER: OUT FB XLV XTN XDC XP4 XP5 WID)** is not carried over: ext put it on other TEST machines'
  records, which 0.13 gives to the machines in those slots. A voice machine's second page needs knobs of its own
  (0.13's `"knobs": n` ids from 555, a page through `core_view_pages`, values per sound in the companion's sound
  records, locks through `core_param_locks`). Same gap as PLAITS's page 2; one design for both is the next step.
- Slot 51's records have no LFO, velocity or aftertouch destination (core-ar2 0.13 leaves +0x24 at 0 on TEST
  records); asked in the core-needs list (item 1 of elekloader-sidecar-core-needs-0.13.md).

## Tests

- Companion: `make -C companion/test` in sidecar-core (test_voice: the input point follows the knob, moves, is
  refused as a loop once and not asked again, goes, and goes with the slot) [test].
- Pi + blob: `make -C core test-aarch64 SCX_TGAIN=... SCX_DAISYSP=<blob/build/daisysp.scx>` in sidecar-firmware
  (pi-voices a05211a): shipped, placed, routed onto CY/CB's input, silent before a trig; each model rings on INT
  (peaks 0.58 / 0.49 / 0.17) and NOISE (0.33 / 0.09 / 0.49), not from BD's stem until it is routed, then from it
  (0.34 / 0.05 / 0.43); all finite, none above 1 [emu-qemu].
- Not yet: a build with core 0.13 and the companion (needs the stock file), the emulator gate (records 450 / 454 and
  the 4-character names to confirm; the stem's level on 1.74), a unit run.
