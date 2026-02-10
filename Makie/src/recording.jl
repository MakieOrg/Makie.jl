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

function Stepper(figlike::FigureLike; backend = current_backend(), format = :png, visible = false, connect = false, screen_kw...)
    config = Dict{Symbol, Any}(screen_kw)
    get!(config, :visible, visible)
    get!(config, :start_renderloop, false)
    screen = getscreen(backend, get_scene(figlike), config, JuliaNative)
    display(screen, figlike; connect = connect)
    return RamStepper(figlike, screen, Matrix{RGBf}[], format)
end

function Stepper(figlike::FigureLike, path::String, step::Int; format = :png, backend = current_backend(), visible = false, connect = false, screen_kw...)
    config = Dict{Symbol, Any}(screen_kw)
    get!(config, :visible, visible)
    get!(config, :start_renderloop, false)
    screen = getscreen(backend, get_scene(figlike), config, JuliaNative)
    display(screen, figlike; connect = connect)
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
    return
end

"""
    record(func, figurelike, path; backend=current_backend(), kwargs...)
    record(func, figurelike, path, iter; backend=current_backend(), kwargs...)

The first signature provides `func` with a VideoStream, which it should call
`recordframe!(io)` on when recording a frame.

The second signature iterates `iter`, calling `recordframe!(io)` internally
after calling `func` with the current iteration element.

Both notations require a Figure, FigureAxisPlot or Scene `figure` to work.
The animation is then saved to `path`, with the format determined by `path`'s
extension.

Under the hood, `record` is just `video_io = Record(func, figurelike, [iter]; same_kw...); save(path, video_io)`.
`Record` can be used directly as well to do the saving at a later point, or to inline a video directly into a Notebook (the video supports, `show(video_io, "text/html")` for that purpose).

# Options one can pass via `kwargs...`:

* `backend::Module = current_backend()`: set the backend to write out video, can be set to `CairoMakie`, `GLMakie`, `WGLMakie`, `RPRMakie`.
### Backend options

See `?Backend.Screen` or `Base.doc(Backend.Screen)` for applicable options that can be passed and forwarded to the backend.

### Video options

$(Base.doc(VideoStreamOptions))

# Typical usage

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
function record(func, figlike::FigureLike, path::AbstractString; kw_args...)
    format = lstrip(splitext(path)[2], '.')
    io = Record(func, figlike; format = format, visible = true, kw_args...)
    return save(path, io)
end

function record(func, figlike::FigureLike, path::AbstractString, iter; kw_args...)
    format = lstrip(splitext(path)[2], '.')
    io = Record(func, figlike, iter; format = format, kw_args...)
    return save(path, io)
end


"""
    record_longrunning(func, figlike, path, iter;
        framerate=24, frame_format=:png, overwrite=false,
        compression=nothing, profile=nothing, pixel_format=nothing, preset=nothing, loop=nothing,
        backend=current_backend(), screen_config...)

Like [`record`](@ref), but saves each frame as an individual image file in a folder next to `path`.
If interrupted and re-run, it will skip already-rendered frames (still calling `func` to advance the
simulation state) and only render new ones.

# Arguments
- `func`: called as `func(i)` for each element `i` in `iter`.
- `figlike`: a `Figure`, `FigureAxisPlot`, or `Scene`.
- `path`: output video path (e.g. `"video.mp4"`). Frames are stored in a sibling folder `"\$(path)_frames/"`.
- `iter`: the iterator to loop over.
- `framerate=24`: target framerate for the output video.
- `frame_format=:png`: image format for saved frames.
- `overwrite=false`: if `true`, re-renders all frames even if they already exist.
- `compression`, `profile`, `pixel_format`, `preset`, `loop`: video encoding options, see [`VideoStreamOptions`](@ref).
- `backend`, `screen_config...`: forwarded to the backend for rendering.

# Example
```julia
record_longrunning(fig, "simulation.mp4", 1:1000) do i
    update_simulation!(i)
end
```
"""
function record_longrunning(func, figlike::FigureLike, path::AbstractString, iter;
        framerate=24, frame_format=:png, overwrite=false, update=true,
        compression=nothing, profile=nothing, pixel_format=nothing, preset=nothing, loop=nothing,
        backend=current_backend(), visible=false, screen_config...)
    p, _ = splitext(path)
    video_format = lstrip(splitext(path)[2], '.')
    frame_folder = p * "_frames"
    isdir(frame_folder) || mkpath(frame_folder)

    n = length(iter)
    nd = max(4, _count_digits(n))
    frame_path(idx) = joinpath(frame_folder, "frame_$(lpad(idx, nd, '0')).$(frame_format)")

    # Figure out which frames already exist
    existing = Set{Int}()
    if !overwrite
        for idx in 1:n
            if isfile(frame_path(idx))
                push!(existing, idx)
            end
        end
    end
    n_existing = length(existing)
    n_to_render = n - n_existing
    if n_existing > 0
        @info "record_longrunning: found $n_existing existing frames, $n_to_render to render"
    end

    # Set up screen
    config = Dict{Symbol, Any}(screen_config)
    get!(config, :visible, visible)
    get!(config, :start_renderloop, false)
    scene = get_scene(figlike)
    update && update_state_before_display!(figlike)
    screen = getscreen(backend, scene, config, JuliaNative)
    progress = ProgressMeter.Progress(n; desc="Recording frames: ", showspeed=true)
    for (idx, i) in enumerate(iter)
        func(i)
        if idx in existing
            ProgressMeter.next!(progress; showvalues=[(:status, "skipped (cached)")])
        else
            frame = colorbuffer(screen)
            FileIO.save(frame_path(idx), frame)
            ProgressMeter.next!(progress; showvalues=[(:status, "rendered")])
        end
        yield()
    end
    ProgressMeter.finish!(progress)
    close(screen)

    # Assemble frames into video using VideoStreamOptions for proper encoding
    @info "record_longrunning: assembling $n frames into video at $path"
    input_pattern = joinpath(frame_folder, "frame_%0$(nd)d.$(frame_format)")
    vso = VideoStreamOptions(video_format, framerate, compression, profile, pixel_format, preset, loop, "quiet", input_pattern, false)
    cmd = to_ffmpeg_cmd(vso)
    run(`$(FFMPEG_jll.ffmpeg()) $cmd $path`)
    return path
end

_count_digits(n) = n <= 0 ? 1 : floor(Int, log10(n)) + 1

"""
    Record(func, figlike, [iter]; kw_args...)

Check [`Makie.record`](@ref) for documentation.
"""
function Record(func, figlike; kw_args...)
    io = VideoStream(figlike; kw_args...)
    func(io)
    return io
end

function Record(func, figlike, iter; kw_args...)
    io = VideoStream(figlike; kw_args...)
    for i in iter
        func(i)
        recordframe!(io)
        @debug "Recording" progress = i / length(iter)
        yield()
    end
    return io
end

function Base.show(io::IO, ::MIME"text/html", vs::VideoStream)
    scene = vs.screen.scene
    if !(scene isa Scene)
        error("Expected Screen to hold a reference to a Scene but got $(repr(scene))")
    end
    w, h = size(scene)
    return mktempdir() do dir
        path = save(joinpath(dir, "video.mp4"), vs)
        # <video> only supports infinite looping, so we loop forever even when a finite number is requested
        loopoption = vs.options.loop ≥ 0 ? "loop" : ""
        print(
            io,
            """<video autoplay controls $loopoption width="$w" height="$h"><source src="data:video/x-m4v;base64,""",
            base64encode(open(read, path)),
            """" type="video/mp4"></video>"""
        )
    end
end
