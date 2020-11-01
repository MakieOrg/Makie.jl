"""
Embedds all produced media in one big html file
"""
function generate_preview(media_root, path=joinpath(@__DIR__, "preview.html"))
    open(path, "w") do io
        for folder in readdir(media_root)
            media = joinpath(media_root, folder, "media")
            if !isfile(media) && ispath(media)
                medias = joinpath.(media, readdir(media))
                println(io, "<h1> $folder </h1>")
                embed_media(io, medias)
            end
        end
    end
end

function tourl(path)
    if Sys.iswindows()
        # There might be a nicer way?
        # Anyways, this seems to be needed on windows
        if !startswith(path, "http")
            path = "file:///" * replace(path, "\\" => "/")
        end
    end
    return repr(path)
end

# NOTE: `save_media` is the function you want to overload
# if you want to create a Gallery with custom types.
# Simply overloading the function should do the trick
# and ReferenceTests will take care of the rest.

function save_media(entry, x::Scene, path::String)
    path = joinpath(path, "image.png")
    save(FileIO.File(DataFormat{:PNG}, path), x) # work around FileIO bug for now
    [path]
end

function save_media(entry, x::String, path::String)
    out = joinpath(path, basename(x))
    if out != x
        mv(x, out, force = true)
    end
    [out]
end

function save_media(entry, x::AbstractPlotting.Stepper, path::String)
    # return a list of all file names
    images = filter(x-> endswith(x, ".png"), readdir(x.folder))
    return map(images) do img
        p = joinpath(x.folder, img)
        out = joinpath(path, basename(p))
        mv(p, out, force = true)
        out
    end
end

function save_media(entry, results::AbstractVector, path::String)
    paths = String[]
    for (i, res) in enumerate(results)
        # Only save supported results
        if res isa Union{Scene, String}
            img = joinpath(path, "image$i.png")
            save(FileIO.File(DataFormat{:PNG}, img), res) # work around FileIO
            push!(paths, img)
        end
    end
    paths
end

function save_media(example, events::RecordEvents, path::String)
    # the path is fixed at record time to be stored relative to the example
    epath = event_path(example, "")
    isfile(epath) || error("Can't find events for example: $(example.unique_name). Please run `record_example_events()`")
    # the current path of RecordEvents is where we now actually want to store the video
    video_path = joinpath(path, "video.mp4")
    record(events.scene, video_path) do io
        replay_events(events.scene, epath) do
            recordframe!(io)
        end
    end
    return [video_path]
end

"""
    embed_image(path::AbstractString)
Returns the html to embed an image
"""
function embed_image(path::AbstractString, alt = "")
    if splitext(path)[2] == "pdf"
        return """
            <iframe src=$(tourl(path))></iframe>
        """
    end
    """
    <img src=$(tourl(path)) alt=$(repr(alt))>
    """
end

"""
    embed_video(path::AbstractString)

Generates a html formatted string for embedding video into Documenter Markdown files
(since `Documenter.jl` doesn't support directly embedding mp4's using ![]() syntax).
"""
function embed_video(path::AbstractString, alt = "")
    """
    <video controls autoplay loop muted>
      <source src=$(tourl(path)) type="video/mp4">
      Your browser does not support mp4. Please use a modern browser like Chrome or Firefox.
    </video>
    """
end

"""
Embeds the most common media types as html
"""
function embed_media(path::String, alt = "")
    file, ext = splitext(path)
    if ext in (".png", ".jpg", ".jpeg", ".JPEG", ".JPG", ".gif", ".pdf", ".svg")
        return embed_image(path, alt)
    elseif ext == ".mp4"
        return embed_video(path, alt)
    else
        error("Unknown media extension: $ext with path: $path")
    end
end


"""
Embeds a vector of media files as HTML
"""
function embed_media(io::IO, paths::AbstractVector{<: AbstractString}, caption = "")
    for (i, path) in enumerate(paths)
        occursin("thumb", path) && continue
        println(io, """
        <div style="display:inline-block">
            <p style="display:inline-block; text-align: center">
                $(embed_media(path, caption))
            </p>
        </div>
        """)
    end
end
