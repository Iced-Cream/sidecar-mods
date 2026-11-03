#!/bin/bash
# Regenerate stub.s from sidecar.c (which includes fxin.c; needs m68k-elf-gcc). The stub's sections become
# elekloader's .run (build.py elek_source): this mod lives in the 128 KB DDR area only.
set -e
cd "$(dirname "$0")"
m68k-elf-gcc -mcpu=5475 -msoft-float -Os -ffreestanding -fno-builtin -fomit-frame-pointer -fno-tree-loop-distribute-patterns -S sidecar.c -o sidecar.s.tmp
{
  echo "| Mod 0032 - the Sidecar companion: the host link's SysEx router over the table sc_cmds."
  echo "| GENERATED from sidecar.c + fxin.c by build.sh (m68k-elf-gcc -mcpu=5475 -Os); edit those."
  echo "	.include \"symbols.inc\""
  grep -v '^\s*\.section\s\+\.note' sidecar.s.tmp | sed -e 's/\.section\t\.text,"a"/.text/' -e 's/^\t\.section\t\.rodata[^\t]*\t*.*/\t.text/' -e 's/^\t\.data$/\t.text/'
} > stub.s
rm sidecar.s.tmp
