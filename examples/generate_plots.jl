include("library.jl")
cd(@__DIR__)

using Makie, GLFW, GeometryTypes, Reactive, FileIO
using GLVisualize, ColorBrewer, Colors
using GLVisualize: loadasset, assetpath


cd(Pkg.dir("Makie"))

sort!(database, by = (x)-> x.groupid)

index = start(database)

isdir("docs/media") || mkdir("docs/media")

while length(database) >= index
    uname = string(database[index].unique_name)
    str = sprint() do io
        global index
        index = print_code(io, database, index; scope_start = "", scope_end = "")
    end
    println(index)
    tmpmod = eval(:(module $(gensym(uname)); end))
    try
        result = eval(tmpmod, Expr(:call, :include_string, str, uname))
        if isa(result, String) && isfile(result)
            println("it's a path!")
            println(result)
        elseif isa(result, AbstractPlotting.Scene)
            println("it's a plot")
            Makie.save("docs/media/$uname.png", result)
        else
            warn("something went really badly with $index & $(typeof(result))")
        end
    catch e
        Base.showerror(STDERR, e)
    end
end
