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

        # Here, we deal with the Juno plotsize.
        # Since SVGs are in units of pt, which is 1/72 in,
        # and pixels (which Juno reports its plotsize as)
        # are 1/96 in, we need to rescale the scene,
        # whose units are in pt, into the expected size in px.
        # This means we have to scale by a factor of 72/96.
        res = get(io, :juno_plotsize, nothing)
        if !isnothing(res)
            if m isa MIME"image/svg+xml"
                res = round.(Int, res .* 0.75)
            end
            resize!(scene, res...)
        end

        ioc = IOContext(io, :full_fidelity => true, :pt_per_unit => get(io, :pt_per_unit, 1.0), :px_per_unit => get(io, :px_per_unit, 1.0))

        screen = backend_show(current_backend[], ioc, m, scene)

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

isijulia() = isdefined(Main, :IJulia) && isdefined(Main.IJulia, :clear_output)
isvscode() = isdefined(Main, :VSCodeServer)

# fallback show when no backend is selected
function backend_show(backend, io::IO, ::MIME"text/plain", scene::Scene)
    if isempty(available_backends)
        @warn """Printing Scene as text. You see this because you haven't loaded any backend (GLMakie, CairoMakie, WGLMakie),
        or you loaded GLMakie, but it didn't build correctly. In the latter case,
        try `]build GLMakie` and watch out for any warnings.
        """
    end
    if !use_display[] && isvscode()
        # do nothing
    elseif !use_display[] && !isempty(available_backends)
        plotpane = has_juno_plotpane()
        if plotpane !== nothing && !plotpane
            # we want to display as inline!, we are in Juno, but the plotpane is disabled
            @warn """Showing scene as inline with Plotpane disabled. This happens because `AbstractPlotting.inline!(true)` is set,
            while `Atom.PlotPaneEnabled[]` is false. Either enable the plotpane, or set inline to false!"""
        else
            if plotpane === nothing && !isijulia()
                @warn """Showing scene as text. This happens because `AbstractPlotting.inline!(true)` is set.
                This needs to be false to show a plot in a window when in the REPL."""
            elseif plotpane === nothing || !plotpane
                 @warn """Showing scene as text. This happens because `AbstractPlotting.inline!(true)` is set.
                This needs to be false to show a plot in a window when in the REPL."""
            end
        end
    end
    
    print(io, scene)
    return
end

function Base.show(io::IO, plot::Combined)
    print(io, typeof(plot))
end

function Base.show(io::IO, plot::Atomic)
    print(io, typeof(plot))
end

function Base.show(io::IO, scene::Scene)
    println(io, "Scene ($(size(scene, 1))px, $(size(scene, 2))px):")

    print(io, "  $(length(scene.plots)) Plot$(_plural_s(scene.plots))")

    if length(scene.plots) > 0
        print(io, ":")
        for (i, plot) in enumerate(scene.plots)
            print(io, "\n")
            print(io, "    $(i == length(scene.plots) ? '└' : '├') ", plot)
        end
    end

    print(io, "\n  $(length(scene.children)) Child Scene$(_plural_s(scene.children))")
    
    if length(scene.children) > 0
        print(io, ":")
        for (i, subscene) in enumerate(scene.children)
            print(io, "\n")
            print(io,"    $(i == length(scene.children) ? '└' : '├') Scene ($(size(subscene, 1))px, $(size(subscene, 2))px)")
        end
    end
end

_plural_s(x) = length(x) != 1 ? "s" : ""

"""
    Stepper(scene, path; format = :jpg)

Creates a Stepper for generating progressive plot examples.

Each "step" is saved as a separate file in the folder
pointed to by `path`, and the format is customizable by
`format`, which can be any output type your backend supports.
"""
mutable struct Stepper
    scene::Scene
    folder::String
    format::Symbol
    step::Int
end

Stepper(scene::Scene, path::String, step::Int; format=:png) = Stepper(scene, path, format, step)

function Stepper(scene::Scene, path::String; format = :png)
    ispath(path) || mkpath(path)
    Stepper(scene, path, format, 1)
end

"""
    step!(s::Stepper)

steps through a `Makie.Stepper` and outputs a file with filename `filename-step.jpg`.
This is useful for generating progressive plot examples.
"""
function step!(s::Stepper)
    FileIO.save(joinpath(s.folder, basename(s.folder) * "-$(s.step).$(s.format)"), s.scene)
    s.step += 1
    return s
end

format2mime(::Type{FileIO.format"PNG"})  = MIME("image/png")
format2mime(::Type{FileIO.format"SVG"})  = MIME("image/svg+xml")
format2mime(::Type{FileIO.format"JPEG"}) = MIME("image/jpeg")
format2mime(::Type{FileIO.format"TIFF"}) = MIME("image/tiff")
format2mime(::Type{FileIO.format"BMP"}) = MIME("image/bmp")
format2mime(::Type{FileIO.format"PDF"})  = MIME("application/pdf")
format2mime(::Type{FileIO.format"TEX"})  = MIME("application/x-tex")
format2mime(::Type{FileIO.format"EPS"})  = MIME("application/postscript")
format2mime(::Type{FileIO.format"HTML"}) = MIME("text/html")

filetype(::FileIO.File{F}) where F = F
# Allow format to be overridden with first argument


