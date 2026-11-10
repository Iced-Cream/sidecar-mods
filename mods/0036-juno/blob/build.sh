#!/bin/bash
# blob/build.sh - JUNO's Pi blob: build/juno.scx, the upstream Sidecar's Juno-106 voice (sim/juno/juno_voice.h, GPL-2.0;
# its factory patches juno_patches.h from shorepine/amy, MIT; tools/sidecar_upstream.sh's commit), with juno_blob.cc as
# one SCX block (sidecar-firmware core/code/scx.h), packed by sidecar-core's tools/scxpack.py. Built files and the
# fetched sources are never committed (vendor/, build/).
#   FIRMWARE=<sidecar-firmware checkout (core/code/scx.h)>  SIDECAR_CORE=<sidecar-core checkout>
# Needs clang and ld.lld.
set -e
cd "$(dirname "$0")"
FW=${FIRMWARE:-../../../../sidecar-firmware}
SC=${SIDECAR_CORE:-../../../vendor/sidecar-core}
UP=vendor/sidecar-upstream
../../../tools/sidecar_upstream.sh "$UP"
CXXF="--target=aarch64-linux-gnu -std=c++14 -O2 -fPIC -fno-plt -fno-exceptions -fno-rtti -fvisibility=hidden
 -fno-asynchronous-unwind-tables -fno-stack-protector -fno-threadsafe-statics -fno-math-errno
 -I$UP/sim/juno -I$FW/core/code"
mkdir -p build/obj
clang++ $CXXF -c juno_blob.cc -o build/obj/juno_blob.o
ld.lld -shared -Bsymbolic -z text -z norelro --hash-style=sysv --build-id=none -z max-page-size=4096 --gc-sections \
  -e scx_entry -o build/juno.elf build/obj/juno_blob.o
python3 "$SC/tools/scxpack.py" build/juno.elf build/juno.scx --name JUNO
