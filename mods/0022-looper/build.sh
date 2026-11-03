#!/bin/bash
# Regenerate stub.s from looper.c (needs m68k-elf-gcc), as 0021-ext does.
# Compiled twice: LP_SFX=1 (the looper's reports never wait on USB: a try-lock of the MIDI mutex) and 0 (they wait,
# as c127fe8); the build's param sfx (--defsym P_SFX) picks one with .if. Since the companion phase (2026-11-03) the
# host SysEx router is mods/0032-sidecar's; this mod registers its 07 / 08 there.
set -e
cd "$(dirname "$0")"
for v in 1 0; do
  m68k-elf-gcc -mcpu=5475 -msoft-float -Os -ffreestanding -fno-builtin -fomit-frame-pointer -DLP_SFX=$v -S looper.c -o looper$v.s.tmp
done
{
  echo "| Mod 0022 - looper mode: TRK + REC, pads as clip slots, reported to the USB host."
  echo "| GENERATED from looper.c by build.sh (m68k-elf-gcc -mcpu=5475 -Os, LP_SFX=1 and 0); edit looper.c."
  echo "	.ifne P_SFX"
  grep -v '^\s*\.section\s\+\.note' looper1.s.tmp | sed -e 's/\.section\t\.text,"a"/.text/' -e 's/^\t\.section\t\.rodata[^\t]*\t*.*/\t.text/'
  echo "	.else"
  grep -v '^\s*\.section\s\+\.note' looper0.s.tmp | sed -e 's/\.section\t\.text,"a"/.text/' -e 's/^\t\.section\t\.rodata[^\t]*\t*.*/\t.text/'
  echo "	.endif"
} > stub.s
rm looper1.s.tmp looper0.s.tmp
