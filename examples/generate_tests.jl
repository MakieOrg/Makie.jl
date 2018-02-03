include("library.jl")
cd(@__DIR__)

using Makie, GLFW, GeometryTypes, Reactive, FileIO
using GLVisualize, ColorBrewer, Colors
using GLVisualize: loadasset, assetpath

open("function_form.jl", "w") do io
    sort!(database, by = (x)-> x.groupid)
    i = start(database)
    while length(database) >= i
        entry = database[i]
        fname = entry.unique_name
        i = print_code(io, database, i, "function $fname()")
    end
end

open("global_form.jl", "w") do io
    sort!(database, by = (x)-> x.groupid)
    i = start(database)
    while length(database) >= i
        i = print_code(io, database, i)
    end
end

include("global_form.jl")
for entry in database
    f = getfield(Main, entry.unique_name)
    f()
end

0.5 in (0.0..2.0)
