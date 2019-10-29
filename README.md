<div align="center">
<h1>asdf-direnv</h1>
<span><a href="https://direnv.net">direnv</a> plugin for asdf version manager</span>
</div>
<hr />

[![Main workflow](https://github.com/asdf-community/asdf-direnv/workflows/Main%20workflow/badge.svg)](https://github.com/asdf-community/asdf-direnv/actions)
[![Average time to resolve an issue](https://isitmaintained.com/badge/resolution/asdf-community/asdf-direnv.svg)](https://isitmaintained.com/project/asdf-community/asdf-direnv 'Average time to resolve an issue')
[![Percentage of issues still open](https://isitmaintained.com/badge/open/asdf-community/asdf-direnv.svg)](https://isitmaintained.com/project/asdf-community/asdf-direnv 'Percentage of issues still open')
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](http://makeapullrequest.com)
[![License](https://img.shields.io/github/license/asdf-community/asdf-direnv?color=brightgreen)](https://github.com/asdf-community/asdf-direnv/blob/master/LICENSE)

## Motivation (or shims de-motivation)

[asdf](https://asdf-vm.com) is a great tool for managing multiple versions of
command line tools. 99% of the time these managed tools work just as expected.

Shims are just tiny wrappers created by asdf that just forward execution to
the _real_ versioned executables installed by asdf. This way, asdf has a single
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
itself by name in PATH (e.g. using `which my-command`) it will find the asdf shim
executable and not the _actual_ executable delegated-to by asdf. This might
cause problems if the command tries to use this location as an installation root
to find auxiliary files, since shims will mask the real executable.

Also, people frequently ask why is reshim needed. Suppose you used asdf to
install a package manager like `npm`, `hex`, `gem`, `cargo`, etc. Any new
binaries installed by these tools wont be available on PATH unless you run
`asdf reshim`. This is because asdf has no way of knowing what the `npm install`
command does, and it's until `asdf reshim` that it will figure out new
executables are available and will create shims for them accordingly.

## Solution

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

## Prerequirements

- Make sure you have the required dependencies installed:
  - curl
  - git

## Usage

First, make sure you install and globally activate the most recent direnv
version:

```bash
asdf install direnv 2.20.0
asdf global  direnv 2.20.0
```

Follow the
[instructions to hook direnv](https://github.com/direnv/direnv/blob/master/docs/hook.md)
into your SHELL.

Then on your project root where you have a `.tool-versions` file, create a
`.envrc` file with the following content:

```bash
source $(asdf which direnv_use_asdf)
use asdf # this will load your .tool-versions file.
```

Other valid `use asdf` examples:

```bash
# Explicitly set the file to load. The file will be automatically watched for changes.
use asdf /path/to/other/.tool-versions

# For plugins that can read legacy version files, and hence not present on .tool-versions,
# you can specify just the tool name and asdf will lookup for the current version.
# However, you have to explicitly ask direnv to watch the legacy file for changes.
use asdf mill
watch_file .mill-version

# Or if for some reason you want to explicitly force a particular tool and version
use asdf rust $ASDF_RUST_VERSION
```

Finally, run `direnv allow .envrc` to trust your new file.

That's it! Now when you leave your project directory and come back to it, direnv
will manage the environment variables for you, for example:

```bash
cd /some/project
direnv: loading .envrc
direnv: using asdf /some/project/.tool-versions
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

## Useful links

Read [direnv documentation](https://direnv.net/) for more on `.envrc`
