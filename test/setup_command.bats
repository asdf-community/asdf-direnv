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
  run asdf direnv setup bash
  grep "export ASDF_DIRENV_BIN" "$HOME/.bashrc"
  grep "direnv hook bash" "$HOME/.bashrc"
  grep "asdf direnv hook asdf" "$XDG_CONFIG_HOME/direnv/lib/use_asdf.sh"
}

@test "setup zsh modifies rcfile" {
  run asdf direnv setup zsh
  grep "export ASDF_DIRENV_BIN" "$HOME/.zshrc"
  grep "direnv hook zsh" "$HOME/.zshrc"
  grep "asdf direnv hook asdf" "$XDG_CONFIG_HOME/direnv/lib/use_asdf.sh"
}

@test "setup fish modifies rcfile" {
  run asdf direnv setup fish
  grep "set -g ASDF_DIRENV_BIN" "$XDG_CONFIG_HOME/fish/conf.d/asdf_direnv.fish"
  grep "direnv hook fish" "$XDG_CONFIG_HOME/fish/conf.d/asdf_direnv.fish"
  grep "asdf direnv hook asdf" "$XDG_CONFIG_HOME/direnv/lib/use_asdf.sh"
}
