#!/usr/bin/env bats
# -*- shell-script -*-

load test_helpers

setup() {
  env_setup
  asdf direnv setup --shell bash --version system
  # shellcheck source=/dev/null
  source "$HOME/.bashrc"
}

teardown() {
  env_teardown
}

@test "dummy 1.0 is available via asdf exec" {
  install_dummy_plugin "dummy" "1.0"
  ASDF_DUMMY_VERSION=1.0 run asdf exec dummy
  [ "$output" == "This is dummy 1.0" ]
}

@test "direnv loads simple envrc" {
  cd "$PROJECT_DIR"

  [ -z "$FOO" ]
  echo 'export FOO=BAR' >"$PROJECT_DIR/.envrc"
  direnv allow "$PROJECT_DIR/.envrc"

  envrc_load
  [ "$FOO" == "BAR" ]
}

# This is to support asdf multiple version multiline feature
@test "use multiple versions for same plugin - multiline" {
  install_dummy_plugin dummy 1.0
  install_dummy_plugin dummy 2.0

  cd "$PROJECT_DIR"
  asdf direnv local dummy 2.0 dummy 1.0
  asdf local dummy 2.0
  echo "dummy 1.0" >>.tool-versions

  asdf direnv local
  envrc_load

  run path_as_lines
  [ "${lines[0]}" = "$(dummy_bin_path dummy 2.0)" ]
  [ "${lines[1]}" = "$(dummy_bin_path dummy 1.0)" ]
}

# This is to support asdf multiple version inline feature
@test "use multiple versions for same plugin - inline" {
  install_dummy_plugin dummy 1.0
  install_dummy_plugin dummy 2.0

  cd "$PROJECT_DIR"
  asdf local dummy 2.0 1.0
  asdf direnv local
  envrc_load

  run path_as_lines
  [ "${lines[0]}" = "$(dummy_bin_path dummy 2.0)" ]
  [ "${lines[1]}" = "$(dummy_bin_path dummy 1.0)" ]
}

@test "use asdf - makes global tools available in PATH" {
  install_dummy_plugin dummy 1.0
  install_dummy_plugin dummy 2.0

  cd "$PROJECT_DIR"
  asdf direnv local

  [ ! "$(type -P dummy)" ] # not available

  asdf global dummy 1.0
  rm -f "$PROJECT_DIR"/.tool-versions # no local tools
  touch .envrc
  envrc_load

  run dummy
  [ "$output" == "This is dummy 1.0" ] # executable in path
}

@test "use asdf - makes local tools available in PATH" {
  install_dummy_plugin dummy 1.0
  install_dummy_plugin dummy 2.0

  cd "$PROJECT_DIR"
  asdf direnv local

  [ ! "$(type -P dummy)" ] # not available

  asdf global dummy 1.0 # should be ignored by asdf
  asdf local dummy 2.0
  # Touching local .envrc file should re-create cached-envrc
  touch .envrc
  envrc_load
  run dummy
  [ "$output" == "This is dummy 2.0" ] # executable in path
}

@test "use asdf - prepends plugin custom shims to PATH" {
  echo "If a plugin has helper shims defined, they also appear on PATH"
  install_dummy_plugin dummy 1.0 mummy
  asdf global dummy 1.0

  cd "$PROJECT_DIR"
  asdf direnv local

  [ ! "$(type -P mummy)" ] # not available
  [ ! "$(type -P dummy)" ] # not available
  envrc_load

  run mummy
  [ "$output" == "This is dummy mummy shim" ] # executable in path

  run dummy
  [ "$output" == "This is dummy 1.0" ] # executable in path

  # plugin bin at head of PATH
  run path_as_lines
  path_as_lines | sed -n 1p | grep "direnv"
  path_as_lines | sed -n 2p | grep "$(dummy_bin_path dummy 1.0)"
  path_as_lines | sed -n 3p | grep "$(dummy_shims_path dummy 1.0)"
}

