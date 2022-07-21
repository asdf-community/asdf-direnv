SH_SRCFILES = $(shell git ls-files "bin/*" "*.bash" "*.bats")
SHFMT_BASE_FLAGS = -s

all: test lint fmt-check

.PHONY: all

fmt:
	shfmt -w $(SHFMT_BASE_FLAGS) $(SH_SRCFILES)
.PHONY: fmt

fmt-check:
	shfmt -d $(SHFMT_BASE_FLAGS) $(SH_SRCFILES)
.PHONY: fmt-check

lint:
	shellcheck $(SH_SRCFILES)
.PHONY: lint

test:
	env TERM=xterm bats -F tap test
.PHONY: test
