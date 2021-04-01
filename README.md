# Release Tools

A collection of scripts to help with creating releases for publishing libraries and dart packages.


[![build](https://github.com/asartalo/release_tools/actions/workflows/ci.yml/badge.svg)](https://github.com/asartalo/conventional/actions/workflows/ci.yml) [![Coverage Status](https://coveralls.io/repos/github/asartalo/release_tools/badge.svg?branch=main)](https://coveralls.io/github/asartalo/release_tools?branch=main)

## Features

**Available**

- `release_tools update_version` - Update the version number of pubspec.yaml
- `release_tools next_version` - Get the next version based on commits.
- `release_tools should_release` - Check if we can create a release based on commits that follow the [Conventional Commit](https://www.conventionalcommits.org/) spec.

**Planned:**

- `release_tools changelog` - Update changelog based on commits that follow the Conventional Commit spec.
- `release_tools update_year` - For syncing years on license files

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

## Update Version

The following command will update the version on `pubspec.yaml` to verion 1.0.1

```sh
$ release_tools update_version 1.0.1
```

## Next Version

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