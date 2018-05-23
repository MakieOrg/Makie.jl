if VERSION >= v"0.7-"
    const jl_finalizer = finalizer
else
    const jl_finalizer = (f, x) -> finalizer(x, f)
end
