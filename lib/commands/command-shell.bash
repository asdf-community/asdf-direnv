#!/usr/bin/env bash

# Exit on error, since this is an executable and not a sourced file.
set -eo pipefail

if [ -n "$ASDF_DIRENV_DEBUG" ]; then
  set -x
fi

# shellcheck source=lib/commands/command.bash
source "$(dirname "${BASH_SOURCE[0]}")/command.bash"

if [ $# -eq 0 ]; then
  echo "Usage: asdf direnv shell <name> <version> [<name> <version>]..."
  echo ""
  echo "Example:"
  echo ""
  echo "$ asdf direnv shell python 3.8.10 nodejs 14.18.2"
  exit 1
fi

load_plugins() {
  while [ $# -gt 0 ]; do
    plugin="$1"
    shift
    if [ $# -eq 0 ]; then
      log_error "Please specify a version for $plugin."
      exit 1
    fi
    version="$1"
    shift
    echo "Loading $plugin $version" >/dev/stderr

    # Set the appropriate ASDF_*_VERSION environment variable. This isn't
    # strictly necessary because we're not using shims, but it's nice because
    # it'll get `asdf current` to print out useful information, and if folks
    # have a special prompt configured (such as powerlevel10k), it'll know
    # about the newly activated tools.
    #
    # (this logic was copied from lib/commands/command-export-shell-version.bash)
    local upcase_name
    upcase_name=$(tr '[:lower:]-' '[:upper:]_' <<<"$plugin")
    local version_env_var="ASDF_${upcase_name}_VERSION"
    export "$version_env_var"="$version"

    eval "$(_plugin_env_bash "$plugin" "$version" "$plugin $version not installed. Run 'asdf install $plugin $version' and try again.")"
  done
}

load_plugins "$@"

$SHELL
