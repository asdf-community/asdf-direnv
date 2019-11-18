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

@test "use asdf [name] [version] - prepends plugin/bin to PATH" {
  install_dummy_plugin dummy 1.0

  cd "$PROJECT_DIR"
  envrc_use_asdf dummy 1.0

  [ ! $(command -v dummy) ] # not available
  envrc_load

  run dummy
  [ "$output" == "This is dummy 1.0" ] # executable in path

  # plugin bin at head of PATH
  path_as_lines | sed -n 1p | grep "$(dummy_bin_path dummy 1.0)"
}


@test "use asdf [name] [version] - prepends plugin custom shims to PATH" {
  echo "If a plugin has helper shims defined, they also appear on PATH"
  install_dummy_plugin dummy 1.0 mummy

  cd "$PROJECT_DIR"
  envrc_use_asdf dummy 1.0

  [ ! $(command -v mummy) ] # not available
  [ ! $(command -v dummy) ] # not available
  envrc_load

  run mummy
  [ "$output" == "This is dummy mummy shim" ] # executable in path

  run dummy
  [ "$output" == "This is dummy 1.0" ] # executable in path

  # plugin bin at head of PATH
  path_as_lines | sed -n 1p | grep "$(dummy_shims_path dummy 1.0)"
  path_as_lines | sed -n 2p | grep "$(dummy_bin_path dummy 1.0)"
}

@test "use asdf [name] [version] - exports plugin custom env not only PATH" {
  install_dummy_plugin dummy 1.0
  cat <<-EOF > "$ASDF_DATA_DIR/plugins/dummy/bin/exec-env"
#!/usr/bin/env bash
export JOJO=JAJA
EOF
  chmod +x "$ASDF_DATA_DIR/plugins/dummy/bin/exec-env"

  cd "$PROJECT_DIR"
  envrc_use_asdf dummy 1.0
  envrc_load

  [ "$JOJO" == "JAJA" ] # Env exported by plugin
}

@test "use asdf [name] - determines version from tool-versions" {
  install_dummy_plugin dummy 1.0
  install_dummy_plugin dummy 2.0

  cd "$PROJECT_DIR"
  asdf global dummy 1.0
  asdf local dummy 2.0
  envrc_use_asdf dummy
  envrc_load

  run dummy
  [ "$output" == "This is dummy 2.0" ] # executable in path
}


@test "use asdf [name] - watches tool-versions for changes" {
  install_dummy_plugin dummy 1.0

  cd "$PROJECT_DIR"
  asdf local dummy 1.0
  envrc_use_asdf dummy
  envrc_load

  asdf exec direnv status | grep -F 'Loaded watch: ".tool-versions"'
}

@test "use asdf [name] - watches plugin legacy file for changes" {
  install_dummy_plugin dummy 1.0
  setup_dummy_legacyfile dummy .dummy-version

  cd "$PROJECT_DIR"
  echo "1.0" > "$PROJECT_DIR/.dummy-version"
  envrc_use_asdf dummy
  envrc_load

  run dummy
  [ "$output" == "This is dummy 1.0" ]

  asdf exec direnv status | grep -F 'Loaded watch: ".dummy-version"'
}

@test "use asdf local - loads only from local tool-versions" {
  install_dummy_plugin dummy 1.0
  install_dummy_plugin dummy 2.0
  install_dummy_plugin gummy 1.0

  cd "$PROJECT_DIR"
  asdf global dummy 1.0
  asdf global gummy 1.0
  asdf local  dummy 2.0

  envrc_use_asdf local
  envrc_load

  run dummy
  [ "$output" == "This is dummy 2.0" ]

  [ ! $(command -v gummy) ] # gummy not available
  [ ! $(path_as_lines | grep "$(dummy_bin_path dummy 1.0)") ]
}

@test "use asdf local - watches tool-versions for changes" {
  install_dummy_plugin dummy 1.0

  cd "$PROJECT_DIR"
  asdf local dummy 1.0
  envrc_use_asdf local
  envrc_load

  asdf exec direnv status | grep -F 'Loaded watch: ".tool-versions"'
}

