import Hiccup, Media, Images, Juno, FileIO, ModernGL, Interact
import FileIO: save

function scene2image(screen::Screen)
    GLWindow.poll_glfw()
    yield()
    render_frame(screen) # let it render
    ModernGL.glFinish()
    return Images.clamp01nan.(GLWindow.screenbuffer(screen))
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

function Base.show(io::IO, mime::MIME"image/png", scene::Makie.Scene)
    s = to_signal(lift_node(scene, :entered_window) do value
        scene2image(scene)
    end)
    display(s)
end

function save(path::String, scene::Scene)
    img = scene2image(scene)
    if img != nothing
        save(path, img)
    else
        error("Scene doesn't contain a plot!")
    end
end

Media.media(Scene, Media.Plot)

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
    framerate::Int
end

"""
    VideoStream(scene::Scene, dir = mktempdir(), name = "video")

returns a stream and a buffer that you can use to not allocate for new frames.
Use `add_frame!(stream, window, buffer)` to add new video frames to the stream.
Use `finish(stream)` to save the video to 'dir/name.mkv'. You can also call
`finish(stream, "mkv")`, `finish(stream, "mp4")`, `finish(stream, "gif")` or `finish(stream, "webm")` to convert the stream to those formats.
"""
function VideoStream(scene::Scene, path, framerate = 30)
    #codec = `-codec:v libvpx -quality good -cpu-used 0 -b:v 500k -qmin 10 -qmax 42 -maxrate 500k -bufsize 1000k -threads 8`
    path = "$path.mkv"
    screen = rootscreen(scene)
    if screen == nothing
        error("Scene doesn't contain any screen")
    end
    tex = GLWindow.framebuffer(screen).color
    res = size(tex)
    io, process = open(`ffmpeg -loglevel panic -f rawvideo -pixel_format rgb24 -s:v $(res[1])x$(res[2]) -r $framerate -i pipe:0 -vf vflip -y $path`, "w")
    VideoStream(io, Matrix{RGB{N0f8}}(res), screen, abspath(path), framerate) # tmp buffer
end

"""
Adds a video frame to the VideoStream
"""
function recordframe!(io::VideoStream)
    #codec = `-codec:v libvpx -quality good -cpu-used 0 -b:v 500k -qmin 10 -qmax 42 -maxrate 500k -bufsize 1000k -threads 8`
    GLWindow.poll_glfw()
    yield()
    render_frame(io.screen) # let it render
    ModernGL.glFinish()
    tex = GLWindow.framebuffer(io.screen).color
    write(io.io, map(RGB{N0f8}, gpu_data(tex)))
    return
end

"""
    finish(io::VideoStream, typ = "mkv"; remove_mkv = true)

Flushes the video stream and optionally converts the file to `typ` which can
be (`mkv` is default and doesn't need convert) gif, mp4 and webm.
If you want to convert the original mkv to multiple formats you should choose
`remove_mkv = false`, and remove it manually after you're done (with `rm(videostream.path)`)
webm yields the smallest file size, mp4 and mk4 are marginally bigger and gifs are up to
6 times bigger!
"""
function finish(io::VideoStream, typ = "mkv"; remove_mkv = true)
    close(io.io)
    path = dirname(io.path)
    typ == "mkv" && return io.path
    name, ext = splitext(basename(io.path))
    path = dirname(io.path)
    out = joinpath(path, name * ".$typ")

    if typ == "mp4"
        run(`ffmpeg -loglevel quiet -i $(io.path) -pix_fmt yuv420p -vcodec copy -acodec copy -y $out`)
        remove_mkv && rm(io.path)
        return out
    elseif typ == "webm"
        run(`ffmpeg -loglevel quiet -i $(io.path) -c:v libvpx-vp9 -threads 16 -b:v 2000k -c:a libvorbis -threads 16 -vf scale=iw:ih -y $out`)
        remove_mkv && rm(io.path)
        return out
    elseif typ == "gif"
        palette_path = mktempdir()
        pname = joinpath(palette_path, "palette.png")
        filters = "fps=15,scale=iw:ih:flags=lanczos"
        run(`ffmpeg -loglevel quiet -v warning -i $(io.path) -vf "$filters,palettegen" -y $pname`)
        run(`ffmpeg -loglevel quiet -v warning -i $(io.path) -i $pname -lavfi "$filters [x]; [x][1:v] paletteuse" -y $out`)
        remove_mkv && rm(io.path)
        return out
    else
        error("Video type $typ not known")
    end
end

Base.mimewritable(::MIME"text/html", scene::VideoStream) = true

function Base.show(io::IO, mime::MIME"text/html", vs::VideoStream)
    path = finish(vs, "mp4")
    html = """
        <video width="100%" autoplay controls="false">
            <source src="$path" type="video/mp4">
            Your browser does not support the video tag. Please use a modern browser like Chrome or Firefox.
        </video>
    """
    display(
        Main.IJulia.InlineDisplay(),
        mime,
        string(
            """<video autoplay controls><source src="data:video/x-m4v;base64,""",
            base64encode(open(read, path)),"""" type="video/mp4"></video>"""
        )
    )
end

export VideoAnnotation, recordstep!

function VideoAnnotation(scene::Scene, file, annotation = "")
    t = text(
        scene, annotation,
        position = (10, 10), align = (:left, :bottom),
        camera = :pixel
    )
    io = VideoStream(scene, dirname(file), basename(file))
    (io, t)
end

function recordstep!(video_io, annotation::String = "", time = 2) # time in seconds
    io, text = video_io
    text[:text] = annotation
    yield()
    for i = 1:round(time * io.framerate)
        recordframe!(io)
    end
    video_io
end


# function Base.show(io::IO, mime::MIME"text/html", vs::VideoStream)
#     path = "file/" * finish(vs, "mp4")
#     html = """
#         <video width="100%" autoplay controls="false">
#             <source src="%path" type="video/mp4">
#             Your browser does not support the video tag. Please use a modern browser like Chrome or Firefox.
#         </video>
#     """
#     display(
#         Main.IJulia.InlineDisplay(),
#         mime,
#         html
#     )
# end


export VideoStream, recordframe!, finish


#
# function to_gif()
#     ffmpeg -y -i ijulia.ogv -vf fps=20, scale=320:-1:flags=lanczos,palettegen palette.png
#     ffmpeg -v warning -i ijulia.ogv -vf scale=300:-1 -gifflags +transdiff -y bbb-trans.gif
#
