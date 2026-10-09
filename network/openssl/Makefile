FPC ?= fpc
OUTPUT ?= output

.PHONY: all
all:
	mkdir -p $(OUTPUT)/units
	$(FPC) -Fu./src -FU$(OUTPUT)/units -FE$(OUTPUT) examples/test1.pas
