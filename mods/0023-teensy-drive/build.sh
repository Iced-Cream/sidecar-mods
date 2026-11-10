#!/bin/bash
# Regenerate stub.s from teensy_drive.c (needs m68k-elf-gcc, and vendor/elekloader for core-ar2's moments.h). The
# stub's sections become elekloader's .run (build.py elek_source): this mod lives in elekloader's DDR area only.
set -e
cd "$(dirname "$0")"
m68k-elf-gcc -mcpu=5475 -msoft-float -Os -ffreestanding -fno-builtin -fomit-frame-pointer -fno-tree-loop-distribute-patterns -I../../vendor/elekloader/elekloader/sdk/include -S teensy_drive.c -o td.s.tmp
{
  echo "| Mod 0023 - teensy-drive: the Sidecar's card as a folder SIDECAR in the file browser, a client of the companion."
  echo "| GENERATED from teensy_drive.c by build.sh (m68k-elf-gcc -mcpu=5475 -Os); edit that."
  echo "	.include \"symbols.inc\""
  grep -v '^\s*\.section\s\+\.note' td.s.tmp | sed -e 's/\.section\t\.text,"a"/.text/' -e 's/^\t\.section\t\.rodata[^\t]*\t*.*/\t.text/' -e 's/^\t\.data$/\t.text/'
} > stub.s
rm td.s.tmp
