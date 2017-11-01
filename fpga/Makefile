PROJ      = top
BUILD     = ./build
DEVICE    = 8k
ifeq (8k,$(DEVICE))
FOOTPRINT = ct256
else
FOOTPRINT = vq100
endif

# Files
FILES = top.v
FILES += core.v
FILES += sump2.v
FILES += mesa2ctrl.v
FILES += mesa2lb.v
FILES += mesa_ascii2nibble.v
FILES += mesa_byte2ascii.v
FILES += mesa_core.v
FILES += mesa_decode.v
FILES += mesa_id.v
FILES += mesa_phy.v
FILES += mesa_tx_uart.v
FILES += mesa_uart.v
FILES += spi_byte2bit.v
FILES += spi_prom.v
FILES += time_stamp.v

.PHONY: all clean burn

all:$(BUILD)/$(PROJ).bin $(BUILD)/$(PROJ).rpt

$(BUILD)/$(PROJ).bin: $(FILES) Makefile
	# if build folder doesn't exist, create it
	mkdir -p $(BUILD)
	# synthesize using Yosys
	yosys -p "synth_ice40 -top top -blif $(BUILD)/$(PROJ).blif" $(FILES)
	# Place and route using arachne
	arachne-pnr  -r -d $(DEVICE) -P $(FOOTPRINT) -o $(BUILD)/$(PROJ).asc -p pinmap_$(FOOTPRINT).pcf $(BUILD)/$(PROJ).blif
	# Convert to bitstream using IcePack
	icepack $(BUILD)/$(PROJ).asc $(BUILD)/$(PROJ).bin
	
%.rpt: %.asc
	icetime -d hx$(DEVICE) -mtr $@ $<

burn:   $(BUILD)/$(PROJ).bin
	iceprogduino $<
clean:
	rm -f build/*

