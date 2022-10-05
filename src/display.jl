@enum ImageStorageFormat JuliaNative GLNative

update_state_before_display!(_) = nothing

function backend_show end

"""
Current backend
"""
const CURRENT_BACKEND = Ref{Union{Missing, Module}}(missing)
current_backend() = CURRENT_BACKEND[]

function set_active_backend!(backend::Union{Missing, Module})
    CURRENT_BACKEND[] = backend
    return
end

function push_screen!(scene::Scene, display)
    error("$(display) not a valid Makie display.")
end

function push_screen!(scene::Scene, display::AbstractDisplay)
    if !any(x -> x === display, scene.current_screens)
        push!(scene.current_screens, display)
        deregister = nothing
        deregister = on(events(scene).window_open, priority=typemax(Int)) do is_open
            # when screen closes, it should set the scene isopen event to false
            # so that's when we can remove the display
            if !is_open
                filter!(x-> x !== display, scene.current_screens)
                !isnothing(deregister) && off(deregister)
            end
            return Consume(false)
        end
    end
    return
end

function delete_screen!(scene::Scene, display::AbstractDisplay)
    filter!(x-> x !== display, scene.current_screens)
    return
end

function set_screen_config!(backend::Module, new_values)
    key = nameof(backend)
    backend_defaults = CURRENT_DEFAULT_THEME[key]
    bkeys = keys(backend_defaults)
    for (k, v) in pairs(new_values)
        if !(k in bkeys)
            error("$k is not a valid screen config. Applicable options: $(keys(backend_defaults)). For help, check `?$(backend).ScreenCofig`")
        end
        backend_defaults[k] = v
    end
    return
end

function merge_screen_config(::Type{Config}, screen_config_kw) where Config
    backend = parentmodule(Config)
    key = nameof(backend)
    backend_defaults = CURRENT_DEFAULT_THEME[key]
    kw_nt = values(screen_config_kw)
    arguments = map(fieldnames(Config)) do name
        if haskey(kw_nt, name)
            return getfield(kw_nt, name)
        else
            return to_value(backend_defaults[name])
        end
    end
    return Config(arguments...)
end

"""


# GLMakie
start_renderloop=true
visible=true
connect=true

# CairoMakie
pt_per_unit=x.pt_per_unit
px_per_unit=x.px_per_unit
antialias=x.antialias
"""
function Base.display(figlike::FigureLike; screen_config...)
    Backend = current_backend()
    if ismissing(Backend)
        error("""
        No backend available!
        Make sure to also `import/using` a backend (GLMakie, CairoMakie, WGLMakie).

        If you imported GLMakie, it may have not built correctly.
        In that case, try `]build GLMakie` and watch out for any warnings.
        """)
    end
    screen = Backend.Screen(get_scene(figlike); screen_config...)
    return display(screen, figlike)
end

function Base.display(screen::MakieScreen, figlike::FigureLike; display_attributes...)
    update_state_before_display!(figlike)
    scene = get_scene(figlike)
    display(screen, scene; display_attributes...)
    return screen
end

const PREFERRED_MIME = Base.RefValue{Union{Automatic, String}}(automatic)

"""
    set_preferred_mime!(mime::Union{String, Symbol, MIME, Automatic}=automatic)

The default is automatic, which lets the display system figure out the best mime.
If set to any other valid mime, will result in `showable(any_other_mime, figurelike)` to return false and only return true for `showable(preferred_mime, figurelike)`.
Depending on the display system used, this may result in nothing getting displayed.
"""
function set_preferred_mime!(mime::Union{String, Symbol, MIME, Automatic}=automatic)
    if mime isa Automatic
        PREFERRED_MIME[] = mime
        return
    end
    # Mimes supported accross Makie backends
    # TODO, make this dynamic and backends can register their mimes?
    supported_mimes = Set([
        "text/html",
        "application/vnd.webio.application+html",
        "application/prs.juno.plotpane+html",
        "juliavscode/html",
        "image/svg+xml",
        "application/pdf",
        "application/postscript",
        "image/png",
        "image/jpeg"])

    mime_str = string(mime)

    if mime_str in supported_mimes
        PREFERRED_MIME[] = mime_str
    else
        error("Mime not supported: $(mime_str). Supported mimes: $(supported_mimes)")
    end
    return
end

function _backend_showable(mime::MIME{SYM}) where SYM
    Backend = current_backend()
    if ismissing(Backend)
        return Symbol("text/plain") == SYM
    end
    backend_support = backend_showable(Backend.Screen, mime)
    if PREFERRED_MIME[] isa Automatic
        return backend_support
    else
        return backend_support && string(SYM) == PREFERRED_MIME[]
    end
