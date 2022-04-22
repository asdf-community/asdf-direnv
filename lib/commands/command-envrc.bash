#!/usr/bin/env bash

set -Eeuo pipefail

# shellcheck source=lib/tools-environment-lib.bash
source "$(dirname "${BASH_SOURCE[0]}")/../tools-environment-lib.bash"

if ! env_file="$(_asdf_cached_envrc "$@")"; then
  log_error "Error generating asdf cached envrc"
  exit 1
fi

echo "$env_file"
