#!/usr/bin/env bats
# -*- shell-script -*-

load test_helpers

setup() {
  env_setup
  EXPECTED_USE_ASDF="$(
    cat <<-'EOF'
use_asdf() {
  source_env "$(asdf cmd direnv envrc "$@")"
}
EOF
  )"
  export EXPECTED_USE_ASDF
}

teardown() {
  env_teardown
}

@test "setup bash modifies rcfile" {
  run asdf cmd direnv setup --shell bash --version system
  # shellcheck disable=SC2016
  grep -F '${XDG_CONFIG_HOME:-$HOME/.config}/asdf-direnv/bashrc' "$HOME/.bashrc"
  grep "export ASDF_DIRENV_BIN" "$XDG_CONFIG_HOME/asdf-direnv/bashrc"
  # shellcheck disable=SC2016
  grep -F 'eval "$($ASDF_DIRENV_BIN hook bash)"' "$XDG_CONFIG_HOME/asdf-direnv/bashrc"
  grep -F "$EXPECTED_USE_ASDF" "$XDG_CONFIG_HOME/direnv/lib/use_asdf.sh"
}

@test "setup zsh modifies rcfile (ZDOTDIR unset)" {
  unset ZDOTDIR
  run asdf cmd direnv setup --shell zsh --version system
  # shellcheck disable=SC2016
  grep -F '${XDG_CONFIG_HOME:-$HOME/.config}/asdf-direnv/zshrc' "$HOME/.zshrc"
  grep "export ASDF_DIRENV_BIN" "$XDG_CONFIG_HOME/asdf-direnv/zshrc"
  # shellcheck disable=SC2016
  grep -F 'eval "$($ASDF_DIRENV_BIN hook zsh)"' "$XDG_CONFIG_HOME/asdf-direnv/zshrc"
  grep -F "$EXPECTED_USE_ASDF" "$XDG_CONFIG_HOME/direnv/lib/use_asdf.sh"
}

@test "setup zsh modifies rcfile (ZDOTDIR set)" {
  # shellcheck disable=SC2030
  export ZDOTDIR="${XDG_CONFIG_HOME:-$HOME/.config}/zsh"
  run asdf cmd direnv setup --shell zsh --version system
  # shellcheck disable=SC2016
  grep -F '${XDG_CONFIG_HOME:-$HOME/.config}/asdf-direnv/zshrc' "$HOME/.config/zsh/.zshrc"
  grep "export ASDF_DIRENV_BIN" "$XDG_CONFIG_HOME/asdf-direnv/zshrc"
  # shellcheck disable=SC2016
  grep -F 'eval "$($ASDF_DIRENV_BIN hook zsh)"' "$XDG_CONFIG_HOME/asdf-direnv/zshrc"
  grep -F "$EXPECTED_USE_ASDF" "$XDG_CONFIG_HOME/direnv/lib/use_asdf.sh"
}

@test "setup fish modifies rcfile" {
  export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
  run asdf cmd direnv setup --shell fish --version system
  grep "set -gx ASDF_DIRENV_BIN" "$XDG_DATA_HOME/fish/vendor_conf.d/asdf_direnv.fish"
  # shellcheck disable=SC2016
  grep -F '$ASDF_DIRENV_BIN hook fish' "$XDG_DATA_HOME/fish/vendor_conf.d/asdf_direnv.fish"
  grep -F "$EXPECTED_USE_ASDF" "$XDG_CONFIG_HOME/direnv/lib/use_asdf.sh"
}

@test "setup bash, do not modify rcfile (ASDF_DIRENV_NO_TOUCH_RC_FILE unset)" {
  unset ASDF_DIRENV_NO_TOUCH_RC_FILE
  run asdf cmd direnv setup --no-touch-rc-file --shell bash --version system
  # shellcheck disable=SC2016
  grep -F '${XDG_CONFIG_HOME:-$HOME/.config}/asdf-direnv/bashrc' "$HOME/.bashrc" && return 1 || return 0
}

@test "setup zsh, do not modify rcfile (ASDF_DIRENV_NO_TOUCH_RC_FILE unset) (ZDOTDIR unset)" {
  unset ASDF_DIRENV_NO_TOUCH_RC_FILE
  unset ZDOTDIR
  run asdf cmd direnv setup --no-touch-rc-file --shell zsh --version system
  # shellcheck disable=SC2016
  grep -F '${XDG_CONFIG_HOME:-$HOME/.config}/asdf-direnv/zshrc' "$HOME/.zshrc" && return 1 || return 0
}

@test "setup zsh, do not modify rcfile (ASDF_DIRENV_NO_TOUCH_RC_FILE unset) (ZDOTDIR set)" {
  unset ASDF_DIRENV_NO_TOUCH_RC_FILE
  # shellcheck disable=SC2030,SC2031
  export ZDOTDIR="${XDG_CONFIG_HOME:-$HOME/.config}/zsh"
  run asdf cmd direnv setup --no-touch-rc-file --shell zsh --version system
  # shellcheck disable=SC2016
  grep -F '${XDG_CONFIG_HOME:-$HOME/.config}/asdf-direnv/zshrc' "$HOME/.config/zsh/.zshrc" && return 1 || return 0
}

@test "setup bash, do not modify rcfile (ASDF_DIRENV_NO_TOUCH_RC_FILE set)" {
  # shellcheck disable=SC2030,SC2031
  export ASDF_DIRENV_NO_TOUCH_RC_FILE=1
  run asdf cmd direnv setup --shell bash --version system
  # shellcheck disable=SC2016
  grep -F '${XDG_CONFIG_HOME:-$HOME/.config}/asdf-direnv/bashrc' "$HOME/.bashrc" && return 1 || return 0
}

@test "setup zsh, do not modify rcfile (ASDF_DIRENV_NO_TOUCH_RC_FILE set) (ZDOTDIR unset)" {
  # shellcheck disable=SC2030,SC2031
  export ASDF_DIRENV_NO_TOUCH_RC_FILE=1
  unset ZDOTDIR
  run asdf cmd direnv setup --shell zsh --version system
  # shellcheck disable=SC2016
  grep -F '${XDG_CONFIG_HOME:-$HOME/.config}/asdf-direnv/zshrc' "$HOME/.zshrc" && return 1 || return 0
}

@test "setup zsh, do not modify rcfile (ASDF_DIRENV_NO_TOUCH_RC_FILE set) (ZDOTDIR set)" {
  # shellcheck disable=SC2031
  export ASDF_DIRENV_NO_TOUCH_RC_FILE=1
  # shellcheck disable=SC2031
  export ZDOTDIR="${XDG_CONFIG_HOME:-$HOME/.config}/zsh"
  run asdf cmd direnv setup --shell zsh --version system
  # shellcheck disable=SC2016
  grep -F '${XDG_CONFIG_HOME:-$HOME/.config}/asdf-direnv/zshrc' "$HOME/.config/zsh/.zshrc" && return 1 || return 0
}

@test "can re-run setup" {
  run asdf cmd direnv setup --shell zsh --version 2.30.3
  grep "export ASDF_DIRENV_BIN=\"$HOME/.asdf/installs/direnv/2.30.3/bin/direnv" "$XDG_CONFIG_HOME/asdf-direnv/zshrc"

  run asdf cmd direnv setup --shell zsh --version 2.31.0
  grep "export ASDF_DIRENV_BIN=\"$HOME/.asdf/installs/direnv/2.31.0/bin/direnv" "$XDG_CONFIG_HOME/asdf-direnv/zshrc"
}
