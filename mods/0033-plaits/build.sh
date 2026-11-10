#!/bin/bash
# Regenerate stub.s from plaits.c (needs m68k-elf-gcc, and vendor/elekloader for core-ar2's machines.h). The stub's
# sections become elekloader's .run (build.py elek_source), except .payload: the PLAITS blob (blob/build/plaits.scx,
# built by blob/build.sh), copied beside the stub by build.py ([sources] payload).
set -e
cd "$(dirname "$0")"
${CC68K:-m68k-elf-gcc} -mcpu=5475 -msoft-float -Os -ffreestanding -fno-builtin -fomit-frame-pointer -fno-tree-loop-distribute-patterns -I../../vendor/elekloader/elekloader/sdk/include -S plaits.c -o plaits.s.tmp
{
  echo "| Mod 0033 - PLAITS, a Pi voice machine on slot 44, a client of the companion's voice service."
  echo "| GENERATED from plaits.c by build.sh (m68k-elf-gcc -mcpu=5475 -Os); edit that."
  echo "	.include \"symbols.inc\""
  grep -v '^\s*\.section\s\+\.note' plaits.s.tmp | sed -e 's/\.section\t\.text,"a"/.text/' -e 's/^\t\.section\t\.rodata[^\t]*\t*.*/\t.text/' -e 's/^\t\.data$/\t.text/'
  echo "| the blob, shipped by the companion's code service (sc_code entry in mod.toml)"
  echo "	.section .payload,\"a\""
  echo "	.balign 4"
  echo "	.global pl_scx"
  echo "pl_scx:"
  echo "	.incbin \"plaits.scx\""
} > stub.s
rm plaits.s.tmp
