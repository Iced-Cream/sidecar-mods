#!/bin/bash
# blob/build.sh - DAISYSP's Pi blob: build/daisysp.scx, Mutable Instruments Plaits' physical models (eurorack, MIT, pinned below) with
# daisysp_blob.cc as one SCX block (sidecar-firmware core/code/scx.h), packed by sidecar-core's tools/scxpack.py.
# Built files and the fetched sources are never committed (vendor/, build/).
#   FIRMWARE=<sidecar-firmware checkout (core/code/scx.h)>  SIDECAR_CORE=<sidecar-core checkout>  [EURORACK=<checkout>]
# Needs clang, ld.lld and the AArch64 C++ headers (Ubuntu: g++-aarch64-linux-gnu).
set -e
cd "$(dirname "$0")"
FW=${FIRMWARE:-../../../../sidecar-firmware}
SC=${SIDECAR_CORE:-../../../vendor/sidecar-core}
V=${EURORACK:-vendor/eurorack}
if [ ! -d "$V/plaits" ]; then
  mkdir -p vendor
  git clone --quiet https://github.com/pichenettes/eurorack.git "$V"
  git -C "$V" checkout --quiet 08460a69a7e1f7a81c5a2abcc7189c9a6b7208d4
  git -C "$V" submodule update --quiet --init stmlib
  git -C "$V/stmlib" checkout --quiet e3bd7c9cc00e4364166f9905c0509b6ffd0535ec
fi
# -DTEST: stmlib's portable Sqrt (its ARM one is Cortex-M asm); Plaits' user data is shim/'s (none)
CXXF="--target=aarch64-linux-gnu -std=c++14 -O2 -fPIC -fno-plt -fno-exceptions -fno-rtti -fvisibility=hidden
 -fno-asynchronous-unwind-tables -fno-stack-protector -fno-threadsafe-statics -fno-math-errno -DTEST -Wno-everything
 -I$PWD/shim -I$V -I$FW/core/code"
mkdir -p build/obj
objs=()
for f in $(cd "$V" && find plaits/dsp/physical_modelling -name '*.cc' | sort) plaits/resources.cc stmlib/dsp/units.cc stmlib/utils/random.cc; do
  o=build/obj/$(echo "$f" | tr / _).o
  [ "$o" -nt "$V/$f" ] || clang++ $CXXF -c "$V/$f" -o "$o"
  objs+=("$o")
done
clang++ $CXXF -c daisysp_blob.cc -o build/obj/daisysp_blob.o
# stmlib's Random keeps its seed in a global: the writable part on its own 64 KB unit (SCX_F_DATA)
ld.lld -shared -Bsymbolic -z text -z norelro --hash-style=sysv --build-id=none -z max-page-size=4096 --gc-sections \
  -T "$SC/blobs/writable.ld" -e scx_entry -o build/daisysp.elf build/obj/daisysp_blob.o "${objs[@]}"
python3 "$SC/tools/scxpack.py" build/daisysp.elf build/daisysp.scx --name DAISYSP --writable
