#!/bin/bash
# Regenerate stub.s from rui.c (needs m68k-elf-gcc), as 0029 does. The stub's sections become elekloader's .run
# (build.py elek_source); .comm/.bss stays .bss in the area: this mod lives in the 128 KB DDR area only.
set -e
cd "$(dirname "$0")"
# Compiled twice: the whole mod, and RUI_SCREEN (the param screen: the remote screen only, 30..3F; rui.c's head). The
# screen build drops the static code only the left-out features used, so their unused-function warnings are expected.
CC="m68k-elf-gcc -mcpu=5475 -msoft-float -Os -ffreestanding -fno-builtin -fomit-frame-pointer -fno-tree-loop-distribute-patterns -Wall -Werror"
$CC -S rui.c -o rui0.s.tmp
$CC -DRUI_SCREEN -Wno-unused-function -Wno-unused-variable -Wno-unused-but-set-variable -S rui.c -o rui1.s.tmp
clean() {
  grep -v '^\s*\.section\s\+\.note' "$1" | sed -e 's/\.section\t\.text,"a"/.text/' -e 's/^\t\.section\t\.rodata[^\t]*\t*.*/\t.text/' -e 's/^\t\.data$/\t.text/'
}
{
  echo "| Mod 0026 - remote UI: the Rytm as a terminal for Sidecar-drawn pages (M1)."
  echo "| GENERATED from rui.c by build.sh (m68k-elf-gcc -mcpu=5475 -Os; screen=1: -DRUI_SCREEN); edit rui.c."
  echo "	.ifne P_SCREEN"
  clean rui1.s.tmp
  echo "	.else"
  clean rui0.s.tmp
  echo "	.endif"
} > stub.s
rm rui0.s.tmp rui1.s.tmp
