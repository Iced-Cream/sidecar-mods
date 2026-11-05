#!/usr/bin/env python3
"""The companion phase's capture comparison (sidecar-core companion/design.md): one scripted host session, played into two
builds in rytm-emu, and every byte each Rytm sends the USB host recorded and compared message by message.

    .venv/bin/python tools/emu/cap_emu.py TAG_A TAG_B [--gone 30-3f] [--new 2c,2d,51]

        exit 0 when the two captures match (but the expected)

Each TAG needs its base (tools/emu/us_base.sh TAG). The host's SysEx goes in with dtboot --usb-midi at fixed clocks (no
live host: the session is the same instruction for instruction in both runs), keys and turns with --press / --turn;
the Rytm's USB MIDI is what dtboot's USB MIDI sender hooks took (DTBOOT_USB_OUT, every byte; rytm-emu 4177ad4 on). The session covers what the core
0.9 build keeps: the hello (35), the FX return (26 / 27) and its mix report (50), the remote screen (3A open / close,
38 / 39 a frame, 3C keepalives, 31 keys, 32 turns, 30 page reports, 33 / 3B snapshots, 36 the splash), and one 2E (the
seq link, left out of the 0.9 build: its answers are an expected difference). DIN MIDI is not compared: nothing in
the session sends on DIN.

Messages are compared in order per command byte. TAG_A is the old set (the core 0.1 release: 0014, 0021, 0022, 0023,
0025 / 0029, the full 0026, 0030, 0032), TAG_B the core 0.9 set (0026 screen, 0027, 0032). A difference is EXPECTED
only when it is the hello's caps byte (the screen build says 1, the full 0026 15), or a command outside what the 0.9
set keeps (26 / 27, 30..3F, 50) that TAG_B never sends: those come from the mods and 0026 parts left out (0021's 10..19,
send FX 20..25, 0026's 29..2D, 45, 49, 4B..4E). Every kept command must match byte for byte, and TAG_B sending a
command TAG_A did not is a failure. RYTM_EMU: rytm-emu's checkout.

--gone: commands TAG_B may stop sending altogether (a mod left out of the set: 2026-11-04 the remote screen 0026 out of
the release, --gone 30-3f); every other kept command must still match byte for byte. The FX return's 26 / 27 / 50 left
the companion on 2026-11-04: no longer kept.
--new: commands TAG_B may send that TAG_A never sent (a service new in TAG_B: 2026-11-04 the store link and step
clock, --new 2c,2d,51); listed with their first message, not compared. A command TAG_A sent stays compared.
"""
import collections
import json
import os
import re
import subprocess
import sys

EMU = os.environ.get("RYTM_EMU", "../rytm-emu")
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
KEPT = {*range(0x30, 0x40), 0x2c, 0x2d, 0x51}
# strict lines stock 1.74 itself gives in rytm-emu 4177ad4 (the same run on the stock .syx; not the mods'). With
# DTEMU_STRICT=1 that write raises an access error and the OS hangs (stock too), so the runs list only (=log).
KNOWN_STRICT = ("strict: pc 40121206 write page 00000000", "strict: pc 401218c8 read  page 00000000")


def sx(cmd, *body, ver=True):
    return "f07d5254%02x" % cmd + ("01" if ver else "") + "".join("%02x" % b for b in body) + "f7"


# one 8-byte column of framebuffer bytes, packed (unpack_rect: groups of up to 7, each a byte of their MSBs first)
RECT = [1, 0, 0, 1, 1] + [0] + [0x11, 0x22, 0x33, 0x44, 0x55, 0x66, 0x77] + [0] + [0x08]

# (M instructions after the base, kind, value)
SESSION = [
    (700, "sx", sx(0x26, 0x7f, ver=False)),          # FX IN: ask
    (800, "sx", sx(0x26, 0x01, ver=False)),          # FX IN: on
    (900, "sx", sx(0x3c)),                           # keepalive (a valid 3x: the hello stops repeating)
    (1000, "sx", sx(0x3a, 0, 1)),                    # open the page (host)
    (1020, "sx", sx(0x38, *RECT)),                   # a rectangle into staging
    (1030, "sx", sx(0x39, 1)),                       # commit it
    (1080, "sx", sx(0x3c)),
    (1100, "press", "T1"),                           # a caught key: 31 down / up
    (1150, "turn", "0:1", 3),                        # encoder 0, +1 three times: 32
    (1180, "sx", sx(0x3c)),
    (1280, "sx", sx(0x3c)),
    (1300, "sx", sx(0x3a, 0, 0)),                    # close the page (host)
    (1400, "sx", sx(0x36, 20)),                      # the splash, 1 s
    (1450, "sx", sx(0x3c)),
    (1600, "sx", sx(0x26, 0x00, ver=False)),         # FX IN: off
    (1700, "sx", sx(0x2e, 0x01, 0x00, 0x00)),        # the seq link (left out of the 0.9 build)
    (1720, "press", "TRK", 60),                      # TRK + YES: the page opens by the user
    (1730, "press", "YES"),
    (1900, "press", "TRK", 60),                      # TRK + YES again: out
    (1910, "press", "YES"),
]
LENGTH = 2200