end
Base.showable(mime::MIME, fig::FigureLike) = _backend_showable(mime)

# need to define this to resolve ambiguoity issue
Base.showable(mime::MIME"application/json", fig::FigureLike) = _backend_showable(mime)

backend_showable(@nospecialize(screen), @nospecialize(mime)) = false

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

function Base.show(io::IO, ::MIME"text/plain", scene::Scene)
    show(io, scene)
end

function Base.show(io::IO, m::MIME, figlike::FigureLike)
    update_state_before_display!(figlike)
    scene = get_scene(figlike)
    backend_show(current_backend().Screen(scene, io, m), io, m, scene)
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
    screen::MakieScreen
    folder::String
    format::Symbol
    step::Int
end

mutable struct RamStepper
    figlike::FigureLike
    screen::MakieScreen
    images::Vector{Matrix{RGBf}}
    format::Symbol
end

function Stepper(figlike::FigureLike; backend=current_backend(), format=:png, visible=false, connect=false, srceen_kw...)
    screen = backend.Screen(get_scene(figlike), JuliaNative; visible=visible, start_renderloop=false, srceen_kw...)
    display(screen, figlike; connect=connect)
    return RamStepper(figlike, screen, Matrix{RGBf}[], format)
end

function Stepper(figlike::FigureLike, path::String, step::Int; format=:png, backend=current_backend(), visible=false, connect=false, screen_config...)
    screen = backend.Screen(get_scene(figlike), JuliaNative; visible=visible, start_renderloop=false, screen_config...)
    display(screen, figlike; connect=connect)
    return FolderStepper(figlike, screen, path, format, step)
end

function Stepper(figlike::FigureLike, path::String; kw...)
    ispath(path) || mkpath(path)
    return Stepper(figlike, path, 1; kw...)
end

"""
    step!(s::Stepper)

steps through a `Makie.Stepper` and outputs a file with filename `filename-step.jpg`.
This is useful for generating progressive plot examples.
"""
function step!(s::FolderStepper)
    update_state_before_display!(s.figlike)
    FileIO.save(joinpath(s.folder, basename(s.folder) * "-$(s.step).$(s.format)"), colorbuffer(s.screen))
    s.step += 1
    return s
end

function step!(s::RamStepper)
    update_state_before_display!(s.figlike)
    img = convert(Matrix{RGBf}, colorbuffer(s.screen))
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

filetype(::FileIO.File{F}) where F = F
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
function FileIO.save(
        filename::String, fig::FigureLike; args...
    )
    FileIO.save(FileIO.query(filename), fig; args...)
end

function FileIO.save(
        file::FileIO.Formatted, fig::FigureLike;
        resolution = size(get_scene(fig)),
        backend = current_backend(),
        screen_config...
    )
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
    mime = format2mime(F)
    open(filename, "w") do io
        # If the scene already got displayed, we get the current screen its displayed on
        # Else, we create a new scene and update the state of the fig
        screen = getscreen(scene, backend) do
            update_state_before_display!(fig)
            return backend.Screen(scene, io, mime; screen_config...)
        end
        backend_show(screen, io, mime, scene)
    end
end

raw_io(io::IO) = io
raw_io(io::IOContext) = raw_io(io.io)

# This has to be overloaded by the backend for its screen type.
function colorbuffer(x::MakieScreen)
    error("colorbuffer not implemented for screen $(typeof(x))")
end

function jl_to_gl_format(image)
    @static if VERSION < v"1.6"
        d1, d2 = size(image)
        bufc = Array{eltype(image)}(undef, d2, d1) #permuted
        ind1, ind2 = axes(image)
        n = first(ind1) + last(ind1)
        for i in ind1
            @simd for j in ind2
                @inbounds bufc[j, n-i] = image[i, j]
            end
        end
        return bufc
    else
        reverse!(image; dims=1)
        return PermutedDimsArray(image, (2, 1))
    end
end

# less specific for overloading by backends
function colorbuffer(screen::MakieScreen, format::ImageStorageFormat)
    image = colorbuffer(screen)
    if format == GLNative
        return jl_to_gl_format(image)
    elseif format == JuliaNative
        return image
    end
end

