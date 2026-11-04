# The companion's store client and step clock on a PC, against the Pi's own services (test_companion.cpp).
#   make -C mods/0032-sidecar/test FIRMWARE=<a sidecar-firmware checkout with core/kv, core/locks, core/clock>
FIRMWARE ?= ../../../../sidecar-firmware
ELEK := ../../../vendor/elekloader/elekloader/sdk/include
CORE := $(FIRMWARE)/core
B := build

test: $(B)/test_companion
	./$(B)/test_companion

$(B)/companion_host.o: companion_host.c ../store.c ../clock.c
	@mkdir -p $(B)
	$(CC) -std=gnu11 -O1 -g -Wall -Wno-unused-function -Wno-pointer-to-int-cast -Wno-int-to-pointer-cast \
	  -I$(ELEK) -fsanitize=address,undefined -c -o $@ companion_host.c

$(B)/test_companion: test_companion.cpp $(B)/companion_host.o $(CORE)/kv/kv.cpp $(CORE)/locks/locks.cpp $(CORE)/clock/clock.cpp
	$(CXX) -std=c++17 -O1 -g -Wall -I$(CORE) -fsanitize=address,undefined -o $@ test_companion.cpp \
	  $(B)/companion_host.o $(CORE)/kv/kv.cpp $(CORE)/locks/locks.cpp $(CORE)/clock/clock.cpp

clean:
	rm -rf $(B)
.PHONY: test clean
