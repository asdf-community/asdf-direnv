#!/usr/bin/env bats
# -*- shell-script -*-

load test_helpers

setup() {
  setup_asdf_direnv
}

teardown() {
  clean_asdf_direnv
}

@test "setup bash modifies rcfile" {
  run asdf direnv setup --shell bash --version system
  # shellcheck disable=SC2016
  grep -F '${XDG_CONFIG_HOME:-$HOME/.config}/asdf-direnv/bashrc' "$HOME/.bashrc"
  grep "export ASDF_DIRENV_BIN" "$XDG_CONFIG_HOME/asdf-direnv/bashrc"
  # shellcheck disable=SC2016
  grep -F 'eval "$($ASDF_DIRENV_BIN hook bash)"' "$XDG_CONFIG_HOME/asdf-direnv/bashrc"
  grep "asdf direnv hook asdf" "$XDG_CONFIG_HOME/direnv/lib/use_asdf.sh"
}

@test "setup zsh modifies rcfile" {
  run asdf direnv setup --shell zsh --version system
  # shellcheck disable=SC2016
  grep -F '${XDG_CONFIG_HOME:-$HOME/.config}/asdf-direnv/zshrc' "$HOME/.zshrc"
  grep "export ASDF_DIRENV_BIN" "$XDG_CONFIG_HOME/asdf-direnv/zshrc"
  # shellcheck disable=SC2016
  grep -F 'eval "$($ASDF_DIRENV_BIN hook zsh)"' "$XDG_CONFIG_HOME/asdf-direnv/zshrc"
  grep "asdf direnv hook asdf" "$XDG_CONFIG_HOME/direnv/lib/use_asdf.sh"
}

@test "setup fish modifies rcfile" {
  run asdf direnv setup --shell fish --version system
  grep "set -gx ASDF_DIRENV_BIN" "$XDG_CONFIG_HOME/fish/conf.d/asdf_direnv.fish"
  # shellcheck disable=SC2016
  grep -F '$ASDF_DIRENV_BIN hook fish' "$XDG_CONFIG_HOME/fish/conf.d/asdf_direnv.fish"
  grep "asdf direnv hook asdf" "$XDG_CONFIG_HOME/direnv/lib/use_asdf.sh"
}

@test "can re-run setup" {
  run asdf direnv setup --shell zsh --version 2.30.3
  grep "export ASDF_DIRENV_BIN=\"$HOME/.asdf/installs/direnv/2.30.3/bin/direnv" "$XDG_CONFIG_HOME/asdf-direnv/zshrc"

  run asdf direnv setup --shell zsh --version 2.31.0
  grep "export ASDF_DIRENV_BIN=\"$HOME/.asdf/installs/direnv/2.31.0/bin/direnv" "$XDG_CONFIG_HOME/asdf-direnv/zshrc"
}
