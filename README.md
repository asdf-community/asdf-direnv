# asdf-direnv

[direnv](https://direnv.net) plugin for asdf version manager

## Build History

[![Build history](https://buildstats.info/github/chart/asdf-community/asdf-direnv?branch=master)](https://github.com/asdf-community/asdf-direnv/actions)

## Motivation (or shims de-motivation)

asdf version resolution [_is slow_](https://github.com/asdf-community/asdf-direnv/issues/80#issuecomment-1079485165) which makes every command execution pay that penalty. `asdf reshim` is needed for finding new executables, and some tools are not happy with their executables being masked by shims.

<details>

[asdf](https://asdf-vm.com) is a great tool for managing multiple versions of
command-line tools. 99% of the time these managed tools work just as expected.

Shims are just tiny wrappers created by asdf that just forward execution to the
_real_ versioned executables installed by asdf. This way, asdf has a single
shims directory added to your PATH and has no need of mangling the PATH for
every installed version.

When you run an asdf-managed command, like `node`, it will actually execute an
asdf-shim, which will determine the `node` version to activate according to your
`.tool-versions` file.

A downside of this is that every single time you run `node` asdf will have to
determine again which version to use. Even if you haven't changed your
`.tool-versions` file to upgrade the node version to use. And this happens for
every shim execution, which could lead to some users experiencing certain
_slowness_ while asdf is looking up versions, since it has to traverse
directories looking up for a .tool-versions file and probably also legacy
version files.

Another inconvenience is that commands installed by these tools can have some
problems by the way asdf shims work. For example, if a command tries to find
itself by name in PATH (e.g. using `which my-command`) it will find the asdf
shim executable and not the _actual_ executable delegated-to by asdf. This might
cause problems if the command tries to use this location as an installation root
to find auxiliary files, since shims will mask the real executable.

Also, people frequently ask why is reshim needed. Suppose you used asdf to
install a package manager like `npm`, `hex`, `gem`, `cargo`, etc. Any new
binaries installed by these tools won't be available on PATH unless you run
`asdf reshim`. This is because asdf has no way of knowing what the `npm install`
command does, and it's until `asdf reshim` that it will figure out new
executables are available and will create shims for them accordingly.

And finally, some packages come not only with language-specific commands, but
with tons of system tools that will shadow those already installed on your
system. While this may be desirable while the language is in use, having it
installed and not activated leaves dead shims all over the place.

</details>

## Solution

Perform asdf version resolution only once and defer environment loading to direnv.

<details>

All these previously mentioned issues can be solved by using asdf along with the
[direnv](https://direnv.net/) tool.

Just like asdf is a tools manager, direnv is an environment-variables manager.
It can update your shell env upon directory change and clean it up when you
leave that directory.

This `asdf-direnv` plugin lets you install `direnv` and also provides a tiny
script to integrate both. Allowing `direnv` to manage any variables exposed by
asdf tools, primarily the PATH environment, but also any other variable exposed
by your plugin (e.g. MIX_HOME exposed by the asdf-elixir plugin).

This way, running `node` will not invoke the asdf-shim but the _real_
asdf-managed executable in PATH. Which will improve speed since version
resolution is out of the way and made only once by `direnv` upon entering your
project directory. Commands trying to find themselves in PATH will find their
expected location. Also, no more _reshim_ needed upon `npm install`.

</details>

## Prerequirements

- Make sure you have the required dependencies installed:
  - curl
  - git

## Usage

### Setup

Install this plugin and run the setup command for all of your preferred shells `bash`/`fish`/`zsh`.

```bash
# for version 0.15 and before
asdf plugin-add direnv
asdf direnv setup --shell bash --version latest
# for asdf 0.16 or higher
asdf plugin add direnv
asdf cmd direnv setup --shell bash --version latest
```

If you already have a `direnv` installation, you can specify `--version system`.

Otherwise this plugin can install it for you. Specify either `--version latest`
or a [direnv release](https://github.com/direnv/direnv/releases) as shown by
`asdf list-all direnv` or`asdf list all direnv` in asdf 0.16 or later.

The setup will hint which files were modified, you might want to review its
changes. After setup, close and open your terminal.

### Configuration

By default asdf-direnv will fail if a plugin is not installed, but is possible
to change this using the environment variable
`ASDF_DIRENV_IGNORE_MISSING_PLUGINS=1`

### Per-Project Environments

Once direnv is hooked into your system, use the `asdf direnv local` (or `asdf
cmd direnv local` for asdf 0.16 or higher) command on your project root
directory to update your environment.

````bash # pre asdf 0.15 asdf direnv local [<tool> <version>]... # asdf 0.16 and
higher asdf cmd direnv local [<tool> <version>]... ```

#### Temporary environments for one-shot commands

Some times you just want to execute a one-shot commmand under certain
environment without creating/modifying `.envrc` and `.tool-versions` files on
your project directory. In those cases, you might want to try using `asdf direnv
shell` or `asdf cmd direnv shell` for asdf 0.16 or higher.

```bash # Enter a new shell having python and node pre 0.16 $ asdf direnv shell
python 3.8.10 nodejs 14.18.2 # asdf 0.16 and higher $ asdf cmd direnv shell
python 3.8.10 nodejs 14.18.2

# Just execute a npx command under some node version. pre 0.16 $ asdf direnv
shell nodejs 14.18.2 -- npx create-react-app # asdf 0.16 and higher $ asdf cmd
direnv shell nodejs 14.18.2 -- npx create-react-app ```

<details> <summary><h3>Updating</h3></summary>

Updating this plugin is the same as any asdf plugin:

  asdf plugin update direnv

Updating the version of direnv you use depends on which installation method
you've chosen:

  - `system`: Nothing special required here, whenever your system package
  manager updates direnv, this plugin will use the updated version.

  - `latest` or `<direnv-release-version>`: Re-run `asdf direnv setup --version
  latest --shell ...` (or `asdf cmd direnv setup --version lastest --shell ...`
  for asdf 0.16 or higher) to update to the latest version of direnv. One may
  optionally add `--no-touch-rc-file` to the command to prevent the shell rc
  file from being modified during the update.

  (NOTE: One may alternatively `export ASDF_DIRENV_NO_TOUCH_RC_FILE=1` to
  permanently prevent modification of shell rc files during updates.)

</details>

<details> <summary><h6>Cached environment</h6></summary>

To speed up things a lot, this plugin creates direnv `envrc` files that contain
your tools environment. They are created automatically whenever your `.envrc` or
your `.tool-versions` files change.

Cached environment files can be found under `$XDG_CACHE_HOME/asdf-direnv/env`.
On most systems that resolves to `~/.config/asdf-direnv/env`. It's always safe
to remove files on this directory since they will be re-generated if missing.

If you ever need to regenerate a cached environment file, just `touch .envrc`.
asdf 0.16 or higher)

Also, the `asdf direnv envrc` (or `asdf cmd direnv envrc` for asdf 0.16 or
higher) for command will print the path to the cached environment file used for
your project.

Now when you leave your project directory and come back to it, direnv will
manage the environment variables for you really fast. For example:

  ```bash direnv: loading .envrc direnv: using asdf direnv: Creating env file
  ~/.cache/asdf-direnv/env/909519368-2773408541-1591703797-361987458 direnv:
  loading ~/.cache/asdf-direnv/env/909519368-2773408541-1591703797-361987458
  direnv: using asdf elixir 1.8.1-otp-21 direnv: using asdf nodejs 12.6.0
  direnv: export +MIX_ARCHIVES +MIX_HOME +NPM_CONFIG_PREFIX ~PATH ```

</details>

<details> <summary><h6>Benchmark</h6></summary>

![benchmark](https://user-images.githubusercontent.com/38746192/67657932-8483fb80-f99b-11e9-96d8-3d46d419ea62.png)

  #### `node --version`

with asdf-direnv:

| Mean [ms] | Min [ms] | Max [ms] | Relative | | --------: | -------: | -------:
| -------: | | 4.3 ± 0.4 |      3.6 |      6.0 |     1.00 |

without asdf-direnv:

|   Mean [ms] | Min [ms] | Max [ms] | Relative | | ----------: | -------: |
-------: | -------: | | 189.7 ± 2.7 |    185.6 |    194.0 |     1.00 |

```bash hyperfine 'node --version' ```

  ---

  #### `npm install -g yarn`

with asdf-direnv:

|    Mean [ms] | Min [ms] | Max [ms] | Relative | | -----------: | -------: |
-------: | -------: | | 683.3 ± 17.3 |    667.9 |    725.1 |     1.00 |

without asdf-direnv:

|    Mean [ms] | Min [ms] | Max [ms] | Relative | | -----------: | -------: |
-------: | -------: | | 870.0 ± 12.9 |    848.4 |    894.6 |     1.00 |

```bash hyperfine --cleanup 'npm uninstall -g yarn' 'npm install -g yarn' ```

</details>

<details> <summary><h3>Pro-Tips</h3></summary>

  - Take a look at `direnv help true`.

  - Getting `$ASDF_DIR/shims` out of the PATH.

  Some users might want to bypass asdf shims altogether. To do so, include only
  `$ASDF_DIR/bin` in your PATH but exclude the shims directory.

  All shims are still available via `asdf exec <shim>`

  ```bash # ~/.bashrc or equivalent

  # Don't source `~/.asdf/asdf.sh` PATH="$PATH:~/.asdf/bin" ```

  Note: This will break any [global
  defaults](https://asdf-vm.com/guide/getting-started.html#global) you have
  specified in `~/.tool-versions`. There are various workarounds for this:

  - Do all work in project directories with their own `.envrc` and
  `.tool-versions`
  - Use [`asdf direnv shell`](#temporary-environments-for-one-shot-commands) for
  one-shot commands or `asdf cmd direnv shell` for asdf 0.16 and higher
  - Create a `~/.envrc` with `use asdf` in it
  - Use your OS's package manager to install any tools you want globally
  accessible

  There are pros and cons to each of these approaches, it's up to you to pick
  the approach that works best for your workstyle.

  - If you want to silence the console output of direnv, you can do that by
  setting an empty environment variable: `export DIRENV_LOG_FORMAT=""`.

  - Some times you might need to configure IDEs or other tools to find
  executables like package managers/code linters/compilers being used on a
  project of yours. For example, to execute `npm` outside your project directory
  you can do:

```bash direnv exec /some/project npm ```

- Remember that activation order is important.

  If a local `.tool-versions` file is present, the order of listed plugins will be
  preserved, so that toolA will be present before toolB in PATH.

```bash
# .tool-versions
toolA 1.0
toolB 2.0
````

- You can `use asdf` even if current directory has no `.tool-versions` file.

  In this case the the activated versions will be the same than those returned
  by `asdf current` command.

- You can override any tool version via environment variables.

  See the asdf documentation regarding versions from environment variables.

```bash
# .envrc
export ASDF_PLUGIN_VERSION=1.0
use asdf
```

- Remember `direnv` can reload the environment whenever a file changes. By
  default this plugin will watch any `.tool-versions` file or legacy version
  file that explicitly selects a tool.

But you can easily watch more files when needed.

```bash
# .envrc
watch_file "package.json"
```

- Using `direnv status` can be helpful to inspect current state. Also,
  you might want to take a look to `direnv --help`.

- Using a non-empty `ASDF_DIRENV_DEBUG` will enable bash-tracing with `set -x` and skip env-cache.

  For example, if you are troubleshooting or trying to debug something weird on
  your environment, use `export ASDF_DIRENV_DEBUG=true; direnv reload` and provide any
  relevant output on an [issue](issues/new).

  Also, if you are contributing a new feature or bug-fix try running
  `env ASDF_DIRENV_DEBUG=true bats -x test` to run all tests with trace mode. If any test
  fails you will see more output.

</details>

## Useful links

Read [direnv documentation](https://direnv.net/) for more on `.envrc`.

If you are willing to contribute, be sure to read our [CONTRIBUTING](https://github.com/asdf-community/asdf-direnv/blob/master/CONTRIBUTING.md) guide.

## License

Licensed under the
[Apache License, Version 2.0](https://www.apache.org/licenses/LICENSE-2.0).
