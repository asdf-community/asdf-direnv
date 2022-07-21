#!/usr/bin/env bats
# -*- shell-script -*-

load test_helpers

setup() {
  env_setup
}

teardown() {
  env_teardown
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

@test "one-shot command can use version different from global/local .tool-versions" {
  asdf direnv setup --shell bash --version system
  # shellcheck source=/dev/null
  source "$HOME/.bashrc"

  install_dummy_plugin dummy 1.0
  install_dummy_plugin dummy 2.0
  install_dummy_plugin dummy 3.0

  asdf global dummy 1.0
  asdf local dummy 2.0
  asdf direnv local

  path_as_lines | run grep 'shims'
  [ "$status" != 0 ] # should not have asdf shims on PATH

  envrc_load
  run dummy
  [ "$status" -eq 0 ]
  [ "${lines[0]}" == "This is dummy 2.0" ]

  run asdf direnv shell dummy 3.0 -- dummy
  [ "$status" -eq 0 ]
  [ "${lines[0]}" == "direnv: using asdf dummy 3.0" ]
  [ "${lines[1]}" == "This is dummy 3.0" ]

  run dummy
  [ "$status" -eq 0 ]
  [ "${lines[0]}" == "This is dummy 2.0" ]
}

@test "without command it spawns a new SHELL with specified tools" {
  echo "dummy" >"$PWD/fake-shell"
  chmod +x "$PWD/fake-shell"

  asdf direnv setup --shell bash --version system
  # shellcheck source=/dev/null
  source "$HOME/.bashrc"

  install_dummy_plugin dummy 1.0
  install_dummy_plugin dummy 2.0
  install_dummy_plugin dummy 3.0

  asdf global dummy 1.0
  asdf local dummy 2.0
  asdf direnv local

  path_as_lines | run grep 'shims'
  [ "$status" != 0 ] # should not have asdf shims on PATH

  envrc_load
  run dummy
  [ "$status" -eq 0 ]
  [ "${lines[0]}" == "This is dummy 2.0" ]

  run env SHELL="$PWD/fake-shell" asdf direnv shell dummy 3.0 # Without arguments it should run SHELL
  [ "$status" -eq 0 ]
  [ "${lines[0]}" == "direnv: using asdf dummy 3.0" ]
  [ "${lines[1]}" == "This is dummy 3.0" ]

  run dummy
  [ "$status" -eq 0 ]
  [ "${lines[0]}" == "This is dummy 2.0" ]
}
