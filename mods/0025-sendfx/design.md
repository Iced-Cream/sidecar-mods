# 0025-sendfx: SEND FX 1 and 2 on the Sidecar's DSP library (design and status, 2026-11-05)

The send FX phase's Rytm mod (plan: the "Send FX phase: plan and picks" doc). It replaces 0025-sendfx-report and
0029-sendfx-ui, which are 1.73 mods; this one is for 1.74 on core-ar2 0.9, in elekloader's DDR area, and a client of
the companion (0032-sidecar). Tags: [code] read in source; [test] the host test below; [I] reasoned, not shown.

## What the user sees

| page key | added page | knobs |
|---|---|---|
| AMP on a voice track | AMPLITUDE 2 (page 16) | A SFX1, B SFX2: the track's sends, 0..127 |
| DELAY on the FX track | SEND FX 1 (page 17) | A TYPE, B ROUTE (PRE / POST), C..F P2..P5 |
| REVERB on the FX track | SEND FX 2 (page 18) | as SEND FX 1 |

TYPE is OFF, CHORUS, COMB, CRUSH, RINGMOD or ECHO (`sfx_types` in sfx.c). FUNC turns in steps of 8. Knob ids 560..573
(`core_params`), page ids 16..18; neither is stock's or another mod's in this repo [code].

## How it works

The effects are graphs of the Pi's DSP library (sidecar-firmware `core/dsp`, decided 2026-11-05). The Pi only knows
"a DELAY in slot 3"; this mod knows what CHORUS means.

| TYPE | blocks | P2..P5 |
|---|---|---|
| CHORUS | DELAY (short, modulated) | TIME, MOD DEPTH, MOD RATE, SPREAD |
| COMB | DELAY (very short, high feedback) | TIME, FEEDBACK, DAMP, TONE |
| CRUSH | SHAPER | DRIVE, BITS, RATE, LEVEL |
| RINGMOD | MOD | RATE, DEPTH, SHAPE, PHASE |
| ECHO | DELAY into FILTER (low-pass) | TIME, FEEDBACK, CUTOFF, SPREAD |

Each new session (`sc_link_epoch`), for each FX not OFF:

1. **PLACE** its blocks (any free slot), wait for the slots (`sc_dsp_result`).
2. **ROUTE**: a chain point per channel between two blocks; the return, the last block's L and R onto OUT 2/3 (PRE,
   through the Rytm's distortion and compressor) or OUT 0/1 (POST); and the sends, each voice stem (IN 2..9) into the
   first block's L and R. One FX at a time and at most 12 in flight, because the companion keeps the last 16 answers.
   A voice's L and R are asked one after the other, so they come out as adjacent points.
3. **Lock sets**: one per block on its params, on the FX track (sets 0..3: FX f's block b = 2f + b), and one per
   (track, FX) on the voice's two send points, target 64 (sets 8..31: 8 + 2t + f). Each gets its bases.

A shared voice (RS/CP, MT/HT, CH/OH, CY/CB) has one pair of send points that both tracks' sets lock, so the last trig
wins [I]. A base change is one BASE op. P1 re-aims the return points with MOVE. A TYPE change frees the FX's slots (the
Pi fades their points out and closes them), drops its sets and builds the new graph. Something refused or unanswered
for 90 ticks marks the FX failed; it is freed and built again 90 ticks later.

Lock sets 8..31 and 0..3 replace the plan's default of 8..20: the per-track send sets need 24, because a set covers
contiguous params and a track's points for the two FX aren't adjacent. storetest (test builds only) keeps 5..7.

Points per session: 8 stems x 2 channels x 2 FX = 32 sends, 4 returns, 2 per two-block graph: 38 with ECHO, of the
Pi's 64.

## Where the values live

The sends are the sound's, as stock's DELAY and REVERB sends are (decided 2026-11-07): each track's two sends are
section 25 of its sound's record on the Pi (the companion's sound records, the sound handle claim approved
2026-11-07), 2 bytes, `[f]` the send to FX f. A sound handle lives in the sound's own bytes, so the sends go wherever
the sound goes: sound copy and paste, a save to the pool, a pool sound loaded into a track, another kit's sound. A
turn puts the section at once; the companion writes the record once the turns stop (12 ticks).

The FX are the kit's: section 25 of the kit's record (`sc_kit_get` / `sc_kit_put`, the kit handle claim approved
2026-11-05), 12 bytes, `[6f]` FX f's TYPE, P1, P2..P5, written back 12 ticks after the last turn. A kit with no
section gets the defaults: FX 1 ECHO, FX 2 CHORUS, P2..P5 64, PRE; a sound with no section sends 0.

