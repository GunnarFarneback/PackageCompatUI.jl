# Example 1

Assume we have a new package with the single dependency
`DataStructures`. Start `compat_ui()`:

```
julia> compat_ui()
Save and quit: q, Help: ?
 > julia
   DataStructures
```
Use up and down arrows to navigate between the packages. Use right
arrow to enter a package. Let’s start with `julia`:

```
julia:
 > [ ] 1.0.0
   [ ] 1.0.1
   [ ] 1.0.2
   [ ] 1.0.3
   [ ] 1.0.4
   [ ] 1.0.5
   [ ] 1.1.0
   [ ] 1.1.1
   [ ] 1.2.0
   [ ] 1.3.0
   [ ] 1.3.1
   [ ] 1.4.0
   [ ] 1.4.1
   [ ] 1.4.2
   [ ] 1.5.0
   [ ] 1.5.1
   [ ] 1.5.2
   [ ] 1.5.3
   [ ] 1.5.4
   [ ] 1.6.0
```
Say that we need Julia 1.3 or later. Move the cursor down to the
`1.3.0` entry and hit `ENTER`:

```
julia: 1.3
   [ ] 1.0.0
   [ ] 1.0.1
   [ ] 1.0.2
   [ ] 1.0.3
   [ ] 1.0.4
   [ ] 1.0.5
   [ ] 1.1.0
   [ ] 1.1.1
   [ ] 1.2.0
 > [x] 1.3.0
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
All later versions which are compatible according to the semantic
versioning rules get automatically toggled as well and at the top we
can see the corresponding value to be used in `[compat]`: `1.3`.

Now leave `julia` with left arrow and navigate the cursor to `DataStructures`:

```
   julia                                   1.3
 > DataStructures
```
Hit right arrow to enter the package:

```
DataStructures:
 > [ ] 0.9.0               2018-06-29
   [ ] 0.10.0              2018-07-19
   [ ] 0.11.0              2018-08-07
   [ ] 0.11.1              2018-08-27
   [ ] 0.12.0              2018-09-11
   [ ] 0.13.0              2018-09-21
   [ ] 0.14.0              2018-09-24
   [ ] 0.14.1              2019-05-22
   [ ] 0.15.0              2019-05-22
   [ ] 0.16.1              2019-10-01
   [ ] 0.17.0              2019-10-01
   [ ] 0.17.1              2019-10-01
   [ ] 0.17.2              2019-10-07
   [ ] 0.17.3              2019-10-21
   [ ] 0.17.4              2019-10-27
   [ ] 0.17.5              2019-10-29
   [ ] 0.17.6              2019-11-22
   [ ] 0.17.7              2020-01-03
   [ ] 0.17.8              2020-01-15
v  [ ] 0.17.9              2020-01-15
```

The `v` at the bottom indicates that the list continues and if we move
the cursor downwards new entries will be scrolled in. This view also
lists the registration date of the different versions (only
unavailable for `julia` itself), which might be helpful in figuring out
what compatibility bounds to consider. Say we need a bugfix from
version `0.18.3` (purely hypothetical). Navigate to the very bottom and
back up to `0.18.3` and hit `ENTER`:

```
DataStructures: 0.18.3
^  [ ] 0.17.11             2020-04-01
   [ ] 0.17.12             2020-04-12
   [ ] 0.17.13             2020-04-19
   [ ] 0.17.14             2020-04-29
   [ ] 0.17.15             2020-04-29
   [ ] 0.17.16             2020-05-16
   [ ] 0.17.17             2020-05-23
   [ ] 0.17.18             2020-06-14
   [ ] 0.17.19             2020-06-25
   [ ] 0.17.20             2020-08-04
   [ ] 0.18.0              2020-08-17
   [ ] 0.18.1              2020-08-23
   [ ] 0.18.2              2020-08-24
 > [x] 0.18.3              2020-09-02
   [x] 0.18.4              2020-09-04
   [x] 0.18.5              2020-09-13
   [x] 0.18.6              2020-09-15
   [x] 0.18.7              2020-10-03
   [x] 0.18.8              2020-10-22
   [x] 0.18.9              2021-01-19
```
Going back again with left arrow we have:

```
Save and quit: q, Help: ?
   julia                                   1.3
 > DataStructures                          0.18.3
```
Upon hitting `q` to save and quit you will find that your
`Project.toml` has been updated with:

```
[compat]
DataStructures = "0.18.3"
julia = "1.3"
```

The tutorial is continued in [Example 2](example2.md).
