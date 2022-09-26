@enum ImageStorageFormat JuliaNative GLNative

update_state_before_display!(_) = nothing

function backend_display end
function backend_show end


"""
Current backend
"""
const current_backend = Ref{Union{Missing, Module}}(missing)

function register_backend!(backend::Module)
    current_backend[] = backend
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
                deregister !== nothing && off(deregister)
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

function set_screen_config!(config::RefValue, new_values)
    config_attributes = propertynames(config)
    for (k, v) in pairs(new_values)
        if !(k in config_attributes)
            error("$k is not a valid screen config. Applicable options: $(config_attributes)")
        end
    end
    config[] = merge(config[], new_values)
end

function backend_display(figlike::FigureLike; screen_kw...)
    update_state_before_display!(figlike)
    Backend = current_backend[]
    scene = get_scene(figlike)
    screen = Backend.Screen(scene; screen_kw...)
    backend_display(screen, scene)
    return screen
end

function backend_display(::Missing, ::Scene; screen_kw...)
    error("""
    No backend available!
    Make sure to also `import/using` a backend (GLMakie, CairoMakie, WGLMakie).

    If you imported GLMakie, it may have not built correctly.
    In that case, try `]build GLMakie` and watch out for any warnings.
    """)
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
function Base.display(fig::FigureLike; screen_kw...)
    return backend_display(fig; screen_kw...)
end

function Base.showable(mime::MIME{M}, scene::Scene) where M
    backend_showable(current_backend[].Screen, mime, scene)
end

# ambig
function Base.showable(mime::MIME"application/json", scene::Scene)
    backend_showable(current_backend[].Screen, mime, scene)
end
function Base.showable(mime::MIME{M}, fig::FigureLike) where M
    backend_showable(current_backend[].Screen, mime, get_scene(fig))
end
# ambig
function Base.showable(mime::MIME"application/json", fig::FigureLike)
    backend_showable(current_backend[].Screen, mime, get_scene(fig))
end

function backend_showable(::Type{Screen}, ::Mime, ::Scene) where {Screen, Mime <: MIME}
    hasmethod(backend_show, Tuple{Screen, IO, Mime, Scene})
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

function Base.show(io::IO, ::MIME"text/plain", scene::Scene)
    show(io, scene)
end

function Base.show(io::IO, m::MIME, figlike::FigureLike)
    ioc = IOContext(io, :full_fidelity => true)
    update_state_before_display!(figlike)
    scene = get_scene(figlike)
    backend_show(current_backend[].Screen(scene), ioc, m, scene)
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

Stepper(figlike::FigureLike, path::String, step::Int; format=:png) = FolderStepper(figlike, path, format, step)
Stepper(figlike::FigureLike; format=:png) = RamStepper(figlike, Matrix{RGBf}[], format)

function Stepper(figlike::FigureLike, path::String; format = :png)
    ispath(path) || mkpath(path)
    FolderStepper(figlike, path, format, 1)
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
        pt_per_unit = 0.75,
        px_per_unit = 1.0,
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

    open(filename, "w") do s
        iocontext = IOContext(s,
            :full_fidelity => true,
            :pt_per_unit => pt_per_unit,
            :px_per_unit => px_per_unit
        )
        show(iocontext, format2mime(F), fig)
    end
end

raw_io(io::IO) = io
raw_io(io::IOContext) = raw_io(io.io)

struct VideoStream
    io
    process
    screen
    path::String
end

"""
    VideoStream(scene::Scene; framerate = 24, visible=false, connect=false, backend_kw...)

Returns a stream and a buffer that you can use, which don't allocate for new frames.
Use [`recordframe!(stream)`](@ref) to add new video frames to the stream, and
[`save(path, stream)`](@ref) to save the video.

* visible=false: make window visible or not
* connect=false: connect window events or not
"""
function VideoStream(fig::FigureLike; framerate::Integer=24, visible=false, connect=false, backend_kw...)
    #codec = `-codec:v libvpx -quality good -cpu-used 0 -b:v 500k -qmin 10 -qmax 42 -maxrate 500k -bufsize 1000k -threads 8`
    dir = mktempdir()
    path = joinpath(dir, "$(gensym(:video)).mkv")
    scene = get_scene(fig)
    screen = backend_display(fig; start_renderloop=false, visible=visible, connect=connect)
    _xdim, _ydim = GeometryBasics.widths(screen)
    xdim = iseven(_xdim) ? _xdim : _xdim + 1
    ydim = iseven(_ydim) ? _ydim : _ydim + 1
    process = @ffmpeg_env open(`$(FFMPEG.ffmpeg) -framerate $(framerate) -loglevel quiet -f rawvideo -pixel_format rgb24 -r $framerate -s:v $(xdim)x$(ydim) -i pipe:0 -vf vflip -y $path`, "w")
    return VideoStream(process.in, process, screen, abspath(path))
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
    save(path::String, io::VideoStream[; kwargs...])

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

### Keyword Arguments:
- `framerate = 24`: The target framerate.
- `compression = 0`: Controls the video compression with `0` being lossless and
                     `51` being the highest compression. Note that `compression = 0`
                     only works with `.mp4` if `profile = high444`.
- `profile = "high422"`: A ffmpeg compatible profile. Currently only applies to
                         `.mp4`. If you have issues playing a video, try
                         `profile = "high"` or `profile = "main"`.