def capture(tag):
    clock = json.load(open(os.path.join(EMU, f"sections/us_{tag}.json")))["clock"]
    raw = os.path.join(ROOT, "build", f"cap_{tag}.bin")
    if os.path.exists(raw):
        os.remove(raw)
    cmd = ["./target/release/dtboot", f"fw/AR174_us_{tag}.syx", "--load", f"sections/us_{tag}.snap",
           "--card", f"sections/us_{tag}.img", "--instr", f"{LENGTH}M", "--every", "100M", "--usb-host",
           "--usb-midi-real"]
    for e in SESSION:
        t = clock + e[0]
        if e[1] == "sx":
            cmd += ["--usb-midi", f"{e[2]}@{t}M"]
        elif e[1] == "press":
            cmd += ["--press", f"{e[2]}@{t}M" + (f":{e[3]}M" if len(e) > 3 else "")]
        elif e[1] == "turn":
            cmd += ["--turn", f"{e[2]}@{t}Mx{e[3]}/4M"]
    r = subprocess.run(cmd, cwd=EMU, env=dict(os.environ, DTEMU_STRICT="log", DTBOOT_USB_OUT=raw),
                       capture_output=True, text=True)
    out = r.stdout + r.stderr
    strict = [l for l in out.splitlines() if l.startswith("strict:") and not l.startswith(KNOWN_STRICT)]
    fault = r.returncode != 0 or "FAULT" in out or bool(strict)
    return (open(raw, "rb").read() if os.path.exists(raw) else b""), fault, out


def messages(midi):
    """The Rytm's SysEx to the host, in order: [(cmd, hex)]; other bytes as ('-', hex)."""
    h = midi.hex()
    return [(int(m.group(1), 16), m.group(0)) for m in re.finditer(r"f07d5254([0-9a-f]{2})(?:[0-7][0-9a-f])*f7", h)]


def main():
    a, b = sys.argv[1:3]
    gone = set()
    if "--gone" in sys.argv:
        for part in sys.argv[sys.argv.index("--gone") + 1].split(","):
            lo, _, hi = part.partition("-")
            gone |= set(range(int(lo, 16), int(hi or lo, 16) + 1))
    new = set()
    if "--new" in sys.argv:
        new = {int(x, 16) for x in sys.argv[sys.argv.index("--new") + 1].split(",")}
    caps = {}
    for tag in (a, b):
        midi, fault, out = capture(tag)
        open(os.path.join(ROOT, "build", f"cap_{tag}.hex"), "w").write(midi.hex() + "\n")
        open(os.path.join(ROOT, "build", f"cap_{tag}.dt.txt"), "w").write(out)
        caps[tag] = messages(midi)
        print(f"{tag}: {len(midi)} bytes, {len(caps[tag])} messages, dtboot {'FAULT' if fault else 'clean'}")
        if fault:
            print("FAIL: dtboot", tag)
            return 1
        if not caps[tag]:
            print("FAIL: nothing captured from", tag)
            return 1
    by = {t: collections.defaultdict(list) for t in caps}
    for t, ms in caps.items():
        for c, m in ms:
            by[t][c].append(m)
    bad = 0
    for c in sorted(set(by[a]) | set(by[b])):
        ma, mb = by[a].get(c, []), by[b].get(c, [])
        if ma == mb:
            print(f"  same      {c:02x}  x{len(ma)}")
            continue
        if c == 0x35 and len(ma) == len(mb) and all(x[:-4] == y[:-4] for x, y in zip(ma, mb)):
            print(f"  expected  35  x{len(ma)}: caps {ma[0][-4:-2]} -> {mb[0][-4:-2]}")
            continue
        if c in gone and not mb:
            print(f"  expected  {c:02x}  {len(ma)} -> 0 (--gone: left out of {b})")
            continue
        if c in new and not ma:
            print(f"  new       {c:02x}  0 -> {len(mb)} (--new), first {mb[0]}")
            continue
        if c not in KEPT and not mb:
            print(f"  expected  {c:02x}  {len(ma)} -> 0 (from a part left out of the 0.9 set)")
            continue
        bad += 1
        print(f"  DIFFERS   {c:02x}  {len(ma)} vs {len(mb)}")
        for x, y in list(zip(ma, mb))[:4]:
            if x != y:
                print(f"     {a}: {x}\n     {b}: {y}")
        if len(ma) != len(mb):
            print(f"     {a} first: {ma[:2]}\n     {b} first: {mb[:2]}")
    print("PASS" if not bad else f"FAIL: {bad} command(s) differ")
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
