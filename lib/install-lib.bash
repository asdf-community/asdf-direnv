#!/usr/bin/env bash

# shellcheck source=lib/tools-environment-lib.bash
source "$(dirname "${BASH_SOURCE[0]}")/tools-environment-lib.bash"

function print_usage() {
  echo "Usage: asdf direnv install"
  echo ""
  echo "Installs tools needed for the current directory. This is very similar"
  echo "to 'asdf install' except it installs the tools in the exact order specified"
  echo "in the '.tool-versions' file, and loads the environment of each tool in order."
  echo ""
  echo "This is useful when installing tools that depend on other tools, for"
  echo "example: the poetry plugin expects python to be available."
  echo ""
  echo "Note: this problem isn't entirely unique to asdf-direnv. asdf itself"
  echo "isn't a full-fledged package manager. It simply doesn't understand"
  echo "dependencies between plugins and therefore cannot do a dependency sort of"
  echo "tools. You'll need to manually sort the lines of your '.tool-versions' file"
  echo "for this to work as intended. See these discussions in core asdf for"
  echo "more information:"
  echo ""
  echo " - https://github.com/asdf-vm/asdf/issues/929"
  echo " - https://github.com/asdf-vm/asdf/issues/1127"
  echo " - https://github.com/asdf-vm/asdf/issues/196"
}

function install_command() {
  while [[ $# -gt 0 ]]; do
    arg=$1
    shift
    case $arg in
      -h | --help)
        print_usage
        exit 1
        ;;
      *)
        echo "Unknown option: $arg"
        exit 1
        ;;
    esac
  done

  install_tools
}

_load_asdf_functions_installs() {
  # `install_tool_version` depends on `reshim_command` from reshim.bash.
  # See https://github.com/asdf-vm/asdf/blob/v0.12.0/lib/functions/installs.bash#L243
  _load_asdf_lib reshim_command commands/reshim.bash

  _load_asdf_lib install_tool_version functions/installs.bash
}

function maybe_install_tool_version() {
  _load_asdf_functions_installs

  local install_path
  install_path=$(get_install_path "$plugin_name" "version" "$version")

  if [ -d "$install_path" ]; then
    printf "%s %s is already installed\n" "$plugin_name" "$version"
  else

    # NOTE: we temporarily loosen the rules while invoking
    # install_tool_version because it's from core asdf and it doesn't run
    # well under "strict mode" (asdf_run_hook invokes get_asdf_config_value
    # in a way such that if the config piece is missing, the program exits
    # immediately if `set -e` is enabled.
    (
      set +ue
      install_tool_version "$plugin_name" "$version"
      set -ue
    )
  fi
}

function install_tools {
  local tools_file
  tools_file="$(_local_versions_file)"

  while IFS=$'\n' read -r plugin_name; do
    while IFS=$'\n' read -r version_and_path; do
      local version _path
      IFS='|' read -r version _path <<<"$version_and_path"

      # Install this tool version if not already installed.
      maybe_install_tool_version "$plugin_name" "$version"

      # Load the tools environment so subsequent installs can use this tool.
      direnv_code=$(_plugin_env_bash "$plugin_name" "$version" ">>> UH OH <<<")
      eval "$direnv_code"
    done <<<"$(_plugin_versions_and_path "$plugin_name")"
  done <<<"$(_plugins_in_file "$tools_file")"

  direnv reload
}
