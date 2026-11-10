#!/bin/bash
# Regenerate stub.s from dspsample.c (needs m68k-elf-gcc, and vendor/elekloader for core-ar2's machines.h). The stub's
# sections become elekloader's .run (build.py elek_source). Nothing shipped: its sound is the Pi's SAMPLE block.
set -e
cd "$(dirname "$0")"
${CC68K:-m68k-elf-gcc} -mcpu=5475 -msoft-float -Os -ffreestanding -fno-builtin -fomit-frame-pointer -fno-tree-loop-distribute-patterns -I../../vendor/elekloader/elekloader/sdk/include -S dspsample.c -o dspsample.s.tmp
{
  echo "| Mod 0035 - DSP SAMPLE, a Pi voice machine on slot 45, a client of the companion's voice service."
  echo "| GENERATED from dspsample.c by build.sh (m68k-elf-gcc -mcpu=5475 -Os); edit that."
  echo "	.include \"symbols.inc\""
  grep -v '^\s*\.section\s\+\.note' dspsample.s.tmp | sed -e 's/\.section\t\.text,"a"/.text/' -e 's/^\t\.section\t\.rodata[^\t]*\t*.*/\t.text/' -e 's/^\t\.data$/\t.text/'
} > stub.s
rm dspsample.s.tmp
