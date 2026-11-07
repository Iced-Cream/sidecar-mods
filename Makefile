# Analog Rytm MKII firmware mods.
PY := .venv/bin/python

.PHONY: all setup symbols layout build verify cavescan ghidra disasm clean \
	cave-selftest release release-check

all: verify

# The container tool, pinned to the commit the build was verified against.
EFT_URL := https://github.com/mischa85/elektron-firmware-tool
EFT_REV := a5bce9a6af644386d900924082993a805e812874
# elekloader (GPL-2.0-or-later), executed only by builds with the companion 0032-sidecar; tools/build.py
# checks this same commit (ELEK_REV): upstream's core-ar2 0.13 release (#358). Its core-ar2 (OS 1.74 only) is built from the source at
# ELEK_CORE_REV in build.py, with Ubuntu's gcc-m68k-linux-gnu (GCC 13; ELEK_CORE_CROSS), as upstream
# does: its C is pre-C23. docs/ELEKLOADER-BUILD.md.
ELEK_URL := https://github.com/elekloader/elekloader
ELEK_REV := 3a7e9431ffaea392fd11c3349cb3ad7bad87b091
CORE_VER := 0.13
# The Sidecar companion (mod 0032-sidecar until 2026-11-05) is its own repository, an ordinary elekloader mod built by
# its own tools/build.py; tools/build.py checks this same commit (SC_REV) and links its elemod into every build with
# 0032-sidecar. mods/0032-sidecar/mod.toml.
SC_URL := https://github.com/Iced-Cream/sidecar-core
SC_REV := 264d3c4a518a63c83a4af0327512e042a287a0c2

setup:
	python3 -m venv .venv
	.venv/bin/pip install -r requirements.txt
	test -d vendor/elektron-firmware-tool/.git || git clone $(EFT_URL) vendor/elektron-firmware-tool
	git -C vendor/elektron-firmware-tool checkout --quiet $(EFT_REV)
	$(MAKE) -C vendor/elektron-firmware-tool
	test -d vendor/elekloader/.git || git clone $(ELEK_URL) vendor/elekloader
	git -C vendor/elekloader checkout --quiet $(ELEK_REV)
	test -d vendor/sidecar-core/.git || git clone $(SC_URL) vendor/sidecar-core
	git -C vendor/sidecar-core checkout --quiet $(SC_REV)

symbols:
	$(PY) tools/symbols.py

# The release for the elekloader web page (docs/ELEKLOADER.md): the companion sidecar-$(VERSION).elemod
# (mods/0032-sidecar) with core-ar2 $(CORE_VER) beside it, in build/release/$(VERSION)/. VERSION is the one place the
# release version is set (build.py reads it too).
VERSION := $(shell cat VERSION)
REL := build/release/$(VERSION)
REL_TAG := rel$(subst .,-,$(VERSION))
# The release set (decided 2026-11-04): the companion alone, with its step clock. It carries the elekloader build
# (mod 0027 folded in) and its services: the router, the store link, the clock. The remote screen 0026 is out of the
# release (it comes back later as a companion service); the rest is out until the Storage phase: 0014, 0021, 0023,
# 0025, 0029 (core storage, machine slots, lock codes, pages); 0022 dropped (its host half would be a Pi counterpart).
# The tree keeps only the mods planned as sidecar-core clients (2026-11-07): 0014, 0021, 0022, 0023, 0025 and the
# companion's entry; the rest are in git history.
RELEASE_MODS := 0032-sidecar
RELEASE_ARGS :=

release: symbols layout
	$(PY) tools/build.py --tag $(REL_TAG) --elek-bundle --mods $(RELEASE_MODS) $(RELEASE_ARGS)
	$(PY) tools/verify.py --tag $(REL_TAG)
	rm -rf $(REL) && mkdir -p $(REL)
	cp build/elek/$(REL_TAG)/core/core-$(CORE_VER).elemod $(REL)/core-$(CORE_VER)-os1.74.elemod
	cp build/elek/$(REL_TAG)/mods/sidecar/out/sidecar-*.elemod $(REL)/
	cp LICENSE NOTICE $(REL)/
	# GPL-2.0 section 3: the corresponding source of core-$(CORE_VER)-os1.74.elemod and of the builder (one commit) beside it
	git -C vendor/elekloader archive --format=tar.gz --prefix=elekloader-$(shell echo $(ELEK_REV) | cut -c1-7)/ \
		$(ELEK_REV) > $(REL)/elekloader-$(shell echo $(ELEK_REV) | cut -c1-7)-src.tar.gz
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

build: symbols layout
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

# Everything under build/ is regenerated from the image.
clean:
	find build -mindepth 1 -maxdepth 1 -exec rm -rf {} +
