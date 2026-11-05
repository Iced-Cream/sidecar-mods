#!/bin/bash
# Regenerate stub.s from sfx.c (needs m68k-elf-gcc, and vendor/elekloader for core-ar2's pages.h). The stub's sections
# become elekloader's .run (build.py elek_source): this mod lives in the 128 KB DDR area only.
set -e
cd "$(dirname "$0")"
m68k-elf-gcc -mcpu=5475 -msoft-float -Os -ffreestanding -fno-builtin -fomit-frame-pointer -fno-tree-loop-distribute-patterns -I../../vendor/elekloader/elekloader/sdk/include -S sfx.c -o sfx.s.tmp
{
  echo "| Mod 0025 - SEND FX 1 and 2 as graphs of the Sidecar's DSP library, a client of the companion."
  echo "| GENERATED from sfx.c by build.sh (m68k-elf-gcc -mcpu=5475 -Os); edit that."
  echo "	.include \"symbols.inc\""
  grep -v '^\s*\.section\s\+\.note' sfx.s.tmp | sed -e 's/\.section\t\.text,"a"/.text/' -e 's/^\t\.section\t\.rodata[^\t]*\t*.*/\t.text/' -e 's/^\t\.data$/\t.text/'
} > stub.s
rm sfx.s.tmp
