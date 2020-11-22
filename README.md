# CompatUI

CompatUI is a terminal text interface to the `[compat]` section of a
Julia `Project.toml` file.

## Installation

```julia
using Pkg
pkg"add https://github.com/GunnarFarneback/CompatUI.jl.git"
```

*Note*: add `CompatUI` to your default environment, not to the project
you want to set compat for.

## Compatibility

CompatUI requires a Julia master version of 2020-11-15 or later (after
the merge of https://github.com/JuliaLang/julia/pull/38393). For full
functionality the not yet merged (as of 2021-11-21) PR
https://github.com/JuliaLang/julia/pull/38489 is also needed.

## Usage

Start Julia with `--project` or use `Pkg.activate` to navigate to the
project you want to set compat for.

```julia
using CompatUI
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
