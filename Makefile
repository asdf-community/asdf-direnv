SH_SRCFILES = $(shell git ls-files "bin/*" "lib/commands/*" "*.bash" "*.bats")
SHFMT_BASE_FLAGS = -s

all: test lint fmt format-check

.PHONY: all

fmt:
	shfmt -w $(SHFMT_BASE_FLAGS) $(SH_SRCFILES)
.PHONY: fmt

format-check:
	shfmt -d $(SHFMT_BASE_FLAGS) $(SH_SRCFILES)
.PHONY: format-check

lint:
	shellcheck $(SH_SRCFILES)
.PHONY: lint

test:
	env TERM=xterm bats -F tap test
.PHONY: test