"""
    FileIO.save(filename, scene; resolution = size(scene), pt_per_unit = 1.0, px_per_unit = 1.0)

Save a `Scene` with the specified filename and format.

# Supported Formats

- `GLMakie`: `.png`, `.jpeg`, and `.bmp`
- `CairoMakie`: `.svg`, `.pdf`, `.png`, and `.jpeg`
- `WGLMakie`: `.png`

# Supported Keyword Arguments

## All Backends

- `resolution`: `(width::Int, height::Int)` of the scene in dimensionless units (equivalent to `px` for GLMakie and WGLMakie).

## CairoMakie

- `pt_per_unit`: The size of one scene unit in `pt` when exporting to a vector format.
- `px_per_unit`: The size of one scene unit in `px` when exporting to a bitmap format. This provides a mechanism to export the same scene with higher or lower resolution.
"""
function FileIO.save(
        f::FileIO.File, scene::Scene;
        resolution = size(scene),
        pt_per_unit = 1.0,
        px_per_unit = 1.0,
    )

    resolution !== size(scene) && resize!(scene, resolution)

    # Delete previous file if it exists and query only the file string for type.
    # We overwrite existing files anyway, so this doesn't change the behavior.
    # But otherwise we could get a filetype :UNKNOWN from a corrupt existing file
    # (from an error during save, e.g.), therefore we don't want to rely on the
    # type readout from an existing file.
    filename = FileIO.filename(f)
    isfile(filename) && rm(filename)
    # query the filetype only from the file extension
    F = filetype(FileIO.query(filename))

    kwarg_pairs = pairs((full_fidelity = true, pt_per_unit = pt_per_unit,
        px_per_unit = px_per_unit))

    open(filename, "w") do s
        show(
            IOContext(s, kwarg_pairs...),
            format2mime(F),
            scene)
    end
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

# This is compat between FFMPEG versions 0.2 and 0.3,
# where 0.3 uses artifacts but 0.2 does not.
# Because of this, we need to check which variable will give FFMPEG's path.
const _ffmpeg_path = isdefined(FFMPEG, :ffmpeg_path) ? FFMPEG.ffmpeg_path : FFMPEG.ffmpeg

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
    process = @ffmpeg_env open(`$_ffmpeg_path -loglevel quiet -f rawvideo -pixel_format rgb24 -r $framerate -s:v $(xdim)x$(ydim) -i pipe:0 -vf vflip -y $path`, "w")
    VideoStream(process.in, process, screen, abspath(path))
end


# This has to be overloaded by the backend for its screen type.
function colorbuffer(x)
    error("colorbuffer not implemented for screen $(typeof(x))")
end

"""
    colorbuffer(scene)
    colorbuffer(screen)

Returns the content of the given scene or screen rasterised to a Matrix of
Colors.  The return type is backend-dependent, but will be some form of RGB
or RGBA.
"""
function colorbuffer(scene::Scene)
    screen = getscreen(scene)
    if isnothing(screen)
        if ismissing(current_backend[])
            error("""
                You have not loaded a backend.  Please load one (`using GLMakie` or `using CairoMakie`)
                before trying to render a Scene.
                """)
        else
            error("""
                The Scene needs an active screen before a colorbuffer can be rendered from it.
                Ensure that it has one via `display(scene)`.
                """)
        end
    end
    return colorbuffer(screen)
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
    save(path::String, io::VideoStream; framerate = 24, compression = 20)

Flushes the video stream and converts the file to the extension found in `path`,
which can be one of the following:
- `.mkv`  (the default, doesn't need to convert)
- `.mp4`  (good for Web, most supported format)
- `.webm` (smallest file size)
- `.gif`  (largest file size for the same quality)

`.mp4` and `.mk4` are marginally bigger and `.gif`s are up to
6 times bigger with the same quality!

The `compression` argument controls the compression ratio; `51` is the
highest compression, and `0` is the lowest (lossless).

See the docs of [`VideoStream`](@ref) for how to create a VideoStream.
If you want a simpler interface, consider using [`record`](@ref).

"""
function save(path::String, io::VideoStream;
              framerate::Int = 24, compression = 20)
    close(io.process)
    wait(io.process)
    p, typ = splitext(path)
    if typ == ".mkv"
        cp(io.path, path, force=true)
    elseif typ == ".mp4"
        ffmpeg_exe(`-loglevel quiet -i $(io.path) -crf $compression -c:v libx264 -preset slow -r $framerate -pix_fmt yuv420p -c:a libvo_aacenc -b:a 128k -y $path`)
    elseif typ == ".webm"
        ffmpeg_exe(`-loglevel quiet -i $(io.path) -crf $compression -c:v libvpx-vp9 -threads 16 -b:v 2000k -c:a libvorbis -threads 16 -r $framerate -vf scale=iw:ih -y $path`)
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
    record(func, scene, path; framerate = 24, compression = 20)
    record(func, scene, path, iter;
            framerate = 24, compression = 20, sleep = true)

The first signature provides `func` with a VideoStream, which it should call `recordframe!(io)` on when recording a frame.

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

The `compression` argument controls the compression ratio; `51` is the
highest compression, and `0` is the lowest (lossless).

When `sleep` is set to `true` (the default), AbstractPlotting will
display the animation in real-time by sleeping in between frames.
Thus, a 24-frame, 24-fps recording would take one second to record.

When it is set to `false`, frames are rendered as fast as the backend
can render them.  Thus, a 24-frame, 24-fps recording would usually
take much less than one second in GLMakie.

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

## Extended help
### Examples

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
function record(func, scene, path; framerate::Int = 24, compression = 20)
    io = VideoStream(scene; framerate = framerate)
    func(io)
    save(path, io; framerate = framerate, compression = compression)
end

function record(func, scene, path, iter; framerate::Int = 24, compression = 20, sleep = true)
    io = VideoStream(scene; framerate = framerate)
    for i in iter
        t1 = time()
        func(i)
        recordframe!(io)
        @debug "Recording" progress=i/length(iter)
        diff = (1/framerate) - (time() - t1)
        if sleep && diff > 0.0
            Base.sleep(diff)
        else
            yield()
        end
    end
    save(path, io, framerate = framerate, compression = compression)
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
