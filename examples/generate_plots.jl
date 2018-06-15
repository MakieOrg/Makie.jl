include("library.jl")
cd(@__DIR__)

using Makie

cd(Pkg.dir("Makie"))
isdir("docs/media") || mkdir("docs/media")

sort!(database, by = (x)-> x.groupid)

index = start(database)
dblen = length(database)
thumbnail_size = 150
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
            info("generating video thumbnail")
            try
                # TODO: currently exporting video thumbnails as .jpg because of ImageMagick issue#120
                run(`ffmpeg -ss 0.1 -i $result -vframes 1 -vf "scale=$(thumbnail_size):-2" -f image2 "./docs/media/thumb-$(uname).jpg"`)
            catch err
                Base.showerror(STDERR, err)
            end
        elseif isa(result, AbstractPlotting.Scene)
            info("it's a plot")
            Makie.save("docs/media/$uname.png", result)
            generate_thumbnail("docs/media/$uname.png"; sz = thumbnail_size)
        else
            warn("something went really badly with index $index & $(typeof(result))")
        end
    catch e
        Base.showerror(STDERR, e)
        println(str)
    end
end
