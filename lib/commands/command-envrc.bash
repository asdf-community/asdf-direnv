#!/usr/bin/env bash

set -Eeuo pipefail

# shellcheck source=lib/tools-environment-lib.bash
source "$(dirname "${BASH_SOURCE[0]}")/../tools-environment-lib.bash"

_print_asdf_cached_envrc "$@"
