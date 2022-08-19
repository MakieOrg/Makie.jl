abstract type AbstractBackend end
function backend_display end

@enum ImageStorageFormat JuliaNative GLNative

"""
Current backend
"""
const current_backend = Ref{Union{Missing,AbstractBackend}}(missing)
const use_display = Ref{Bool}(true)

function inline!(inline=true)
    use_display[] = !inline
    return
end

function register_backend!(backend::AbstractBackend)
    current_backend[] = backend
    return
end

function push_screen!(scene::Scene, display)
    # Ok lets leave a warning here until we fix CairoMakie!
    @debug("Backend doesn't return screen from show methods. This needs fixing!")
end

function push_screen!(scene::Scene, display::AbstractDisplay)
    if !any(x -> x === display, scene.current_screens)
        push!(scene.current_screens, display)
        deregister = nothing
        deregister = on(events(scene).window_open; priority=typemax(Int)) do is_open
            # when screen closes, it should set the scene isopen event to false
            # so that's when we can remove the display
            if !is_open
                filter!(x -> x !== display, scene.current_screens)
                deregister !== nothing && off(deregister)
            end
            return Consume(false)
        end
    end
    return
end

function delete_screen!(scene::Scene, display::AbstractDisplay)
    filter!(x -> x !== display, scene.current_screens)
    return
end

function backend_display(s::FigureLike; kw...)
    update_state_before_display!(s)
    return backend_display(current_backend[], get_scene(s); kw...)
end

function backend_display(::Missing, ::Scene; kw...)
    return error("""
           No backend available!
           Make sure to also `import/using` a backend (GLMakie, CairoMakie, WGLMakie).

           If you imported GLMakie, it may have not built correctly.
           In that case, try `]build GLMakie` and watch out for any warnings.
           """)
end

update_state_before_display!(_) = nothing

function Base.display(fig::FigureLike; kw...)
    scene = get_scene(fig)
    if !use_display[]
        update_state_before_display!(fig)
        return Core.invoke(display, Tuple{Any}, scene)
    else
        screen = backend_display(fig; kw...)
        push_screen!(scene, screen)
        return screen
    end
end

function Base.showable(mime::MIME{M}, scene::Scene) where {M}
    return backend_showable(current_backend[], mime, scene)
end
# ambig
function Base.showable(mime::MIME"application/json", scene::Scene)
    return backend_showable(current_backend[], mime, scene)
end
function Base.showable(mime::MIME{M}, fig::FigureLike) where {M}
    return backend_showable(current_backend[], mime, get_scene(fig))
end
# ambig
function Base.showable(mime::MIME"application/json", fig::FigureLike)
    return backend_showable(current_backend[], mime, get_scene(fig))
end

function backend_showable(::Backend, ::Mime, ::Scene) where {Backend,Mime<:MIME}
    return hasmethod(backend_show, Tuple{Backend,IO,Mime,Scene})
end

# fallback show when no backend is selected
function backend_show(backend, io::IO, ::MIME"text/plain", scene::Scene)
    if backend isa Missing
        @warn """
        Printing Scene as text because no backend is available (GLMakie, CairoMakie, WGLMakie).
        Maybe you imported GLMakie but it didn't build correctly.
        In that case, try `]build GLMakie` and watch out for any warnings.
        """
    end
    print(io, scene)
    return
end

function Base.show(io::IO, ::MIME"text/plain", scene::Scene; kw...)
    return show(io, scene; kw...)
end

function Base.show(io::IO, m::MIME, figlike::FigureLike)
    ioc = IOContext(io, :full_fidelity => true)
    update_state_before_display!(figlike)
    backend_show(current_backend[], ioc, m, get_scene(figlike))
    return
end

"""
    Stepper(scene, path; format = :jpg)

Creates a Stepper for generating progressive plot examples.

Each "step" is saved as a separate file in the folder
pointed to by `path`, and the format is customizable by
`format`, which can be any output type your backend supports.

Notice that the relevant `Makie.step!` is not
exported and should be accessed by module name.
"""
mutable struct FolderStepper
    figlike::FigureLike
    folder::String
    format::Symbol
    step::Int
