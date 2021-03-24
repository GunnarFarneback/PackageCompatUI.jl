"""
    using PackageCompatUI
    compat_ui()

Interactive terminal interface to the `[compat]` section of
`Project.toml` for the *currently active project*.
"""
module PackageCompatUI

export compat_ui

using Pkg
using Downloads: download
using JSON3
using Scratch
using Git
using Dates

include("menu.jl")

"""
    compat_ui()

Interactive terminal interface to the `[compat]` section of
`Project.toml` for the currently active project.

*Keyword arguments*:

* `pagesize`: Maximum number of lines used for the UI. Default is 20.
* `dates`: Whether to show registration date for package versions.
  Default is true. If disabled the UI starts faster.

*Controls*:

Move up and down with arrow keys. Arrow right and left to enter and
leave packages. Use Enter to toggle compatible versions. Quit and save
with `q`. Online help with `?`.

When toggling a compatible version, all semantically versioning
compatible versions are also set or unset.

*Colors*:

* Red: No compat information available for the package.
* Yellow: Compat declared for some versions of the package, but not the latest.
* Green: Compatible with the latest version of the package.
* Gray: Package is not registered.
"""
function compat_ui(;pagesize = 20, dates = true)
    if VERSION < v"1.6.0-DEV.1554"
        println("Julia version must be at least 1.6.0-DEV.1554.")
        return
    end
    project = Pkg.Types.read_project(Base.active_project())
    needs_compat = filter(p -> !Pkg.Types.is_stdlib(last(p)),
                          merge(project.deps, project.extras))
    selected = 1
    versions = Dict{String, Vector{String}}()
    version_dates = Dict{String, Dict{String, String}}()
    for (package, uuid) in needs_compat
        print("loading data for ", rpad(package, 60), "\r")
        versions[package], version_dates[package] = find_versions(uuid, dates)
    end
    print(rpad("\r", 80), "\r")
    versions["julia"] = get_julia_versions()
    version_dates["julia"] = Dict{String, String}()
    packages = vcat("julia", sort(collect(keys(needs_compat))))
    data = MenuData(packages, project.compat, versions, version_dates)
    menu = Menu(data, pagesize)
    menu.cursor[] = selected
    request(menu, cursor = menu.cursor)
    project.compat = data.compat
    Pkg.Types.write_project(project, Base.active_project())
    return
end

function gitcmd(repo)
    function (x...)
        cmd = Git.git()
        push!(cmd.exec, "-C", repo, x...)
        readlines(cmd)
    end
end

# Find registry version information for the package with the given
# `uuid`. This may pick up information from multiple registries.
# Look up registration date of versions if `find_dates` is true.
function find_versions(uuid, find_dates)
    versions = String[]
    dates = Dict{String, String}()
    for registry in Pkg.Types.collect_registries()
        reg_data = Pkg.Types.read_registry(joinpath(registry.path,
                                                    "Registry.toml"))
        if haskey(reg_data["packages"], string(uuid))
            package_dir = reg_data["packages"][string(uuid)]["path"]
            versions_file = joinpath(registry.path, package_dir,
                                     "Versions.toml")
            append!(versions, keys(Pkg.TOML.parsefile(versions_file)))
            if find_dates
                find_version_dates!(dates, reg_data, package_dir)
            end
        end
    end

    return sort(versions, by = VersionNumber), dates
end

fetched_this_session = Set{String}()

function find_version_dates!(dates, registry, package_dir)
    registry_name = registry["name"]
    repo = @get_scratch!(registry_name)
    git = gitcmd(repo)
    if !isdir(joinpath(repo, "refs"))
        println("\nCloning the $(registry_name) Registry. This might take some time.")
        git("clone", "--bare", registry["repo"], ".")
        println()
    else
        if registry_name ∉ fetched_this_session
            git("fetch", "-q", "origin", "master:master")
            push!(fetched_this_session, registry_name)
        end
    end
    time = 0

    for blame in git("blame", "-p", joinpath(package_dir, "Versions.toml"))
        if startswith(blame, "committer-time")
            time = parse(Int, last(split(blame)))
        elseif startswith(blame, "\t")
            m = match(r"\[\"(.*)\"\]", blame)
            if !isnothing(m)
                version = only(m.captures)
                dates[version] = Dates.format(unix2datetime(time), "yyyy-mm-dd")
            end
        end
    end
end

function get_julia_versions()
    io = IOBuffer()
    download("https://julialang-s3.julialang.org/bin/versions.json", io)
    seekstart(io)
    json = JSON3.read(io)
    versions = sort(VersionNumber.(String.(keys(json))))
    filter!(v -> v >= v"1" && isempty(v.build) && isempty(v.prerelease),
            versions)
    return string.(versions)
end

function find_compatible_versions(versions, compat)
    if isempty(compat)
        return String[]
    end
    semver = Pkg.Types.semver_spec(compat)
    return filter(v -> VersionNumber(v) in semver, versions)
end

function compute_compat(version_strings, compatible_version_strings)
    versions = VersionNumber.(base_version.(version_strings))
    compatible_versions = VersionNumber.(base_version.(compatible_version_strings))
    compat = String[]

    # 0.0.x versions. Just list all of them individually.
    append!(compat, string.(filter(is00x, compatible_versions)))

    # 0.x.y versions.
    xy_versions = filter(is0xy, versions)
    for x in unique([v.minor for v in xy_versions])
        x_versions = filter(v -> v.minor == x, xy_versions)
        for (i, v) in enumerate(x_versions)
            if v in compatible_versions
                if issubset(x_versions[(i + 1):end], compatible_versions)
                    push!(compat, compact_version(v))
                    break
                end
                push!(compat, string("=", v))
            end
        end
    end

    # x.y.z versions.
    xyz_versions = filter(isxyz, versions)
    for x in unique([v.major for v in xyz_versions])
        x_versions = filter(v -> v.major == x, xyz_versions)
        for (i, v) in enumerate(x_versions)
            if v in semver_spec(compat)
                continue
            end
            if v in compatible_versions
                if issubset(x_versions[(i + 1):end], compatible_versions)
                    push!(compat, compact_version(v))
                    continue
                end
                y = v.minor
                y_versions = filter(v -> v.minor == y, x_versions[(i + 1):end])
                if issubset(y_versions, compatible_versions)
                    push!(compat, compact_version(v, "~"))
                    continue
                end
                push!(compat, string("=", v))
            end
        end
    end
    return join(compat, ", ")
end

# Remove prerelease and build numbers.
function base_version(version::String)
    v = VersionNumber(version)
    return string(VersionNumber(v.major, v.minor, v.patch, (), ()))
end

# Extension of `Pkg.Types.semver_spec` for vector of strings.
function semver_spec(s::Vector{String})
    if isempty(s)
        return Pkg.Types.VersionSpec([])
    end
    return Pkg.Types.semver_spec(join(s, ", "))
end

is00x(v::VersionNumber) = v.major == v.minor == 0
is0xy(v::VersionNumber) = v.major == 0 && v.minor > 0
isxyz(v::VersionNumber) = v.major > 0

function compact_version(v::VersionNumber, s = "")
    if v.patch > 0
        return string(s, v)
    end
    if v.minor > 0 || s == "~"
        return string(s, v.major, ".", v.minor)
    end
    return string(s, v.major)
end

end # module
