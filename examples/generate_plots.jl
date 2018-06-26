include("library.jl")
cd(@__DIR__)

using Makie, ImageTransformations, FileIO
using ImageFiltering  # needed for Gaussian-filtering images during resize


"""
    generate_thumbnail(path::AbstractString; sz::Int = 200)

Generates a (proportionally-scaled) thumbnail with maximum side dimension `sz`.
`sz` must be an integer, and the default value is 200 pixels.
"""
function generate_thumbnail(path::AbstractString, thumb_path::AbstractString; sz::Int = 200)
    !isfile(path) && warn("Input argument must be a file!")
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
    FileIO.save(thumb_path, newimg)
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


function record_examples(path, tags...; thumbnails = true, thumbnail_size = 128)
    eval_examples(tags...) do entry, result
        uname = entry.unique_name
        full_path = joinpath(path, "$(uname)")
        thumb_path = joinpath(path, "thumb-$(uname).jpg")
        info("Recording example: $(entry.title)")
        if isa(result, String) && isfile(result)
            # TODO: currently exporting video thumbnails as .jpg because of ImageMagick issue#120
            # seek to the middle of the video and grab a frame
            if abspath(result) != abspath(full_path * ".mp4")
                cp(result, full_path * ".mp4")
            end
            seektime = get_video_duration(result) / 2
            if thumbnails
                run(`ffmpeg -loglevel quiet -ss $seektime -i $result -vframes 1 -vf "scale=$(thumbnail_size):-2" -y -f image2 $thumb_path`)
            end
        elseif isa(result, Scene)
            Makie.save(full_path * ".jpg", result)
            thumbnails && generate_thumbnail(full_path * ".jpg", thumb_path; sz = thumbnail_size)
        else
            warn("Unsupported return type with example $(entry.title) and $(typeof(result))")
        end
    end
end

AbstractPlotting.set_theme!(resolution = (500, 500))
cd(Pkg.dir("Makie"))
isdir("docs/media") || mkdir("docs/media")
record_examples("docs/media", thumbnails = true)
