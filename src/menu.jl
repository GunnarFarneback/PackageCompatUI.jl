using REPL.TerminalMenus
using REPL.TerminalMenus: _ConfiguredMenu, Config, ARROW_LEFT, ARROW_RIGHT
import REPL.TerminalMenus: options, writeline, writeLine, keypress, cancel,
                           pick, selected, header

struct MenuData
    # Names of the packages which are listed in the main menu.
    packages::Vector{String}
    # Mapping from package name to compat specification as a string.
    compat::Dict{String, String}
    # Mapping from package name to a vector of versions numbers as
    # strings.
    versions::Dict{String, Vector{String}}
    # Mapping from package name to a mapping of version numbers to
    # registration dates. The latter mappings may be empty or
    # incomplete.
    dates::Dict{String, Dict{String, String}}
end

mutable struct Menu <: _ConfiguredMenu{Config}
    pagesize::Int
    pageoffset::Int
    options::Array{String,1}
    selected::Set{Int}
    cursor::Base.RefValue{Int}
    mode::Symbol
    saved_state::Dict{Symbol, Any}
    data::MenuData
    show_help::Bool
    config::Config
end

function get_help_texts()
    return split("""
                 ?:             Toggle show help
                 ARROW RIGHT:   Choose package (also ENTER)
                 ARROW LEFT, d: Leave package
                 ENTER, SPACE:  Toggle semver compatible versions
                 q:             Save and quit
                 Ctrl-c:        Quit without saving
                 ARROW UP:      Move up
                 ARROW DOWN:    Move down
                 PAGE UP:       Move page up
                 PAGE DOWN:     Move page down
                 HOME:          Move to first item
                 END:           Move to last item
                 """, "\n", keepempty = false)
end

function Menu(data::MenuData, pagesize::Int = 10; kwargs...)
    pageoffset = 0
    selected = Set{Int}()
    cursor = Ref(0)
    mode = :-
    options = copy(data.packages)
    menu = Menu(pagesize, pageoffset, options, selected, cursor, mode,
                Dict{Symbol, Any}(), data, false, Config(; kwargs...))
    update_package_colors!(menu)
    return menu
end

options(menu::Menu) = menu.options

function cancel(menu::Menu)
    if menu.mode != :-
        # Force saving compat in current menu before exiting.
        switch_menu!(menu)
    end
end

selected(menu::Menu) = nothing

function pick(menu::Menu, cursor::Int)
    if menu.show_help
        load_state!(menu, menu.mode)
        menu.show_help = false
    end
    if menu.mode == :-
        switch_menu!(menu)
    else
        toggle_selected!(menu)
    end
    return false
end

function keypress(menu::Menu, c::UInt32)
    if menu.show_help
        load_state!(menu, menu.mode)
        menu.show_help = false
    elseif c == Int('?')
        save_state!(menu)
        menu.options = get_help_texts()
        menu.cursor[] = 1
        menu.pageoffset = 0
        menu.show_help = true
    elseif menu.mode == :-
        if c == Int(ARROW_RIGHT)
            switch_menu!(menu)
        end
    else
        if c in (Int(ARROW_LEFT), Int('d'))
            switch_menu!(menu)
        elseif c == Int(' ')
            toggle_selected!(menu)
        end
    end
    return false
end

function switch_menu!(menu::Menu)
    save_state!(menu)
    if menu.mode == :-
        package = menu.data.packages[menu.cursor[]]
        if isempty(menu.data.versions[package])
            return
        end
        if haskey(menu.saved_state, Symbol(package))
            load_state!(menu, Symbol(package))
        else
            versions = menu.data.versions[package]
            dates = menu.data.dates[package]
            menu.cursor[] = 1
            menu.pageoffset = 0
            menu.options = [string(rpad(v, 20), get(dates, v, ""))
                            for v in versions]
            compat = find_compatible_versions(versions,
                                              get(menu.data.compat,
                                                  package, ""))
            menu.selected = Set(findall(v -> v in compat, versions))
            menu.mode = Symbol(package)
        end
    else
        update_compat_string!(menu)
        load_state!(menu, :-)
        update_package_colors!(menu)
    end
end

function toggle_selected!(menu::Menu)
    if menu.cursor[] in menu.selected
        operation = delete!
    else
        operation = push!
    end
    versions = menu.data.versions[String(menu.mode)]
    spec = Pkg.Types.semver_spec(base_version(versions[menu.cursor[]]))
    for (i, version) in enumerate(versions)
        if VersionNumber(version) in spec
            operation(menu.selected, i)
        end
    end
    update_compat_string!(menu)
end

function save_state!(menu::Menu)
    state = (menu.pageoffset, menu.cursor[], menu.options, menu.selected)
    menu.saved_state[menu.mode] = state
end

function load_state!(menu::Menu, mode::Symbol)
    @assert haskey(menu.saved_state, mode)
    saved_state = menu.saved_state[mode]
    menu.pageoffset, menu.cursor[], menu.options, menu.selected = saved_state
    menu.mode = mode
end

function writeline(buf::IOBuffer, menu::Menu, idx::Int, iscursor::Bool)
    # This is a workaround for
    # https://github.com/JuliaLang/julia/pull/48173.
    #
    # It can be removed when no Julia versions before 1.9 (probably)
    # are supported.
    #
    # Note that while this workaround avoids indexing out of bounds
    # and makes the menu work correctly, the result is still less than
    # ideal with the options needlessly jumping around.
    if idx <= 0
        print(buf, "")
        return
    end

    if menu.mode == :-
        print(buf, menu.options[idx])
    else
        c = idx in menu.selected ? "x" : " "
        print(buf, "[$c] ", menu.options[idx])
    end
end

function header(menu::Menu)
    if menu.show_help
        return ""
    elseif menu.mode == :-
        return "Save and quit: q, Help: ?"
    end
    package = string(menu.mode)
    color = package_color(menu, package)
    compat = get(menu.data.compat, package, "")
    if length(package) + length(compat) >= 78
        compat = string(compat[1:(74 - length(package))], "…")
    end
    return string(Base.text_colors[color], package,
                  Base.text_colors[:default], ": ",
                  compat)
end

function update_package_colors!(menu::Menu)
    @assert menu.mode == :-
    for (i, package) in enumerate(menu.data.packages)
        color = package_color(menu, package)
        compat = get(menu.data.compat, package, "")
        if length(compat) >= 40
            compat = string(compat[1:36], "…")
        end
        colored_package = string(Base.text_colors[color],
                                 rpad(package, 40),
                                 Base.text_colors[:default],
                                 compat)
        menu.options[i] = colored_package
    end
end

function package_color(menu::Menu, package)
    versions = menu.data.versions[package]
    compat = get(menu.data.compat, package, "")
    compatible_versions = find_compatible_versions(versions, compat)
    if isempty(versions)
        color = :light_black
        compat = "not registered"
    elseif isempty(compatible_versions)
        color = :red
    elseif last(versions) ∉ compatible_versions
        color = :yellow
    else
        color = :green
    end
    return color
end

function update_compat_string!(menu)
    package = String(menu.mode)
    versions = menu.data.versions[package]
    compatible_versions = versions[sort(collect(menu.selected))]
    compat = compute_compat(versions, compatible_versions)
    if !isempty(compat)
        menu.data.compat[package] = compat
    else
        delete!(menu.data.compat, package)
    end
end