function getscreen(f::Function, scene::Scene, backend::Module)
    screen = getscreen(scene)
    if !isnothing(screen) && parentmodule(typeof(screen)) == backend
        return screen
    end
    if ismissing(backend)
        error("""
            You have not loaded a backend.  Please load one (`using GLMakie` or `using CairoMakie`)
            before trying to render a Scene.
            """)
    else
        return f()
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
function colorbuffer(fig::FigureLike, format::ImageStorageFormat = JuliaNative; backend = current_backend(), screen_config...)
    scene = get_scene(fig)
    screen = getscreen(scene, backend) do
        screen = backend.Screen(scene, format; start_renderloop=false, visible=false, screen_config...)
        display(screen, fig; connect=false)
        return screen
    end
    return colorbuffer(screen, format)
end

# Fallback for any backend that will just use colorbuffer to write out an image
function backend_show(screen::MakieScreen, io::IO, m::MIME"image/png", scene::Scene)
    display(screen, scene; connect=false)
    img = colorbuffer(screen)
    FileIO.save(FileIO.Stream{FileIO.format"PNG"}(Makie.raw_io(io)), img)
    return
end

function backend_show(screen::MakieScreen, io::IO, m::MIME"image/jpeg", scene::Scene)
    display(screen, scene; connect=false)
    img = colorbuffer(scene)
    FileIO.save(FileIO.Stream{FileIO.format"JPEG"}(Makie.raw_io(io)), img)
    return
end

const VIDEO_STREAM_OPTIONS_FORMAT_DESC = """
- `format = "mkv"`: The format of the video. Can be one of the following:
    * `"mkv"`  (open standard, the default)
    * `"mp4"`  (good for Web, most supported format)
    * `"webm"` (smallest file size)
    * `"gif"`  (largest file size for the same quality)

  `mp4` and `mk4` are marginally bigger than `webm`. `gif`s can be significantly (as much as
  6x) larger with worse quality (due to the limited color palette) and only should be used
  as a last resort, for playing in a context where videos aren't supported.
"""

const VIDEO_STREAM_OPTIONS_KWARGS_DESC = """
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
$VIDEO_STREAM_OPTIONS_FORMAT_DESC
$VIDEO_STREAM_OPTIONS_KWARGS_DESC
"""
struct VideoStreamOptions
    format::String
    framerate::Int
    compression::Union{Nothing,Int}
    profile::Union{Nothing,String}
    pixel_format::Union{Nothing,String}

    function VideoStreamOptions(format::AbstractString, framerate::Integer, compression, profile, pixel_format)

        if format == "mp4"
            (profile === nothing) && (profile = "high422")
            (pixel_format === nothing) && (pixel_format = (profile == "high444" ? "yuv444p" : "yuv420p"))
        end

        if format in ("mp4", "webm")
            (compression === nothing) && (compression = 20)
        end

        # items are name, value, allowed_formats
        allowed_kwargs = [("compression", compression, ("mp4", "webm")),
                          ("profile", profile, ("mp4",)),
                          ("pixel_format", pixel_format, ("mp4",))]

        for (name, value, allowed_formats) in allowed_kwargs
            if !(format in allowed_formats) && value !== nothing
                @warn("""`$name`, with value $(repr(value))
                    was passed as a keyword argument to `record` or `VideoStream`,
                    which only has an effect when the output video's format is one of: $(collect(allowed_formats)).
                    But the actual video format was $(repr(format)).
                    Keyword arg `$name` will be ignored.
                    """)
            end
        end
        return new(format, framerate, compression, profile, pixel_format)
    end
end

