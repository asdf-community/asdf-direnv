#!/usr/bin/env bats
# -*- shell-script -*-

load test_helpers

setup() {
  setup_asdf_direnv
}

teardown() {
  clean_asdf_direnv
}

@test "asdf executable should be on path" {
  command -v asdf
}

@test "direnv executable should not be on path" {
  [ ! $(command -v direnv) ]
}

@test "direnv_use_asdf should not be on path" {
  [ ! $(command -v direnv_use_asdf) ]
}

@test "direnv is available via asdf" {
  asdf exec direnv --version
}

@test "direnv_use_asdf is available via asdf" {
  asdf which direnv_use_asdf
}

@test "dummy 1.0 is available via asdf exec" {
  install_dummy_plugin "dummy" "1.0"
  ASDF_DUMMY_VERSION=1.0 asdf exec dummy
  [ "$output" = "dummy 1.0" ]
}

@test "use asdf dummy 1.0 explicitly activates" {
  install_dummy_plugin "dummy" "1.0"
  echo "dummy 1.0" > "$PROJECT_DIR/.tool-versions"
  envrc_use_asdf # no args should load local file

  [ ! $(command -v dummy) ] # not available before cd
  cd "$PROJECT_DIR"
  echo $PATH
  tree -a $HOME
  command -v dummy # available after cd
}
