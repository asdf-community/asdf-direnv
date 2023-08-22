#!/usr/bin/env bash

# Exit on error, since this is an executable and not a sourced file.
set -Eeuo pipefail

# shellcheck source=lib/install-lib.bash
source "$(dirname "${BASH_SOURCE[0]}")/../install-lib.bash"
install_command "$@"
