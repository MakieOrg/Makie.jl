include("library.jl")
cd(@__DIR__)

using Makie, GLFW, GeometryTypes, Reactive, FileIO
using GLVisualize, ColorBrewer, Colors
using GLVisualize: loadasset, assetpath

function unique_name!(name, defined)
    funcname = Symbol(replace(lowercase(name), r"[ #$!@#$%^&*()+]", '_'))
    i = 1
    while isdefined(Main, funcname) || (funcname in defined)
        funcname = Symbol("$(funcname)_$i")
        i += 1
    end
    push!(defined, funcname)
    funcname
end


open("../test/visual_regression_funcs.jl", "w") do io
    last_setup = first(database).setup
    println(io, last_setup)
    defined = Set(Symbol[])
    for (i, entry) in enumerate(database)
        if entry.setup != last_setup
            last_setup = entry.setup
            println(io, last_setup)
        end
        funcname = unique_name!(entry.title, defined)
        println(io, "function $(funcname)()")
        for line in split(entry.source, "\n")
            println(io, " "^4, line)
        end
        println(io, "end")
    end
end
