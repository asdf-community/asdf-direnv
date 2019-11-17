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

  echo "direnv $ASDF_DIRENV_VERSION" > "$HOME/.tool-versions"
  asdf reshim direnv "$ASDF_DIRENV_VERSION"

  PROJECT_DIR=$HOME/project
  mkdir -p "$PROJECT_DIR"
}

clean_asdf_direnv() {
  rm -rf "$BASE_DIR"
}

envrc_load() {
  eval "$(asdf exec direnv export bash)"
}

allow_direnv() {
  asdf exec direnv allow
}

envrc_use_asdf() {
  echo 'source $(asdf which direnv_use_asdf)' > ".envrc"
  echo "use asdf $*" >> ".envrc"
  allow_direnv
}

install_dummy_plugin() {
  local plugin_name="$1"
  local version="${2:-'1.0'}"

  mkdir -p "${ASDF_DATA_DIR}/plugins/${plugin_name}/shims/"
  echo "echo Plugin $plugin_name" > "${ASDF_DATA_DIR}/plugins/$plugin_name/shims/plugin_${plugin_name}"
  chmod +x "${ASDF_DATA_DIR}/plugins/$plugin_name/shims/plugin_${plugin_name}"

  mkdir -p "${ASDF_DATA_DIR}/installs/${plugin_name}/${version}/bin"
  echo "echo This is $plugin_name $version" > "${ASDF_DATA_DIR}/installs/${plugin_name}/${version}/bin/${plugin_name}"
  chmod +x "${ASDF_DATA_DIR}/installs/${plugin_name}/${version}/bin/${plugin_name}"

  asdf reshim "$plugin_name" "$version"
}
