#!/bin/bash
# Regenerate stub.s from daisysp.c (needs m68k-elf-gcc, and vendor/elekloader for core-ar2's machines.h). The stub's
# sections become elekloader's .run (build.py elek_source), except .payload: the DAISYSP blob (blob/build/daisysp.scx,
# built by blob/build.sh), copied beside the stub by build.py ([sources] payload).
set -e
cd "$(dirname "$0")"
${CC68K:-m68k-elf-gcc} -mcpu=5475 -msoft-float -Os -ffreestanding -fno-builtin -fomit-frame-pointer -fno-tree-loop-distribute-patterns -I../../vendor/elekloader/elekloader/sdk/include -S daisysp.c -o daisysp.s.tmp
{
  echo "| Mod 0034 - DAISYSP, a Pi voice machine on slot 51, a client of the companion's voice service."
  echo "| GENERATED from daisysp.c by build.sh (m68k-elf-gcc -mcpu=5475 -Os); edit that."
  echo "	.include \"symbols.inc\""
  grep -v '^\s*\.section\s\+\.note' daisysp.s.tmp | sed -e 's/\.section\t\.text,"a"/.text/' -e 's/^\t\.section\t\.rodata[^\t]*\t*.*/\t.text/' -e 's/^\t\.data$/\t.text/'
  echo "| the blob, shipped by the companion's code service (sc_code entry in mod.toml)"
  echo "	.section .payload,\"a\""
  echo "	.balign 4"
  echo "	.global ds_scx"
  echo "ds_scx:"
  echo "	.incbin \"daisysp.scx\""
} > stub.s
rm daisysp.s.tmp
