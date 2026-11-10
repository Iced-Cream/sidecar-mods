# 0035-dspsample: DSP SAMPLE on the Sidecar's generic engine (design and status, 2026-11-10)

The third of ext's voices (0021-ext, design.md "DSP SAMPLE", "MOD knob", "1045", "7h") moved onto core-ar2 0.13 and
the companion's services, as its own client mod (Connor's plan, 2026-11-07). Connor's pick (2026-11-10): the Pi gets
a generic sample service and a SAMPLE library block, which DSP SAMPLE uses and MULTISAMPLE, CHOP and the looper may
later. Tags: [code] read in source; [test] a host test; [I] reasoned, not shown.

## What the user sees

DSP SAMPLE (DSPS) in every track's machine list, slot 45 (SD TEST's). SD TEST has records for sound indices 9..12, 15
and 16 only, so its SRC page has six knobs:

| knob | label | range | default | to SAMPLE |
|---|---|---|---|---|
| A | SMP | 0..127 | 0 | the pool entry: 0 OFF, n entry n - 1; shows the file's name |
| B | TUN | 40..88, centred | 64 | semitones from 64, added to the trig's note's distance from C4 |
| C | STA | 0..127 | 0 | start, over the sample's length |
| F | END | 0..127 | 127 | end; before STA plays backwards |
| G | LOP | 0..1 | 0 | 1: loop STA..END |
| H | LEV | 0..127 | 100 | output level (unity at 100) |

The trig's note (the sequencer's or a played one) sets the pitch: C4 plays the file at its own rate. The Rytm's own
filter, overdrive and amp shape it, as on every Pi voice.

## How it works

- **Rytm** (dspsample.c): one `core_machines` entry, slot 45, home -1, every voice; its engine is the companion's
  `sc_voice_engine` with block "SAMPLE" (the library's, nothing shipped) and `words` {0, 1, 2, 3, 6, 7}: the six
  knob words go as SAMPLE's params 0..5. A `core_params` text entry on record 417 shows SMP's file name from the
  companion's sample client (`sc_sample_name`), cut at the extension and to 7 characters, "!" first when the Pi could
  not load it, the number while the name is not known yet.
- **Companion** (sidecar-core pi-voices c6a9af4): voice.c's `words`; samples.c, the sample client (add, drop, a cache
  of names and states).
- **Pi** (sidecar-firmware sample-service 5093cae): core/samples, the project's pool (128 entries, kept per project ID
  on the card, each WAV loaded whole into a 96 MB arena); core/dsp/sample.h, SAMPLE.

## How samples get into the pool

`sc_sample_add(owner, "/Samples/...")` from any client mod. DSP SAMPLE itself adds none: the card browser
(teensy-drive, thread "Move teensy-drive onto sidecar-core 0.13") is the place to pick a file from the Pi's card and
LOAD TO PROJ it, as ext's pool did. Until it does, a pool can be filled only by a client that calls the add.

## Page 2

Behind the SRC key (2026-11-10, Connor's pick): the companion's voice page (its page id 19, shared by every voice mod)
shows "DSP SAMPLE 2" on the track that runs it (SD). Knobs: FIN (cents, bipolar), VEL (velocity onto level: SAMPLE's P7), on this mod's own knob ids (core-ar2 0.13 `knobs = 2`). The values
are the sound's (this mod's section 35 of the companion's sound record), 0..127, sent to the Pi as the block's params 6, 7 (FIN, VEL)
in every trig and when they change. No p-locks on page 2 yet [code]. Whether stock's SRC key steps to a listed page on
1.74 is [I] (ext measured a second SRC press opening the machine list): the emulator gate checks it.

## Not carried over from ext (yet)

- The resonator (ext's ENG STR BRI DMP MIX FB on the SRC page): a graph of SAMPLE into a resonator block, once the voice
  service places a chain and SD TEST's six records have room (page 2).
- MOD's seven modes (ONE LOOP SLICE GRAIN STRCH PLUCK WAVE): SAMPLE has one shot and loop only.
- SMP banks (ext's record 441, index << 8 | bank << 5): the pool is 128 entries, SMP's range.

## Tests

- Pi: `make -C core test` in sidecar-firmware (sample-service): test_samples, the pool ops, each WAV format, the list per
  project, a full arena, SAMPLE's one shot, loop, backwards, pitch, OFF, stereo [test]; also under qemu-aarch64.
- Companion: `make -C companion/test` in sidecar-core with FIRMWARE at sample-service: test_voice's word map and the
  sample client against the Pi's service [test].
- Not yet: a build with core 0.13 and the companion (needs the stock file), the emulator gate (record 417, the name's
  fit), a Pi kernel build, a unit run.
