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

### Setup

Install this plugin and run the setup command for all of your preferred shells `bash`/`fish`/`zsh`.

```bash
asdf plugin-add direnv
asdf direnv setup --shell bash --version latest
```

If you already have a `direnv` installation, you can specify `--version system`.

Otherwise this plugin can install it for you. Specify either `--version latest`
or a [direnv release](https://github.com/direnv/direnv/releases) as shown by `asdf list-all direnv`.


The setup will hint which files were modified, you might want to review its changes.
After setup, close and open your terminal.

### Configuration

By default asdf-direnv will fail if a plugin is not installed, but is possible
to change this using the environment variable
`ASDF_DIRENV_IGNORE_MISSING_PLUGINS=1`

### Per-Project Environments

Once direnv is hooked into your system, use the  `asdf direnv local`
command on your project root directory to update your environment.

``` bash
asdf direnv local [<tool> <version>]...
```

#### Temporary environments for one-shot commands

Some times you just want to execute a one-shot commmand under certain
environment without creating/modifying `.envrc` and `.tool-versions` files
on your project directory. In those cases, you might want to try using
`asdf direnv shell`.


``` bash
# Enter a new shell having python and node
$ asdf direnv shell python 3.8.10 nodejs 14.18.2

# Just execute a npx command under some node version.
$ asdf direnv shell nodejs 14.18.2 -- npx create-react-app
```

<details>
<summary><h3>Updating</h3></summary>

Updating this plugin is the same as any asdf plugin:

    asdf plugin update direnv

Updating the version of direnv you use depends on which installation method you've chosen:

- `system`: Nothing special required here, whenever your system package manager
  updates direnv, this plugin will use the updated version.

- `latest` or `<direnv-release-version>`: Re-run `asdf direnv setup --version
  latest --shell ...` to update to the latest version of direnv. One may optionally
  add `--no-touch-rc-file` to the command to prevent the shell rc file from being
  modified during the update.

  (NOTE: One may alternatively `export ASDF_DIRENV_NO_TOUCH_RC_FILE=1` to permanently
  prevent modification of shell rc files during updates.)

</details>

<details>
  <summary><h6>Cached environment</h6></summary>

To speed up things a lot, this plugin creates direnv `envrc` files that contain
your tools environment. They are created automatically whenever your `.envrc` or your
`.tool-versions` files change.

Cached environment files can be found under `$XDG_CACHE_HOME/asdf-direnv/env`.
On most systems that resolves to `~/.config/asdf-direnv/env`. It's always safe to
remove files on this directory since they will be re-generated if missing.

If you ever need to regenerate a cached environment file, just `touch .envrc`.

Also, the `asdf direnv envrc` command will print the path to the cached environment
file used for your project.

Now when you leave your project directory and come back to it, direnv will
manage the environment variables for you really fast. For example:

```bash
direnv: loading .envrc
direnv: using asdf
direnv: Creating env file ~/.cache/asdf-direnv/env/909519368-2773408541-1591703797-361987458
direnv: loading ~/.cache/asdf-direnv/env/909519368-2773408541-1591703797-361987458
direnv: using asdf elixir 1.8.1-otp-21
direnv: using asdf nodejs 12.6.0
direnv: export +MIX_ARCHIVES +MIX_HOME +NPM_CONFIG_PREFIX ~PATH
```

</details>

<details>
  <summary><h6>Benchmark</h6></summary>

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

</details>

<details>
  <summary><h3>Pro-Tips</h3></summary>

- Take a look at `direnv help true`.

- Getting `$ASDF_DIR/shims` out of the PATH.

  Some users might want to bypass asdf shims altogether. To do so,
  include only `$ASDF_DIR/bin` in your PATH but exclude the shims
  directory.

  All shims are still available via `asdf exec <shim>`

  ```bash
  # ~/.bashrc or equivalent

  # Don't source `~/.asdf/asdf.sh`
  PATH="$PATH:~/.asdf/bin"
  ```

  Note: This will break any [global defaults](https://asdf-vm.com/guide/getting-started.html#global) you have specified in
  `~/.tool-versions`. There are various workarounds for this:

   - Do all work in project directories with their own `.envrc` and `.tool-versions`
   - Use [`asdf direnv shell`](#temporary-environments-for-one-shot-commands) for one-shot commands
   - Create a `~/.envrc` with `use asdf` in it
   - Use your OS's package manager to install any tools you want globally accessible

  There are pros and cons to each of these approaches, it's up to you to pick
  the approach that works best for your workstyle.

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

<<<<<<
______________
asdf plugins repository
_______________
The purpose of the asdf plugins repository is to enable shorthand installation of plugins with:
>>>>>>>>>>>
asdf plugin add <name>
The asdf core team recommend using the long-form which does not rely on this repository:

asdf plugin add <name> <git_url>
Read each plugins code before installation and usage.

Existing Plugins

Plugins listed here should be stable and actively maintained. If you have issues with a specific plugin please raise them on the plugin repository first. If a deprecated plugin is listed here, please let us know and create a PR to add the most used alternative.

Creating a new Plugin

Read the creating plugins guide
Consider using our Template which has the core functionality to tools published to GitHub releases and CI for GitHub/GitLab/CircleCI out of the box.
asdf-community

If you're creating a new plugin consider creating it as part of the asdf-community project. This is a separate community project with consolidated maintenance.

Contributing a new Plugin

Install repo dependencies: asdf install
Add the plugin to the repository README.md Plugin List table.
Create a file with the shortname you wish to be used by asdf in plugins/<name>. The contents should be repository = <your_repo>.
eg: printf "repository = https://github.com/asdf-vm/asdf-nodejs.git\n" > plugins/nodejs
Test your code : scripts/test_plugin.bash --file plugins/<name>
Format your code & this README: scripts/format.bash
Create a PR following the instructions in the PR template.
Security

The asdf core provides a security policy which covers the core asdf tool. Plugins are the responsibility of their creators and not covered by the asdf policy. It is the responsibility of the user to evaluate each plugin they use for security concerns, even those in the asdf-community repositories. You can pin a plugin to a commit of the source repo with asdf plugin update <name> <git-ref>, however running asdf plugin update <name> or asdf plugin update --all will change the sha you have previously set.

<Plugin List> in a tabular form

{
(Tool / Language	Plugin Repository	Plugin CI Status
.Net	hensou/asdf-dotnet	Build
.Net Core	emersonsoares/asdf-dotnet-core	Build Status
1password-cli	NeoHsu/asdf-1password-cli	Build
act	grimoh/asdf-act	GitHub Actions Status
action-validator	mpalmer/action-validator	Test
actionlint	crazy-matt/asdf-actionlint	Build
adr-tools	td7x/asdf/adr-tools	pipeline status
ag (the_silver_searcher)	koketani/asdf-ag	GitHub Actions Status
age	threkk/asdf-age	GitHub Actions Status
age-plugin-yubikey	str4d/age-plugin-yubikey	GitHub Actions Status
agebox	slok/asdf-agebox	Build Status
air	pdemagny/asdf-air	Build Status
aks-engine	robsonpeixoto/asdf-aks-engine	Build Status
alias	andrewthauer/asdf-alias	Main workflow
allure	comdotlinux/asdf-allure	Build
alp	asdf-community/asdf-alp	Main workflow
amass	dhoeric/asdf-amass	Build Status
Amazon ECR Credential Helper	dex4er/asdf-amazon-ecr-credential-helper	CI
Ambient	jtakakura/asdf-ambient	Build Status
Ansible (ansible-base)	amrox/asdf-pyapp	Build Status
ant	jackboespflug/asdf-ant	Build Status
Apache Jmeter	comdotlinux/asdf-jmeter	Build Status
Apollo Router	safx/asdf-apollo-router	Build Status
arc	ORCID/asdf-arc	Build
argo	sudermanjr/asdf-argo	Build Status
argo-rollouts	abatilo/asdf-argo-rollouts	build
argocd	beardix/asdf-argocd	Build Status
aria2	asdf-community/asdf-aria2	Build Status
asciidoctorj	gliwka/asdf-asciidoctorj	Build Status
assh	zekker6/asdf-assh	Test
aws-copilot	NeoHsu/asdf-copilot	Build
aws-amplify-cli	LozanoMatheus/asdf-aws-amplify-cli	Build
AWS IAM authenticator	zekker6/asdf-aws-iam-authenticator	Test
aws-nuke	bersalazar/asdf-aws-nuke	Build Status
aws-sam-cli	amrox/asdf-pyapp	Build Status
aws-sso-cli	adamcrews/asdf-aws-sso-cli	Build
awscli	MetricMike/asdf-awscli	Build Status
awscli-local	paulo-ferraz-oliveira/asdf-awscli-local	Build Status
awsebcli	amrox/asdf-pyapp	Build Status
aws-vault	karancode/asdf-aws-vault	GitHub Actions Status
awsls	chessmango/asdf-awsls	GitHub Actions Status
awsrm	chessmango/asdf-awsrm	GitHub Actions Status
awsweeper	chessmango/asdf-awsweeper	GitHub Actions Status
azure-cli (az)	EcoMind/asdf-azure-cli	CI
Azure Functions Core Tools	daveneeley/asdf-azure-functions-core-tools	Build Status
babashka	pitch-io/asdf-babashka	Build Status
balena-cli	boatkit-io/asdf-balena-cli	Build Status
bashbot	mathew-fleisch/asdf-bashbot	Build Status
bat	wt0f/asdf-bat	pipeline status
Batect	johnlayton/asdf-batect	Build Status
Bats (Bash unittest)	timgluz/asdf-bats	Build Status
Bazel	rajatvig/asdf-bazel	Build Status
bbr	vmware-tanzu/tanzu-plug-in-for-asdf	Build Status
bbr-s3-config-validator	vmware-tanzu/tanzu-plug-in-for-asdf	Build Status
benthos	benthosdev/benthos-asdf	Build Status
Bin	joe733/asdf-bin	Build Status
binnacle	Traackr/asdf-binnacle	Build Status
Bitwarden	vixus0/asdf-bitwarden	Build Status
Bombardier	NeoHsu/asdf-bombardier	Build
borg	lwiechec/asdf-borg	Build
bosh	vmware-tanzu/tanzu-plug-in-for-asdf	Build Status
bottom (btm)	carbonteq/asdf-btm	Build Status
Boundary	asdf-community/asdf-hashicorp	Build
bpkg	bpkg/asdf-bpkg	GitHub Actions Status
Brig	Ibotta/asdf-brig	Build Status
BTrace	joschi/asdf-btrace	Main workflow
Buf	truepay/asdf-buf	Build Status
Buildpack	johnlayton/asdf-buildpack	GitHub Actions Status
Bun	cometkim/asdf-bun	CI
Bundler	jonathanmorley/asdf-bundler	Build Status
Caddy	salasrod/asdf-caddy	Build Status
Calicoctl	FairwindsOps/asdf-calicoctl	GitHub Actions Status
Camunda Modeler	barmac/asdf-camunda-modeler	Build Status
cargo-make	kachick/asdf-cargo-make	Build Status
Carp	susurri/asdf-carp	Build Status
carthage	younke/asdf-carthage	Build Status
ccache	asdf-community/asdf-ccache	Build Status
certstrap	carnei-ro/asdf-certstrap	Build Status
cidr-merger	ORCID/asdf-cidr-merger	Build
cidrchk	ORCID/asdf-cidrchk	Build
circleci-cli	ucpr/asdf-circleci-cli	Build
cf	mattysweeps/asdf-cf	Build Status
cfssl	mathew-fleisch/asdf-cfssl	Build Status
chamber	mintel/asdf-chamber	Build Status
cheat	jmoratilla/asdf-cheat-plugin	Build Status
checkov	bosmak/asdf-checkov	Build Status
chezmoi	joke/asdf-chezmoi	Build Status
chezscheme	asdf-community/asdf-chezscheme	Build Status
CHICKEN	evhan/asdf-chicken	Build Status
choose	carbonteq/asdf-choose	Build Status
Chromedriver	schinckel/asdf-chromedriver	Build status
cilium-cli	carnei-ro/asdf-cilium-cli	Build Status
cilium-hubble	NitriKx/asdf-cilium-hubble	Build Status
Clojure	asdf-community/asdf-clojure	Build Status
Cloudflared	threkk/asdf-cloudflared	GitHub Actions Status
cloud-sql-proxy	pbr0ck3r/asdf-cloud-sql-proxy	CI
Clusterawsadm	kahun/asdf-clusterawsadm	Build Status
Clusterctl	pfnet-research/asdf-clusterctl	Build Status
cmctl	asdf-community/asdf-cmctl	Build Status
CMake	asdf-community/asdf-cmake	Build
CockroachDB	salasrod/asdf-cockroach	Build Status
CocoaPods	ronnnnn/asdf-cocoapods	Build Status
Codefresh	gurukulkarni/asdf-codefresh	Build Status
CodeQL	bored-engineer/asdf-codeql	Build Status
Colima	CrouchingMuppet/asdf-colima	Build Status
Conan	amrox/asdf-pyapp	Build Status
Concourse	mattysweeps/asdf-concourse	Build Status
Conduit	gmcabrita/asdf-conduit	Build Status
Conform	skyzyx/asdf-conform	Build Status
conftest	looztra/asdf-conftest	Build Status
Consul	asdf-community/asdf-hashicorp	Build
container-diff	cgroschupp/asdf-container-diff	Main workflow
container-structure-test	jonathanmorley/asdf-container-structure-test	ASDF CI
cookiecutter	shawon-crosen/asdf-cookiecutter	Build Status
Copper	vladlosev/asdf-copper	Build Status
Coq	gingerhot/asdf-coq	Build Status
cosign	wt0f/asdf-cosign	Build Status
coursier	jiahuili430/asdf-coursier	Build Status
crane	dmpe/asdf-crane	Build Status
crc	sqtran/asdf-crc	Build Status
credhub	vmware-tanzu/tanzu-plug-in-for-asdf	Build Status
crictl	FairwindsOps/asdf-crictl	Build Status
crossplane-cli	joke/asdf-crossplane-cli	Build Status
ctlptl	ezcater/asdf-ctlptl	Build Status
Crystal	asdf-community/asdf-crystal	Main workflow
ctop	NeoHsu/asdf-ctop	Build
CUE	asdf-community/asdf-cue	Build Status
cyclonedx	xeedio/asdf-cyclonedx	Build Status
D (DMD)	sylph01/asdf-dmd	Build Status
dagger	virtualstaticvoid/asdf-dagger	Build Status
Dart	PatOConnor43/asdf-dart	Build Status
Dasel	asdf-community/asdf-dasel	Build Status
datree	lukeab/asdf-datree	Build Status
Dbmate	juusujanar/asdf-dbmate	Test
Deck	nutellinoit/asdf-deck	Build Status
Delta	andweeb/asdf-delta	Build Status
Deno	asdf-community/asdf-deno	Main workflow
Dep	paxosglobal/asdf-dep	Build Status
depot	depot/asdf-depot	Build
Desk	endorama/asdf-desk	Build Status
DevSpace	NeoHsu/asdf-devspace	Build
DevStream	zhenyuanlau/asdf-dtm	Build
dhall	aaaaninja/asdf-dhall	Build Status
difftastic	volf52/asdf-difftastic	Build
digdag	jtakakura/asdf-digdag	Main workflow
direnv	asdf-community/asdf-direnv	Main workflow
dive	looztra/asdf-dive	Build Status
djinni	cross-language-cpp/asdf-djinni	Build
docker-slim	xataz/asdf-docker-slim	Build
docker-compose-v1	yilas/asdf-docker-compose-v1	Build Status
dockle	mathew-fleisch/asdf-dockle	Build Status
doctl	maristgeek/asdf-doctl	Build Status
docToolchain	joschi/asdf-doctoolchain	Main workflow
docuum	bradym/asdf-docuum	GitHub Workflow Status
DOME	jtakakura/asdf-dome	Build Status
doppler	takutakahashi/asdf-doppler	Build Status
dotenv-linter	wesleimp/asdf-dotenv-linter	Build Status
Dotty	asdf-community/asdf-dotty	Build Status
dprint	asdf-community/asdf-dprint	Build Status
Draft	kristoflemmens/asdf-draft	Build Status
Driftctl	nlamirault/asdf-driftctl	GitHub Actions Status
drone	virtualstaticvoid/asdf-drone	Build Status
duf	NeoHsu/asdf-duf	Build
dust	looztra/asdf-dust	GitHub Actions Status
DVC	fwfurtado/asdf-dvc	GitHub Actions Status
dyff	wt0f/asdf-dyff	pipeline status
ecspresso	kayac/asdf-ecspresso	Build
editorconfig-checker	gabitchov/asdf-editorconfig-checker	Build Status
ejson	cipherstash/asdf-ejson	Build
eksctl	elementalvoid/asdf-eksctl	GitHub Actions Status
Elasticsearch	asdf-community/asdf-elasticsearch	Build Status
Elixir	asdf-vm/asdf-elixir	Build Status
Elm	asdf-community/asdf-elm	Build Status
embulk	yuokada/asdf-embulk	Build Status
Emscripten SDK	RobLoach/asdf-emsdk	Build Status
EnvCLI	zekker6/asdf-envcli	Build Status
Ephemeral Postgres	smashedtoatoms/asdf-ephemeral-postgres	Build Status
Erlang	asdf-vm/asdf-erlang	Build Status
esy	asdf-community/asdf-esy	Build Status
etcd	particledecay/asdf-etcd	Build Status
Evans	goki90210/asdf-evans	GitHub Actions Status:Main
exa	nyrst/asdf-exa	pipeline status
fd	wt0f/asdf-fd	pipeline status
FFmpeg	acj/asdf-ffmpeg	Build Status
figma-export	younke/asdf-figma-export	Build Status
fillin	ouest/asdf-fillin	Build Status
firebase	jthegedus/asdf-firebase	Build
fission	virtualstaticvoid/asdf-fission	Build Status
flarectl	ORCID/asdf-flarectl	Build
flatc	TheOpenDictionary/asdf-flatc	Build Status
Flutter	oae/asdf-flutter	Build Status
Flux2	tablexi/asdf-flux2	Main workflow
Fluxctl	stefansedich/asdf-fluxctl	Build Status
fly	vmware-tanzu/tanzu-plug-in-for-asdf	Build Status
flyctl	chessmango/asdf-flyctl	GitHub Actions Status
flyway	junminahn/asdf-flyway	Build Status
func-e	carnei-ro/asdf-func-e	Build Status
Furyctl	sighupio/asdf-furyctl	Build Status
fx	wt0f/asdf-fx	Build Status
fzf	kompiro/asdf-fzf	Build Status
Gauche	sakuro/asdf-gauche	Build Status
gallery-dl	iul1an/asdf-gallery-dl	Build Status
gam	offbyone/asdf-gam	Build Status
gator	MxNxPx/asdf-gator	Build Status
gcc-arm-none-eabi	dlech/asdf-gcc-arm-none-eabi	Build
gcloud	jthegedus/asdf-gcloud	Build
getenvoy	asdf-community/asdf-getenvoy	Build Status
ghidra	Honeypot95/asdf-ghidra	Build Status
ghorg	gbloquel/asdf-ghorg	Build Status
ghq	kajisha/asdf-ghq	Build Status
ginkgo	jimmidyson/asdf-ginkgo	Build Status
git	jcaigitlab/asdf-git	GitLab CI Status
git-chglog	GoodwayGroup/asdf-git-chglog	GitHub Actions Status
gitconfig	0ghny/asdf-gitconfig	Github Actions Status
GitHub CLI	bartlomiejdanek/asdf-github-cli	Build Status
GitHub Markdown ToC	skyzyx/asdf-github-markdown-toc	Build Status
Gitleaks	jmcvetta/asdf-gitleaks	Build
Gitsign	spencergilbert/asdf-gitsign	Build
gitui	looztra/asdf-gitui	GitHub Actions Status
GLab	particledecay/asdf-glab	Build
Gleam	vic/asdf-gleam	Build Status
Glen	bradym/asdf-glen	Main workflow
glooctl	halilkaya/asdf-glooctl	ci
glow	chessmango/asdf-glow	GitHub Actions Status
GNU Guile	indiebrain/asdf-guile	Build Status
GNU nano	mfakane/asdf-nano	GitHub Actions Status
Go	asdf-community/asdf-golang	CI
go-sdk	yacchi/asdf-go-sdk	Build
go-containerregistry	dex4er/asdf-go-containerregistry	CI
go-getter	ryodocx/asdf-go-getter	GitHub Actions Status
go-jsonnet	craigfurman/asdf-go-jsonnet	Build Status
go-jira	dguihal/asdf-go-jira	GitHub Actions Status
go-junit-report	jwillker/asdf-go-junit-report	GitHub Actions Status
go-swagger	jfreeland/asdf-go-swagger	Build Status
goconvey	therounds-contrib/asdf-goconvey	Build Status
gofumpt	looztra/asdf-gofumpt	Build Status
GoHugo	nklmilojevic/asdf-hugo	Build Status
gojq	jimmidyson/asdf-gojq	Build Status
golangci-lint	hypnoglow/asdf-golangci-lint	Build Status
Go Migrate	joschi/asdf-gomigrate	Main workflow
gomplate	sneakybeaky/asdf-gomplate	Build Status
Gopass	trallnag/asdf-gopass	primary
GoReleaser	kforsthoevel/asdf-goreleaser	Main workflow
Goss	raimon49/asdf-goss	plugin test
GraalVM	asdf-community/asdf-graalvm	Build Status
Gradle	rfrancis/asdf-gradle	Build Status
Gradle Profiler	joschi/asdf-gradle-profiler	CI
Grails	weibemoura/asdf-grails	Build Status
Grain	cometkim/asdf-grain	CI
Granted	dex4er/asdf-granted	CI
grex	ouest/asdf-grex	Build Status
Groovy	weibemoura/asdf-groovy	Build Status
grpcurl	asdf-community/asdf-grpcurl	CI
grpc-health-probe	zufardhiyaulhaq/asdf-grpc-health-probe	Build
grype	poikilotherm/asdf-grype	Main
gum	lwiechec/asdf-gum	Build
gwvault	GoodwayGroup/asdf-gwvault	GitHub Actions Status
hadolint	devlincashman/asdf-hadolint	Build Status
Hamler	scudelletti/asdf-hamler	Build
has	sylvainmetayer/asdf-has	Build
Haskell	asdf-community/asdf-haskell	Build Status
Hasura-cli	gurukulkarni/asdf-hasura	GitHub Actions Status
Haxe	asdf-community/asdf-haxe	Build Status
hcl2json	dex4er/asdf-hcl2json	CI
hcloud	chessmango/asdf-hcloud	GitHub Actions Status
Helm	Antiarchitect/asdf-helm	Build Status
Helm Chart Releaser	Antiarchitect/asdf-helm-cr	Main workflow
Helm Chart Tester	tablexi/asdf-helm-ct	Main workflow
Helm Diff	dex4er/asdf-helm-diff	CI
helm-docs	sudermanjr/asdf-helm-docs	Build Status
Helmfile	feniix/asdf-helmfile	Build Status
Helmsman	luisdavim/asdf-helmsman	Build Status
heroku-cli	treilly94/asdf-heroku-cli	Build
hey	raimon49/asdf-hey	plugin test
httpie-go	abatilo/asdf-httpie-go	build
Hub	vixus0/asdf-hub	Build Status
Hugo	NeoHsu/asdf-hugo	Build
Hurl	raimon49/asdf-hurl	Build
hwatch	chessmango/asdf-hwatch	GitHub Actions Status
Hygen	brentjanderson/asdf-hygen	CI
Hyperfine	volf52/asdf-hyperfine	Build
iamlive	chessmango/asdf-iamlive	GitHub Actions Status
iam-policy-json-to-terraform	carlduevel/asdf-iam-policy-json-to-terraform	Build Status
ibmcloud	triangletodd/asdf-ibmcloud	Build Status
Idris	asdf-community/asdf-idris	Build Status
Idris2	asdf-community/asdf-idris2	Build
ImageMagick	mangalakader/asdf-imagemagick	Imagemagick Plugin Test
imgpkg	vmware-tanzu/asdf-carvel	Build Status
Infracost	dex4er/asdf-infracost	CI
Inlets	nlamirault/asdf-inlets	GitHub Actions Status
Io	mracos/asdf-io	Build
Istioctl	virtualstaticvoid/asdf-istioctl	Build
Janet	Jakski/asdf-janet	Build
Java	halcyon/asdf-java	Build Status
jb	beardix/asdf-jb	GitHub Actions Status
jbang	joschi/asdf-jbang	Main workflow
jib	joschi/asdf-jib	Main workflow
jiq	chessmango/asdf-jiq	GitHub Actions Status
jless	jc00ke/asdf-jless	Build Status
JMESPath	skyzyx/asdf-jmespath	Build Status
jq	lsanwick/asdf-jq	GitHub Actions Status
jqp	wt0f/asdf-jqp	pipeline status
JReleaser	joschi/asdf-jreleaser	GitHub Actions Status
json2k8s	k14s/asdf-k14s	Build Status
Jsonnet	Banno/asdf-jsonnet	Build Status
Julia	rkyleg/asdf-julia	Build Status
Just	olofvndrhr/asdf-just	Build Status
jx	vbehar/asdf-jx	Build Status
k0sctl	Its-Alex/asdf-plugin-k0sctl	GitHub Actions Status
k2tf	carlduevel/asdf-k2tf	GitHub Actions Status
k3d	spencergilbert/asdf-k3d	GitHub Actions Status
k3sup	cgroschupp/asdf-k3sup	GitHub Actions Status
k6	grimoh/asdf-k6	GitHub Actions Status
k9s	looztra/asdf-k9s	Build Status
kafka	ueisele/asdf-kafka	Build Status
kafkactl	anweber/asdf-kafkactl	Build Status
kapp	vmware-tanzu/asdf-carvel	Build Status
kbld	vmware-tanzu/asdf-carvel	Build Status
kcat	douglasdgoulart/asdf-kcat	Build Status
kcctl	joschi/asdf-kcctl	Main workflow
kconf	particledecay/asdf-kconf	Test Plugin
Kind	johnlayton/asdf-kind	GitHub Actions Status
Kiota	asdf-community/asdf-kiota	Build Status
ki	comdotlinux/asdf-ki	Build Status
kn	joke/asdf-kn	Build Status
ko	zasdaym/asdf-ko	Build Status
Koka	susurri/asdf-koka	Build
Kompose	technikhil314/asdf-kompose	GitHub Actions Status
Kops	Antiarchitect/asdf-kops	Build Status
Kotlin	asdf-community/asdf-kotlin	Build Status
Kpt	nlamirault/asdf-kpt	GitHub Actions Status
kp	vmware-tanzu/tanzu-plug-in-for-asdf	Build Status
kscript	edgelevel/asdf-kscript	Build Status
krab	ohkrab/asdf-krab	Build Status
krew	bjw-s/asdf-krew	Build Status
Ksonnet	Banno/asdf-ksonnet	Build Status
ktlint	esensar/asdf-ktlint	Build Status
kube-capacity	looztra/asdf-kube-capacity	Build Status
kube-code-generator	jimmidyson/asdf-kube-code-generator	Build Status
kube-controller-tools	jimmidyson/asdf-kube-controller-tools	Build Status
kube-credential-cache	ryodocx/kube-credential-cache	GitHub Actions Status
kube-linter	devlincashman/asdf-kube-linter	Build Status
kube-score	bageljp/asdf-kube-score	Build Status
kubebuilder	virtualstaticvoid/asdf-kubebuilder	GitHub Actions Status
kubecm	samhvw8/asdf-kubecm	GitHub Actions Status
kubecolor	dex4er/asdf-kubecolor	CI
kubeconform	lirlia/asdf-kubeconform	GitHub Actions Status
Kubectl	asdf-community/asdf-kubectl	Build Status
kubectl-bindrole	looztra/asdf-kubectl-bindrole	Build Status
kubectl-convert	iul1an/asdf-kubectl-convert	Build Status
kubectl-buildkit	ezcater/asdf-kubectl-buildkit	Build
kubectl-kots	ganta/asdf-kubectl-kots	Build Status
kubectx	wt0f/asdf-kubectx	pipeline status
Kubefedctl	kvokka/asdf-kubefedctl	Build Status
Kubefirst	Claywd/asdf-kubefirst	Build Status
Kubelogin	sechmann/asdf-kubelogin	Build Status
Kubemqctl	johnlayton/asdf-kubemqctl	GitHub Actions Status
kubent	virtualstaticvoid/asdf-kubent	Build Status
Kubergrunt	NeoHsu/asdf-kubergrunt	Build
Kubeseal	stefansedich/asdf-kubeseal	Build Status
Kubesec	vitalis/asdf-kubesec	Build Status
kubeshark	carnei-ro/asdf-kubeshark	Build Status
kubespy	jfreeland/asdf-kubespy	Build Status
Kubeval	stefansedich/asdf-kubeval	Build Status
KubeVela	gustavclausen/asdf-kubevela	Build Status
Kubie	johnhamelink/asdf-kubie	Build Status
Kustomize	Banno/asdf-kustomize	Build Status
kuttl	jimmidyson/asdf-kuttl	Build Status
kwt	vmware-tanzu/asdf-carvel	Build Status
lab	particledecay/asdf-lab	Test Plugin
lazygit	nklmilojevic/asdf-lazygit	Build Status
Lean	asdf-community/asdf-lean	Build Status
Leiningen	miorimmax/asdf-lein	Build Status
Lefthook	jtzero/asdf-lefthook	Build
Levant	asdf-community/asdf-hashicorp	Build
LFE	asdf-community/asdf-lfe	Build Status
Lima	CrouchingMuppet/asdf-lima	Build Status
Link (system tools)	asdf-community/asdf-link	Build Status
Linkerd	kforsthoevel/asdf-linkerd	GitHub Actions Status
liqoctl	pdemagny/asdf-liqoctl	Build Status
Litestream	threkk/asdf-litestream	GitHub Actions Status
Logtalk	LogtalkDotOrg/asdf-logtalk	Build Status
Loki-Logcli	comdotlinux/asdf-loki-logcli	Build Status
Lua	Stratus3D/asdf-lua	Build Status
LuaJIT	smashedtoatoms/asdf-luaJIT	Build Status
lua-language-server	bellini666/asdf-lua-language-server	Build Status)
Lucy	cometkim/asdf-lucy	CI
maestro	dotanuki-labs/asdf-maestro	CI
mage	mathew-fleisch/asdf-mage	Build Status
make	yacchi/asdf-make	Build Status
mani	anweber/asdf-mani	Build Status
mark	jfreeland/asdf-mark	Build Status
markdownlint-cli2	paulo-ferraz-oliveira/asdf-markdownlint-cli2	Build Status
marp-cli	xataz/asdf-marp-cli	Build
mask	aaaaninja/asdf-mask	Build Status
Maven	halcyon/asdf-maven	Build Status
mdbook	cipherstash/asdf-mdbook	Code Health
mdbook-linkcheck	cipherstash/asdf-mdbook-linkcheck	Code Health
melt	chessmango/asdf-melt	GitHub Actions Status
Memcached	furkanural/asdf-memcached	Build
Mercury	susurri/asdf-mercury	Build
Meson	asdf-community/asdf-meson	Build Status
Micronaut	weibemoura/asdf-micronaut	Build Status
Mill	asdf-community/asdf-mill	Build Status
minify	axilleas/asdf-minify	Build Status
Minikube	alvarobp/asdf-minikube	Build Status
Minio	aeons/asdf-minio	Build Status
Minio Client	penpyt/asdf-mc	Build Status
Minishift	sqtran/asdf-minishift	Build Status
Mint	mint-lang/asdf-mint	Build Status
mitmproxy	NeoHsu/asdf-mitmproxy	Build
mkcert	salasrod/asdf-mkcert	Build Status
mlton	asdf-community/asdf-mlton	Main workflow
mockery	cabify/asdf-mockery	Build Status
mongo-tools	itspngu/asdf-mongo-tools	CI
MongoDB	sylph01/asdf-mongodb	Build Status
mongosh	itspngu/asdf-mongosh	CI
mutanus	SoriUR/asdf-mutanus	Build Status
mvnd	joschi/asdf-mvnd	GitHub Actions Status
MySQL	iroddis/asdf-mysql	Build Status
nancy	iilyak/asdf-nancy	Build Status
nasm	Dpbm/asdf-nasm	Build Status
Neko Virtual Machine	asdf-community/asdf-neko	Main workflow
Neovim	richin13/asdf-neovim	Build Status
nerdctl	dmpe/asdf-nerdctl	Build
newrelic-cli	NeoHsu/asdf-newrelic-cli	Build
nfpm	ORCID/asdf-nfpm	Build
Nim	asdf-community/asdf-nim	Build Status
Ninja	asdf-community/asdf-ninja	Build Status
Node.js	asdf-vm/asdf-nodejs	Build Status
Nomad	asdf-community/asdf-hashicorp	Build
nova	elementalvoid/asdf-nova	GitHub Actions Status
NSC	dex4er/asdf-nsc	CI
oapi-codegen	dylanrayboss/asdf-oapi-codegen	Build Status
oc	sqtran/asdf-oc	Build Status
oci	yasn77/asdf-oci	Build Status
OCaml	asdf-community/asdf-ocaml	Build Status
Odin	jtakakura/asdf-odin	Build Status
odo	rm3l/asdf-odo	Build status
okta-aws-cli	bennythejudge/asdf-plugin-okta-aws-cli	Build Status
Okteto	BradenM/asdf-okteto	Build Status
om	vmware-tanzu/tanzu-plug-in-for-asdf	Build Status
OPA	tochukwuvictor/asdf-opa	Build status
Opam	asdf-community/asdf-opam	Build status
openfaas-faas-cli	zekker6/asdf-faas-cli	Build Status
OpenResty	smashedtoatoms/asdf-openresty	Build Status
opensearch	randikabanura/asdf-opensearch	Build Status
opensearch-cli	iul1an/asdf-opensearch-cli	Build Status
openshift-install	hhemied/asdf-openshift-install	Build Status
Operator SDK	Medium/asdf-operator-sdk	Build Status
Opsgenie-lamp	ORCID/asdf-opsgenie-lamp	Build
Osm	nlamirault/asdf-osm	GitHub Actions Status
osqueryi	davidecavestro/asdf-osqueryi	Build Status
pachctl	abatilo/asdf-pachctl	build
Packer	asdf-community/asdf-hashicorp	Build
patat	airtonix/asdf-patat	Build
peco	asdf-community/asdf-peco	Build Status
pdm	1oglop1/asdf-pdm	Build Status
Perl	ouest/asdf-perl	Build
PHP	asdf-community/asdf-php	Build status
pint	sam-burrell/asdf-pint	Build Status
pipectl	pipe-cd/asdf-pipectl	Build Status
pipx	joe733/asdf-pipx	Build Status
pivnet	vmware-tanzu/tanzu-plug-in-for-asdf	Build Status
Please	asdf-community/asdf-please	Build status
Pluto	FairwindsOps/asdf-pluto	GitHub Actions Status
pnpm	jonathanmorley/asdf-pnpm	GitHub Actions Status
Poetry	asdf-community/asdf-poetry	GitHub Actions Status
Polaris	particledecay/asdf-polaris	Test Plugin
Popeye	nlamirault/asdf-popeye	GitHub Actions Status
Postgres	smashedtoatoms/asdf-postgres	Build Status
powerline-go	dex4er/asdf-powerline-go	CI
PowerShell	daveneeley/asdf-powershell-core	Build Status
pre-commit	jonathanmorley/asdf-pre-commit	GitHub Actions Status
protoc	paxosglobal/asdf-protoc	Build Status
protoc-gen-grpc-web	pbr0ck3r/asdf-protoc-gen-grpc-web	Build Status
protoc-gen-go-grpc	pbr0ck3r/asdf-protoc-gen-go-grpc	Build Status
protoc-gen-go	pbr0ck3r/asdf-protoc-gen-go	Build Status
protoc-gen-js	pbr0ck3r/asdf-protoc-gen-js	Build Status
protolint	spencergilbert/asdf-protolint	Build
Proton GE	augustobmoura/asdf-protonge	Build Status
psc-package	nsaunders/asdf-psc-package	Build Status
Pulumi	canha/asdf-pulumi	Build Status
purerl	GoNZooo/asdf-purerl	Build Status
PureScript	nsaunders/asdf-purescript	Build Status
Purty	nsaunders/asdf-purty	Build Status
Python	danhper/asdf-python	Build Status
q	moritz-makandra/asdf-plugin-qdns	Build Status
Quarkus CLI	asdf-community/asdf-quarkus	Build
R	asdf-community/asdf-r	Build Status
RabbitMQ	w-sanches/asdf-rabbitmq	Build Status
Racket	asdf-community/asdf-racket	Build Status
Raku	m-dango/asdf-raku	Build Status
Rancher	abinet/asdf-rancher	Build Status
Rbac-lookup	looztra/asdf-rbac-lookup	Build Status
Rclone	johnlayton/asdf-rclone	GitHub Actions Status
Rebar	Stratus3D/asdf-rebar	Build Status
Reckoner	FairwindsOps/asdf-reckoner	GitHub Actions Status
Redis	smashedtoatoms/asdf-redis	Build Status
Redis-cli	NeoHsu/asdf-redis-cli	Build
redo	chessmango/asdf-redo	GitHub Actions Status
redskyctl	sudermanjr/asdf-redskyctl	Build Status
Reg	looztra/asdf-reg	Build Status
regctl	ORCID/asdf-regctl	Build
restic	xataz/asdf-restic	Build
revive	bjw-s/asdf-revive	Build
richgo	paxosglobal/asdf-richgo	Build Status
Riff	abinet/asdf-riff	Build Status
ripgrep	wt0f/asdf-ripgrep	pipeline status
RKE	particledecay/asdf-rke	Build Status
rome	kichiemon/asdf-rome	Build Status
rstash	carlduevel/asdf-rstash	Build Status
rlwrap	asdf-community/asdf-rlwrap	Main workflow
Ruby	asdf-vm/asdf-ruby	Build Status
Rust	code-lever/asdf-rust	Build Status
rust-analyzer	Xyven1/asdf-rust-analyzer	Build Status
rye	Azuki-bar/asdf-rye	Build Status
saml2aws	elementalvoid/asdf-saml2aws	GitHub Actions Status
SBT	bram2000/asdf-sbt	Build Status
Scala	asdf-community/asdf-scala	Build Status
scaleway-cli	albarralnunez/asdf-plugin-scaleway-cli	Build Status
scalingo-cli	brandon-welsch/asdf-scalingo-cli	Build Status
Scarb	software-mansion/asdf-scarb	CI
sccache	emersonmx/asdf-sccache	Build Status
Scenery	skyzyx/asdf-scenery	Build Status
schemacrawler	davidecavestro/asdf-schemacrawler	Build Status
Seed7	susurri/asdf-seed7	CI
Semgrep	brentjanderson/asdf-semgrep	CI
semtag	junminahn/asdf-semtag	Build Status
semver	mathew-fleisch/asdf-semver	Build Status
Sentinel	asdf-community/asdf-hashicorp	Build
Serf	asdf-community/asdf-hashicorp	Build
serverless	pdemagny/asdf-serverless	Build Status
shell2http	ORCID/asdf-shell2http	Build Status
Shellcheck	luizm/asdf-shellcheck	Build Status
Shellspec	poikilotherm/asdf-shellspec	Build Status
Shfmt	luizm/asdf-shfmt	Build Status
Sinker	elementalvoid/asdf-sinker	GitHub Actions Status
Skaffold	nklmilojevic/asdf-skaffold	Build Status
skate	chessmango/asdf-skate	GitHub Actions Status
Sloth	slok/asdf-sloth	Build Status
smithy	aws/asdf-smithy	GitHub Actions Status
SML/NJ	samontea/asdf-smlnj	Build Status
Snyk	nirfuchs/asdf-snyk	Build Status
soft-serve	chessmango/asdf-soft-serve	GitHub Actions Status
Solidity	diegodorado/asdf-solidity	Build Status
Sops	feniix/asdf-sops	Build Status
sopstool	elementalvoid/asdf-sopstool	GitHub Actions Status
soracom-cli	grimoh/asdf-soracom	GitHub Actions Status
Sourcery	younke/asdf-sourcery	Build Status
spacectl	bodgit/asdf-spacectl	Build Status
Spago	nsaunders/asdf-spago	Build Status
Spark	joshuaballoch/asdf-spark	Build Status
Spectral	vbyrd/asdf-spectral	Build Status
Spin	pavloos/asdf-spin	Build Status
Spring Boot CLI	joschi/asdf-spring-boot	Main workflow
Spruce	woneill/asdf-spruce	Build Status
sqldef	cometkim/asdf-sqldef	CI
SQLite	cLupus/asdf-sqlite	Build Status
sshuttle	xanmanning/asdf-sshuttle	Build
Stack	sestrella/asdf-ghcup	CI
starboard	zufardhiyaulhaq/asdf-starboard	Build
starport	nikever/asdf-starport	Build Status
starship	grimoh/asdf-starship	GitHub Actions Status
steampipe	carnei-ro/asdf-steampipe	Build Status
Steel Bank Common Lisp (sbcl)	smashedtoatoms/asdf-sbcl	Build Status
step	log2/asdf-step	Build
Stern	looztra/asdf-stern	Build Status
stripe-cli	offbyone/asdf-stripe	Build Status
stylua	jc00ke/asdf-stylua	Build Status
svu	asdf-community/asdf-svu	Main workflow
swag	behoof4mind/asdf-swag	Build Status
Swift	fcrespo82/asdf-swift	Build Status
SwiftFormat	younke/asdf-swiftformat	Build Status
SwiftGen	younke/asdf-swiftgen	Build Status
Swiftlint	klundberg/asdf-swiftlint	Build Status
SWIProlog	mracos/asdf-swiprolog	Build Status
syft	davidgp1701/asdf-syft	GitHub Actions Status
syncher	nwillc/syncher	GitHub Actions Status
talhelper	bjw-s/asdf-talhelper	Build
Talos	particledecay/asdf-talos	Test Plugin
talosctl	bjw-s/asdf-talosctl	Build Status
Tanka	trotttrotttrott/asdf-tanka	Build Status
Task	particledecay/asdf-task	Test Plugin
tctl	eko/asdf-tctl	Build Status
Tekton-cli	johnhamelink/asdf-tekton-cli	Build Status
Teleport Enterprise	highb/asdf-teleport-ent	Build
Teleport Community	MaloPolese/asdf-teleport-community	Build
telepresence	pirackr/asdf-telepresence	Build
teller	pdemagny/asdf-teller	Build Status
temporalite	eko/asdf-temporalite	Build Status
terradozer	chessmango/asdf-terradozer	GitHub Actions Status
Terraform	asdf-community/asdf-hashicorp	Build
Terraform-docs	looztra/asdf-terraform-docs	Build Status
terraform-ls	asdf-community/asdf-hashicorp	Build
terraform-lsp	bartlomiejdanek/asdf-terraform-lsp	Build Status
Terraform-validator	looztra/asdf-terraform-validator	Build Status
Terraformer	grimoh/asdf-terraformer	GitHub Actions Status
Terragrunt	ohmer/asdf-terragrunt	Build Status
Terramate	martinlindner/asdf-terramate	Build
Terrascan	hpdobrica/asdf-terrascan	Build Status
tfctl	deas/asdf-tfctl	Build
tfc-agent	asdf-community/asdf-hashicorp	Build
tfenv	carlduevel/asdf-tfenv	Build Status
TFLint	skyzyx/asdf-tflint	Build Status
tfmigrate	dex4er/asdf-tfmigrate	CI
tfnotify	jnavarrof/asdf-tfnotify	Build Status
TFSec	woneill/asdf-tfsec	Build Status
tfstate-lookup	carnei-ro/asdf-tfstate-lookup	Build Status
tfswitch	iul1an/asdf-tfswitch	Build Status
tfupdate	yuokada/asdf-tfupdate	Build Status
tf-summarize	adamcrews/asdf-tf-summarize	Build
Thrift	alisaifee/asdf-thrift	Build Status
Tilt	eaceaser/asdf-tilt	CI workflow
Timoni	Smana/asdf-timoni	Build
Titan	gabitchov/asdf-titan	Build
tlsg-cli	0ghny/asdf-tlsgcli	Build
Tmux	aphecetche/asdf-tmux	Build Status
Tokei	gasuketsu/asdf-tokei	Build
tomcat	mbutov/asdf-tomcat	GitHub Actions Status
tonnage	elementalvoid/asdf-tonnage	GitHub Actions Status
tool-versions-to-env	smartcontractkit/tool-versions-to-env-action	GitHub Actions Status
Trdsql	johnlayton/asdf-trdsql	GitHub Actions Status
tree-sitter	ivanvc/asdf-tree-sitter	Build Status
tridentctl	asdf-community/asdf-tridentctl	CI
Trivy	zufardhiyaulhaq/asdf-trivy	Build
tsuru	virtualstaticvoid/asdf-tsuru	Build Status
tttyd	ivanvc/asdf-ttyd	Build Status
tuist	cprecioso/asdf-tuist	Build Status
tx	ORCID/asdf-transifex	Build Status
typos	aschiavon91/asdf-typos	Build Status
uaa-cli	vmware-tanzu/tanzu-plug-in-for-asdf	Build Status
Unison	susurri/asdf-unison	Build
upt	ORCID/asdf-upt	Build
upx	jimmidyson/asdf-upx	Build Status
usql	itspngu/asdf-usql	CI
V	jthegedus/asdf-v	Build Status
vale	pdemagny/asdf-vale	Build Status
vals	dex4er/asdf-vals	CI
Vault	asdf-community/asdf-hashicorp	Build
Velero	looztra/asdf-velero	Build Status
vendir	vmware-tanzu/asdf-carvel	Build Status
Venom	aabouzaid/asdf-venom	Build Status
vcluster	wt0f/asdf-vcluster	Pipeline Status
vela	pdemagny/asdf-vela	Build Status
velad	pdemagny/asdf-velad	Build Status
vhs	chessmango/asdf-vhs	GitHub Actions Status
Viddy	ryodocx/asdf-viddy	GitHub Actions Status
Vim	tsuyoshicho/asdf-vim	GitHub Actions Status:Commit
vultr-cli	ikuradon/asdf-vultr-cli	GitHub Actions Status:Commit
watchexec	nyrst/asdf-watchexec	pipeline status
WASI SDK	coolreader18/asdf-wasi-sdk	Build Status
WASM-4	jtakakura/asdf-wasm4	Build Status
wasm3	tachyonicbytes/asdf-wasm3	Build Status
wasmer	tachyonicbytes/asdf-wasmer	Build Status
wasmtime	tachyonicbytes/asdf-wasmtime	Build Status
Waypoint	asdf-community/asdf-hashicorp	Build
weave-gitops	deas/asdf-weave-gitops	Build
Websocat	bdellegrazie/asdf-websocat	GitHub Actions Status
Wren CLI	jtakakura/asdf-wren-cli	Build Status
wrk	ivanvc/asdf-wrk	Build Status
Wtfutil	NeoHsu/asdf-wtfutil	Build
XCTestHTMLReport	younke/asdf-xchtmlreport	Build Status
XcodeGen	younke/asdf-xcodegen	Build Status
xc	airtonix/asdf-xc	Build Status
xcodes	younke/asdf-xcodes	Build Status
xh	NeoHsu/asdf-xh	Build
yadm	particledecay/asdf-yadm	Test Plugin
yamlfmt	kachick/asdf-yamlfmt	Check
yamllint	ericcornelissen/asdf-yamllint	Check
Yarn	twuni/asdf-yarn	Build Status
yay	aaaaninja/asdf-yay	Build Status
Yor	ordinaryexperts/asdf-yor	Build
youtube-dl	iul1an/asdf-youtube-dl	Build
yj	ryodocx/asdf-yj	GitHub Actions Status
yq	sudermanjr/asdf-yq	Build Status
ytt	vmware-tanzu/asdf-carvel	Build Status
zbctl	camunda-community-hub/asdf-zbctl	Build Status
zellij	chessmango/asdf-zellij	GitHub Actions Status
Zephyr	nsaunders/asdf-zephyr	Build Status
Zig	cheetah/asdf-zig	Build Status
zigmod	kachick/asdf-zigmod	Build Status
Zola	salasrod/asdf-zola	Build Status
zoxide	nyrst/asdf-zoxide	Build Status
zprint	carlduevel/asdf-zprint	Build Status
