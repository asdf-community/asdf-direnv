#!/usr/bin/env bats
# -*- shell-script -*-

load test_helpers

setup() {
  setup_asdf_direnv
}

teardown() {
  clean_asdf_direnv
}

@test "local command touches .tool-versions and .envrc" {
  install_dummy_plugin "dummy" "1.0"

  run asdf direnv setup bash
  run asdf direnv local dummy 1.0
  grep "dummy 1.0" ".tool-versions"
  grep "use asdf" ".envrc"

  source "$HOME/.bashrc"
  envrc_load
  run dummy

  [ "$output" = "This is dummy 1.0" ]
}
