#!/usr/bin/env bash

use_asdf() {
  source_env "$(asdf direnv _asdf_cached_envrc "$@")"
}

if [ "1" == "$DIRENV_IN_ENVRC" ] && [ "$0" == "${BASH_SOURCE[0]}" ]; then
  echo "$0"
fi