end

mutable struct RamStepper
    figlike::FigureLike
    images::Vector{Matrix{RGBf}}
    format::Symbol
end

function Stepper(figlike::FigureLike, path::String, step::Int; format=:png)
    return FolderStepper(figlike, path, format, step)
end
Stepper(figlike::FigureLike; format=:png) = RamStepper(figlike, Matrix{RGBf}[], format)

function Stepper(figlike::FigureLike, path::String; format=:png)
    ispath(path) || mkpath(path)
    return FolderStepper(figlike, path, format, 1)
end

"""
    step!(s::Stepper)

steps through a `Makie.Stepper` and outputs a file with filename `filename-step.jpg`.
This is useful for generating progressive plot examples.
"""
function step!(s::FolderStepper)
    FileIO.save(joinpath(s.folder, basename(s.folder) * "-$(s.step).$(s.format)"), s.figlike)
    s.step += 1
    return s
end

function step!(s::RamStepper)
    img = convert(Matrix{RGBf}, colorbuffer(s.figlike))
    push!(s.images, img)
    return s
end

function FileIO.save(dir::String, s::RamStepper)
    if !isdir(dir)
        mkpath(dir)
    end
    for (i, img) in enumerate(s.images)
        FileIO.save(joinpath(dir, "step-$i.$(s.format)"), img)
    end
end

format2mime(::Type{FileIO.format"PNG"}) = MIME("image/png")
format2mime(::Type{FileIO.format"SVG"}) = MIME("image/svg+xml")
format2mime(::Type{FileIO.format"JPEG"}) = MIME("image/jpeg")
format2mime(::Type{FileIO.format"TIFF"}) = MIME("image/tiff")
format2mime(::Type{FileIO.format"BMP"}) = MIME("image/bmp")
format2mime(::Type{FileIO.format"PDF"}) = MIME("application/pdf")
format2mime(::Type{FileIO.format"TEX"}) = MIME("application/x-tex")
format2mime(::Type{FileIO.format"EPS"}) = MIME("application/postscript")
format2mime(::Type{FileIO.format"HTML"}) = MIME("text/html")

filetype(::FileIO.File{F}) where {F} = F
# Allow format to be overridden with first argument

"""
    FileIO.save(filename, scene; resolution = size(scene), pt_per_unit = 0.75, px_per_unit = 1.0)

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
function FileIO.save(filename::String, fig::FigureLike; args...)
    return FileIO.save(FileIO.query(filename), fig; args...)
end

function FileIO.save(file::FileIO.Formatted, fig::FigureLike;
                     resolution=size(get_scene(fig)),
                     pt_per_unit=0.75,
                     px_per_unit=1.0)
    scene = get_scene(fig)
    if resolution != size(scene)
        resize!(scene, resolution)
    end

    filename = FileIO.filename(file)
    # Delete previous file if it exists and query only the file string for type.
    # We overwrite existing files anyway, so this doesn't change the behavior.
    # But otherwise we could get a filetype :UNKNOWN from a corrupt existing file
    # (from an error during save, e.g.), therefore we don't want to rely on the
    # type readout from an existing file.
    isfile(filename) && rm(filename)
    # query the filetype only from the file extension
    F = filetype(file)

    open(filename, "w") do s
        iocontext = IOContext(s,
                              :full_fidelity => true,
                              :pt_per_unit => pt_per_unit,
                              :px_per_unit => px_per_unit)
        return show(iocontext, format2mime(F), fig)
    end
end

raw_io(io::IO) = io
raw_io(io::IOContext) = raw_io(io.io)

"""
    record_events(f, scene::Scene, path::String)