@test "use asdf current - activates currently selected plugins" {
  install_dummy_plugin dummy 1.0
  install_dummy_plugin dummy 2.0
  install_dummy_plugin gummy 1.0
  install_dummy_plugin puppy 2.0
  install_dummy_plugin mummy 1.0 # installed, but not seelcted globally nor locally

  setup_dummy_legacyfile dummy .dummy-version

  cd "$PROJECT_DIR"
  asdf global dummy 1.0
  asdf global gummy 1.0

  echo "2.0" > "$PROJECT_DIR/.dummy-version"
  asdf local puppy 2.0

  envrc_use_asdf current
  envrc_load

  run dummy # selected from legacyfile
  [ "$output" == "This is dummy 2.0" ]

  run puppy # selected from local tool-versions
  [ "$output" == "This is puppy 2.0" ]

  run gummy # selected from global tool-versions
  [ "$output" == "This is gummy 1.0" ]

  [ ! $(command -v mummy) ] # never selected
  [ ! $(path_as_lines | grep "$(dummy_bin_path dummy 1.0)") ]
}

@test "use asdf current - watches selection files" {
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

  envrc_use_asdf current
  envrc_load

  asdf exec direnv status | grep -F 'Loaded watch: ".tool-versions"'
  asdf exec direnv status | grep -F 'Loaded watch: "../.tool-versions"'
}

@test "use asdf current - watches legacy files" {
  install_dummy_plugin dummy 2.0
  setup_dummy_legacyfile dummy .dummy-version

  cd "$PROJECT_DIR"
  echo "2.0" > "$PROJECT_DIR/.dummy-version"

  envrc_use_asdf current
  envrc_load

  asdf exec direnv status
  asdf exec direnv status | grep -F 'Loaded watch: ".dummy-version"'
}

@test "use asdf current - sets local tools on PATH before global tools" {
  # NOTE: order between tools is undefined when xargs maxproc > 1
  export ASDF_CONCURRENCY=1 # Disabled xargs parallelism for deterministic tests

  install_dummy_plugin dummy 1.0
  install_dummy_plugin gummy 1.0
  install_dummy_plugin mummy 1.0
  install_dummy_plugin puppy 1.0
  install_dummy_plugin rummy 1.0

  setup_dummy_legacyfile dummy .dummy-version

  cd "$PROJECT_DIR"
  asdf global mummy 1.0
  asdf global rummy 1.0

  echo "1.0" > "$PROJECT_DIR/.dummy-version"
  asdf local puppy 1.0
  asdf local gummy 1.0

  envrc_use_asdf current
  envrc_load

  path_as_lines
  local dummy_line="$(path_as_lines | grep -n -F "$(dummy_bin_path dummy 1.0)" | cut -d: -f1)"
  local gummy_line="$(path_as_lines | grep -n -F "$(dummy_bin_path gummy 1.0)" | cut -d: -f1)"
  local mummy_line="$(path_as_lines | grep -n -F "$(dummy_bin_path mummy 1.0)" | cut -d: -f1)"
  local puppy_line="$(path_as_lines | grep -n -F "$(dummy_bin_path puppy 1.0)" | cut -d: -f1)"
  local rummy_line="$(path_as_lines | grep -n -F "$(dummy_bin_path rummy 1.0)" | cut -d: -f1)"

  [ "$puppy_line" -lt "$gummy_line" ] # first tool in tool-versions is also first on PATH
  [ "$gummy_line" -lt "$mummy_line" ] # local plugins should be on PATH before gloabl ones
  [ "$puppy_line" -lt "$mummy_line" ]
  [ "$puppy_line" -lt "$dummy_line" ] # since dummy is not in tool-versions its loaded after local tools
  # global plugins order is lexicographical since they are not in tool-versions file
  [ "$dummy_line" -lt "$mummy_line" ] # dummy is resolved by `use asdf global` since its not in tool-versions
  [ "$mummy_line" -lt "$rummy_line" ]
}
