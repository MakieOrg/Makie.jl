include("library.jl")
cd(@__DIR__)

using Makie, ImageTransformations, FileIO
using ImageFiltering  # needed for Gaussian-filtering images during resize

AbstractPlotting.set_theme!(resolution = (500, 500))

cd(Pkg.dir("Makie"))
isdir("docs/media") || mkdir("docs/media")

"""
    generate_thumbnail(path::AbstractString; sz::Int = 200)

Generates a (proportionally-scaled) thumbnail with maximum side dimension `sz`.
`sz` must be an integer, and the default value is 200 pixels.
"""
function generate_thumbnail(path::AbstractString; sz::Int = 200)
    !isfile(path) && warn("Input argument must be a file!")
    dir = dirname(path)
    origname = basename(path)
    thumbname = "thumb-$(origname)"
    img = Images.load(path)

    # calculate new image size `newsz`
    (height, width) = size(img)
    (scale_height, scale_width) = sz ./ (height, width)
    scale = min(scale_height, scale_width)
    newsz = round.(Int, (height, width) .* scale)

    # filter image + resize image
    gaussfactor = 0.4
    σ = map((o,n) -> gaussfactor*o/n, size(img), newsz)
    kern = KernelFactors.gaussian(σ)   # from ImageFiltering
    imgf = ImageFiltering.imfilter(img, kern, NA())
    newimg = ImageTransformations.imresize(imgf, newsz)

    # save image
    FileIO.save(joinpath(dir, thumbname), newimg)
end


"""
    get_video_duration(path::AbstractString)

Returns the duration of the video in seconds (Float32).
Accepted file types: mp4, mkv, and gif.

Requires `ffprobe` (usually comes installed with `ffmpeg`).

Note that while this accepts gif, it will not work to get duration of the gif
(`ffprobe` doesn't support that), so it will just fallback to return 0.5 sec.
"""
function get_video_duration(path::AbstractString)
    !isfile(path) && error("input is not a file!")
    accepted_exts = ("mp4", "gif", "mkv")
    filename = basename(path)
    !(split(filename, ".")[2] in accepted_exts) && error("accepted file types are mp4 and gif!")
    try
        dur = readstring(`ffprobe -loglevel quiet -print_format compact=print_section=0:nokey=1:escape=csv -show_entries format=duration -i "$(path)"`)
        dur = parse(Float32, dur)
    catch e
        warn("`get_video_duration` on $filename did not work, using fallback video duration of 0.5 seconds")
        dur = 0.5
    end
end


function record_examples(tags...)
    examples = sort(database, by = (x)-> x.groupid)
    if !isempty(tags)
        filter!(examples) do entry
            all(x-> String(x) in entry.tags, tags)
        end
    end
    index = start(examples)
    dblen = length(examples)
    thumbnail_size = 150
    while dblen >= index
        # use the unique_name of the database entry as filename
        uname = string(examples[index].unique_name)
        println(examples[index].title)
        str = sprint() do io
            # declare global index so it can be modified by the function inside loop
            index = print_code(io, examples, index; scope_start = "", scope_end = "")
        end
        # sandbox the string in a module
        tmpmod = eval(:(module $(gensym(uname)); end))
        # eval the sandboxed module using include_string
        try
            result = eval(tmpmod, Expr(:call, :include_string, str, uname))
            if isa(result, String) && isfile(result)
                try
                    # TODO: currently exporting video thumbnails as .jpg because of ImageMagick issue#120
                    # seek to the middle of the video and grab a frame
                    seektime = (get_video_duration(result))/2
                    run(`ffmpeg -loglevel quiet -ss $seektime -i $result -vframes 1 -vf "scale=$(thumbnail_size):-2" -y -f image2 "./docs/media/thumb-$(uname).jpg"`)
                catch err
                    Base.showerror(STDERR, err)
                end
            elseif isa(result, AbstractPlotting.Scene)
                Makie.save("docs/media/$uname.png", result)
                generate_thumbnail("docs/media/$uname.png"; sz = thumbnail_size)
            else
                warn("something went really badly with index $index & $(typeof(result))")
            end
        catch e
            Base.showerror(STDERR, e)
            println(STDERR)
            Base.show_backtrace(STDERR, Base.catch_backtrace())
            println(STDERR)
            println(str)
        end
    end
end
record_examples()
