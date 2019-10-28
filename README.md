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

[asdf](https://asdf-vm.com) is a great tool for managing multiple versions of command line tools. 99% of the time these managed tools work just as expected.

Shims are just tiny executables managed by asdf that just forward execution to the *real* versioned executables installed by asdf.
This way asdf has a single shims directory added to your PATH and has no need of mangling the PATH for every installed tool.

So, when you execute an asdf-managed command, like `node`, it will actually run an asdf-shim, which will determine which `node` version
to activate according to your `.tool-versions` file.

As convenient as it is, every single time you run `node` asdf will have to determine again which version to use. Even if you haven't
changed your `.tool-versions` file to upgrade the nodejs plugin version. And this happens for every shim execution, which could lead
to some users experiencing certain _slowness_ while asdf is looking up versions (since it has to check not only .tool-versions, but
probably also legacy version files every time)

Another inconvenience is that commands installed by these tools can have some problems by the way asdf shims work. For example,
if a command tries to find itself by name in PATH (eg, using `which my-command`) it will find the asdf shim executable and
not the *actual* executable delegated-to by asdf. This might cause problems if the command tries to use this location
as an installation root to find auxiliary files, since shims will mask the real executable.

Another problem usually found by asdf users is, if you have an asdf-managed package manager, say `npm`, `hex`, `gem` and the like.
Any new binaries installed by these tools is not available on PATH unless you `asdf reshim`. This is because asdf has no way of knowing
what the `npm install` command does, and it's untill `asdf reshim` that it will figure out new executables are available and will
create shims for them accordingly.

## Solution

All these previously mentioned issues can be solved by using asdf along with the [direnv](https://direnv.net/) tool.

Just like asdf is a tools manager, direnv is an environment-variables manager.
It can update your shell env upon directory change and clean it up when you leave that directory.

This `asdf-direnv` plugin lets you install `direnv` and also provides a tiny script to integrate both.
Allowing `direnv` to manage any variables exposed by asdf tools, primarily the PATH environment, but also
any other variable exposed by your plugin (eg, MIX_HOME exposed by the asdf-elixir plugin).

This way, running `node` will not invoke the asdf-shim but the *real* asdf-managed executable in PATH.
Which will improve speed since version is resolution is out of the way and made only once by `direnv` upon entering your project directory.
Commands trying to find themselves in PATH will find their expected location.
Also no more _re-shim_ needed upon `npm install`.


## Prerequirements

- Make sure you have the required dependencies installed:
  - curl
  - git

## Installation

```bash
asdf plugin-add direnv https://github.com/asdf-community/asdf-direnv.git
```

## Usage


First, make sure you install and globally activate the most recent direnv version:

```bash
asdf install direnv 2.20.0
asdf global  direnv 2.20.0
```

Follow the [instructions to hook direnv](https://github.com/direnv/direnv/blob/master/docs/hook.md) into your SHELL.

Then on your project root where you have a `.tool-versions` file, create a `.envrc` file with the following content:

```bash
source $(asdf which direnv_use_asdf) # needed until https://github.com/direnv/direnv/pull/534 gets merged.
use asdf

# Other valid `use asdf` examples:
# use asdf /path/to/other/.tool-versions # if you want to load from another location
# use asdf rust $ASDF_RUST_VERSION # for things not on the tool versions file.
```

Finally, run `direnv allow .envrc` to trust your new file.

That's it!

Now when you leave your project directoy and come back to it, direnv will manage the
environment variables for you, for example:

```bash
cd /some/project
direnv: loading .envrc
direnv: using asdf /some/project/.tool-versions
direnv: using asdf elixir 1.8.1-otp-21
direnv: using asdf nodejs 12.6.0
direnv: export +MIX_ARCHIVES +MIX_HOME +NPM_CONFIG_PREFIX ~PATH
```


## Useful links

Read [direnv documentation](https://direnv.net/) for more on `.envrc`
