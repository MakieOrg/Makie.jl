struct PlotDisplay <: AbstractDisplay end

abstract type AbstractBackend end
function backend_display end

"""
Currently available displays by backend
"""
const available_backends = AbstractBackend[]
const current_backend = Ref{Union{Missing,AbstractBackend}}(missing)
const use_display = Ref{Bool}(true)

function inline!(inline = true)
    use_display[] = !inline
end

function register_backend!(backend::AbstractBackend)
    push!(available_backends, backend)
    if(length(available_backends) == 1)
        current_backend[] = backend
    end
    nothing
end


const has_ffmpeg = Ref(false)

function __init__()
    pushdisplay(PlotDisplay())
    has_ffmpeg[] = try
        success(`ffmpeg -h`)
    catch
        false
    end
end

function Base.display(d::PlotDisplay, scene::Scene)
    use_display[] || throw(MethodError(display, (d, scene)))
    try
        return backend_display(current_backend[], scene)
    catch ex
        if ex isa MethodError && ex.f in (backend_display, backend_show)
            throw(MethodError(display, (d, scene)))
        else
            rethrow()
        end
    end
end

Base.showable(mime::MIME, scene::Scene) = backend_showable(current_backend[], mime, scene)
# ambig
Base.showable(mime::MIME"application/json", ::Scene) = backend_showable(current_backend[], mime, scene)

# have to be explicit with mimetypes to avoid ambiguity

function backend_show end
for M in (MIME"text/plain", MIME)
    @eval function Base.show(io::IO, m::$M, scene::Scene)
        res = get(io, :juno_plotsize, size(scene))
        resize!(scene, res...)
        update!(scene)
        return AbstractPlotting.backend_show(current_backend[], io, m, scene)
    end
end

function backend_showable(backend, m::MIME, scene::Scene)
    hasmethod(backend_show, Tuple{typeof(backend), IO, typeof(m), typeof(scene)})
end

# fallback show when no backend is selected
function backend_show(backend, io::IO, ::MIME"text/plain", scene::Scene)
    println(io, "Scene ($(size(scene, 1))px, $(size(scene, 2))px):")
    println(io, "events:")
    for field in fieldnames(Events)
        println(io, "    ", field, ": ", to_value(getfield(scene.events, field)))
    end
    println(io, "plots:")
    for plot in scene.plots
        println(io, "   *", typeof(plot))
    end
    print(io, "subscenes:")
    for subscene in scene.children
        print(io, "\n   *scene($(size(subscene, 1))px, $(size(subscene, 2))px)")
    end
    return
end

function backend_show(backend, io::IO, ::MIME"text/plain", plot::Combined)
    println(io, typeof(plot))
    println(io, "plots:")
    for p in plot.plots
        println(io, "   *", typeof(p))
    end
    print(io, "attributes:")
    for (k, v) in theme(plot)
        print(io, "\n  $k : $(typeof(v))")
    end
end

function Base.show(io::IO, ::MIME"text/plain", plot::Atomic)
    println(io, typeof(plot))
    print(io, "attributes:")
    for (k, v) in theme(plot)
        print(io, "\n  $k : $(typeof(to_value(v)))")
    end
end




# Stepper for generating progressive plot examples
mutable struct Stepper
    scene::Scene
    folder::String
    step::Int
end

function Stepper(scene, path)
    ispath(path) || mkpath(path)
    Stepper(scene, path, 1)
end

function FileIO.save(filename::String, scene::Scene)
    open(filename, "w") do s
        show(IOContext(s, :full_fidelity => true), MIME"image/png"(), scene)
    end
end
"""
    step!(s::Stepper)
steps through a `Makie.Stepper` and outputs a file with filename `filename-step.jpg`.
This is useful for generating progressive plot examples.
"""
function step!(s::Stepper)
    FileIO.save(joinpath(s.folder, basename(s.folder) * "-$(s.step).jpg"), s.scene)
    s.step += 1
    return s
end


"""
Record all window events that happen while executing function `f`
for `scene` and serializes them to `path`.
"""
function record_events(f, scene::Scene, path::String)
    display(scene)
    result = Vector{Pair{Float64, Pair{Symbol, Any}}}()
    for field in fieldnames(Events)
        on(getfield(scene.events, field)) do value
            value = isa(value, Set) ? copy(value) : value
            push!(result, time() => (field => value))
        end
    end
    f()
    open(path, "w") do io
        serialize(io, result)
    end
end


"""
Replays the serialized events recorded with `record_events` in `path` in `scene`.
"""
replay_events(scene::Scene, path::String) = replay_events(()-> nothing, scene, path)
function replay_events(f, scene::Scene, path::String)
    display(scene)
    events = open(io-> deserialize(io), path)
    sort!(events, by = first)
    for i in 1:length(events)
        t1, (field, value) = events[i]
        field == :mousedrag && continue
        if field == :mousebuttons
            Base.invokelatest() do
                getfield(scene.events, field)[] = value
            end
        else
            Base.invokelatest() do
                getfield(scene.events, field)[] = value
            end
        end
        f()
        yield()
        if i < length(events)
            t2, (field, value) = events[i + 1]
            # min sleep time 0.001
            (t2 - t1 > 0.001) && sleep(t2 - t1)
        end
    end
end

struct RecordEvents
    scene::Scene
    path::String
end

function Base.display(d::PlotDisplay, re::RecordEvents)
    display(d, re.scene)
end


struct VideoStream
    io
    process
    screen
    path::String
end


