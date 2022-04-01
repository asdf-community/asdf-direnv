#!/usr/bin/env bash

# Exit on error, since this is an executable and not a sourced file.
set -eo pipefail

# shellcheck source=lib/setup-lib.bash
source "$(dirname "${BASH_SOURCE[0]}")/../setup-lib.bash"
local_command "${@}"
