include("library.jl")
cd(@__DIR__)

using Makie, GLFW, GeometryTypes, Reactive, FileIO

cd(Pkg.dir("Makie"))
isdir("docs/media") || mkdir("docs/media")

sort!(database, by = (x)-> x.groupid)

index = start(database)
dblen = length(database)
while dblen - 1 >= index
    # use the unique_name of the database entry as filename
    uname = string(database[index].unique_name)
    info("Working on index: $index, uname: $uname")
    str = sprint() do io
        # declare global index so it can be modified by the function inside loop
        global index
        index = print_code(io, database, index; scope_start = "", scope_end = "")
    end
    # sandbox the string in a module
    tmpmod = eval(:(module $(gensym(uname)); end))
    # eval the sandboxed module using include_string
    try
        result = eval(tmpmod, Expr(:call, :include_string, str, uname))
        if isa(result, String) && isfile(result)
            info("it's a path! -- video")
            info("path is: $result")
        elseif isa(result, AbstractPlotting.Scene)
            info("it's a plot")
            Makie.save("docs/media/$uname.png", result)
            generate_thumbnail("docs/media/$uname.png"; sz = 200)
        else
            warn("something went really badly with index $index & $(typeof(result))")
        end
    catch e
        Base.showerror(STDERR, e)
    end
end