Until 2026-11-07 the sends were in the kit's section too (36 bytes: `[2t + f]` the sends, then the FX at `[24 + 6f]`),
because only the kit handle had been claimed when the values moved onto the Pi. A kit section of that layout still
gives its FX; its sends are not read (they were only in test projects).

After a kit change or a sound loaded into a track, the track's sends arrive when its sound's record has loaded, a few
ticks later [I].

## P-locks (part 2)

Decided 2026-11-05: Pi locks with the mod's own entry, rebuilt on the Pi rather than taking core's limited lock rows
and codes. With a trig held, stock walks every held trig and calls the parameter set's lock functions with the step;
core-ar2 0.11 (`core_param_locks`, a local core change collected in the elekloader handoff) hands those for ids
560..573 to `sfx_locks`: `get`, `turn`, `set` and `clear`, each with the track and the step [code].

- A lock is a LOCK op in the knob's set on the Pi: a send on its track's send set (both points, L and R), P2..P5 on
  the block param the TYPE maps it to. TYPE and ROUTE take none; a send off a voice track or a P off the FX track
  neither. The first turn starts from the knob's value; the knob's own value stays.
- The locks live in the mod's section (25) of the playing pattern's record on the Pi (the companion's rec.c):
  `[0] 1`, then `{<key> <step> <value>}`, key `2t + f` for a send, `24 + 4f + j` for FX f's P(2 + j); 300 at most.
- When the pattern's record loads (another pattern plays, a project load) and when an FX's sets are declared, the FX's
  sets get CLEAR 7F 7F on the Pi and its locks are sent again, 24 ops a tick at most.
- A TYPE change keeps the P locks; they then lock the new TYPE's params [I, as stock keeps a slot's locks].
- After a pattern switch the new pattern's locks arrive when its record has loaded, so its first steps may play the
  old ones [I]. A shared voice's points are locked by both tracks' sets: the last trig wins [I].

## Not yet

- **Knob labels.** These ids aren't lockable params, so stock labels the knobs ERR, names them ERROR in the header
  pop-up and shows ERR as the value with a trig held [code, core-ar2 README]. A label, name and held-trig value
  hook in core is the fix (handoff item 2).
- **Held-trig calls for ids above 554.** The ids sit above core's pseudo ids (469..554, lock.c), so they can't be
  taken for a lockable param's LFO slot. lock-check uses borrowed stock ids; whether stock calls the lock functions
  for 560..573 at all, or checks the id against the set first (vtable +36) and drops the turn, is to check in the
  emulator. If it drops them, core needs that hook too.
- **Step edits.** Clearing, copying, pasting, shifting or undoing a trig, and reloading a pattern, doesn't move its
  Pi locks yet (handoff item 3, to follow core's step-record ledger).
- **The FX's slots while PLACE answers are pending** leak until the next session if TYPE changes in that window [I].
- **A status member** for the Pi's /status (`sfx_diag` holds the counters).

## Tests

`make -C mods/0025-sendfx/test FIRMWARE=<sidecar-firmware>`: sfx.c through the companion against the Pi's store,
locks, route and DSP library (sidecar-firmware branch send-fx). It covers the defaults built at link-up (two DELAYs
and a FILTER, 32 send points, the chain, the returns, 27 sets), a send's gain, an SD hit returning as ECHO's repeat on
MAIN FX and not straight away, P1 POST, a TYPE change (CHORUS to CRUSH), P2 as a block's base, the kit section and the sounds' sends written
and read back across kits, a send going with its sound into another kit and track, an old-layout kit section, p-locks (a P2 and a send lock on the Pi, TYPE/ROUTE and off-track refused, the pattern
record written, another pattern's own locks, back again, a clear, a new session sending them again), and a new
session. [test] PASS 2026-11-05.

Build: `ELEK_CORE_WORKTREE=1 tools/build.py --tag sfx2 --mods 0032-sidecar 0025-sendfx` (the companion from vendor/sidecar-core; once with `--param 0032-sidecar:clock=1`, now always in)
links core 0.10 (the working tree's), the companion and this mod (61628 bytes of the DDR area spare) and
tools/verify.py passes [code, 2026-11-05]. ELEK_CORE_WORKTREE is for test builds only.

Not done: the emulator gate and a unit run (they need the stock firmware, on the PC).
