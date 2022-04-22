#!/usr/bin/env bats
# -*- shell-script -*-

load test_helpers

setup() {
  env_setup
  asdf direnv setup --shell bash --version system
}

teardown() {
  env_teardown
}

@test "local command touches .tool-versions and .envrc - single tool" {
  install_dummy_plugin "dummy" "1.0"

  run asdf direnv local dummy 1.0
  grep "dummy 1.0" ".tool-versions"
  grep "use asdf" ".envrc"

  asdf direnv local
  envrc_load
  run dummy

  [ "$output" = "This is dummy 1.0" ]
}

@test "local command touches .tool-versions and .envrc - multiple tools" {
  install_dummy_plugin "dummy" "1.0"
  install_dummy_plugin "gummy" "2.0"

  asdf direnv local gummy 2.0 dummy 1.0

  run cat .tool-versions
  [ "${lines[0]}" = "gummy 2.0" ]
  [ "${lines[1]}" = "dummy 1.0" ]

  run cat .envrc
  [ "${lines[0]}" = "use asdf" ]

  envrc_load

  run dummy
  [ "$output" = "This is dummy 1.0" ]

  run gummy
  [ "$output" = "This is gummy 2.0" ]
}
