#!/usr/bin/env bash

# Exit on error, since this is an executable and not a sourced file.
set -eo pipefail

# shellcheck source=lib/tools-environment-lib.bash
source "$(dirname "${BASH_SOURCE[0]}")/../tools-environment-lib.bash"

case "$1" in
  "_"*)
    "$@"
    ;;
  *)
    exec "$direnv" "$@"
    ;;
esac
