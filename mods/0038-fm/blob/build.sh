#!/bin/bash
# blob/build.sh - 6-OP FM's Pi blob: build/fm.scx, the upstream Sidecar's 6-OP FM voice (sim/plaits/fm_machine.h, GPL-2.0,
# tools/sidecar_upstream.sh's commit) on Mutable Instruments Plaits' six-op engine (eurorack, MIT, pinned below), with
# fm_blob.cc as one SCX block (sidecar-firmware core/code/scx.h), packed by sidecar-core's tools/scxpack.py. Plaits is
# patched as upstream's teensy/setup_plaits_lib.sh patches it for the Pi: a voice load unpacks only the voice into patch
# 0 or 1 (no click on a PAT change), and the operators' NEON path. Built files and the fetched sources are never
# committed (vendor/, build/).
#   FIRMWARE=<sidecar-firmware checkout (core/code/scx.h)>  SIDECAR_CORE=<sidecar-core checkout>  [EURORACK=<checkout>]
# Needs clang, ld.lld and the AArch64 C++ headers (Ubuntu: g++-aarch64-linux-gnu).
set -e
cd "$(dirname "$0")"
FW=${FIRMWARE:-../../../../sidecar-firmware}
SC=${SIDECAR_CORE:-../../../vendor/sidecar-core}
V=${EURORACK:-vendor/eurorack}
UP=vendor/sidecar-upstream
if [ ! -d "$V/plaits" ]; then
  mkdir -p vendor
  git clone --quiet https://github.com/pichenettes/eurorack.git "$V"
  git -C "$V" checkout --quiet 08460a69a7e1f7a81c5a2abcc7189c9a6b7208d4
  git -C "$V" submodule update --quiet --init stmlib
  git -C "$V/stmlib" checkout --quiet e3bd7c9cc00e4364166f9905c0509b6ffd0535ec
fi
../../../tools/sidecar_upstream.sh "$UP"
# Plaits and stmlib, patched (upstream's setup_plaits_lib.sh, the Pi's patches; the Teensy-only ones left out)
S=build/src
rm -rf "$S"; mkdir -p "$S"
cp -R "$V/plaits" "$V/stmlib" "$S/"
cp "$UP/sim/plaits/shim/plaits/user_data.h" "$S/plaits/user_data.h"
cp "$UP/sim/plaits/shim/stmlib/utils/random.h" "$S/stmlib/utils/random.h"
sed -i 's|^#endif$|#define RYTM_FM_SINGLE_PATCH 1\n#endif|' "$S/plaits/user_data.h"
E="$S/plaits/dsp/engine2/six_op_engine.cc"
sed -i 's|^#include "plaits/resources.h"$|#include "plaits/resources.h"\n#include "plaits/user_data.h"|' "$E"
perl -0pi -e 's|(void SixOpEngine::LoadUserData\(const uint8_t\* user_data\) \{\n)|$1  if (user_data \&\& user_data == fm_user_bank()) {   // rytm: one voice, into patch fm_user_slot()\n    fm::Patch* target = \&patches_[fm_user_slot() \& 1];\n    target->Unpack(user_data);\n    for (int i = 0; i < kNumSixOpVoices; ++i) {\n      if ((fm_user_slot() \& 2) ? true : voice_[i].patch() == target) voice_[i].UnloadPatch();\n    }\n    return;\n  }\n|' "$E"
grep -q 'rytm: one voice, into patch fm_user_slot()' "$E" || { echo "six_op_engine.cc: patch failed"; exit 1; }
O="$S/plaits/dsp/fm/operator.h"
cp "$UP/sim/plaits/operator_neon.h" "$S/plaits/dsp/fm/operator_neon.h"
perl -0pi -e 's|void RenderOperators\(\n|void RenderOperatorsC(\n|; s|\};\s*\n\}  // namespace fm|};\n\n#include "plaits/dsp/fm/operator_neon.h"\n\n}  // namespace fm|' "$O"
perl -pi -e 's|^(#include <algorithm>)$|$1\n#if defined(__ARM_NEON) \&\& defined(__aarch64__)\n#include <arm_neon.h>\n#endif|' "$O"
grep -q 'arm_neon.h' "$O" && grep -q 'operator_neon.h' "$O" || { echo "operator.h: NEON patch failed"; exit 1; }
cp "$UP/sim/plaits/fm_machine.h" "$S/fm_machine.h"
# -DTEST: stmlib's portable Sqrt (its ARM one is Cortex-M asm)
CXXF="--target=aarch64-linux-gnu -std=c++14 -O2 -fPIC -fno-plt -fno-exceptions -fno-rtti -fvisibility=hidden
 -fno-asynchronous-unwind-tables -fno-stack-protector -fno-threadsafe-statics -fno-math-errno -DTEST -Wno-everything
 -I$PWD/$S -I$FW/core/code"
mkdir -p build/obj
objs=()
for f in $(cd "$S" && find plaits/dsp -name '*.cc' | sort) plaits/resources.cc stmlib/dsp/units.cc stmlib/utils/random.cc; do
  o=build/obj/$(echo "$f" | tr / _).o
  clang++ $CXXF -c "$S/$f" -o "$o"
  objs+=("$o")
done
clang++ $CXXF -c fm_blob.cc -o build/obj/fm_blob.o
# the six-op hand-over (fm_user_bank / fm_user_slot) and stmlib's Random seed are mutable globals: the writable part on its
# own 64 KB unit (SCX_F_DATA)
ld.lld -shared -Bsymbolic -z text -z norelro --hash-style=sysv --build-id=none -z max-page-size=4096 --gc-sections \
  -T "$SC/blobs/writable.ld" -e scx_entry -o build/fm.elf build/obj/fm_blob.o "${objs[@]}"
python3 "$SC/tools/scxpack.py" build/fm.elf build/fm.scx --name FM --writable
