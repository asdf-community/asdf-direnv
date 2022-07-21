#!/usr/bin/env bash

set -Eeuo pipefail

# shellcheck source=lib/tools-environment-lib.bash
source "$(dirname "${BASH_SOURCE[0]}")/../tools-environment-lib.bash"

function print_generic_error() {
  log_error "Error generating asdf cached envrc"
}
trap print_generic_error ERR

_print_asdf_cached_envrc "$@"
