<div align="center">
<h1>asdf-direnv</h1>
<span><a href="https://direnv.net">direnv</a> plugin for asdf version manager</span>
</div>
<hr />

[![Main workflow](https://github.com/asdf-community/asdf-direnv/workflows/Main%20workflow/badge.svg)](https://github.com/asdf-community/asdf-direnv/actions)
[![Average time to resolve an issue](https://isitmaintained.com/badge/resolution/asdf-community/asdf-direnv.svg)](https://isitmaintained.com/project/asdf-community/asdf-direnv "Average time to resolve an issue")
[![Percentage of issues still open](https://isitmaintained.com/badge/open/asdf-community/asdf-direnv.svg)](https://isitmaintained.com/project/asdf-community/asdf-direnv "Percentage of issues still open")
[![All Contributors](https://img.shields.io/badge/all_contributors-1-orange.svg)](#contributors)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](http://makeapullrequest.com)
[![License](https://img.shields.io/github/license/asdf-community/asdf-direnv?color=brightgreen)](https://github.com/asdf-community/asdf-direnv/blob/master/LICENSE)

## Motivation (or shims de-motivation)

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

#### Setup

First, make sure you install this plugin, then install and globally activate
the most recent direnv version:

```bash
asdf plugin-add direnv
asdf install direnv 2.20.0
asdf global  direnv 2.20.0
```

Then edit your `.bashrc` or equivalent shell profile:

```bash
# If you have the following line enabled, comment or remove it.
## . $HOME/.asdf/asdf.sh

# In order to bypass asdf shims. We *only* add the `ASDF_DIR/bin`
# directory to PATH, since we still want to use `asdf` but not its shims.
[[ $PATH == *"asdf/bin"* ]] || export PATH="$PATH:$ASDF_DIR/bin"

# Optionally, add asdf command completions.
. $ASDF_DIR/completions/asdf.bash

# Hook direnv into your shell.
eval "$(asdf exec direnv hook bash)"
```

If you are not using bash, adapt the previous snippet by following the
[instructions to hook direnv into various other SHELLS](https://github.com/direnv/direnv/blob/master/docs/hook.md)

Note that even when the `shims` directory is no longer in PATH, you are always
able to invoke any asdf managed command via `asdf exec`.

#### The .envrc file.

Once hooked into your shell, `direnv` will expect to find a `.envrc` file
whenever you need to change tool versions.

On your project directory you can now create an `.envrc` file like this:

```bash
source $(asdf which direnv_use_asdf)
use asdf # this will activate your plugins listed by `asdf current`
```

Finally, run `asdf exec direnv allow .envrc` to trust your new file.

###### That's it!

Now when you leave your project directory and come back to it, direnv
will manage the environment variables for you, for example:

```bash
cd /some/project
direnv: loading .envrc
direnv: using asdf /some/project/.tool-versions
direnv: using asdf elixir 1.8.1-otp-21
direnv: using asdf nodejs 12.6.0
direnv: export +MIX_ARCHIVES +MIX_HOME +NPM_CONFIG_PREFIX ~PATH
```

#### Other `use asdf` options.

`use asdf` with no argument is equivalent to `use asdf current`.

_Note_: Tool versions are resolved just like `asdf current tool-name`.

When a tool gets activated, this plugin will automatically watch the
file specifying its version (be it a tool-versions file or
legacy version file) for changes.

- `use asdf current` **(default)**

Just an alias for `use asdf global` followed by `use asdf local`.
Activating global plugins first makes sure your local tools are first on PATH.

- `use asdf TOOL_NAME [VERSION]`

Load the environment for a tool and version.

- `use asdf FILE_NAME`

Load the environment for tools listed on file.

- `use asdf local`

Only load the environment for tools present in upmost `.tool-versions` file.

- `use asdf global`

Only load the environment for tools not present in upmost `.tool-versions` file.

This works by listing all your installed plugins and filtering out those present
in the upmost `.tool-versions` file. Effectively activating any globally
selected plugin like those present on `~/.tool-versions` and also those
local tools that use legacy filenames.

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

### Tips for direnv beginners

- If you want to silence the console output of direnv, you can do that by setting
  an empty environment variable `DIRENV_LOG_FORMAT`.

- Remember that activation order is important. In the following example,
  toolB will be present before toolA in PATH.

```bash
# .envrc
use asdf toolA 1.0
use asdf toolB 2.0
```

- Remember `direnv` can reload the environment whenever a file changes.
  By default this plugin will watch any `.tool-versions` file or legacy
  version file that explicitly selects a tool.

But you can easily watch more files when needed.

```bash
# .envrc
watch_file "package.json"
```

- Using `asdf exec direnv status` can be helpful to inspect current state.
  Also, you might want to take a look to `asdf exec direnv --help`.

## Useful links

Read [direnv documentation](https://direnv.net/) for more on `.envrc`

## Contributors

Thanks goes to these wonderful people ([emoji key](https://allcontributors.org/docs/en/emoji-key)):

<!-- ALL-CONTRIBUTORS-LIST:START - Do not remove or modify this section -->
<!-- prettier-ignore -->
<table>
  <tr>
    <td align="center"><a href="https://keybase.io/oeiuwq"><img src="https://avatars3.githubusercontent.com/u/331?v=4" width="100px;" alt="Victor Borja"/><br /><sub><b>Victor Borja</b></sub></a><br /><a href="https://github.com/asdf-community/asdf-direnv/commits?author=vic" title="Code">💻</a></td>
  </tr>
</table>

<!-- ALL-CONTRIBUTORS-LIST:END -->

This project follows the [all-contributors](https://github.com/all-contributors/all-contributors) specification. Contributions of any kind welcome!
