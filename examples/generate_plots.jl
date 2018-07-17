include("library.jl")
cd(@__DIR__)


function record_examples(path, tags...; thumbnails = true, thumbnail_size = 128)
    eval_examples(tags...) do entry, result
        uname = entry.unique_name
        full_path = joinpath(path, "$(uname)")
        thumb_path = joinpath(path, "thumb-$(uname).jpg")
        info("Recording example: $(entry.title)")
        if isa(result, String) && isfile(result)
            # TODO: currently exporting video thumbnails as .jpg because of ImageMagick issue#120
            # seek to the middle of the video and grab a frame
            cp(result, full_path * "mp4")
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
record_examples("docs/media", :heatmap, thumbnails = true)