function to_ffmpeg_cmd(vso::VideoStreamOptions, xdim::Integer, ydim::Integer)
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
    (format, framerate, compression, profile, pixel_format) = (vso.format, vso.framerate, vso.compression, vso.profile, vso.pixel_format)
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

    ffmpeg_options = if format == "mkv"
        `-i pipe:0
         -vf vflip
         -an
        `
    elseif format == "mp4"
        `-i pipe:0
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
        `-threads 16
         -i pipe:0
         -vf scale=$(xdim):$(ydim),vflip
         -crf $(compression)
         -c:v libvpx-vp9
         -b:v 0
         -an
        `
    elseif format == "gif"
        # from https://superuser.com/a/556031
        # avoids creating a PNG file of the palette
        `-i pipe:0
         -vf "vflip,fps=$(framerate),scale=$(xdim):-1:flags=lanczos,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse"
        `
    else
        error("Video type $(format) not known")
    end

    return `$(ffmpeg_prefix) $(ffmpeg_options)`
end

struct VideoStream
    io
    process::Base.Process
    screen::MakieScreen
    buffer::Matrix{RGB{N0f8}}
    path::String
    options::VideoStreamOptions
end

"""
    VideoStream(scene::Scene; framerate = 24, visible=false, connect=false, screen_config...)

Returns a stream and a buffer that you can use, which don't allocate for new frames.
Use [`recordframe!(stream)`](@ref) to add new video frames to the stream, and
[`save(path, stream)`](@ref) to save the video.

* visible=false: make window visible or not
* connect=false: connect window events or not
"""
function VideoStream(fig::FigureLike;
        format="mp4", framerate=24, compression=nothing, profile=nothing, pixel_format=nothing,
        visible=false, connect=false, backend=current_backend(),
        screen_config...)

    dir = mktempdir()
    path = joinpath(dir, "$(gensym(:video)).$(format)")
    scene = get_scene(fig)
    screen = backend.Screen(scene, GLNative; visible=visible, start_renderloop=false, screen_config...)
    display(screen, fig; connect=connect)
    _xdim, _ydim = size(screen)
    xdim = iseven(_xdim) ? _xdim : _xdim + 1
    ydim = iseven(_ydim) ? _ydim : _ydim + 1
    buffer = Matrix{RGB{N0f8}}(undef, xdim, ydim)
    vso = VideoStreamOptions(format, framerate, compression, profile, pixel_format)
    cmd = to_ffmpeg_cmd(vso, xdim, ydim)
    process = @ffmpeg_env open(`$cmd $path`, "w")
    return VideoStream(process.in, process, screen, buffer, abspath(path), vso)
end

"""
    recordframe!(io::VideoStream)

Adds a video frame to the VideoStream `io`.
"""
function recordframe!(io::VideoStream)
    glnative = colorbuffer(io.screen, GLNative)
    # Make no copy if already Matrix{RGB{N0f8}}
    # There may be a 1px padding for odd dimensions
    xdim, ydim = size(glnative)
    copy!(view(io.buffer, 1:xdim, 1:ydim), glnative)
    write(io.io, io.buffer)
    return
end

"""
    save(path::String, io::VideoStream)

Flushes the video stream and saves it to `path`. `path`'s file extension must be the same as
the format that the `VideoStream` was created with (e.g., if created with format "mp4" then
`path`'s file extension must be ".mp4"). If using [`record`](@ref) then this is handled for
you, as the `VideoStream`'s format is deduced from the file extension of the path passed to
`record`.
"""
function save(path::String, io::VideoStream)
    close(io.process)
    wait(io.process)
    p, typ = splitext(path)
    video_fmt = io.options.format
    if typ != ".$(video_fmt)"
        error("invalid `path`; the video stream was created for `$(video_fmt)`, but the provided path had extension `$(typ)`")
    end
    cp(io.path, path; force=true)
    rm(io.path)
    return path
end

"""
    record(func, figurelike, path; kwargs...)
    record(func, figurelike, path, iter; kwargs...)

The first signature provides `func` with a VideoStream, which it should call
`recordframe!(io)` on when recording a frame.

The second signature iterates `iter`, calling `recordframe!(io)` internally
after calling `func` with the current iteration element.

Both notations require a Figure, FigureAxisPlot or Scene `figure` to work.
The animation is then saved to `path`, with the format determined by `path`'s
extension.

$VIDEO_STREAM_OPTIONS_FORMAT_DESC

### Keyword Arguments:
$VIDEO_STREAM_OPTIONS_KWARGS_DESC


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
function record(func, figlike::FigureLike, path::AbstractString; record_kw...)
    format = lstrip(splitext(path)[2], '.')
    io = Record(func, figlike; format=format, record_kw...)
    save(path, io)
end

function record(func, figlike::FigureLike, path::AbstractString, iter; record_kw...)
    format = lstrip(splitext(path)[2], '.')
    io = Record(func, figlike, iter; format=format, record_kw...)
    save(path, io)
end


function Record(func, figlike; videostream_kw...)
    io = VideoStream(figlike; videostream_kw...)
    func(io)
    return io
end

function Record(func, figlike, iter; videostream_kw...)
    io = VideoStream(figlike; videostream_kw...)
    for i in iter
        func(i)
        recordframe!(io)
        @debug "Recording" progress=i/length(iter)
        yield()
    end
    return io
end

function Base.show(io::IO, ::MIME"text/html", vs::VideoStream)
    mktempdir() do dir
        path = save(joinpath(dir, "video.mp4"), vs)
        print(
            io,
            """<video autoplay controls><source src="data:video/x-m4v;base64,""",
            base64encode(open(read, path)),
            """" type="video/mp4"></video>"""
        )
    end
end
