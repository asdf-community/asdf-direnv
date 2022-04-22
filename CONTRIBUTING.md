# All contributions welcome

Not only code-related, you are also welcome to contribute by reporting new
issues you might find or by helping others on discussions, or by promoting
the usage of this tool with your friends/co-workers/audience.

The only requirement is being kind and mindful of others, all communication
shall be done with respect and without any kind of discrimination nor aggresive
language/attitudes towards anyone.

# Contributing code

When contributing code, consider adding a new test unless you see that your code
change is trivial and is already being covered by an existing test.
In that case, mention which test is already testing your feature on the pull-request.

For new features, it's essential to have a new test that exercises the new code path
and feature.

## Code conventions

Executable commands are under `lib/commands/command-*.bash` and follow the asdf
convention for defining custom commands. These commands are intended to be
executed directly by our users, and shall always start with `set -Eeuo pipefail`
in order to stop on first error. Commands shall not source each other. The ony
way to share code is to source other bash files outside of `lib/commands`.


We are not strictly POSIX complaint, nor seek to have it as a requirement, but
we do want things to work on both Linux and MacOS (our CI runs on both OSes).
When possible, prefer commands and options that work on most platforms.


Naming is hard, try to name shell functions according to their intention.
As a convention, private auxiliary functions (not intended to be used by commands)
might start with an underscore.


Prefer splitting code into functions instead of having a very long function do all the things.

Test shall also be kept small and focused to a single feature, but feel free to add
more tests if a single feature can have variations. eg, if we support several shells
be sure to have tests for each of them.

If you are adding a new command, create a new test suite (that is a `.bats` file) for it.

See how other tests are implemented, and use them as starting point. Use our `envrc_load`
defined at `test_helpers.bash` in order to load the direnv environment on your test.
Also, be sure to read about [`bats-core`](https://github.com/bats-core/bats-core) usage, most importantly its `run` and `$output`.

## Development tools

You'll need the following software installed: `asdf`, `make`, `bats-core`, `shfmt` and `shellcheck`.
Some people might install those with [asdf-plugins](https://github.com/asdf-vm/asdf-plugins) or perhaps as system installed packages.

Note that on this project `.envrc` and `.tool-versions` files are git-ignored so you can choose
freely where these tools come from on your local environment.

## Running tests

Running `make` will perform all integration tests, check formatting, and check for common shell problems in code.

## Debugging tests

If you find a test broken by your changes sometimes it's better to run just that particular test
with tracing mode enabled.

```
# Run a single test, all things you echo on your test code will be visible on your terminal. tip: `echo $output`
env ASDF_DIRENV_DEBUG=true  bats -x test/use_asdf.bats -f 'use multiple versions for same plugin - multiline'
```

## Getting help

Your pull-request does not need to be perfect. If you feel like you've implemented your core idea
and did your best on writing tests but something still fails, push and create the pull-request anyways.
Ask for help and we will be happy to get things sorted out.

> Quærendo Invenietis: Seek and you shall find.
