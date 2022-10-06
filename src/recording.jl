
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
