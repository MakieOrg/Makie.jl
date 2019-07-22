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
    if !(backend in available_backends)
        push!(available_backends, backend)
    end
    # only set as the current backend if it's the only one
    if(length(available_backends) == 1)
        current_backend[] = backend
    end
    nothing
end

function push_screen!(scene::Scene, display::AbstractDisplay)
    push!(scene.current_screens, display)
    on(events(scene).window_open) do is_open
        # when screen closes, it should set the scene isopen event to false
        # so that's when we can remove the display
        if !is_open
            filter!(x-> x !== display, scene.current_screens)
        end
    end
end

function Base.display(d::PlotDisplay, scene::Scene)
    # set update to true, without triggering an event
    # this just indicates, that now we may update on e.g. resize
    use_display[] || throw(MethodError(display, (d, scene)))
    try
        update!(scene)
        screen = backend_display(current_backend[], scene)
        push_screen!(scene, screen)
        return screen
    catch ex
        if ex isa MethodError && ex.f in (backend_display, backend_show)
            throw(MethodError(display, (d, scene)))
        else
            rethrow()
        end
    end
end

function Base.showable(mime::MIME{M}, scene::Scene) where M
    # If we use a display, we are not able to show via mimes!
    use_display[] && return false
    backend_showable(current_backend[], mime, scene)
end
# ambig
function Base.showable(mime::MIME"application/json", scene::Scene)
    use_display[] && return false
    backend_showable(current_backend[], mime, scene)
end

# have to be explicit with mimetypes to avoid ambiguity

function backend_show end

for M in (MIME"text/plain", MIME)
    @eval function Base.show(io::IO, m::$M, scene::Scene)
        # set update to true, without triggering an event
        # this just indicates, that now we may update on e.g. resize
        update!(scene)
        res = get(io, :juno_plotsize, nothing)
        res !== nothing && resize!(scene, res...)
        screen = backend_show(current_backend[], io, m, scene)

        # E.g. text/plain doesn't have a display
        screen isa AbstractScreen && push_screen!(scene, screen)
        return screen
    end
end

function backend_showable(backend, m::MIME, scene::Scene)
    hasmethod(backend_show, Tuple{typeof(backend), IO, typeof(m), typeof(scene)})
end

function has_juno_plotpane()
    if isdefined(Main, :Atom)
        return Main.Atom.PlotPaneEnabled[]
    else
        return nothing
    end
end
# fallback show when no backend is selected
function backend_show(backend, io::IO, ::MIME"text/plain", scene::Scene)
    if isempty(available_backends)
        @warn """Printing Scene as text. You see this because you haven't loaded any backend (GLMakie, CairoMakie, WGLMakie),
        or you loaded GLMakie, but it didn't build correctly. In the latter case,
        try `]build GLMakie` and watch out for any warnings.
        """
    end
    if !use_display[] && !isempty(available_backends)
        plotpane = has_juno_plotpane()
        if plotpane !== nothing && !plotpane
            # we want to display as inline!, we are in Juno, but the plotpane is disabled
            @warn """Showing scene as inline with Plotpane disabled. This happens because `AbstractPlotting.inline!(true)` is set,
            while `Atom.PlotPaneEnabled[]` is false. Either enable the plotpane, or set inline to false!"""
        else
            if plotpane === nothing || !plotpane
                @warn """Showing scene as text. This happens because `AbstractPlotting.inline!(true)` is set.
                This needs to be false to show a plot in a window when in the REPL."""
            end
        end
    end
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

function Base.show(io::IO, plot::Combined)
    println(io, typeof(plot))
    println(io, "plots:")
    for p in plot.plots
        println(io, "   *", typeof(p))
    end
    print(io, "attributes:")
    for (k, v) in theme(plot)
        print(io, "\n  $k : $(typeof(to_value(v)))")
    end
end