- `pixel_format = "yuv420p"`: A ffmpeg compatible pixel format (pix_fmt). Currently
                              only applies to `.mp4`. Defaults to `yuv444p` for
                              `profile = high444`.
"""
function save(
        path::String, io::VideoStream;
        framerate::Int = 24, compression = 20, profile = "high422",
        pixel_format = profile == "high444" ? "yuv444p" : "yuv420p",
        kwargs...
    )

    close(io.process)
    wait(io.process)
    p, typ = splitext(path)
    if typ == ".mkv"
        cp(io.path, path, force=true)
    else
        mktempdir() do dir
            out = joinpath(dir, "out$(typ)")
            if typ == ".mp4"
                # ffmpeg_exe(`-loglevel quiet -i $(io.path) -crf $compression -c:v libx264 -preset slow -r $framerate -pix_fmt yuv420p -c:a libvo_aacenc -b:a 128k -y $out`)
                ffmpeg_exe(`-loglevel quiet -i $(io.path) -crf $compression -c:v libx264 -preset slow -r $framerate -profile:v $profile -pix_fmt $pixel_format -c:a libvo_aacenc -b:a 128k -y $out`)
            elseif typ == ".webm"
                ffmpeg_exe(`-loglevel quiet -i $(io.path) -crf $compression -c:v libvpx-vp9 -threads 16 -b:v 2000k -c:a libvorbis -threads 16 -r $framerate -vf scale=iw:ih -y $out`)
            elseif typ == ".gif"
                filters = "fps=$framerate,scale=iw:ih:flags=lanczos"
                palette_path = dirname(io.path)
                pname = joinpath(palette_path, "palette.bmp")
                isfile(pname) && rm(pname, force = true)
                ffmpeg_exe(`-loglevel quiet -i $(io.path) -vf "$filters,palettegen" -y $pname`)
                ffmpeg_exe(`-loglevel quiet -i $(io.path) -i $pname -lavfi "$filters [x]; [x][1:v] paletteuse" -y $out`)
                rm(pname, force = true)
            else
                rm(io.path)
                error("Video type $typ not known")
            end
            cp(out, path, force=true)
        end
    end
    rm(io.path)
    return path
end

"""
    record(func, figure, path; framerate = 24, compression = 20, kwargs...)
    record(func, figure, path, iter; framerate = 24, compression = 20, kwargs...)

The first signature provides `func` with a VideoStream, which it should call
`recordframe!(io)` on when recording a frame.

The second signature iterates `iter`, calling `recordframe!(io)` internally
after calling `func` with the current iteration element.

Both notations require a Figure, FigureAxisPlot or Scene `figure` to work.

The animation is then saved to `path`, with the format determined by `path`'s
extension.  Allowable extensions are:
- `.mkv`  (the default, doesn't need to convert)
- `.mp4`  (good for Web, most supported format)
- `.webm` (smallest file size)
- `.gif`  (largest file size for the same quality)

`.mp4` and `.mk4` are marginally bigger than `webm` and `.gif`s are up to
6 times bigger with the same quality!

The `compression` argument controls the compression ratio; `51` is the
highest compression, and `0` or `1` is the lowest (with `0` being lossless).

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

### Keyword Arguments:
- `framerate = 24`: The target framerate.
- `compression = 0`: Controls the video compression with `0` being lossless and
                     `51` being the highest compression. Note that `compression = 0`
                     only works with `.mp4` if `profile = high444`.
- `profile = "high422`: A ffmpeg compatible profile. Currently only applies to
                        `.mp4`. If you have issues playing a video, try
                        `profile = "high"` or `profile = "main"`.
- `pixel_format = "yuv420p"`: A ffmpeg compatible pixel format (pix_fmt). Currently
                              only applies to `.mp4`. Defaults to `yuv444p` for
                              `profile = high444`.
"""
function record(func, figlike, path; framerate::Int = 24, kwargs...)
    io = Record(func, figlike, framerate = framerate)
    save(path, io, framerate = framerate; kwargs...)
end

function Record(func, figlike; framerate=24)
    io = VideoStream(figlike; framerate = framerate)
    func(io)
    return io
end

function record(func, figlike, path, iter; framerate::Int = 24, kwargs...)
    io = Record(func, figlike, iter; framerate=framerate)
    save(path, io, framerate = framerate; kwargs...)
end

function Record(func, figlike, iter; framerate::Int = 24)
    io = VideoStream(figlike; framerate=framerate)
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



# This has to be overloaded by the backend for its screen type.
function colorbuffer(x::AbstractScreen)
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
        return collect(PermutedDimsArray(image, (2, 1)))
    end
end

# less specific for overloading by backends
function colorbuffer(screen::Any, format::ImageStorageFormat = JuliaNative)
    image = colorbuffer(screen)
    if format == GLNative
        if string(typeof(screen)) == "GLMakie.Screen"
            @warn "Inefficient re-conversion back to GLNative buffer format. Update GLMakie to support direct buffer access" maxlog=1
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
function colorbuffer(fig::FigureLike, format::ImageStorageFormat = JuliaNative)
    scene = get_scene(fig)
    screen = getscreen(scene)
    if isnothing(screen)
        if ismissing(current_backend[])
            error("""
                You have not loaded a backend.  Please load one (`using GLMakie` or `using CairoMakie`)
                before trying to render a Scene.
                """)
        else
            return colorbuffer(backend_display(fig; visible=false, start_renderloop=false, connect=false), format)
        end
    end
    return colorbuffer(screen, format)
end
