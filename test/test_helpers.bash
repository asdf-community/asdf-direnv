#!/usr/bin/env/bash

die() {
  echo "$@"
  exit 1
}

direnv() {
  "$ASDF_DIRENV_BIN" "$@"
}

env_setup() {
  ASDF_CMD="$(type -P asdf)"
  test -x "$ASDF_CMD" || die "Expected asdf command to be available."
  ASDF_ROOT="$(dirname "$(dirname "$ASDF_CMD")")"

  ASDF_DIRENV="$(dirname "$BATS_TEST_DIRNAME")"

  ASDF_WHERE_DIRENV="$(asdf where direnv)"
  test -n "$ASDF_WHERE_DIRENV" || die "Expected asdf-direnv plugin to be already be installed."

  ASDF_DIRENV_VERSION="$(basename "$ASDF_WHERE_DIRENV")"
  PATH_WITHOUT_ASDF="$(echo "$PATH" | tr ':' $'\n' | grep -v asdf | tr $'\n' ':' | sed -e 's#:$##')"

  BASE_DIR=$(mktemp -dt asdf.XXXX)
  HOME=$BASE_DIR/home
  XDG_CONFIG_HOME="$HOME/.config"
  XDG_CACHE_HOME="$HOME/.cache"
  ASDF_DIR="$HOME/.asdf"
  ASDF_DATA_DIR="$ASDF_DIR"
  EMPTY_DIR=$(mktemp -dt asdf.XXXX)

  # A temporary "system" direnv binary outside of asdf.
  DIRENV_SYS=$(mktemp -dt direnv.XXXX)
  ln -s "$ASDF_WHERE_DIRENV/bin/direnv" "$DIRENV_SYS/direnv"

  # NOTE: dont add asdf shims directory to PATH
  # NOTE: we add direnv to PATH for testing system-installed direnv setup.
  PATH="${ASDF_DIR}/bin:$PATH_WITHOUT_ASDF:${DIRENV_SYS}"

  mkdir -p "$XDG_CACHE_HOME" "$XDG_CONFIG_HOME"

  mkdir -p "${ASDF_DIR}"/{bin,lib}
  mkdir -p "${ASDF_DATA_DIR}"/{plugins,installs,shims}
  cp "$ASDF_ROOT"/bin/asdf "${ASDF_DIR}/bin"
  cp -r "$ASDF_ROOT"/lib/* "${ASDF_DIR}/lib"

  ln -s "$ASDF_DIRENV" "${ASDF_DATA_DIR}/plugins/direnv"
  mkdir -p "${ASDF_DATA_DIR}/installs/direnv"
  ln -s "$ASDF_WHERE_DIRENV" "${ASDF_DATA_DIR}/installs/direnv/$ASDF_DIRENV_VERSION"

  echo "direnv $ASDF_DIRENV_VERSION" >"$HOME/.tool-versions"
  asdf reshim direnv "$ASDF_DIRENV_VERSION"

  ASDF_DIRENV_BIN="$ASDF_WHERE_DIRENV/bin/direnv" # uses ASDF_DIRENV_VERSION from env.
  test -x "$ASDF_DIRENV_BIN"                      # make sure it's executable

  PROJECT_DIR=$HOME/project
  mkdir -p "$PROJECT_DIR"
  cd "$PROJECT_DIR" || exit 1
}

env_teardown() {
  rm -rf "$BASE_DIR" "$EMPTY_DIR"
  unset ASDF_CONCURRENCY
}

envrc_load() {
  direnv export bash | sed -e "s/;export/\n export/g"
  eval "$(direnv export bash)"
  direnv status
  cat .envrc
}

envrc_unload() {
  # Simulate someone leaving a directory and direnv unloading by cd-ing into an
  # empty directory and loading a `direnv export` (it's smart enough to unset
  # environment variables as needed).
  cd "$EMPTY_DIR" || exit 1
  eval "$(direnv export bash)"
  cd - || exit 1
}

dummy_bin_path() {
  local plugin_name="${1:-dummy}"
  local version="${2:-'1.0'}"
  echo "$ASDF_DATA_DIR/installs/${plugin_name}/${version}/bin"
}

dummy_shims_path() {
  local plugin_name="${1:-dummy}"
  local version="${2:-'1.0'}"
  echo "$ASDF_DATA_DIR/plugins/${plugin_name}/shims"
}

path_as_lines() {
  echo "$PATH" | tr ':' $'\n'
}

install_dummy_plugin() {
  local plugin_name="${1:-dummy}"
  local version="${2:-'1.0'}"
  local shim="$3"

  mkdir -p "${ASDF_DATA_DIR}/plugins/${plugin_name}/bin"

  # create a 'list-all' script
  local list_all_path="${ASDF_DATA_DIR}/plugins/${plugin_name}/bin/list-all"
  cat <<-EOF >"$list_all_path"
#!/usr/bin/env bash
echo 1.0 2.0 2.1
EOF
  chmod +x "$list_all_path"

  if test -n "$shim"; then
    local plugin_shims
    plugin_shims="${ASDF_DATA_DIR}/plugins/${plugin_name}/shims"
    mkdir -p "$plugin_shims"
    echo "echo This is $plugin_name $shim shim" >"${plugin_shims}/$shim"
    chmod +x "${plugin_shims}/$shim"
  fi

  local plugin_bin
  plugin_bin="$(dummy_bin_path "$plugin_name" "$version")"
  mkdir -p "$plugin_bin"
  echo "echo This is $plugin_name $version" >"${plugin_bin}/${plugin_name}"
  chmod +x "${plugin_bin}/${plugin_name}"

  asdf reshim "$plugin_name" "$version"
}

setup_dummy_legacyfile() {
  local plugin_name="${1:-dummy}"
  local legacyfile="${2:-.${plugin_name}-version}"

  echo "legacy_version_file = yes" >"$HOME/.asdfrc"
  cat <<-EOF >"$ASDF_DATA_DIR/plugins/${plugin_name}/bin/list-legacy-filenames"
#!/usr/bin/env bash
echo ${legacyfile}
EOF
  chmod +x "$ASDF_DATA_DIR/plugins/${plugin_name}/bin/list-legacy-filenames"
}
