# asdf-direnv

[direnv](https://direnv.net) plugin for asdf version manager

## Build History

[![Build history](https://buildstats.info/github/chart/asdf-community/asdf-direnv?branch=master)](https://github.com/asdf-community/asdf-direnv/actions)

## Motivation (or shims de-motivation)

asdf version resolution [*is slow*](https://github.com/asdf-community/asdf-direnv/issues/80#issuecomment-1079485165) which makes every command execution pay that penalty. `asdf reshim` is needed for finding new executables, and some tools are not happy with their executables being masked by shims.

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

#### Setup

First, make sure you install this plugin, which will make all the
`asdf direnv` subcommands available to you:

```bash
asdf plugin-add direnv
asdf help # you should see `asdf direnv` commands listed here.
```

Then, make sure you have [direnv](https://direnv.net/) installed.
You can either use your system package manager or asdf to install it:

```bash
# When already installed just activate the system version:
asdf global direnv system
```

```bash
# Install with asdf and globally activate:
asdf install direnv latest
asdf global direnv latest
```


Then edit your `.bashrc` or equivalent shell profile:

```bash
# File: ~/.bashrc

export ASDF_DIRENV_BIN="$(asdf which direnv)" # or `$(command -v direnv)` for system managed.

# Hook direnv into your shell.
eval "$($ASDF_DIRENV_BIN hook bash)"
```

If you are not using bash, adapt the previous snippet by following the
[instructions to hook direnv into various other SHELLS](https://github.com/direnv/direnv/blob/master/docs/hook.md)

##### Global asdf-direnv integration.

The [`~/.config/direnv/direnvrc`](https://direnv.net/#faq) file is a good place
to add common functionality for all `.envrc` file.

The following snippet makes the `use asdf` feature available:

```bash
# File: ~/.config/direnv/direnvrc
source "$(asdf direnv hook asdf)"

# Uncomment the following line to make direnv silent by default.
# export DIRENV_LOG_FORMAT=""
```

##### The .envrc file in your project root.

Once hooked into your shell, `direnv` will expect to find a `.envrc` file
whenever you need to change tool versions.

On your project directory, create an `.envrc` file like this:

```bash
# File: /your/project/.envrc
use asdf
```

Finally, run `direnv allow` to trust your new file.

###### Cached environment

To speed up things a lot, this plugin creates direnv `envrc` files that contain
your plugins environment. They are created whenever your `.envrc` or your
`.tool-versions` files change, and are cached under `$XDG_CACHE_HOME/asdf-direnv`.

If you ever need to regenerate a cached environment file, just `touch .envrc`.

Now when you leave your project directory and come back to it, direnv will
manage the environment variables for you really fast. For example:

```bash
direnv: loading .envrc
direnv: using asdf
direnv: Creating env file ~/.asdf/installs/direnv/2.20.0/env/909519368-2773408541-1591703797-361987458
direnv: loading ~/.asdf/installs/direnv/2.20.0/env/909519368-2773408541-1591703797-361987458
direnv: using asdf elixir 1.8.1-otp-21
direnv: using asdf nodejs 12.6.0
direnv: export +MIX_ARCHIVES +MIX_HOME +NPM_CONFIG_PREFIX ~PATH
```

## Benchmark

![benchmark](https://user-images.githubusercontent.com/38746192/67657932-8483fb80-f99b-11e9-96d8-3d46d419ea62.png)

#### `node --version`

with asdf-direnv:

| Mean [ms] | Min [ms] | Max [ms] | Relative |
| --------: | -------: | -------: | -------: |
| 4.3 ± 0.4 |      3.6 |      6.0 |     1.00 |

without asdf-direnv:

|   Mean [ms] | Min [ms] | Max [ms] | Relative |
| ----------: | -------: | -------: | -------: |
| 189.7 ± 2.7 |    185.6 |    194.0 |     1.00 |

```bash
hyperfine 'node --version'
```

---

#### `npm install -g yarn`

with asdf-direnv:

|    Mean [ms] | Min [ms] | Max [ms] | Relative |
| -----------: | -------: | -------: | -------: |
| 683.3 ± 17.3 |    667.9 |    725.1 |     1.00 |

without asdf-direnv:

|    Mean [ms] | Min [ms] | Max [ms] | Relative |
| -----------: | -------: | -------: | -------: |
| 870.0 ± 12.9 |    848.4 |    894.6 |     1.00 |

```bash
hyperfine --cleanup 'npm uninstall -g yarn' 'npm install -g yarn'
```

### Pro-Tips

- Take a look at `direnv help true`.

- Getting `$ASDF_DIR/shims` out of the PATH.

  Some users might want to bypass asdf shims altogether. To do so,
  include only `$ASDF_DIR/bin` in your PATH but exclude the shims
  directory.

  All shims are still available via `asdf exec <shim>`

```bash
# ~/.bashrc or equivalent

# Dont source `~/.asdf/asdf.sh`
PATH="$PATH:~/.asdf/bin"
source "~/.asdf/lib/asdf.sh" # just load the asdf wrapper function
```

- If you want to silence the console output of direnv, you can do that by
  setting an empty environment variable: `export DIRENV_LOG_FORMAT=""`.

- Some times you might need to configure IDEs or other tools to find executables
  like package managers/code linters/compilers being used on a project of yours.
  For example, to execute `npm` outside your project directory you can do:

```bash
direnv exec /some/project npm
```

- Remember that activation order is important.

  If a local `.tool-versions` file is present, the order of listed plugins will be
  preserved, so that toolA will be present before toolB in PATH.

```bash
# .tool-versions
toolA 1.0
toolB 2.0
```

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

- You can omit direnv on your global `~/.tool-versions` file.

  You just need to provide the version via an environment variable.

```bash
# File: ~/.bashrc

# Hook direnv into your shell.
eval "$(env ASDF_DIRENV_VERSION=2.20.0 asdf direnv hook bash)"

# A shortcut for asdf managed direnv.
direnv() { env ASDF_DIRENV_VERSION=2.20.0 asdf direnv "$@"; }
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
  your environment, use `env ASDF_DIRENV_DEBUG=true direnv reload` and provide any
  relevant output on an [issue](issues/new).

  Also, if you are contributing a new feature or bug-fix try running
  `env ASDF_DIRENV_DEBUG=true make` to run all tests with trace mode. If any test
  fails you will see more output.

## Useful links

Read [direnv documentation](https://direnv.net/) for more on `.envrc`

## License

Licensed under the
[Apache License, Version 2.0](https://www.apache.org/licenses/LICENSE-2.0).
