using UUIDs: UUID
using Pkg
using Pkg.Types: VersionSpec
using REPL.TerminalMenus: _ConfiguredMenu, Config, ARROW_LEFT, ARROW_RIGHT, request
import REPL.TerminalMenus: numoptions, writeline, writeLine, keypress, cancel,
                           pick, selected, header

mutable struct IndirectMenu <: _ConfiguredMenu{Config}
    pagesize::Int
    pageoffset::Int
    cursor::Base.RefValue{Int}
    saved_state::Dict{Any, Any}
    key::Tuple
    options::Dict{Any, Dict{UUID, String}}
    config::Config
end

function IndirectMenu(options, pagesize::Int = 10; kwargs...)
    pageoffset = 0
    cursor = Ref(1)
    menu = IndirectMenu(pagesize, pageoffset, cursor, Dict(), (), options,
                        Config(; kwargs...))
    return menu
end

pick(m::IndirectMenu, cursor) = false
cancel(m::IndirectMenu) = nothing
numoptions(m::IndirectMenu) = length(m.options[m.key])
selected(m::IndirectMenu) = nothing
function writeline(buf::IOBuffer, menu::IndirectMenu, idx::Int, iscursor::Bool)
    print(buf, collect(values(menu.options[menu.key]))[idx])
end
header(m::IndirectMenu) = ""
function keypress(menu::IndirectMenu, c::UInt32)
    menu.saved_state[menu.key] = (menu.pageoffset, menu.cursor[])
    if c == Int(ARROW_RIGHT)
        if menu.key == ()
            menu.key = (collect(keys(menu.options[()]))[menu.cursor[]],)
            load_state!(menu)
        end
    elseif c == Int(ARROW_LEFT)
        if menu.key != ()
            menu.key = ()
            load_state!(menu)
        end
    end
    return false
end

function load_state!(menu::IndirectMenu)
    menu.pageoffset, menu.cursor[] = get(menu.saved_state, menu.key, (0, 1))
end

mutable struct PkgData
    name::String
    uuid::UUID
    versions::Vector{VersionNumber}
    deps_of_latest_version::Dict{String, UUID}
    compat_of_latest_version::Dict{String, VersionSpec}
end

function indirect_compat_ui()
    project = Pkg.Types.read_project(Base.active_project())
    direct_deps = filter(p -> !Pkg.Types.is_stdlib(last(p)), project.deps)
    registries = Pkg.Registry.reachable_registries()
    indirect_deps = find_indirect_deps(registries, direct_deps)
    options = Dict{Any, Dict{UUID, String}}()
    options[()] = Dict{UUID, String}()
    for (uuid, dep) in indirect_deps
        dep_options = Dict{UUID, String}()
        color = :default
        for (name, uuid) in dep.deps_of_latest_version
            compat = get(dep.compat_of_latest_version, name, nothing)
            entry, up_to_date = format_dependency_entry(uuid, name, compat,
                                                        indirect_deps)
            dep_options[uuid] = entry
            if !up_to_date
                color = :red
            end
        end
        options[(dep.uuid,)] = dep_options
        options[()][uuid] = string(Base.text_colors[color], dep.name,
                                   Base.text_colors[:default])
    end
    menu = IndirectMenu(options, 50)
    request(menu, cursor = menu.cursor)
end

function format_dependency_entry(uuid, name, compat, deps)
    versions = deps[uuid].versions
    latest_version = maximum(versions)
    color = :default
    up_to_date = true
    if isnothing(compat)
        compat_version = latest_version
        color = :blue
    else
        compat_versions = filter(in(compat), versions)
        if isempty(compat_versions)
            compat_version = "None"
            color = :red
            up_to_date = false
        else
            compat_version = maximum(filter(in(compat), versions))
            if compat_version != latest_version
                color = :red
                up_to_date = false
            end
        end
    end
    return string(rpad(latest_version, 15), " ",
                  Base.text_colors[color], rpad(compat_version, 15),
                  Base.text_colors[:default], " ",
                  name), up_to_date
end

# Find all indirect dependencies, direct dependencies included but
# stdlibs excluded, under the assumption that the latest version can
# be used of all packages. I.e. compat is ignored.
function find_indirect_deps(registries, direct_deps)
    all_deps = Dict{UUID, PkgData}()
    unprocessed_deps = Dict(uuid => name for (name, uuid) in direct_deps)
    while !isempty(unprocessed_deps)
        uuid, name = pop!(unprocessed_deps)
        versions = VersionNumber[]
        deps_of_latest_version = Dict{String, UUID}()
        compat_of_latest_version = Dict{String, VersionSpec}()
        for registry in registries
            if haskey(registry.pkgs, uuid)
                pkg = registry.pkgs[uuid]
                Pkg.Registry.init_package_info!(pkg)
                versions_this_reg = keys(pkg.info.version_info)
                append!(versions, versions_this_reg)
                latest_version = maximum(versions)
                if latest_version == maximum(versions_this_reg)
                    empty!(deps_of_latest_version)
                    for (range, deps) in pkg.info.deps
                        if latest_version in range
                            merge!(deps_of_latest_version, deps)
                        end
                    end
                    empty!(compat_of_latest_version)
                    for (range, compat) in pkg.info.compat
                        if latest_version in range
                            merge!(compat_of_latest_version, compat)
                        end
                    end
                end
            end
        end
        filter!(pair -> !Pkg.Types.is_stdlib(last(pair)),
                deps_of_latest_version)
        filter!(pair -> haskey(deps_of_latest_version, first(pair)),
                compat_of_latest_version)

        pkg_data = PkgData(name, uuid, versions, deps_of_latest_version,
                           compat_of_latest_version)
        all_deps[uuid] = pkg_data
        for (name, uuid) in deps_of_latest_version
            if !haskey(all_deps, uuid)
                unprocessed_deps[uuid] = name
            end
        end
    end
    # The Julia dependency is special.
    julia = all_deps[UUID("1222c4b2-2114-5bfd-aeef-88e4692bbb3e")]
    julia.versions = VersionNumber.(get_julia_versions())
    empty!(julia.deps_of_latest_version)
    return all_deps
end