function Base.show(io::IO, plot::Atomic)
    println(io, typeof(plot))
    print(io, "attributes:")
    for (k, v) in theme(plot)
        print(io, "\n  $k : $(typeof(to_value(v)))")
    end
end



"""
Stepper for generating progressive plot examples.
"""
mutable struct Stepper
    scene::Scene
    folder::String
    step::Int
end

function Stepper(scene, path)
    ispath(path) || mkpath(path)
    Stepper(scene, path, 1)
end

format2mime(::Type{FileIO.format"PNG"}) = MIME"image/png"()
format2mime(::Type{FileIO.format"SVG"}) = MIME"image/svg+xml"()
format2mime(::Type{FileIO.format"JPEG"}) = MIME"image/jpeg"()

# Allow format to be overridden with first argument
"""
    FileIO.save(filename, scene; resolution = size(scene))

Saves a `Scene` to file!
Allowable formats depend on the backend;
- `GLMakie` allows `.png`, `.jpeg`, and `.bmp`.
- `CairoMakie` allows `.svg`, `pdf`, and `.jpeg`.
- `WGLMakie` allows `.png`.
Resolution can be specified, via `save("path", scene, resolution = (1000, 1000))`!
"""
function FileIO.save(
        f::FileIO.File{F}, scene::Scene;
        resolution = size(scene)
    ) where F

    resolution !== size(scene) && resize!(scene, resolution)
    open(FileIO.filename(f), "w") do s
        show(IOContext(s, :full_fidelity => true), format2mime(F), scene)
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
    record_events(f, scene::Scene, path::String)

Records all window events that happen while executing function `f`
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
    replay_events(f, scene::Scene, path::String)
    replay_events(scene::Scene, path::String)

Replays the serialized events recorded with `record_events` in `path` in `scene`.
"""
replay_events(scene::Scene, path::String) = replay_events(()-> nothing, scene, path)
function replay_events(f, scene::Scene, path::String)
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
        if i < length(events)
            t2, (field, value) = events[i + 1]
            # min sleep time 0.001
            if (t2 - t1 > 0.001)
                sleep(t2 - t1)
            else
                yield()
            end
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
    VideoStream(scene::Scene, framerate = 24)

Returns a stream and a buffer that you can use, which don't allocate for new frames.
Use [`recordframe!(stream)`](@ref) to add new video frames to the stream, and
[`save(path, stream)`](@ref) to save the video.
"""
function VideoStream(
        scene::Scene; framerate::Integer = 24
    )
    #codec = `-codec:v libvpx -quality good -cpu-used 0 -b:v 500k -qmin 10 -qmax 42 -maxrate 500k -bufsize 1000k -threads 8`
    dir = mktempdir()
    path = joinpath(dir, "$(gensym(:video)).mkv")
    update!(scene)
    screen = backend_display(current_backend[], scene)
    push_screen!(scene, screen)
    _xdim, _ydim = size(scene)
    xdim = _xdim % 2 == 0 ? _xdim : _xdim + 1
    ydim = _ydim % 2 == 0 ? _ydim : _ydim + 1
    process = @ffmpeg_env open(`$ffmpeg -loglevel quiet -f rawvideo -pixel_format rgb24 -r $framerate -s:v $(xdim)x$(ydim) -i pipe:0 -vf vflip -y $path`, "w")
    VideoStream(process.in, process, screen, abspath(path))
end

function colorbuffer(x)
    error("colorbuffer not implemented for screen $(typeof(x))")
end