Records all window events that happen while executing function `f`
for `scene` and serializes them to `path`.
"""
function record_events(f, scene::Scene, path::String)
    display(scene)
    result = Vector{Pair{Float64,Pair{Symbol,Any}}}()
    for field in fieldnames(Events)
        # These are not Observables
        (field == :mousebuttonstate || field == :keyboardstate) && continue
        on(getfield(scene.events, field); priority=typemax(Int)) do value
            value = isa(value, Set) ? copy(value) : value
            push!(result, time() => (field => value))
            return Consume(false)
        end
    end
    f()
    open(path, "w") do io
        return serialize(io, result)
    end
end

"""
    replay_events(f, scene::Scene, path::String)
    replay_events(scene::Scene, path::String)

Replays the serialized events recorded with `record_events` in `path` in `scene`.
"""
replay_events(scene::Scene, path::String) = replay_events(() -> nothing, scene, path)
function replay_events(f, scene::Scene, path::String)
    events = open(io -> deserialize(io), path)
    sort!(events; by=first)
    for i in 1:length(events)
        t1, (field, value) = events[i]
        (field == :mousebuttonstate || field == :keyboardstate) && continue
        Base.invokelatest() do
            return getfield(scene.events, field)[] = value
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

Base.display(re::RecordEvents) = display(re.scene)

_VIDEO_STREAM_OPTIONS_FORMAT_DESC = """
- `format = "mkv"`: The format of the video. Can be one of the following:
    * `"mkv"`  (the default)
    * `"mp4"`  (good for Web, most supported format)
    * `"webm"` (smallest file size)
    * `"gif"`  (largest file size for the same quality)

  `mp4` and `mk4` are marginally bigger than `webm`. `gif`s can be significantly (as much as
  6x) larger with worse quality (due to the limited color palette) and only should be used
  as a last resort, for playing in a context where videos aren't supported.
"""

_VIDEO_STREAM_OPTIONS_KWARGS_DESC = """
- `framerate = 24`: The target framerate.
- `compression = 20`: Controls the video compression via `ffmpeg`'s `-crf` option, with
  smaller numbers giving higher quality and larger file sizes (lower compression), and and
  higher numbers giving lower quality and smaller file sizes (higher compression). The
  minimum value is `0` (lossless encoding).
    - For `mp4`, `51` is the maximum. Note that `compression = 0` only works with `mp4` if
      `profile = high444`.
    - For `webm`, `63` is the maximum.
    - `compression` has no effect on `mkv` and `gif` outputs.
- `profile = "high422"`: A ffmpeg compatible profile. Currently only applies to `mp4`. If
  you have issues playing a video, try `profile = "high"` or `profile = "main"`.
- `pixel_format = "yuv420p"`: A ffmpeg compatible pixel format (`-pix_fmt`). Currently only
  applies to `mp4`. Defaults to `yuv444p` for `profile = high444`.
"""

"""
    VideoStreamOptions(; format="mkv", framerate=24, compression=20, profile=nothing, pixel_format=nothing)

Holds the options that will be used for encoding a `VideoStream`. `profile` and
`pixel_format` are only used when `format` is `"mp4"`; a warning will be issued if `format`
is not `"mp4"` and those two arguments are not `nothing`. Similarly, `compression` is only
valid when `format` is `"mp4"` or `"webm"`.

You should not create a `VideoStreamOptions` directly; instead, pass its keyword args to the
`VideoStream` constructor. See the docs of [`VideoStream`](@ref) for how to create a
`VideoStream`. If you want a simpler interface, consider using [`record`](@ref).

