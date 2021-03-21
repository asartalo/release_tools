# Release Tools

A collection of scripts to help with creating releases for publishing libraries and dart packages.

## Features

**Available Scripts:**

- `release_tools:update_version` - Update the version number of pubspec.yaml

**Planned:**

- `release_tools:next_version` - Get the next version based on commits.
- `release_tools:should_release` - Check if we can create a release based on commits that follow the [Conventional Commit](https://www.conventionalcommits.org/) spec.
- `release_tools:changelog` - Update changelog based on commits that follow the Conventional Commit spec.
- `release_tools:update_year` - For syncing years on license files

## Installation

TODO

## Update Version

```sh
$ pub run release_tools:update_version 1.0.1
```