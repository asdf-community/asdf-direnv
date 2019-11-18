#!/usr/bin/env/bash

die() {
  echo "$@"
  exit 1
}

setup_asdf_direnv() {
  ASDF_CMD="$(command -v asdf)"
  test -x "$ASDF_CMD" || die "Expected asdf command to be available."
  ASDF_ROOT="$(dirname "$(dirname "$ASDF_CMD")")"

  ASDF_DIRENV="$(dirname "$BATS_TEST_DIRNAME")"

  ASDF_WHERE_DIRENV="$(asdf where direnv)"
  test -n "$ASDF_WHERE_DIRENV" || die "Expected asdf-direnv to be already be installed."

  ASDF_DIRENV_VERSION="$(basename "$ASDF_WHERE_DIRENV")"
  PATH_WITHOUT_ASDF="$(echo "$PATH" | tr ':' $'\n' | grep -v asdf | tr $'\n' ':' | sed -e 's#:$##')"

  BASE_DIR=$(mktemp -dt asdf.XXXX)
  HOME=$BASE_DIR/home
  ASDF_DIR="$HOME/.asdf"
  ASDF_DATA_DIR="$ASDF_DIR"
  PATH="${ASDF_DIR}/bin:$PATH_WITHOUT_ASDF" # NOTE: dont add shims directory to PATH

  mkdir -p "${ASDF_DIR}"/{bin,lib}
  mkdir -p "${ASDF_DATA_DIR}"/{plugins,installs,shims}
  cp "$ASDF_ROOT"/bin/asdf "${ASDF_DIR}/bin"
  cp -r "$ASDF_ROOT"/lib/* "${ASDF_DIR}/lib"

  ln -s "$ASDF_DIRENV" "${ASDF_DATA_DIR}/plugins/direnv"
  mkdir -p "${ASDF_DATA_DIR}/installs/direnv"
  ln -s "$ASDF_WHERE_DIRENV" "${ASDF_DATA_DIR}/installs/direnv/$ASDF_DIRENV_VERSION"

  echo "direnv $ASDF_DIRENV_VERSION" >"$HOME/.tool-versions"
  asdf reshim direnv "$ASDF_DIRENV_VERSION"

  PROJECT_DIR=$HOME/project
  mkdir -p "$PROJECT_DIR"
}

clean_asdf_direnv() {
  rm -rf "$BASE_DIR"
  unset ASDF_CONCURRENCY
}

envrc_load() {
  eval "$(asdf exec direnv export bash)"
}

allow_direnv() {
  asdf exec direnv allow
}

envrc_use_asdf() {
  echo 'source $(asdf which direnv_use_asdf)' >".envrc"
  echo "use asdf $*" >>".envrc"
  allow_direnv
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
