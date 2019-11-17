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
  ASDF_DUMMY_VERSION=1.0 run asdf exec dummy
  [ "$output" == "This is dummy 1.0" ]
}

@test "direnv loads simple envrc" {
  cd "$PROJECT_DIR"

  [ -z "$FOO" ]
  echo 'export FOO=BAR' > "$PROJECT_DIR/.envrc"
  asdf exec direnv allow "$PROJECT_DIR/.envrc"

  envrc_load
  [ "$FOO" ==  "BAR" ]
}

@test "use asdf dummy 1.0 needs no local tool-versions file" {
  cd "$PROJECT_DIR"

  install_dummy_plugin dummy 1.0
  envrc_use_asdf dummy 1.0

  [ ! $(command -v dummy) ] # not available
  envrc_load
  run dummy
  [ "$output" == "This is dummy 1.0" ]
}
