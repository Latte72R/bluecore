PROJECT := core
SIM_TOP := top

FILELIST := $(PROJECT).f
TB := src/tb_verilator.cpp
OBJ_DIR := obj_dir
SIM := sim

VERILATOR_FLAGS ?=
VERILATOR_CPPFLAGS := $(filter -D%,$(VERILATOR_FLAGS))

SYNTH_TOP ?= core
TIMING_PATHS ?= 10

TEST_DIR ?= test/share
TEST_FILTER ?= rv64ui-p-

.PHONY: build clean sim test synth fmax

build:
	veryl fmt
	veryl build

clean:
	veryl clean
	rm -rf $(OBJ_DIR)

sim:
	verilator --cc $(VERILATOR_FLAGS) \
		$(if $(VERILATOR_CPPFLAGS),-CFLAGS "$(VERILATOR_CPPFLAGS)") \
		-f $(FILELIST) \
		--exe $(TB) \
		--top-module $(PROJECT)_$(SIM_TOP) \
		--Mdir $(OBJ_DIR)
	$(MAKE) -C $(OBJ_DIR) -f V$(PROJECT)_$(SIM_TOP).mk
	mv $(OBJ_DIR)/V$(PROJECT)_$(SIM_TOP) $(OBJ_DIR)/$(SIM)

test:
	python3 test/test.py -r $(OBJ_DIR)/$(SIM) $(TEST_DIR) $(TEST_FILTER)

synth:
	veryl synth --top $(SYNTH_TOP) \
		--timing-paths $(TIMING_PATHS) \
		--dump-timing \
		--dump-area

fmax:
	@veryl synth --top $(SYNTH_TOP) --timing-paths 1 | \
	awk '/^  timing:/ { \
		delay = $$2; \
		printf "critical_path: %.3f ns\nfmax: %.2f MHz\n", delay, 1000.0 / delay; \
		found = 1 \
	} END { exit found ? 0 : 1 }'
