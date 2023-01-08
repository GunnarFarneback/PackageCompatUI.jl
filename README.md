# PackageCompatUI

PackageCompatUI is a terminal text interface to the `[compat]` section
of a Julia `Project.toml` file.

## Installation

```julia
using Pkg
pkg"add PackageCompatUI"
```

*Note*: add PackageCompatUI to your default environment, not to the
project you want to set compat for.

*Note*: As of Julia v1.8, the `pkg>`-REPL-mode
[natively supports editing of the compat section](https://pkgdocs.julialang.org/dev/repl/#repl-compat).
This is very rudimentary compared to PackageCompatUI but starts faster.

## Compatibility

PackageCompatUI requires Julia 1.6 or later.

## Usage

Start Julia with `--project` or use `Pkg.activate` to navigate to the
project you want to set compat for.

```julia
using PackageCompatUI
compat_ui()
```

### Controls

|              |                                   |
| ------------ | --------------------------------- |
| ?            | Toggle show help                  |
| →, ENTER     | Enter package                     |
| ←, d         | Leave package                     |
| ENTER, SPACE | Toggle semver compatible versions |
| q            | Save and quit                     |
| Ctrl-c       | Quit without saving               |
| ↑            | Move up                           |
| ↓            | Move down                         |
| PAGE UP      | Move page up                      |
| PAGE DOWN    | Move page down                    |
| HOME         | Move to first item                |
| END          | Move to last item                 |

### Colors

* Red: No compat information available for the package.
* Yellow: Compat declared for some versions of the package, but not the latest.
* Green: Compatible with the latest version of the package.
* Gray: Package is not registered.

## Tutorial

[Example 1](docs/example1.md) and [Example 2](docs/example2.md).
