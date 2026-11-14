#!/bin/bash
# build.sh - the Analog Four MKII OS with the Sidecar mod: your stock OS 1.56 with elekloader's core-a4mk2 0.8, the A4 companion
# (mod `sidecar`, sidecar-core companion-a4) and the mod in mod/, which is the companion's client. Needs python3, a
# cross compiler for core-a4mk2 (m68k-linux-gnu-, the default here) and two checkouts: elekloader on core-a4mk2-sc at b1677c5
# (https://github.com/Iced-Cream/elekloader) and sidecar-core on a4-companion at aadf302 (https://github.com/Iced-Cream/sidecar-core).
# Never commit the output: it holds Elektron's firmware.
#   STOCK=/path/Analog-Four_MKII_OS1.56.syx ELEKLOADER=/path/elekloader SIDECAR_CORE=/path/sidecar-core ./build.sh [OUTDIR]
# a4156.lock.json is read, never written: the build works on a copy in OUTDIR (OUTDIR/a4156.lock.json), which also holds
# the companion's fields. Diff the two to see that this mod's fields kept their place.
set -euo pipefail
H=$(cd "$(dirname "$0")" && pwd)
: "${STOCK:?STOCK: your Analog-Four_MKII_OS1.56.syx}" "${ELEKLOADER:?ELEKLOADER: an elekloader checkout on core-a4mk2-sc}" \
  "${SIDECAR_CORE:?SIDECAR_CORE: a sidecar-core checkout on a4-companion}"
STOCK=$(cd "$(dirname "$STOCK")" && pwd)/$(basename "$STOCK")
ELEKLOADER=$(cd "$ELEKLOADER" && pwd); SIDECAR_CORE=$(cd "$SIDECAR_CORE" && pwd)
SUM=$( (command -v sha256sum >/dev/null && sha256sum "$STOCK" || shasum -a 256 "$STOCK") | cut -d' ' -f1)
case $SUM in
  5aea489db3e747547f71d5e08a2d20253149fe6258defad60306402d2fc23cb5) ;;
  *) echo "$STOCK is not stock Analog Four MKII OS 1.56" >&2; exit 1 ;;
esac
OUT=${1:-$H/out}; mkdir -p "$OUT"; OUT=$(cd "$OUT" && pwd)
V=$(python3 -c "import json;print(json.load(open('$H/mod/mod.json'))['version'])")
export ELEKLOADER_CROSS=${ELEKLOADER_CROSS:-m68k-linux-gnu-} PYTHONDONTWRITEBYTECODE=1
rm -f "$OUT"/*.elemod
(cd "$ELEKLOADER" && python3 -m elekloader.sdk.build mods/core-a4mk2 --stock "$STOCK" --out "$OUT")
ELEK_A4_DIR="$ELEKLOADER" python3 "$SIDECAR_CORE/tools/build_a4.py" --stock "$STOCK" --out "$OUT/companion"
mv "$OUT"/companion/*.elemod "$OUT/" && rm -rf "$OUT/companion"
(cd "$ELEKLOADER" && python3 -m elekloader.sdk.build "$H/mod" --stock "$STOCK" --out "$OUT")
CORE=$(ls "$OUT"/core-*.elemod); SC=$(ls "$OUT"/sidecar-[0-9]*.elemod); MOD="$OUT/sidecar-a4-$V.elemod"
cd "$ELEKLOADER"
python3 -m elekloader.lint "$MOD" --stock "$STOCK" --with "$CORE" --with "$SC"
cp "$H/a4156.lock.json" "$OUT/a4156.lock.json"
python3 -m elekloader.patch --stock "$STOCK" --mod "$CORE" --mod "$SC" --mod "$MOD" \
  --out "$OUT/a4156_sidecar.syx" --version ${STAMP:-SA13} --lockfile "$OUT/a4156.lock.json"
(command -v sha256sum >/dev/null && sha256sum "$OUT/a4156_sidecar.syx" || shasum -a 256 "$OUT/a4156_sidecar.syx")
