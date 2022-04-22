#!/usr/bin/env bash

set -Eeuo pipefail

# TODO: remove once we release 0.4.0
cat <<-'EOF' >&2
Looks like you are using the 'asdf direnv hook asdf' command which was removed in asdf-direnv 0.3.0.

You might want to run 'asdf direnv setup' again. See the README for instructions on updating.

Also, be sure to remove the old integration from '~/.config/direnv/direnvrc'. Look for a line that reads 'asdf direnv hook asdf'.

The new setup command will use (and automatically manage) '~/.config/direnv/lib/use_asdf.sh' instead, 
since '~/.config/direnv/direnvrc' is intended for people to manually customize.
EOF
exit 1
