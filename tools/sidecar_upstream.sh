#!/bin/bash
# tools/sidecar_upstream.sh DEST - the upstream Sidecar firmware's voice sources (trigcondition/sidecar-firmware, GPL-2.0,
# pinned below), for the blobs that port its Pi voices (0036 JUNO, 0037 MD, 0038 6-OP FM): a sparse, shallow checkout
# of the paths they read, in DEST. Never committed (each blob's vendor/). Rerun freely: an existing DEST at the pinned
# commit is kept.
set -e
REV=39808ae76b4cc4e6f33f42518ee1c5d4c4cb6235   # upstream dev, 2026-11-10 (MD in place of DIGIDRUM since 2026-10-29)
DEST=${1:?usage: sidecar_upstream.sh DEST}
if [ "$(git -C "$DEST" rev-parse HEAD 2>/dev/null)" = "$REV" ]; then exit 0; fi
rm -rf "$DEST"; mkdir -p "$DEST"
git -C "$DEST" init --quiet
git -C "$DEST" remote add origin https://github.com/trigcondition/sidecar-firmware.git
git -C "$DEST" sparse-checkout set --no-cone /sim/juno/ /sim/plaits/fm_machine.h /sim/plaits/operator_neon.h \
  /sim/plaits/shim/ /third_party/mdkit/include/ /third_party/mdkit/src/ /third_party/mdkit/LICENSE \
  /third_party/mdkit/NOTICE /plugins/mdkit/ /sdk/rmp/rmp_api.h /LICENSE
git -C "$DEST" fetch --quiet --depth 1 origin "$REV"
git -C "$DEST" checkout --quiet FETCH_HEAD
