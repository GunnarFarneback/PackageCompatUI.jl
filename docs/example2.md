# Example 2

Continuing from [Example 1](example1.md) you find that your package is
using some Julia internals and actually isn’t compatible with Julia
1.6 (yet). How should the `julia` entry then look? Start `compat_ui`
again

```
julia> compat_ui()
Save and quit: q, Help: ?
 > julia                                   1.3
   DataStructures                          0.18.3
```
and enter `julia`:

```
julia: 1.3
 > [ ] 1.0.0
   [ ] 1.0.1
   [ ] 1.0.2
   [ ] 1.0.3
   [ ] 1.0.4
   [ ] 1.0.5
   [ ] 1.1.0
   [ ] 1.1.1
   [ ] 1.2.0
   [x] 1.3.0
   [x] 1.3.1
   [x] 1.4.0
   [x] 1.4.1
   [x] 1.4.2
   [x] 1.5.0
   [x] 1.5.1
   [x] 1.5.2
   [x] 1.5.3
   [x] 1.5.4
   [x] 1.6.0
```
Navigate to the bottom and hit `ENTER` to toggle off `1.6.0`:

```
julia: ~1.3, ~1.4, ~1.5
   [ ] 1.0.0
   [ ] 1.0.1
   [ ] 1.0.2
   [ ] 1.0.3
   [ ] 1.0.4
   [ ] 1.0.5
   [ ] 1.1.0
   [ ] 1.1.1
   [ ] 1.2.0
   [x] 1.3.0
   [x] 1.3.1
   [x] 1.4.0
   [x] 1.4.1
   [x] 1.4.2
   [x] 1.5.0
   [x] 1.5.1
   [x] 1.5.2
   [x] 1.5.3
   [x] 1.5.4
 > [ ] 1.6.0
```
Quit with `q` and find `Project.toml` updated to:

```
[compat]
DataStructures = "0.18.3"
julia = "~1.3, ~1.4, ~1.5"
```
