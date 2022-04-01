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
  grep "export ASDF_DIRENV_BIN" "$HOME/.bashrc"
  grep -F 'eval "$($ASDF_DIRENV_BIN hook bash)"' "$HOME/.bashrc"
  grep "asdf direnv hook asdf" "$XDG_CONFIG_HOME/direnv/lib/use_asdf.sh"
}

@test "setup zsh modifies rcfile" {
  run asdf direnv setup --shell zsh --version system
  grep "export ASDF_DIRENV_BIN" "$HOME/.zshrc"
  grep -F 'eval "$($ASDF_DIRENV_BIN hook zsh)"' "$HOME/.zshrc"
  grep "asdf direnv hook asdf" "$XDG_CONFIG_HOME/direnv/lib/use_asdf.sh"
}

@test "setup fish modifies rcfile" {
  run asdf direnv setup --shell fish --version system
  grep "set -gx ASDF_DIRENV_BIN" "$XDG_CONFIG_HOME/fish/conf.d/asdf_direnv.fish"
  grep -F '$ASDF_DIRENV_BIN hook fish' "$XDG_CONFIG_HOME/fish/conf.d/asdf_direnv.fish"
  grep "asdf direnv hook asdf" "$XDG_CONFIG_HOME/direnv/lib/use_asdf.sh"
}
