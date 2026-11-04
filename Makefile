# Analog Rytm MKII firmware mods.
PY := .venv/bin/python

.PHONY: all setup symbols layout build verify cavescan ghidra disasm clean \
	comp-selftest comp-cal-gen comp-cal-check comp-cal-build cave-selftest release release-check

all: verify

# The container tool, pinned to the commit the build was verified against.
EFT_URL := https://github.com/mischa85/elektron-firmware-tool
EFT_REV := a5bce9a6af644386d900924082993a805e812874
# elekloader (GPL-2.0-or-later), executed only by builds with 0027-elekloader; tools/build.py
# checks this same commit (ELEK_REV). Its core-ar2 0.9 (OS 1.74 only) is built from the source at
# ELEK_CORE_REV in build.py, with Ubuntu's gcc-m68k-linux-gnu (GCC 13; ELEK_CORE_CROSS), as upstream
# does: its C is pre-C23. mods/0027-elekloader/design.md.
ELEK_URL := https://github.com/irpina/elekloader
ELEK_REV := 9f72fb05bd3baeacdf04af00dc2d1357abf96134
CORE_VER := 0.9

setup:
	python3 -m venv .venv
	.venv/bin/pip install -r requirements.txt
	test -d vendor/elektron-firmware-tool/.git || git clone $(EFT_URL) vendor/elektron-firmware-tool
	git -C vendor/elektron-firmware-tool checkout --quiet $(EFT_REV)
	$(MAKE) -C vendor/elektron-firmware-tool
	test -d vendor/elekloader/.git || git clone $(ELEK_URL) vendor/elekloader
	git -C vendor/elekloader checkout --quiet $(ELEK_REV)

symbols:
	$(PY) tools/symbols.py

# The release for the elekloader web page (docs/ELEKLOADER.md): the Sidecar set as two elemods, the companion
# sidecar-$(VERSION).elemod (mods/0032-sidecar) and rytm-sidecar-$(VERSION).elemod, which requires it, with core-ar2
# $(CORE_VER) beside them, in build/release/$(VERSION)/. VERSION is the one place the release version is set (build.py
# reads it too).
VERSION := $(shell cat VERSION)
REL := build/release/$(VERSION)
REL_TAG := rel$(subst .,-,$(VERSION))
# The core-ar2 0.9 set (companion phase, decided 2026-11-03): the companion (with the FX-return routing that was 0030)
# and the remote screen 0026, both generic services of the Pi engine. Out until the Storage phase: 0014, 0021, 0023,
# 0025, 0029 (core storage, machine slots, lock codes, pages); 0022 dropped (its host half would be a Pi counterpart).
# 0031-remote-keys stays out of production builds (a dev / test feature: RUI_DEV=1 tools/build_rui.sh).
RELEASE_MODS := 0026-remote-ui 0027-elekloader 0032-sidecar
RELEASE_ARGS := --param 0026-remote-ui:screen=1 --param 0032-sidecar:clock=1

release: symbols layout
	$(PY) tools/comp/calib_tables.py --check
	$(PY) tools/build.py --tag $(REL_TAG) --elek-bundle --mods $(RELEASE_MODS) $(RELEASE_ARGS)
	$(PY) tools/verify.py --tag $(REL_TAG)
	rm -rf $(REL) && mkdir -p $(REL)
	cp build/elek/$(REL_TAG)/core/core-$(CORE_VER).elemod $(REL)/core-$(CORE_VER)-os1.74.elemod
	cp build/elek/$(REL_TAG)/mods/sidecar/out/sidecar-$(VERSION).elemod \
		build/elek/$(REL_TAG)/mods/rytm-sidecar/out/rytm-sidecar-$(VERSION).elemod $(REL)/
	cp LICENSE NOTICE $(REL)/
	# GPL-2.0 section 3: the corresponding source of core-$(CORE_VER)-os1.74.elemod and of the builder (one commit) beside it
	git -C vendor/elekloader archive --format=tar.gz --prefix=elekloader-9f72fb0/ \
		$(ELEK_REV) > $(REL)/elekloader-9f72fb0-src.tar.gz
	{ echo "release $(VERSION), built from rytm-mods $$(git rev-parse HEAD)$$(git diff --quiet HEAD || echo ' (uncommitted changes)')"; \
	  echo "elekloader $$(git -C vendor/elekloader rev-parse HEAD) (builder and core-ar2 $(CORE_VER))"; \
	  m68k-elf-as --version | head -1; $${ELEK_CORE_CROSS:-m68k-linux-gnu-}gcc --version | head -1; $(PY) --version; uname -sm; } > $(REL)/TOOLCHAIN.txt
	cd $(REL) && { command -v sha256sum > /dev/null && SUM="sha256sum" || SUM="shasum -a 256"; \
		$$SUM *.elemod *.tar.gz LICENSE NOTICE TOOLCHAIN.txt > SHA256SUMS; } && cat SHA256SUMS