@test "use asdf - exports plugin custom env not only PATH" {
  install_dummy_plugin dummy 1.0
  cat <<-EOF >"$ASDF_DATA_DIR/plugins/dummy/bin/exec-env"
#!/usr/bin/env bash
export JOJO=JAJA
export FOO=$'\nBAR' # something starting with new line
EOF
  chmod +x "$ASDF_DATA_DIR/plugins/dummy/bin/exec-env"

  cd "$PROJECT_DIR"
  export ASDF_DUMMY_VERSION=1.0
  asdf direnv local
  envrc_load

  [ "$JOJO" == "JAJA" ]  # Env exported by plugin
  [ "$FOO" == $'\nBAR' ] # Keeps special chars
}

@test "use asdf - determines version from tool-versions" {
  install_dummy_plugin dummy 1.0
  install_dummy_plugin dummy 2.0

  cd "$PROJECT_DIR"
  asdf global dummy 1.0
  asdf local dummy 2.0
  asdf direnv local
  envrc_load

  run dummy
  [ "$output" == "This is dummy 2.0" ] # executable in path
}

@test "use asdf - resolves latest:X version from tool-versions" {
  install_dummy_plugin dummy 2.0
  install_dummy_plugin dummy 2.1

  cd "$PROJECT_DIR"
  asdf global dummy 2.0
  # Note: we're writing directly to .tool-versions rather than using `asdf
  # local dummy latest:2` because that `asdf local` command will actually
  # resolve the appropriate vresion rather than putting the unresolved version
  # in the .tool-versions file.
  echo "dummy latest:2" >.tool-versions
  asdf direnv local
  envrc_load

  run dummy
  [ "$output" == "This is dummy 2.1" ] # executable in path
}

@test "use asdf - resolves latest version from tool-versions" {
  install_dummy_plugin dummy 2.0
  install_dummy_plugin dummy 2.1

  cd "$PROJECT_DIR"
  # Note: we're writing directly to .tool-versions rather than using `asdf
  # local dummy latest` because that `asdf local` command will actually
  # resolve the appropriate vresion rather than putting the unresolved version
  # in the .tool-versions file.
  echo "dummy latest" >.tool-versions
  asdf direnv local
  envrc_load

  run dummy
  [ "$output" == "This is dummy 2.1" ] # executable in path
}

@test "use asdf - watches tool-versions for changes" {
  install_dummy_plugin dummy 1.0

  cd "$PROJECT_DIR"
  asdf local dummy 1.0
  asdf direnv local
  envrc_load

  direnv status | grep -F 'Loaded watch: ".tool-versions"'
}

@test "use asdf - watches plugin legacy file for changes" {
  install_dummy_plugin dummy 1.0
  setup_dummy_legacyfile dummy .dummy-version

  cd "$PROJECT_DIR"
  echo "1.0" >"$PROJECT_DIR/.dummy-version"
  asdf direnv local
  envrc_load

  run dummy
  [ "$output" == "This is dummy 1.0" ]

  direnv status | grep -F 'Loaded watch: ".dummy-version"'
}

@test "use asdf - activates currently selected plugins" {
  install_dummy_plugin dummy 1.0
  install_dummy_plugin dummy 2.0
  install_dummy_plugin gummy 1.0
  install_dummy_plugin puppy 2.0
  install_dummy_plugin mummy 1.0 # installed, but not seelcted globally nor locally

  setup_dummy_legacyfile dummy .dummy-version

  cd "$PROJECT_DIR"
  asdf global dummy 1.0
  asdf global gummy 1.0

  echo "2.0" >"$PROJECT_DIR/.dummy-version"
  asdf local puppy 2.0

  asdf direnv local
  envrc_load

  run dummy # selected from legacyfile
  [ "$output" == "This is dummy 2.0" ]

  run puppy # selected from local tool-versions
  [ "$output" == "This is puppy 2.0" ]

  run gummy # selected from global tool-versions
  [ "$output" == "This is gummy 1.0" ]

  [ ! "$(type -P mummy)" ] # not available
  # It's nice to check test output consistently.
  # shellcheck disable=SC2143
  [ ! "$(path_as_lines | grep "$(dummy_bin_path dummy 1.0)")" ]
}

