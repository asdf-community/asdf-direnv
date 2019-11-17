#!/usr/bin/env/bash

die() {
  echo "$@"
  exit 1
}

ASDF_CMD="$(command -v asdf)"
test -x "$ASDF_CMD" || die "Expected asdf command to be available."

ASDF_DIRENV="$(dirname "$BATS_TEST_DIRNAME")"

ASDF_WHERE_DIRENV="$(asdf where direnv)"
test -n "$ASDF_WHERE_DIRENV" || die "Expected asdf-direnv to be already be installed."

ASDF_DIRENV_VERSION="$(basename "$ASDF_WHERE_DIRENV")"
PATH_WITHOUT_ASDF="$(echo "$PATH" | tr ':' $'\n' | grep -v asdf | tr $'\n' ':' | sed -e 's#:$##')"

setup_asdf_direnv() {
  BASE_DIR=$(mktemp -dt asdf.XXXX)
  HOME=$BASE_DIR/home
  ASDF_DIR=$HOME/.asdf
  mkdir -p "$ASDF_DIR/plugins"
  mkdir -p "$ASDF_DIR/installs"
  mkdir -p "$ASDF_DIR/shims"
  mkdir -p "$ASDF_DIR/tmp"

  echo "direnv $ASDF_DIRENV_VERSION" > "$HOME/.tool-versions"

  mkdir -p "$ASDF_DIR/installs/direnv"
  ln -s "$ASDF_DIRENV" "$ASDF_DIR/plugins/direnv"
  ln -s "$ASDF_WHERE_DIRENV" "$ASDF_DIR/installs/direnv/$ASDF_DIRENV_VERSION"

  $ASDF_CMD reshim direnv "$ASDF_DIRENV_VERSION"

  ASDF_BIN="$(dirname "$ASDF_CMD")"

  PATH="$ASDF_BIN:$PATH_WITHOUT_ASDF" # NOTE: dont add shims directory to PATH

  PROJECT_DIR=$HOME/project
  mkdir -p "$PROJECT_DIR"
  ENVRC="$PROJECT_DIR/.envrc"

  eval "$(asdf exec direnv hook bash)"
}

clean_asdf_direnv() {
  rm -rf "$BASE_DIR"
  unset ASDF_DIR
  unset ASDF_DATA_DIR
}

allow_direnv() {
  asdf exec direnv allow "$ENVRC"
}

envrc_use_asdf() {
  echo 'source $(asdf which direnv_use_asdf)' > "$ENVRC"
  echo "use asdf $@" >> "$ENVRC"
  allow_direnv
}

install_dummy_plugin() {
  local plugin_name="$1"
  local version="${2:-'1.0'}"

  mkdir -p "$ASDF_DIR/plugins/${plugin_name}/shims/"
  echo "echo $plugin_name" > "$ASDF_DIR/plugins/$plugin_name/shims/plugin_${plugin_name}"
  chmod +x "$ASDF_DIR/plugins/$plugin_name/shims/plugin_${plugin_name}"

  mkdir -p "$ASDF_DIR/installs/${plugin_name}/${version}/bin"
  echo "echo $plugin_name $version" > "$ASDF_DIR/installs/${plugin_name}/${version}/bin/${plugin_name}"
  chmod +x "$ASDF_DIR/installs/${plugin_name}/${version}/bin/${plugin_name}"

  $ASDF_CMD reshim "$plugin_name" "$version"
}
