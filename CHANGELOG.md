# Changelog

All notable changes to this project will be documented in this file.

Please update it as part of your Pull-Request. Add a new entry at the top of the `Unreleased` section.
Try to keep it short. Just a single line and the number of your PR/Issues. 
All other relevant information should be provided on related issues or the PR itself.

When creating a new release, just create another section and include a link to the release and a
github compare-link with the previous one.

## [Unreleased](https://github.com/asdf-community/asdf-direnv/compare/v0.2.0..master)

- Speed up direnv stdlib by trying not to use asdf exec. #120

- Do not add plugin paths for "system" versions. #116 


## [0.2.0](https://github.com/asdf-community/asdf-direnv/releases/v0.2.0) (2022-03-16)


- Fix bug introduced by ASDF_DIRENV_DEBUG that was keeeping `set -x` on cached file. #111

- Enable tracing with non-empty ASDF_DIRENV_DEBUG #110

- Custom plugin shims now lower in PATH than bins #109

- Fix race condition when 2 processes are generating env files at the same time #107

- Do not assume that the $ASDF_DIR env var is set #104

- Use a different directory for cached envrc files. #105

- Use EditorConfig for shfmt "parser or printer flags" #98

- Handle special characters in the watch patch. #99

- Alternative way of loading asdf utils #96

- Better help #97

- Don't bother checking if a "system" version of a plugin is installed. #93

- More robust error handling #88

- Add export to environment variable #86

- Bump version shown in readme #71

- Improve handling of SIGINT, SIGTERM, and ERR #70

- Add support for Darwin on arm #65


## [0.1.0](https://github.com/asdf-community/asdf-direnv/releases/0.1.0) (2020-08-22)

- Recommend having a wrapper direnv function so that people dont have to write asdf exec direnv stuff

- Old shim is now part of asdf direnv extension command.

- You can have an .envrc with use asdf even if the directory has no .tool-versions file. All asdf current tools will be activated. In alpha

- Remove all variants of use asdf * have been removed.

  Doing use asdf will just ask asdf which versions are available in current directory.
  use asdf local/global were just internal apis and not intended for people to use.
  use asdf tool version was a bad choice since people should store versions on their .tool-versions file.

- Move commands to new asdf `lib/commands/*.bash` location
  See https://asdf-vm.com/#/plugins-create?id=extension-commands-for-asdf-cli

- use `asdf exec direnv` in .bashrc (#39)
