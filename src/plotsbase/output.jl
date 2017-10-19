import Hiccup, Media, Images, Juno, FileIO, ModernGL

function scene2image(screen::Screen)
    yield()
    render_frame(screen) # let it render
    ModernGL.glFinish()
    return GLWindow.screenbuffer(screen)
end
function scene2image(scene::Scene)
    screen = getscreen(scene)
    if screen != nothing
        return scene2image(screen)
    else
        return nothing
    end
end

Base.mimewritable(::MIME"image/png", scene::Scene) = true

function Base.show(io::IO, ::MIME"image/png", scene::Scene)
    img = scene2image(scene)
    if img != nothing
        png = map(RGB{N0f8}, img)
        FileIO.save(FileIO.Stream(FileIO.DataFormat{:PNG}, io), png)
    end
    return
end


function save(path::String, scene::Scene)
    img = scene2image(scene)
    if img != nothing
        FileIO.save(path, img)
    else
        error("Scene doesn't contain a plot!")
    end
end

Media.media(Scene, Media.Plot)

function Juno.render(e::Juno.Editor, plt::Scene)
    Juno.render(e, nothing)
end

const use_atom_plot_pane = Ref(false)
use_plot_pane(x::Bool = true) = (use_atom_plot_pane[] = x)

function Juno.render(pane::Juno.PlotPane, plt::Scene)
    if use_atom_plot_pane[]
        img = scene2image(plt)
        if img != nothing
            Juno.render(pane, HTML("<img src=\"data:image/png;base64,$(stringmime(MIME("image/png"), img))\">"))
        end
    end
end



immutable VideoStream
    io
    buffer
    screen::GLWindow.Screen
    path::String
end

"""
    VideoStream(scene::Scene, dir = mktempdir(), name = "video")

returns a stream and a buffer that you can use to not allocate for new frames.
Use `add_frame!(stream, window, buffer)` to add new video frames to the stream.
Use `finish(stream)` to save the video to 'dir/name.mkv'. You can also call
`finish(stream, "mkv")` or `finish(stream, "webm")` to convert the stream to those formats.
"""
function VideoStream(scene::Scene, dir = mktempdir(), name = "video")
    #codec = `-codec:v libvpx -quality good -cpu-used 0 -b:v 500k -qmin 10 -qmax 42 -maxrate 500k -bufsize 1000k -threads 8`
    path = joinpath(dir, "$name.mkv")
    screen = rootscreen(scene)
    if screen == nothing
        error("Scene doesn't contain any screen")
    end
    tex = GLWindow.framebuffer(screen).color
    res = size(tex)
    io, process = open(`ffmpeg -f rawvideo -pixel_format rgb24 -s:v $(res[1])x$(res[2]) -i pipe:0 -vf vflip -y $path`, "w")
    VideoStream(io, Matrix{RGB{N0f8}}(res), screen, abspath(path)) # tmp buffer
end

"""
Adds a video frame to the VideoStream
"""
function recordframe!(io::VideoStream)
    #codec = `-codec:v libvpx -quality good -cpu-used 0 -b:v 500k -qmin 10 -qmax 42 -maxrate 500k -bufsize 1000k -threads 8`
    render_frame(io.screen)
    tex = GLWindow.framebuffer(io.screen).color
    write(io.io, map(RGB{N0f8}, gpu_data(tex)))
    return
end

function finish(io::VideoStream, typ = "mkv")
    close(io.io)
    if typ == "mkv"
        return io.path
    elseif typ == "mp4"
        path = dirname(io.path)
        name, ext = splitext(basename(io.path))
        out = joinpath(path, name * ".mp4")
        run(`ffmpeg -i $(io.path) -vcodec copy -acodec copy $out`)
        rm(io.path)
        return out
    elseif typ == "webm"
        path = dirname(io.path)
        name, ext = splitext(basename(io.path))
        out = joinpath(path, name * ".webm")
        run(`ffmpeg -i $path -c:v libvpx-vp9 -threads 16 -b:v 2000k -c:a libvorbis -threads 16 -vf $out`)
        rm(io.path)
        return out
    else
        error("Video type $typ not known")
    end
end

Base.mimewritable(::MIME"image/png", scene::VideoStream) = true

function Base.show(io::IO, ::MIME"image/png", vs::VideoStream)
    path = finish(vs, "mp4")
    show(
        io,
        "text/html",
        string(
            """<video autoplay controls><source src="data:video/x-m4v;base64,""",
            base64encode(open(readbytes, path)),
            """" type="video/mp4"></video>"""
        )
    )
end


export VideoStream, recordframe!, finish

# mimewriteable to PNG if 2D colorant array

# if IJulia.inited
#     export set_ijulia_output
#
#     function set_ijulia_output(mimestr::AbstractString)
#         # info("Setting IJulia output format to $mimestr")
#         global _ijulia_output
#         _ijulia_output[1] = mimestr
#     end
#     function IJulia.display_dict(plt::Plot)
#         global _ijulia_output
#         Dict{String, String}(_ijulia_output[1] => sprint(show, _ijulia_output[1], plt))
#     end
#
#     # default text/plain passes to html... handles Interact issues
#     function Base.show(io::IO, m::MIME"text/plain", plt::Plot)
#         show(io, MIME("text/html"), plt)
#     end
#
#     ENV["MPLBACKEND"] = "Agg"
#     set_ijulia_output("text/html")
# end