### Keyword Arguments:
$_VIDEO_STREAM_OPTIONS_FORMAT_DESC
$_VIDEO_STREAM_OPTIONS_KWARGS_DESC
"""
struct VideoStreamOptions
    format::String
    framerate::Int
    compression::Int
    profile::Union{Nothing,String}
    pixel_format::Union{Nothing,String}

    function VideoStreamOptions(format, framerate, compression, profile, pixel_format)
        if format == "mp4"
            profile = @something profile "high422"
            pixel_format = @something pixel_format (profile == "high444" ? "yuv444p" : "yuv420p")
        end

        # items are name, value, allowed_formats
        allowed_kwargs = [("compression", compression, ("mp4", "webm")),
                          ("profile", profile, ("mp4",)),
                          ("pixel_format", pixel_format, ("mp4",))]

        for (name, value, allowed_formats) in allowed_kwargs
            if !(format in allowed_formats) && value !== nothing
                @eval @warn(string('`',
                                   $name,
                                   "` was passed to VideoStreamOptions, yet `format` was not one of ",
                                   $allowed_formats,
                                   ". `",
                                   $name,
                                   "` will be ignored."),
                            format = $format,
                            $name = $value)
            end
        end

        return new(format, framerate, compression, profile, pixel_format)
    end

    function VideoStreamOptions(; format="mkv", framerate=24, compression=20,
                                profile=nothing, pixel_format=nothing)
        return VideoStreamOptions(format, framerate, compression, profile, pixel_format)
    end
end

struct VideoStream
    io::Any
    process::Any
    screen::Any
    path::String
    options::VideoStreamOptions
end

"""
    VideoStream(scene::Scene; kwargs...)

Returns a stream and a buffer that you can use, which don't allocate for new frames.
Use [`recordframe!(stream)`](@ref) to add new video frames to the stream, and
[`save(path, stream)`](@ref) to save the video.

### Keyword Arguments:
- `visible=false`: make window visible or not
- `connect=false`: connect window events or not
$_VIDEO_STREAM_OPTIONS_FORMAT_DESC
$_VIDEO_STREAM_OPTIONS_KWARGS_DESC
"""
function VideoStream(fig::FigureLike; visible=false, connect=false,
                     format="mkv", framerate=24, compression=20, profile=nothing, pixel_format=nothing)
    options = VideoStreamOptions(; format, framerate, compression, profile, pixel_format)

    (format, framerate, compression, profile, pixel_format) = let o = options
        (o.format, o.framerate, o.compression, o.profile, o.pixel_format)
    end

    #codec = `-codec:v libvpx -quality good -cpu-used 0 -b:v 500k -qmin 10 -qmax 42 -maxrate 500k -bufsize 1000k -threads 8`
    dir = mktempdir()
    path = joinpath(dir, "$(gensym(:video)).$(format)")
    scene = get_scene(fig)
    screen = backend_display(fig; start_renderloop=false, visible=visible, connect=connect)
    _xdim, _ydim = size(scene)
    xdim = iseven(_xdim) ? _xdim : _xdim + 1
    ydim = iseven(_ydim) ? _ydim : _ydim + 1

    # explanation of ffmpeg args. note that the order of args is important; args pertaining
    # to the input have to go before -i and args pertaining to the output have to go after.
    # -y: "yes", overwrite any existing without confirmation
    # -f: format is raw video (from frames)
    # -framerate: set the input framerate
    # -pixel_format: the buffer we're sending ffmpeg via stdin contains rgb24 pixels
    # -s:v: sets the dimensions of the input to xdim × ydim
    # -i: read input from stdin (pipe:0)
    # -vf: video filter for the output
    # -c:v, -c:a: video and audio codec, respectively
    # -b:v, -b:a: video and audio bitrate, respectively
    # -crf: "constant rate factor", the lower the better the quality (0 is lossless, 51 is
    #   maximum compression)
    # -pix_fmt: (mp4 only) the output pixel format
    # -profile:v: (mp4 only) the output video profile
    # -an: no audio in output

    ffmpeg_prefix = `
        $(FFMPEG.ffmpeg)
        -y
        -loglevel quiet
        -f rawvideo
        -framerate $(framerate)
        -pixel_format rgb24
        -r $(framerate)
        -s:v $(xdim)x$(ydim)
    `

    ffmpeg_args = if format == "mkv"
        `$(ffmpeg_prefix)
         -i pipe:0
         -vf vflip
         -an
        `
    elseif format == "mp4"
        `$(ffmpeg_prefix)
         -i pipe:0
         -profile:v $(profile)
         -vf scale=$(xdim):$(ydim),vflip
         -crf $(compression)
         -preset slow
         -c:v libx264
         -pix_fmt $(pixel_format)
         -an
        `
    elseif format == "webm"
        # this may need improvement, see here: https://trac.ffmpeg.org/wiki/Encode/VP9
        `$(ffmpeg_prefix)
         -threads 16
         -i pipe:0
         -vf scale=$(xdim):$(ydim),vflip
         -crf $(compression)
         -c:v libvpx-vp9
         -b:v 0
         -an
         -threads 16
        `
    elseif format == "gif"
        # from https://superuser.com/a/556031
        # avoids creating a PNG file of the palette
        `$(ffmpeg_prefix)
         -i pipe:0
         -vf "vflip,fps=$(framerate),scale=$(xdim):-1:flags=lanczos,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse"
        `
    else
        error("Video type $(format) not known")
    end

    process = @ffmpeg_env open(`$ffmpeg_args $path`, "w")

    return VideoStream(process.in, process, screen, abspath(path), options)
end

# This has to be overloaded by the backend for its screen type.
function colorbuffer(x::AbstractScreen)
    return error("colorbuffer not implemented for screen $(typeof(x))")
end

function jl_to_gl_format(image)
    @static if VERSION < v"1.6"
        d1, d2 = size(image)
        bufc = Array{eltype(image)}(undef, d2, d1) #permuted
        ind1, ind2 = axes(image)
        n = first(ind1) + last(ind1)
        for i in ind1
            @simd for j in ind2
                @inbounds bufc[j, n - i] = image[i, j]
            end
        end
        return bufc
    else
        reverse!(image; dims=1)
        return collect(PermutedDimsArray(image, (2, 1)))
    end
end

# less specific for overloading by backends
function colorbuffer(screen::Any, format::ImageStorageFormat=JuliaNative)
    image = colorbuffer(screen)
    if format == GLNative
        if string(typeof(screen)) == "GLMakie.Screen"
            @warn "Inefficient re-conversion back to GLNative buffer format. Update GLMakie to support direct buffer access" maxlog = 1
        end
        return jl_to_gl_format(image)
    elseif format == JuliaNative
        return image
    end
end

"""
    colorbuffer(scene, format::ImageStorageFormat = JuliaNative)
    colorbuffer(screen, format::ImageStorageFormat = JuliaNative)

