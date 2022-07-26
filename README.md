# Release Tools

A collection of scripts to help with creating releases for publishing libraries
and dart packages.

[![build](https://github.com/asartalo/release_tools/actions/workflows/ci.yml/badge.svg)](https://github.com/asartalo/release_tools/actions/workflows/ci.yml)
[![Coverage Status](https://coveralls.io/repos/github/asartalo/release_tools/badge.svg?branch=main)](https://coveralls.io/github/asartalo/release_tools?branch=main)
[![Pub](https://img.shields.io/pub/v/release_tools.svg)](https://pub.dev/packages/release_tools)

## Features

- `release_tools update_version` - Update the version number of pubspec.yaml
- `release_tools next_version` - Get the next version based on commits.
- `release_tools should_release` - Check if we can create a release based on
  commits that follow the
  [Conventional Commit](https://www.conventionalcommits.org/) spec.
- `release_tools changelog` - Update changelog based on commits that follow the
  Conventional Commit spec.
- `release_tools update_year` - For syncing years on license files.
- `release_tools remote_tag_id` - Get the commit id of a remote tag.
- `release_tools current_version` - Get the current version of this package.
- `release_tools prepare_release` - Complete release prep logic using the tools
  previously mentioned.

## Notes Before Using

To be effective, `release_tools` makes a few assumptions about a project:

- It uses `git` as scm
- Commits follow the [Conventional Commit](https://www.conventionalcommits.org/)
  spec
- Versions are tagged

If your project needs are typical, you probably only need `prepare_release`.
However, if you need more fine-grained control, use the other scripts as you see
fit.

## Installation

I recommend installing `release_tools` globally so that it won't interfere with
your project's own dependecies. Constrain it to a specific version to limit
supply-chain exploits.

```sh
$ pub global activate release_tools 0.3.1
```

## Scripts

### update_version

The following command will update the version on `pubspec.yaml` on the current
directory to version 1.0.1

```sh
$ release_tools update_version 1.0.1
```

If you want to update the version on a text file other than `pubspec.yaml`, use
the `--file` option:

```sh
$ release_tools update_version --file="README.md" 1.0.1
```

By default, it will look for strings that look like semver-flavored version
strings. If you want to be specific, you can specify a template for replacement.
For example, if the `README.md` file contains the following text:

```markdown
# My Project

Current Version: 1.0.0

Starting from version 1.0.0, all alert buttons will be red.
```

Running the following command...

```sh
$ release_tools update_version --file="README.md" --template="Current Version: [VERSION]" 1.0.1
```

...will change the contents of `README.md` to:

```markdown
# My Project

Current Version: 1.0.1

Starting from version 1.0.0, all alert buttons will be red.
```

### next_version

```sh
$ release_tools next_version 1.0.1
$ release_tools next_version
```

If you don't pass the version to increment from, it will attempt to get the
version from `pubspec.yaml`. The script will return the next version based on
the releasable commit logs that follow the conventional commit spec.

For example, if the commit logs contain a commit with the following message:

```
feat: something new

BREAKING-CHANGE: this changes everything
```

... then it will output a new major version:

```
2.0.0
```

By default, `next_version` considers all the logs from the beginning of the
commit history but you can also specify a starting range:

```sh
$ release_tools next_version --from=abcde1234 1.0.1
```

...where `--from` should point to a commit id.

It will also increment the build number if the version on the `pubspec.yaml` or
the version passed has it if there are releasable commits.

```sh
$ release_tools next_version 1.0.1+1
# 1.1.0+2
```

If you don't want this behavior, pass the `--freezeBuild` flag.

```sh
$ release_tools next_version --freezeBuild 1.0.1+1
# 1.1.0+1
```

To output just the version without the build number, pass the `--noBuild` flag.

```sh
$ release_tools next_version --noBuild 1.0.1+1
# 1.1.0
```

### should_release

The following will print 'yes' to stdout if there are releasable commits, or
'no' if there are none.

```sh
$ release_tools should_release
yes
$ release_tools should_release --from=abcde1234
no
```

"Releasable" here means that the commit logs contain at least one `fix` (PATCH),
`feat` (MINOR), or `BREAKING` (MAJOR) logs as described in the conventional
commits spec.

### changelog

The following will update the changelog based on the releasable commits.

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

### update_year

A simple tool for updating the year on LICENSE files. Note that the logic is
really simple. It simply updates the first 4-digit number to the current year
which may or may not be enough for your needs.

```sh
$ release_tools update_year
$ release_tools update_year --license=MY_LICENSE_FILE
```

### remote_tag_id

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

### current_version

Use this if you need to retrieve the current version on pubspec.yaml

```sh
$ release_tools current_version
# 1.0.2
```

### prepare_release

Complete release preparation logic with the following steps:

1. Get the current version
2. Get the commits from the last version tag or, if a version tag is not
   available for the last release, it will get them from the beginning of the
   commit history
3. Check if a release is appropriate and if so...
4. Update version on pubspec including incrementing the build number
5. Create summary changelog from the commits

```sh
$ release_tools prepare_release
```

If there are no releasable commits, it will print the following:

```sh
There are no releasable commits
```

Otherwise, it will print something like the following:

```sh
Version bumped to: 0.2.5

SUMMARY:

# 0.2.5 (2021-05-03)

## Bug Fixes

- **changelog:** performance section in changelogs ([063e07d](commit/063e07d))

## Features

- prepare_release command ([877d63e](commit/877d63e))
```

If you need a summary of the result of the script run, you can pass `-w` to
write some summary files like in the following:

```sh
$ release_tools prepare_release -w
```

This will create two files, `VERSION.txt` and `RELEASE_SUMMARY.txt` which will
contain just the version for release and the summary of changes, respectively.

## Similar Tools

- [pub_release](https://pub.dev/packages/pub_release) - A much more mature
  release tool. I wanted to use this tool on my projects but found I didn't need
  a lot of its features. Still awesome!
- [melos](https://pub.dev/packages/melos) - This one is geared towards
  monorepos.