@test "use asdf - watches selection files" {
  install_dummy_plugin dummy 1.0
  install_dummy_plugin dummy 2.0
  install_dummy_plugin gummy 1.0
  install_dummy_plugin puppy 2.0
  install_dummy_plugin mummy 1.0 # installed, but not seelcted globally nor locally

  cd "$PROJECT_DIR"
  asdf global dummy 1.0
  asdf global gummy 1.0

  asdf local dummy 2.0
  asdf local puppy 2.0

  asdf direnv local
  envrc_load

  direnv status | grep -F 'Loaded watch: ".tool-versions"'
  direnv status | grep -F 'Loaded watch: "../.tool-versions"'
}

@test "use asdf - watches legacy files" {
  install_dummy_plugin dummy 2.0
  setup_dummy_legacyfile dummy .dummy-version

  cd "$PROJECT_DIR"
  echo "2.0" >"$PROJECT_DIR/.dummy-version"

  asdf direnv local
  envrc_load

  direnv status
  direnv status | grep -F 'Loaded watch: ".dummy-version"'
}

@test "use asdf - sets local tools on PATH before global tools" {
  install_dummy_plugin dummy 1.0
  install_dummy_plugin gummy 1.0
  install_dummy_plugin mummy 1.0
  install_dummy_plugin puppy 1.0
  install_dummy_plugin rummy 1.0

  setup_dummy_legacyfile dummy .dummy-version

  cd "$PROJECT_DIR"
  asdf global mummy 1.0
  asdf global rummy 1.0

  echo "1.0" >"$PROJECT_DIR/.dummy-version"
  asdf local puppy 1.0
  asdf local gummy 1.0

  asdf direnv local
  envrc_load

  path_as_lines
  local dummy_line
  dummy_line="$(path_as_lines | grep -n -F "$(dummy_bin_path dummy 1.0)" | cut -d: -f1)"
  local gummy_line
  gummy_line="$(path_as_lines | grep -n -F "$(dummy_bin_path gummy 1.0)" | cut -d: -f1)"
  local mummy_line
  mummy_line="$(path_as_lines | grep -n -F "$(dummy_bin_path mummy 1.0)" | cut -d: -f1)"
  local puppy_line
  puppy_line="$(path_as_lines | grep -n -F "$(dummy_bin_path puppy 1.0)" | cut -d: -f1)"
  local rummy_line
  rummy_line="$(path_as_lines | grep -n -F "$(dummy_bin_path rummy 1.0)" | cut -d: -f1)"

  [ "$puppy_line" -lt "$gummy_line" ] # first tool in tool-versions is also first on PATH
  [ "$gummy_line" -lt "$mummy_line" ] # local plugins should be on PATH before gloabl ones
  [ "$puppy_line" -lt "$mummy_line" ]
  [ "$puppy_line" -lt "$dummy_line" ] # since dummy is not in tool-versions its loaded after local tools
  # global plugins order is lexicographical since they are not in tool-versions file
  [ "$dummy_line" -lt "$mummy_line" ] # dummy is resolved by `use asdf global` since its not in tool-versions
  [ "$mummy_line" -lt "$rummy_line" ]
}

@test "error in use asdf should not get cached" {
  # Setup: use dummy plugin v1.0
  install_dummy_plugin dummy 1.0
  cd "$PROJECT_DIR"
  asdf direnv local dummy 1.0

  # Now switch to dummy v2.0, which we do *not* have installed. This should
  # fail, but should *not* generate a cached env file of that failure.
  echo "dummy 2.0" >.tool-versions
  envrc_load &>/tmp/load1

  # Now install dummmy 2.0. The next time someone enters this directory, we
  # should successfully load this plugin.
  install_dummy_plugin dummy 2.0

  # Simulate someone entering this directory fresh: first unload before loading again.
  envrc_unload
  envrc_load

  # Finally, verify that dummy 2.0 is actually loaded. It wouldn't be if we had
  # a cached failure from the first load.
  run path_as_lines
  [ "${lines[0]}" = "$(dummy_bin_path dummy 2.0)" ]
}

@test "use asdf - ignore missing plugin" {
  install_dummy_plugin "dummy" "1.0"

  asdf direnv local dummy 1.0
  echo "missing 3.0" >>.tool-versions

  export ASDF_DIRENV_IGNORE_MISSING_PLUGINS=1
  asdf direnv local
  run envrc_load

  echo "$output" | grep "direnv: ignoring not installed plugin: missing"
}
