# Release Tools

A collection of scripts to help with creating releases for publishing libraries and dart packages.


[![build](https://github.com/asartalo/release_tools/actions/workflows/ci.yml/badge.svg)](https://github.com/asartalo/conventional/actions/workflows/ci.yml) [![Coverage Status](https://coveralls.io/repos/github/asartalo/release_tools/badge.svg?branch=main)](https://coveralls.io/github/asartalo/release_tools?branch=main)

## Features

- `release_tools update_version` - Update the version number of pubspec.yaml
- `release_tools next_version` - Get the next version based on commits.
- `release_tools should_release` - Check if we can create a release based on commits that follow the [Conventional Commit](https://www.conventionalcommits.org/) spec.
- `release_tools changelog` - Update changelog based on commits that follow the Conventional Commit spec.
- `release_tools update_year` - For syncing years on license files
- `release_tools remote_tag_id` - Get the commit id of a remote tag

## Notes Before Installing

To be effective, `release_tools` makes a few assumptions about a project:

- It uses `git` as scm
- Commits follow the [Conventional Commit](https://www.conventionalcommits.org/) spec
- Versions are tagged


## Installation

I recommend installing `release_tools` globally so that it won't interfere with your project's own dependecies:

```sh
$ pub global activate release_tools
```

## update_version

The following command will update the version on `pubspec.yaml` to version 1.0.1

```sh
$ release_tools update_version 1.0.1
```

## next_version

If you leave out the version to increment from, it will attempt to obtain the version from pubspec.yaml

```sh
$ release_tools next_version
```

The following command will incremeent the commands based on the commit logs that follow the conventional commit spec.

```sh
$ release_tools next_version 1.0.1
# 1.1.0
```

For example, if the commit logs contain a commit with the following message:

```
feat: something new

BREAKING-CHANGE: this changes everything
```

... then it will output a new major version:
```
2.0.0
```

By default it considers all the logs from the beginning but you can also specify a starting range:

```sh
$ release_tools next_version --from=abcde1234 1.0.1
```

...where `--from` should point to a commit id.

## should_release

The following will print 'yes' to stdout if there are releasable commits, or 'no' if there are none.

```sh
$ release_tools should_release
yes
$ release_tools should_release --from=abcde1234
no
```

## changelog

The following will update changelog based on the commit logs that follow the Conventional Commit spec.

```sh
$ release_tools changelog 2.0.1
$ release_tools changelog --from=3682c64 2.0.1
```

A sample changelog would be the following:

```markdown
# 1.0.0 (2021-02-09)

## Bug Fixes

- eat healthy ([#3](issues/3)) ([cf60800](commit/cf60800))

## Features

- **movement:** it jumps ([#1](issues/1)) ([925fcd3](commit/925fcd3))
- **movement:** it pounces ([#2](issues/2)) ([a25fcd3](commit/a25fcd3))
- **communication:** it talks ([#4](issues/4)) ([a25fcd3](commit/a25fcd3))
- **communication:** it sends sms ([#5](issues/5)) ([b25fcd3](commit/b25fcd3))

## BREAKING CHANGES

- null-safety ([#6](issues/6)) ([43cf9b7](commit/43cf9b7))
```

## update_year

A simple tool for updating the year on LICENSE files. Note that the logic is really simple. It simply updates the first 4-digit number to the current year which may or may not be enough for your needs.

```sh
$ release_tools update_year
$ release_tools update_year --license=MY_LICENSE_FILE
```

## remote_tag_id

Use this to retrieve the commit id of a tag on the git repository's remote.

```sh
$ release_tools remote_tag_id 0.2.2
# 3ed81541a61c7502b658c027f6d5ec87c129c1a9
```

Underneath, it simply runs the following git command:

```sh
git ls-remote -q --tags origin 0.2.2
```

You can specify the remote repository instead of the default 'origin' if needed:

```sh
$ release_tools remote_tag_id --remote=source 0.2.2
```