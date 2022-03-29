#!/usr/bin/env bash

# Exit on error, since this is an executable and not a sourced file.
set -eo pipefail

# shellcheck source=/dev/null
source "$(dirname "${BASH_SOURCE[0]}")/../setup-lib.bash"
setup_command "$@"
