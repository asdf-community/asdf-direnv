#!/usr/bin/env bash

use_asdf() {
  if ! env_file="$(asdf direnv _asdf_cached_envrc "$@")"; then
    log_error "Error generating asdf cached envrc"
    exit 1
  else
    source_env "$env_file"
  fi
}

if [ "1" == "$DIRENV_IN_ENVRC" ] && [ "$0" == "${BASH_SOURCE[0]}" ]; then
  echo "$0"
fi
