function register_backend!(backend)
    @warn("`register_backend!` is an internal deprecated function, which shouldn't be used outside Makie.
    if you must really use this function, it's now `set_active_backend!(::Module)")
end

function backend_display(args...)
    @warn("`backend_display` is an internal deprecated function, which shouldn't be used outside Makie.
    if you must really use this function, it's now just `display(::Backend.Screen, figlike)`")
end