Returns the content of the given scene or screen rasterised to a Matrix of
Colors. The return type is backend-dependent, but will be some form of RGB
or RGBA.

- `format = JuliaNative` : Returns a buffer in the format of standard julia images (dims permuted and one reversed)
- `format = GLNative` : Returns a more efficient format buffer for GLMakie which can be directly
                        used in FFMPEG without conversion
"""
function colorbuffer(fig::FigureLike, format::ImageStorageFormat=JuliaNative)
    scene = get_scene(fig)
    screen = getscreen(scene)
    if isnothing(screen)
        if ismissing(current_backend[])
            error("""
                You have not loaded a backend.  Please load one (`using GLMakie` or `using CairoMakie`)
                before trying to render a Scene.
                """)
        else
            return colorbuffer(backend_display(fig; visible=false, start_renderloop=false, connect=false),
                               format)
        end
    end
    return colorbuffer(screen, format)
end

"""
    recordframe!(io::VideoStream)

Adds a video frame to the VideoStream `io`.
"""
function recordframe!(io::VideoStream)
    frame = convert(Matrix{RGB{N0f8}}, colorbuffer(io.screen, GLNative))
    _xdim, _ydim = size(frame)
    if isodd(_xdim) || isodd(_ydim)
        xdim = iseven(_xdim) ? _xdim : _xdim + 1
        ydim = iseven(_ydim) ? _ydim : _ydim + 1
        padded = fill(zero(eltype(frame)), (xdim, ydim))
        padded[1:_xdim, 1:_ydim] = frame
        frame = padded
    end
    write(io.io, frame)
    return
end

"""
    save(path::String, io::VideoStream)

