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
