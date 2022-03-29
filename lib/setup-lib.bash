#!/usr/bin/env bash

if [ -n "$ASDF_DIRENV_DEBUG" ]; then
  set -x
fi

function ok() {
  echo -n "✔️" >&2
  if test -n "$*"; then
    echo -n "  $*" >&2
  fi
  echo >&2
}

function hmm() {
  echo -n "❗️" >&2
  if test -n "$*"; then
    echo -n " $*" >&2
  fi
  echo >&2
  return 1
}

function fail() {
  echo -n "❌" >&2
  if test -n "$*"; then
    echo -n "  $*" >&2
  fi
  echo >&2
  exit 1
}

function prompt() {
  local input default
  if test -n "$1"; then
    echo -n "⌨  $1: " >&2
    shift
  fi
  default="$1"
  read -r input
  if test -n "$input"; then
    echo "$input"
  else
    echo "$default"
  fi
}

function run_cmd() {
  echo -n "▶ $* # ...  " >&2
  if "${@}"; then
    ok
  else
    local status="$?"
    hmm "Failed with status $status"
    return "$status"
  fi
}

function maybe_run_cmd() {
  echo -n "▶ $* # ...  " >&2
  "${@}" || true
  ok
}

function modifying() {
  echo -n "✍  Modifying $1 " >&2
  if echo "$2" >>"$1"; then
    ok
  else
    fail
  fi
}

function grep_or_add() {
  local file content
  file="$1"
  shift
  read -d $'\0' -r content
  if grep -s "$content" "$file" >&2 >/dev/null; then
    ok "$file looks fine"
    return 0
  else
    mkdir -p "$(dirname "$file")"
    modifying "$file" "$content"
  fi
}

function check_for() {
  echo "Checking for $1..." >&2
  shift
  "$@"
}

function asdf_bin_in_path() {
  local bin
  bin="$(command -v asdf 2>/dev/null)"
  if test -x "$bin"; then
    ok "Found asdf at $(command -v asdf)"
  fi
}

function installed_direnv() {
  local bin
  bin="${ASDF_DIRENV_BIN:-$(asdf which direnv 2>/dev/null || true)}"
  if test -x "$bin"; then
    ASDF_DIRENV_BIN="$bin"
  else
    local version
    version="$(prompt "Please specify a direnv version to use [version-number/latest/SYSTEM]" "system")"
    case "$version" in
      system | SYSTEM | "")
        ASDF_DIRENV_BIN="$(run_cmd env ASDF_DIRENV_VERSION=system asdf which direnv)"
        ;;
      latest | LATEST)
        run_cmd asdf install direnv latest
        version="$(asdf list direnv | tail -n 1 | sed -e 's/ //g')" # since `ASDF_DIRENV_VERSION=latest asdf which direnv` does not work
        ASDF_DIRENV_BIN="$(run_cmd env ASDF_DIRENV_VERSION="$version" asdf which direnv)"

        ;;
      *)
        run_cmd asdf install direnv "$version"
        ASDF_DIRENV_BIN="$(run_cmd env ASDF_DIRENV_VERSION="$version" asdf which direnv)"
        ;;
    esac
  fi
  test -x "$ASDF_DIRENV_BIN"
  ok "Found direnv at ${ASDF_DIRENV_BIN}"
  export ASDF_DIRENV_BIN
}

function direnv_shell_integration() {
  local rcfile
  case "${ASDF_DIRENV_SHELL:-$SHELL}" in
    *bash*)
      rcfile="$HOME/.bashrc"
      cat <<-EOF | grep_or_add "$rcfile"
export ASDF_DIRENV_BIN="$ASDF_DIRENV_BIN"
eval "\$($ASDF_DIRENV_BIN hook bash)"
EOF
      ;;
    *zsh*)
      rcfile="$HOME/.zshrc"
      cat <<-EOF | grep_or_add "$rcfile"
export ASDF_DIRENV_BIN="$ASDF_DIRENV_BIN"
eval "\$($ASDF_DIRENV_BIN hook zsh)"
EOF
      ;;
    *fish*)
      rcfile="${XDG_CONFIG_HOME:-$HOME/.config}/fish/conf.d/asdf_direnv.fish"
      cat <<-EOF | grep_or_add "$rcfile"
set -g ASDF_DIRENV_BIN "$ASDF_DIRENV_BIN"
$ASDF_DIRENV_BIN hook fish | source
EOF
      ;;
    *)
      fail "Don't know how to setup for shell $SHELL. PR welcome!"
      ;;
  esac
}

function direnv_asdf_integration() {
  local rcfile="${XDG_CONFIG_HOME:-$HOME/.config}/direnv/lib/use_asdf.sh"
  cat <<-EOF | grep_or_add "$rcfile"
source "\$(asdf direnv hook asdf)"

# Uncomment the following line to make direnv silent by default.
# export DIRENV_LOG_FORMAT=""
EOF
}

function setup_command() {
  if test -n "$1"; then
    export ASDF_DIRENV_SHELL="$1"
  fi

  check_for "asdf" asdf_bin_in_path || fail "Make sure you have asdf installed. Follow instructions at https://asdf-vm.com"
  check_for "direnv" installed_direnv || fail "An installation of direnv is required to continue. See https://github.com/asdf-community/asdf-direnv"
  check_for "direnv shell integration" direnv_shell_integration || fail "direnv shell hook must be installed. See https://direnv.net/docs/hook.html"
  check_for "direnv asdf integration" direnv_asdf_integration || fail "asdf-direnv function must be installed on direnvrc. See https://github.com/asdf-community/asdf-direnv"
}

function local_command() {
  local plugin version
  while [ $# -gt 0 ]; do
    plugin="$1"
    shift

    if [ $# -eq 0 ]; then
      fail "Please specify a version for $plugin.\n" >&2
    fi
    version="$1"
    shift

    maybe_run_cmd asdf plugin-add "$plugin"
    run_cmd asdf install "$plugin" "$version"
    run_cmd asdf local "$plugin" "$version"
  done

  printf "use asdf\n\0" | grep_or_add ".envrc"
  run_cmd direnv allow
}
