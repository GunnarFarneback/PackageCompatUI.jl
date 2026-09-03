function (@main)(ARGS)
    empty!(LOAD_PATH)
    push!(LOAD_PATH, pwd())
    if isnothing(Base.active_project())
        println("Error: No `Project.toml` or `JuliaProject.toml` found.")
    else
        compat_ui(pagesize = 40)
    end
end
