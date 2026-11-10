# teensy-drive's C on a PC: make -C mods/0023-teensy-drive/test
CC ?= cc
test: ../teensy_drive.c host_test.c
	$(CC) -std=gnu11 -Wall -Wno-unused-function -DTD_HOST -I.. host_test.c -o $(TMPDIR)/td_host_test
	$(TMPDIR)/td_host_test
TMPDIR ?= /tmp
.PHONY: test