Flushes the video stream and saves it to `path`. `path`'s file extension must be the same as
the format that the `VideoStream` was created with (e.g., if created with format "mp4" then
`path`'s file extension must be ".mp4"). If using [`record`](@ref) then this is handled for
you, as the `VideoStream`'s format is deduced from the file extension of the path passed to
`record`.

This function takes no keyword arguments; any encoding options must have been passed to the
`VideoStream` when it was constructed (either directly, or via `record`). See
[`VideoStream`](@ref) or [`record`](@ref) for information on those options.
"""
function save(path::String, io::VideoStream)
    close(io.process)
    wait(io.process)
    _, typ = splitext(path)

    video_fmt = io.options.format
    if typ != ".$(video_fmt)"
        error("invalid `path`; the video stream was created for `$(video_fmt)`, but the provided path had extension `$(typ)`")
    end

    cp(io.path, path; force=true)
    rm(io.path)
    return path
end

"""
    record(func, figure, path; kwargs...)
    record(func, figure, path, iter; kwargs...)

The first signature provides `func` with a VideoStream, which it should call
`recordframe!(io)` on when recording a frame.

The second signature iterates `iter`, calling `recordframe!(io)` internally
after calling `func` with the current iteration element.

Both notations require a Figure, FigureAxisPlot or Scene `figure` to work.

The animation is then saved to `path`, with the format determined by `path`'s
extension.  Allowable extensions are `.mkv`, `.mp4`, `.webm`, and `.gif`.

### Keyword Arguments:
$_VIDEO_STREAM_OPTIONS_KWARGS_DESC

Typical usage patterns would look like:

```julia
record(figure, "video.mp4", itr) do i
    func(i) # or some other manipulation of the figure
end
```

or, for more tweakability,

```julia
record(figure, "test.gif") do io
    for i = 1:100
        func!(figure)     # animate figure
        recordframe!(io)  # record a new frame
    end
end
```

If you want a more tweakable interface, consider using [`VideoStream`](@ref) and
[`save`](@ref).

## Extended help
### Examples

```julia
fig, ax, p = lines(rand(10))
record(fig, "test.gif") do io
    for i in 1:255
        p[:color] = RGBf(i/255, (255 - i)/255, 0) # animate figure
        recordframe!(io)
    end
end
```
or
```julia
fig, ax, p = lines(rand(10))
record(fig, "test.gif", 1:255) do i
    p[:color] = RGBf(i/255, (255 - i)/255, 0) # animate figure
end
```
"""
function record(func, figlike, path; framerate=24, compression=20, profile=nothing, pixel_format=nothing)
    format = lstrip(splitext(path)[2], '.')
    io = Record(func, figlike; format, framerate, compression, profile, pixel_format)
    return save(path, io)
end

function Record(func, figlike; format, framerate, compression, profile, pixel_format)
    io = VideoStream(figlike;
                     format, framerate, compression, profile, pixel_format)
    func(io)
    return io
end

function record(func, figlike, path, iter; framerate=24, compression=20, profile=nothing,
                pixel_format=nothing)
    format = lstrip(splitext(path)[2], '.')
    io = Record(func, figlike, iter; format, framerate, compression, profile, pixel_format)
    return save(path, io)
end

function Record(func, figlike, iter; format, framerate, compression, profile, pixel_format)
    io = VideoStream(figlike;
                     format, framerate, compression, profile, pixel_format)
    for i in iter
        func(i)
        recordframe!(io)
        @debug "Recording" progress = i / length(iter)
        yield()
    end
    return io
end

function Base.show(io::IO, ::MIME"text/html", vs::VideoStream)
    mktempdir() do dir
        path = save(joinpath(dir, "video.mp4"), vs)
        return print(io,
                     """<video autoplay controls><source src="data:video/x-m4v;base64,""",
                     base64encode(open(read, path)),
                     """" type="video/mp4"></video>""")
    end
end
