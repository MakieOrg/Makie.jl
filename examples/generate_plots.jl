include("library.jl")
cd(@__DIR__)

using Makie, GLFW, GeometryTypes, Reactive, FileIO
using GLVisualize, ColorBrewer, Colors
using GLVisualize: loadasset, assetpath

open("plot_me.jl", "w") do io
# stuff removed -> don't need to make a new file
end

cd(Pkg.dir("Makie"))
sort!(database, by = (x)-> x.groupid)
isladjfk = start(database)
while length(database) >= isladjfk
    uname = string(database[isladjfk].unique_name)
    str = sprint() do io
        global isladjfk
        isladjfk = print_code(io, database, isladjfk; scope_start = "let\n")
        # println(io, "Makie.save(\"$uname.png\"), scene")
    end
    println(isladjfk)
    # println(str)
    tmpmod = eval(:(module $(gensym(uname)); end))
    try
        result = eval(tmpmod, Expr(:call, :include_string, str, uname))
        if isa(result, String) && isfile(result)
            println(STDOUT, "it's a path!")
            println(STDOUT, result)
            # mv(path, joinpath(pwd(), basename(path)))
        elseif isa(result, AbstractPlotting.Scene)
            println(STDOUT, "it's a plot")
            Makie.save("$uname.png", result)
        else
            warn("something went really badly with $isladjfk")
        end
    end
end
