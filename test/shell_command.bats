#!/usr/bin/env bats
# -*- shell-script -*-

load test_helpers

setup() {
  setup_asdf_direnv
}

teardown() {
  clean_asdf_direnv
}

@test "calling without arguments prints help" {
  run asdf direnv shell
  echo "$output" | grep "Usage: asdf direnv shell"
}

@test "calling with --help prints help" {
  run asdf direnv shell --help
  echo "$output" | grep "Usage: asdf direnv shell"
}

@test "calling with -h prints help" {
  run asdf direnv shell -h
  echo "$output" | grep "Usage: asdf direnv shell"
}

@test "calling with plugin name but without version fails" {
  run asdf direnv shell dummy
  [ "$status" -eq 1 ]
  echo "$output" | grep "Please specify a version for dummy"
}

@test "can specify a one-shot command to run" {
  install_dummy_plugin dummy 1.0
  run asdf direnv shell dummy 1.0 -- dummy
  [ "$status" -eq 0 ]
  [ "${lines[0]}" == "direnv: using asdf dummy 1.0" ]
  [ "${lines[1]}" == "This is dummy 1.0" ]
}
