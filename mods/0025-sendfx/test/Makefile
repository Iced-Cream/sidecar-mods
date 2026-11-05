# SEND FX (sfx.c) through the companion (its test/companion_host.c) against the Pi's own services (test_sendfx.cpp).
#   make -C mods/0025-sendfx/test FIRMWARE=<a sidecar-firmware checkout with core/dsp>
FIRMWARE ?= ../../../../sidecar-firmware
ELEK := ../../../vendor/elekloader/elekloader/sdk/include
SC := ../../0032-sidecar
CORE := $(FIRMWARE)/core
B := build
SAN := -fsanitize=address,undefined
PI := $(CORE)/kv/kv.cpp $(CORE)/locks/locks.cpp $(CORE)/route/route.cpp $(CORE)/dsp/dsp.cpp $(CORE)/proc/proc.cpp $(CORE)/clock/clock.cpp

test: $(B)/test_sendfx
	./$(B)/test_sendfx

$(B)/companion_host.o: $(SC)/test/companion_host.c $(SC)/store.c $(SC)/rec.c $(SC)/clock.c
	@mkdir -p $(B)
	$(CC) -std=gnu11 -O1 -g -Wall -Wno-unused-function -Wno-pointer-to-int-cast -Wno-int-to-pointer-cast \
	  -I$(ELEK) $(SAN) -c -o $@ $<

$(B)/sfx.o: ../sfx.c sfx_host.h
	@mkdir -p $(B)
	$(CC) -std=gnu11 -O1 -g -Wall -Wextra -I$(ELEK) -include sfx_host.h $(SAN) -c -o $@ ../sfx.c

$(B)/test_sendfx: test_sendfx.cpp $(B)/companion_host.o $(B)/sfx.o $(PI)
	$(CXX) -std=c++17 -O1 -g -Wall -I$(CORE) -I$(CORE)/host $(SAN) -o $@ test_sendfx.cpp $(B)/companion_host.o $(B)/sfx.o $(PI)

clean:
	rm -rf $(B)
.PHONY: test clean