"""
    recordframe!(io::VideoStream)

Adds a video frame to the VideoStream `io`.
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
    save(path::String, io::VideoStream; framerate = 24)

Flushes the video stream and converts the file to the extension found in `path`,
which can be one of the following:
- `.mkv`  (the default, doesn't need to convert)
- `.mp4`  (good for Web, most supported format)
- `.webm` (smallest file size)
- `.gif`  (largest file size for the same quality)

`.mp4` and `.mk4` are marginally bigger and `.gif`s are up to
6 times bigger with the same quality!

See the docs of [`VideoStream`](@ref) for how to create a VideoStream.
If you want a simpler interface, consider using [`record`](@ref).

"""
function save(path::String, io::VideoStream;
              framerate::Int = 24)
    close(io.process)
    wait(io.process)
    p, typ = splitext(path)
    if typ == ".mkv"
        cp(io.path, path, force=true)
    elseif typ == ".mp4"
        ffmpeg_exe(`-loglevel quiet -i $(io.path) -c:v libx264 -preset slow -r $framerate -pix_fmt yuv420p -c:a libvo_aacenc -b:a 128k -y $path`)
    elseif typ == ".webm"
        ffmpeg_exe(`-loglevel quiet -i $(io.path) -c:v libvpx-vp9 -threads 16 -b:v 2000k -c:a libvorbis -threads 16 -r $framerate -vf scale=iw:ih -y $path`)
    elseif typ == ".gif"
        filters = "fps=$framerate,scale=iw:ih:flags=lanczos"
        palette_path = dirname(io.path)
        pname = joinpath(palette_path, "palette.bmp")
        isfile(pname) && rm(pname, force = true)
        ffmpeg_exe(`-loglevel quiet -i $(io.path) -vf "$filters,palettegen" -y $pname`)
        ffmpeg_exe(`-loglevel quiet -i $(io.path) -i $pname -lavfi "$filters [x]; [x][1:v] paletteuse" -y $path`)
        rm(pname, force = true)
    else
        rm(io.path)
        error("Video type $typ not known")
    end
    rm(io.path)
    return path
end


"""
    record(func, scene, path; framerate = 24)
    record(func, scene, path, iter; framerate = 24)

Records the Scene `scene` after the application of `func` on it for each element
in `itr` (any iterator).  `func` must accept an element of `itr`.

The animation is then saved to `path`, with the format determined by `path`'s
extension.  Allowable extensions are:
- `.mkv`  (the default, doesn't need to convert)
- `.mp4`  (good for Web, most supported format)
- `.webm` (smallest file size)
- `.gif`  (largest file size for the same quality)

`.mp4` and `.mk4` are marginally bigger and `.gif`s are up to
6 times bigger with the same quality!

Typical usage patterns would look like:

```julia
record(scene, "video.mp4", itr) do i
    func(i) # or some other manipulation of the Scene
end
```

or, for more tweakability,

```julia
record(scene, "test.gif") do io
    for i = 1:100
        func!(scene)     # animate scene
        recordframe!(io) # record a new frame
    end
end
```

If you want a more tweakable interface, consider using [`VideoStream`](@ref) and
[`save`](@ref).

## Examples

```julia
scene = lines(rand(10))
record(scene, "test.gif") do io
    for i in 1:255
        scene.plots[:color] = Colors.RGB(i/255, (255 - i)/255, 0) # animate scene
        recordframe!(io)
    end
end
```
or
```julia
scene = lines(rand(10))
record(scene, "test.gif", 1:255) do i
    scene.plots[:color] = Colors.RGB(i/255, (255 - i)/255, 0) # animate scene
end
```
"""
function record(func, scene, path; framerate::Int = 24)
    io = VideoStream(scene; framerate = framerate)
    func(io)
    save(path, io; framerate = framerate)
end

"""
    record(func, scene, path, iter; framerate = 24)

This is simply a shorthand to wrap a for loop in `record`.

Example:

```example
    scene = lines(rand(10))
    record(scene, "test.gif", 1:100) do i
        scene.plots[:color] = Colors.RGB(i/255, 0, 0) # animate scene
    end
```
"""
function record(func, scene, path, iter; framerate::Int = 24)
    io = VideoStream(scene; framerate = framerate)
    for i in iter
        t1 = time()
        func(i)
        recordframe!(io)
        diff = (1/framerate) - (time() - t1)
        if diff > 0.0
            sleep(diff)
        else
            yield()
        end
    end
    save(path, io, framerate = framerate)
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