"""
    VideoStream(scene::Scene, dir = mktempdir(), name = "video")

returns a stream and a buffer that you can use to not allocate for new frames.
Use `add_frame!(stream, window, buffer)` to add new video frames to the stream.
Use `save(stream)` to save the video to 'dir/name.mkv'. You can also call
`save(stream, "mkv")`, `save(stream, "mp4")`, `save(stream, "gif")` or `save(stream, "webm")` to convert the stream to those formats.
"""
function VideoStream(scene::Scene)
    if !has_ffmpeg[]
        error("You can't create a video stream without ffmpeg installed.
         Please install ffmpeg, e.g. via https://ffmpeg.org/download.html.
         When you download the binaries, please make sure that you add the path to your PATH
         environment variable.
         On unix you can install ffmpeg with `sudo apt-get install ffmpeg`.
        ")
    end
    #codec = `-codec:v libvpx -quality good -cpu-used 0 -b:v 500k -qmin 10 -qmax 42 -maxrate 500k -bufsize 1000k -threads 8`
    dir = mktempdir()
    path = joinpath(dir, "$(gensym(:video)).mkv")
    screen = backend_display(current_backend[], scene)
    AbstractPlotting.update!(scene)
    _xdim, _ydim = widths(pixelarea(scene)[])
    xdim = _xdim % 2 == 0 ? _xdim : _xdim + 1
    ydim = _ydim % 2 == 0 ? _ydim : _ydim + 1
    process = open(`ffmpeg -loglevel quiet -f rawvideo -pixel_format rgb24 -r 24 -s:v $(xdim)x$(ydim) -i pipe:0 -vf vflip -y $path`, "w")
    VideoStream(process.in, process, screen, abspath(path))
end

function colorbuffer(x)
    error("colorbuffer not implemented for screen $(typeof(x))")
end

"""
Adds a video frame to the VideoStream
"""
function recordframe!(io::VideoStream)
    #codec = `-codec:v libvpx -quality good -cpu-used 0 -b:v 500k -qmin 10 -qmax 42 -maxrate 500k -bufsize 1000k -threads 8`
    frame = colorbuffer(io.screen)
    _xdim, _ydim = size(frame)
    xdim = _xdim % 2 == 0 ? _xdim : _xdim + 1
    ydim = _ydim % 2 == 0 ? _ydim : _ydim + 1
    frame_out = fill(RGB{N0f8}(1, 1, 1), ydim, xdim)
    for x in 1:_xdim, y in 1:_ydim
        c = frame[(_xdim + 1) - x, y]
        frame_out[y, x] = RGB{N0f8}(c)
    end
    write(io.io, frame_out)
    return
end

"""
    save(path::String, io::VideoStream)

Flushes the video stream and converts the file to the extension found in `path` which can
be `mkv` is default and doesn't need convert, `gif`, `mp4` and `webm`.
`mp4` is recommended for the internet, since it's the most supported format.
`webm` yields the smallest file size, `mp4` and `mk4` are marginally bigger and `gif`s are up to
6 times bigger with same quality!
"""
function save(path::String, io::VideoStream)
    close(io.process)
    wait(io.process)
    p, typ = splitext(path)
    if typ == ".mkv"
        cp(io.path, out)
    elseif typ == ".mp4"
        run(`ffmpeg -loglevel quiet -i $(io.path) -c:v libx264 -preset slow -crf 24 -pix_fmt yuv420p -c:a libvo_aacenc -b:a 128k -y $path`)
    elseif typ == ".webm"
        run(`ffmpeg -loglevel quiet -i $(io.path) -c:v libvpx-vp9 -threads 16 -b:v 2000k -c:a libvorbis -threads 16 -vf scale=iw:ih -y $path`)
    elseif typ == ".gif"
        filters = "fps=15,scale=iw:ih:flags=lanczos"
        palette_path = dirname(io.path)
        pname = joinpath(palette_path, "palette.bmp")
        isfile(pname) && rm(pname, force = true)
        run(`ffmpeg -loglevel quiet -i $(io.path) -vf "$filters,palettegen" -y $pname`)
        run(`ffmpeg -loglevel quiet -i $(io.path) -i $pname -lavfi "$filters [x]; [x][1:v] paletteuse" -y $path`)
        rm(pname, force = true)
    else
        rm(io.path)
        error("Video type $typ not known")
    end
    rm(io.path)
    return path
end


"""
    record(func, scene, path)
usage:
```example
    record(scene, "test.gif") do io
        for i = 1:100
            scene.plots[:color] = ...# animate scene
            recordframe!(io) # record a new frame
        end
    end
```
"""
function record(func, scene, path)
    io = VideoStream(scene)
    func(io)
    save(path, io)
end

"""
    record(func, scene, path, iter)
usage:
```example
    record(scene, "test.gif", 1:100) do i
        scene.plots[:color] = ...# animate scene
    end
```
"""
function record(func, scene, path, iter)
    io = VideoStream(scene)
    for i in iter
        t1 = time()
        func(i)
        recordframe!(io)
        diff = (1/24) - (time() - t1)
        if diff > 0.0
            sleep(diff)
        else
            yield()
        end
    end
    save(path, io)
end



function Base.show(io::IO, mime::MIME"text/html", vs::VideoStream)
    mktempdir() do dir
        path = finish(vs, joinpath(dir, "video.mp4"))
        print(
            io,
            """<video autoplay controls><source src="data:video/x-m4v;base64,""",
            base64encode(open(read, path)),
            """" type="video/mp4"></video>"""
        )
    end
end
