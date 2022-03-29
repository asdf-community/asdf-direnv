#!/usr/bin/env bash

# Exit on error, since this is an executable an not a sourced file.
set -eo pipefail

# shellcheck source=/dev/null
source "$(dirname "${BASH_SOURCE[0]}")/../setup-lib.bash"
local_command "${@}"