# Only the published files + the stock .syx, through upstream's command line and the web
# page's code path: MAIN OS must be the release build's, sections 1/2/5/8 stock.
release-check:
	$(PY) tools/release_check.py --dir $(REL) --expect build/mainos_$(REL_TAG).bin \
		--expect-syx build/Analog-Rytm_MKII_OS1.74_$(REL_TAG).syx --doc docs/ELEKLOADER.md

layout:
	$(PY) tools/layout.py

# Mod 0006's calib.inc must be what its calibration.toml gives before anything
# is assembled from it.
build: symbols layout
	$(PY) tools/comp/calib_tables.py --check
	$(PY) tools/build.py

verify: build
	$(PY) tools/verify.py $(if $(TAG),--tag $(TAG),)

# Candidate code caves in the stock image. The cave pool in
# registry/allocations.toml comes from this scan, not from anyone else's survey.
cavescan: build
	$(PY) tools/cavescan.py

ghidra:
	./re/ghidra/import.sh

# Whole-image disassembly with ColdFire EMAC decoding. objdump takes the ISA
# from the ELF header, so a raw binary is read as plain m68k and every EMAC
# opcode - mac, msac and the movclr that reads an accumulator and clears it -
# comes out as ".short". The .archtag section holds one EMAC instruction purely
# so the assembler stamps the ISA; .text carries the image at its own addresses.
MAINOS_BASE := 0x40000400
disasm: build
	printf '\t.section .archtag,"a"\n\tmovclr.l %%acc0,%%d0\n\t.text\n\t.incbin "build/stock_mainos.bin"\n' \
		> build/mainos_wrap.s
	m68k-elf-as -mcpu=5475 build/mainos_wrap.s -o build/mainos_wrap.o
	m68k-elf-objdump -d -j .text --adjust-vma=$(MAINOS_BASE) build/mainos_wrap.o \
		| sed 's/^ *//' > build/mainos_emac.dis

# Regression tests for the cave analysis. Needs `make build` for the image and
# `make disasm` for the dead-code pass; the tests that need either skip without it.
cave-selftest:
	$(PY) tools/test_cavescan.py

# Mod 0006's calibration (re/subsystems/compressor-calibration.md). Every
# calibrated value lives in mods/0006-comp-preview/calibration.toml; the fits
# run from tools/comp/calibrate.py on a calibration's recordings.
# comp-selftest: host checks of the calibration frames' decoding, and of a
# run's preflight, verification and report on synthetic captures.
# comp-cal-gen: write calib.inc from calibration.toml.
# comp-cal-check: calib.inc is current.
comp-selftest:
	$(PY) tools/comp/calframes_selftest.py
	$(PY) tools/comp/verify_selftest.py > /dev/null && echo "verify: PASS"
	$(PY) tools/comp/preflight_selftest.py

comp-cal-gen:
	$(PY) tools/comp/calib_tables.py

comp-cal-check:
	$(PY) tools/comp/calib_tables.py --check

# The calibration image: 0006 alone, cal = 1. Flash
# build/Analog-Rytm_MKII_OS1.74_cal.syx, then calibrate.py.
comp-cal-build: symbols layout
	$(PY) tools/comp/calib_tables.py --check
	$(PY) tools/build.py --tag cal --mods 0006-comp-preview --param 0006-comp-preview:cal=1
	$(PY) tools/verify.py --tag cal

# Everything under build/ is regenerated from the image except build/comp, a
# calibration's recordings off the hardware, and build/comp_rig.json, the rig's
# ports and the calibration project's roles.
clean:
	find build -mindepth 1 -maxdepth 1 ! -name comp ! -name comp_rig.json -exec rm -rf {} +
