#!/bin/bash
# blob/build.sh - MD's Pi blob: build/md.scx, the upstream Sidecar's built-in MD (voice byte 0x40 since 2026-10-29, in
# place of DIGIDRUM): mdkit's 30 Machinedrum voices (soejrd/mdkit, CC0 1.0, as upstream vendors it in third_party/mdkit)
# through upstream's MD glue (plugins/mdkit/mdk.c, MIT, compiled as upstream's core/engines/setup_engines.sh compiles
# the built-in: MDK_FAM_MD, MDK_BUILTIN, its PI cymbals windowed by plugins/mdkit/patch_pi.py), with md_blob.c as one
# SCX block (sidecar-firmware core/code/scx.h), packed by sidecar-core's tools/scxpack.py. Sources at
# tools/sidecar_upstream.sh's commit. Built files and the fetched sources are never committed (vendor/, build/).
#   FIRMWARE=<sidecar-firmware checkout (core/code/scx.h)>  SIDECAR_CORE=<sidecar-core checkout>
# Needs clang and ld.lld.
set -e
cd "$(dirname "$0")"
FW=${FIRMWARE:-../../../../sidecar-firmware}
SC=${SIDECAR_CORE:-../../../vendor/sidecar-core}
UP=vendor/sidecar-upstream
../../../tools/sidecar_upstream.sh "$UP"
# upstream's MDKit/ layout (setup_engines.sh): mdkit's voices flat, the PI cymbals windowed, the glue in glue/
M=build/MDKit
rm -rf "$M"; mkdir -p "$M/glue/rmp"
cp "$UP"/third_party/mdkit/include/*.h "$M/"
for f in "$UP"/third_party/mdkit/src/*/*/mdkit_*.[ch]; do cp "$f" "$M/"; done
for v in rc cc hh; do python3 "$UP/plugins/mdkit/patch_pi.py" "$UP/third_party/mdkit/src/pi/$v" "$M" "$v" >/dev/null; done
cp "$UP"/plugins/mdkit/{mdk.c,families.h,mdk_tap.h,mdk_fir.h,md_tables.h} "$M/glue/"
cp "$UP/sdk/rmp/rmp_api.h" "$M/glue/rmp/"
CF="--target=aarch64-linux-gnu -std=c11 -O2 -fPIC -fno-plt -fvisibility=hidden -fno-asynchronous-unwind-tables
 -fno-stack-protector -fno-math-errno -I$M -I$M/glue -I$FW/core/code"
mkdir -p build/obj
objs=()
for f in "$M"/mdkit_*.c; do
  o=build/obj/$(basename "$f" .c).o
  clang $CF -c "$f" -o "$o"
  objs+=("$o")
done
clang $CF -c md_blob.c -o build/obj/md_blob.o
ld.lld -shared -Bsymbolic -z text -z norelro --hash-style=sysv --build-id=none -z max-page-size=4096 --gc-sections \
  -e scx_entry -o build/md.elf build/obj/md_blob.o "${objs[@]}"
python3 "$SC/tools/scxpack.py" build/md.elf build/md.scx --name MD
