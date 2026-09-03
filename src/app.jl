function (@main)(ARGS)
    empty!(LOAD_PATH)
    push!(LOAD_PATH, pwd())
    compat_ui(pagesize = 40)
end
