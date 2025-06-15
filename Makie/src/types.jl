abstract type AbstractCamera end
abstract type Block end
abstract type AbstractAxis <: Block end

# placeholder if no camera is present
struct EmptyCamera <: AbstractCamera end
get_space(::EmptyCamera) = :clip

@enum RaymarchAlgorithm begin
    IsoValue # 0
    Absorption # 1
    MaximumIntensityProjection # 2
    AbsorptionRGBA # 3
    AdditiveRGBA # 4
    IndexedAbsorptionRGBA # 5
end

const ComputePlots = Union{Scatter, Lines, LineSegments, Image, Heatmap, Mesh, Surface, Voxels, Volume, MeshScatter, Text}

include("interaction/iodevices.jl")

"""
    enum TickState

Identifies the source of a tick:
- `BackendTick`: A tick used for backend purposes which is not present in `event.tick`.
- `UnknownTickState`: A tick from an uncategorized source (e.g. initialization of Events).
- `PausedRenderTick`: A tick from a paused renderloop.
- `SkippedRenderTick`: A tick from a running renderloop where the previous image was reused.
- `RegularRenderTick`: A tick from a running renderloop where a new image was produced.
- `OneTimeRenderTick`: A tick from a call to `colorbuffer`, i.e. an image request from `save` or `record`.
"""
@enum TickState begin
    BackendTick
    UnknownTickState # GLMakie only allows states > UnknownTickState
    PausedRenderTick
    SkippedRenderTick
    RegularRenderTick
    OneTimeRenderTick
end

"""
    struct TickState

Contains information for tick events:
- `state::TickState`: identifies what caused the tick (see Makie.TickState)
- `count::Int64`: number of ticks produced since the start of rendering (display or record)
- `time::Float64`: time that has passed since the first tick in seconds
- `delta_time`: time that has passed since the last tick in seconds
"""
struct Tick
    state::TickState    # flag for the type of tick event
    count::Int64        # number of ticks since start
    time::Float64       # time since scene initialization
    delta_time::Float64 # time since last tick
end
Tick() = Tick(UnknownTickState, 0, 0.0, 0.0)


"""
This struct provides accessible `Observable`s to monitor the events
associated with a Scene.

Functions that act on an `Observable` must return `Consume()` if the function
consumes an event. When an event is consumed it does
not trigger other observer functions. The order in which functions are executed
can be controlled via the `priority` keyword (default 0) in `on`.

Example:
```julia
on(events(scene).mousebutton, priority = 20) do event
    if is_correct_event(event)
        do_something()
        return Consume()
    end
    return
end
```

## Fields
$(TYPEDFIELDS)
"""
struct Events
    """
    The area of the window in pixels, as a `Rect2`.
    """
    window_area::Observable{Rect2i}
    """
    The DPI resolution of the window, as a `Float64`.
    """
    window_dpi::Observable{Float64}
    """
    The state of the window (open => true, closed => false).
    """
    window_open::Observable{Bool}

    """
    Most recently triggered `MouseButtonEvent`. Contains the relevant
    `event.button` and `event.action` (press/release)

    See also [`ispressed`](@ref).
    """
    mousebutton::Observable{MouseButtonEvent}
    """
    A Set of all currently pressed mousebuttons.
    """
    mousebuttonstate::Set{Mouse.Button}
    """
    The position of the mouse as a `NTuple{2, Float64}`.
    Updates once per event poll/frame.
    """
    mouseposition::Observable{NTuple{2, Float64}} # why no Vec2?
    """
    The direction of scroll
    """
    scroll::Observable{NTuple{2, Float64}} # why no Vec2?

    """
    Most recently triggered `KeyEvent`. Contains the relevant `event.key` and
    `event.action` (press/repeat/release)

    See also [`ispressed`](@ref).
    """
    keyboardbutton::Observable{KeyEvent}
    """
    Contains all currently pressed keys.
    """
    keyboardstate::Set{Keyboard.Button}

    """
    Contains the last typed character.
    """
    unicode_input::Observable{Char}
    """
    Contains a list of filepaths to files dragged into the scene.
    """
    dropped_files::Observable{Vector{String}}
    """
    Whether the Scene window is in focus or not.
    """
    hasfocus::Observable{Bool}
    """
    Whether the mouse is inside the window or not.
    """
    entered_window::Observable{Bool}

    """
    A `tick` is triggered whenever a new frame is requested, i.e. during normal
    rendering (even if the renderloop is paused) or when an image is produced
    for `save` or `record`. A Tick contains:
    - `state` which identifies what caused the tick (see Makie.TickState)
    - `count` which increments with every tick
    - `time` which is the total time since the screen has been created
    - `delta_time` which is the time since the last frame
    """
    tick::Observable{Tick}
end

function Base.show(io::IO, events::Events)
    println(io, "Events:")
    fields = propertynames(events)
    maxlen = maximum(length ∘ string, fields)
    for field in propertynames(events)
        pad = maxlen - length(string(field)) + 1
        println(io, "  $field:", " "^pad, to_value(getproperty(events, field)))
    end
    return
end

function Events()
    events = Events(
        Observable(Recti(0, 0, 0, 0)),
        Observable(100.0),
        Observable(false),

        Observable(MouseButtonEvent(Mouse.none, Mouse.release)),
        Set{Mouse.Button}(),
        Observable((0.0, 0.0)),
        Observable((0.0, 0.0)),

        Observable(KeyEvent(Keyboard.unknown, Keyboard.release)),
        Set{Keyboard.Button}(),
        Observable('\0'),
        Observable(String[]),
        Observable(false),
        Observable(false),
        Observable(Tick())
    )

    connect_states!(events)
    return events
end

function connect_states!(e::Events)
    on(e.mousebutton, priority = typemax(Int)) do event
        set = e.mousebuttonstate
        if event.action == Mouse.press
            push!(set, event.button)
        elseif event.action == Mouse.release
            delete!(set, event.button)
        else
            error("Unrecognized Keyboard action $(event.action)")
        end
        # This never consumes because it just keeps track of the state
        return Consume(false)
    end

    on(e.keyboardbutton, priority = typemax(Int)) do event
        set = e.keyboardstate
        if event.key != Keyboard.unknown
            if event.action == Keyboard.press
                push!(set, event.key)
            elseif event.action == Keyboard.release
                delete!(set, event.key)
            elseif event.action == Keyboard.repeat
                # set should already have the key
            else
                error("Unrecognized Keyboard action $(event.action)")
            end
        end
        # This never consumes because it just keeps track of the state
        return Consume(false)
    end
    return
end

# Compat only
function Base.getproperty(e::Events, field::Symbol)
    if field === :mousebuttons
        error("`events.mousebuttons` is deprecated. Use `events.mousebutton` to react to `MouseButtonEvent`s instead.")
    elseif field === :keyboardbuttons
        error("`events.keyboardbuttons` is deprecated. Use `events.keyboardbutton` to react to `KeyEvent`s instead.")
    elseif field === :mousedrag
        error("`events.mousedrag` is deprecated. Use `events.mousebutton` or a mouse state machine (`addmouseevents!`) instead.")
    else
        return getfield(e, field)
    end
end

function Base.empty!(events::Events)
    for field in fieldnames(Events)
        field in (:mousebuttonstate, :keyboardstate) && continue
        obs = getfield(events, field)
        for (prio, f) in obs.listeners
            prio == typemax(Int) && continue
            off(obs, f)
        end
    end
    return
end

abstract type BooleanOperator end

"""
    IsPressedInputType

Union containing possible input types for `ispressed`.
"""
const IsPressedInputType = Union{Bool, BooleanOperator, Mouse.Button, Keyboard.Button, Set, Vector, Tuple}

"""
    Camera(pixel_area)

Struct to hold all relevant matrices and additional parameters, to let backends
apply camera based transformations.

## Fields
$(TYPEDFIELDS)
"""
struct Camera
    """
    projection used to convert pixel to device units
    """
    pixel_space::Observable{Mat4d}

    """
    View matrix is usually used to rotate, scale and translate the scene
    """
    view::Observable{Mat4d}

    """
    Projection matrix is used for any perspective transformation
    """
    projection::Observable{Mat4d}

    """
    just projection * view
    """
    projectionview::Observable{Mat4d}

    """
    resolution of the canvas this camera draws to
    """
    resolution::Observable{Vec2f}

    """
    Direction in which the camera looks.
    """
    view_direction::Observable{Vec3f}
    """
    Eye position of the camera, used for e.g. ray tracing.
    """
    eyeposition::Observable{Vec3f}
    """
    Up direction of the current camera (e.g. Vec3f(0, 1, 0) for 2d)
    """
    upvector::Observable{Vec3f}

    """
    To make camera interactive, steering observables are connected to the different matrices.
    We need to keep track of them, so, that we can connect and disconnect them.
    """
    steering_nodes::Vector{ObserverFunction}
end


"""
Holds the transformations for Scenes.
## Fields
$(TYPEDFIELDS)
"""
struct Transformation <: Transformable
    parent::RefValue{Transformation}
    translation::Observable{Vec3d}
    scale::Observable{Vec3d}
    rotation::Observable{Quaternionf}
    origin::Observable{Vec3d}
    model::Observable{Mat4d}
    parent_model::Observable{Mat4d}
    # data conversion observable, for e.g. log / log10 etc
    transform_func::Observable{Any}

    function Transformation(translation, scale, rotation, transform_func, origin = Vec3d(0))
        translation_o = convert(Observable{Vec3d}, translation)
        scale_o = convert(Observable{Vec3d}, scale)
        rotation_o = convert(Observable{Quaternionf}, rotation)
        origin_o = convert(Observable{Vec3d}, origin)
        parent_model = Observable(Mat4d(I))
        model = map(translation_o, scale_o, rotation_o, origin_o, parent_model) do t, s, r, o, p
            # Order: translation * scale * rotation
            return p * transformationmatrix(t + o - s .* (r * o), s, r)
        end
        transform_func_o = convert(Observable{Any}, transform_func)
        return new(
            RefValue{Transformation}(),
            translation_o, scale_o, rotation_o, origin_o, model, parent_model, transform_func_o
        )
    end
end

function Transformation(
        transform_func = identity;
        scale = Vec3d(1),
        translation = Vec3d(0),
        rotation = Quaternionf(0, 0, 0, 1),
        origin = Vec3d(0)
    )
    return Transformation(translation, scale, rotation, transform_func, origin)
end

function Transformation(
        parent::Transformable;
        scale = Vec3d(1),
        translation = Vec3d(0),
        rotation = Quaternionf(0, 0, 0, 1),
        origin = Vec3d(0),
        transform_func = nothing
    )
    connect_func = isnothing(transform_func)
    trans = isnothing(transform_func) ? identity : transform_func

    trans = Transformation(
        translation,
        scale,
        rotation,
        trans,
        origin
    )
    connect!(transformation(parent), trans; connect_func = connect_func)
    return trans
end

function Base.show(io::IO, ::MIME"text/plain", t::Transformation)
    println(io, "Transformation()")
    println(io, "          parent = ", isassigned(t.parent) ? "Transformation(…)" : "#undef")
    println(io, "     translation = ", t.translation[])
    println(io, "           scale = ", t.scale[])
    println(io, "        rotation = ", t.rotation[])
    println(io, "          origin = ", t.origin[])
    println(io, "           model = ", t.model[])
    return println(io, "  transform_func = ", t.transform_func[])
end

struct ScalarOrVector{T}
    sv::Union{T, Vector{T}}
end

Base.convert(::Type{<:ScalarOrVector}, v::AbstractVector{T}) where {T} = ScalarOrVector{T}(collect(v))
Base.convert(::Type{<:ScalarOrVector}, x::T) where {T} = ScalarOrVector{T}(x)
Base.convert(::Type{<:ScalarOrVector{T}}, x::ScalarOrVector{T}) where {T} = x
Base.:(==)(a::ScalarOrVector, b::ScalarOrVector) = a.sv == b.sv
function collect_vector(sv::ScalarOrVector, n::Int)
    return if sv.sv isa Vector
        if length(sv.sv) != n
            error("Requested collected vector with $n elements, contained vector had $(length(sv.sv)) elements.")
        end
        sv.sv
    else
        fill(sv.sv, n)
    end
end

"""
    GlyphExtent

Store information about the bounding box of a single glyph.
"""
struct GlyphExtent
    ink_bounding_box::Rect2f
    ascender::Float32
    descender::Float32
    hadvance::Float32
end

function GlyphExtent(font, char)
    extent = get_extent(font, char)
    ink_bb = FreeTypeAbstraction.inkboundingbox(extent)
    ascender = FreeTypeAbstraction.ascender(font)
    descender = FreeTypeAbstraction.descender(font)
    hadvance = FreeTypeAbstraction.hadvance(extent)

    return GlyphExtent(ink_bb, ascender, descender, hadvance)
end

function GlyphExtent(texchar::TeXChar)
    l = MathTeXEngine.leftinkbound(texchar)
    r = MathTeXEngine.rightinkbound(texchar)
    b = MathTeXEngine.bottominkbound(texchar)
    t = MathTeXEngine.topinkbound(texchar)
    ascender = MathTeXEngine.ascender(texchar)
    descender = MathTeXEngine.descender(texchar)
    hadvance = MathTeXEngine.hadvance(texchar)

    return GlyphExtent(Rect2f((l, b), (r - l, t - b)), ascender, descender, hadvance)
end

"""
    GlyphCollection

Stores information about the glyphs in a string that had a layout calculated for them.
"""
struct GlyphCollection
    glyphs::Vector{UInt64}
    fonts::ScalarOrVector{FTFont}
    origins::Vector{Point3f}
    extents::Vector{GlyphExtent}
    scales::ScalarOrVector{Vec2f}
    rotations::ScalarOrVector{Quaternionf}
    colors::ScalarOrVector{RGBAf}
    strokecolors::ScalarOrVector{RGBAf}
    strokewidths::ScalarOrVector{Float32}

    function GlyphCollection(
            glyphs, fonts, origins, extents, scales, rotations,
            colors, strokecolors, strokewidths
        )

        n = length(glyphs)
        # @assert length(fonts) == n
        @assert length(origins) == n
        @assert length(extents) == n
        @assert attr_broadcast_length(scales) in (n, 1) "$(typeof(scales)) has length $(length(scales)) but should have $n or 1"
        @assert attr_broadcast_length(rotations) in (n, 1)
        @assert attr_broadcast_length(colors) in (n, 1)
        @assert strokewidths isa Number || strokewidths isa AbstractVector{<:Number}
        return new(
            glyphs,
            to_font(fonts),
            origins,
            extents,
            ScalarOrVector{Vec{2, Float32}}(to_2d_scale(scales)),
            to_rotation(rotations),
            to_color(colors),
            to_color(strokecolors),
            to_linewidth(strokewidths)
        )
    end
end

function Base.:(==)(a::GlyphCollection, b::GlyphCollection)
    return a.glyphs == b.glyphs &&
        a.fonts == b.fonts &&
        a.origins == b.origins &&
        a.extents == b.extents &&
        a.scales == b.scales &&
        a.rotations == b.rotations &&
        a.colors == b.colors &&
        a.strokecolors == b.strokecolors &&
        a.strokewidths == b.strokewidths
end


# The color type we ideally use for most color attributes
const RGBColors = Union{RGBAf, Vector{RGBAf}, Vector{Float32}}

const LogFunctions = Union{typeof(log10), typeof(log2), typeof(log)}

"""
    ReversibleScale

Custom scale struct, taking a forward and inverse arbitrary scale function.

## Fields
$(TYPEDFIELDS)
"""
struct ReversibleScale{F <: Function, I <: Function, T <: AbstractInterval} <: Function
    """
    forward transformation (e.g. `log10`)
    """
    forward::F
    """
    inverse transformation (e.g. `exp10` for `log10` such that inverse ∘ forward ≡ identity)
    """
    inverse::I
    """
    default limits (optional)
    """
    limits::NTuple{2, Float32}
    """
    valid limits interval (optional)
    """
    interval::T
    name::Symbol
    function ReversibleScale(forward, inverse = Automatic(); limits = (0.0f0, 10.0f0), interval = (-Inf32, Inf32), name = Symbol(forward))
        inverse isa Automatic && (inverse = inverse_transform(forward))
        isnothing(inverse) && throw(
            ArgumentError(
                "Cannot determine inverse transform: you can use `ReversibleScale($(forward), inverse($(forward)))` instead."
            )
        )
        interval isa AbstractInterval || (interval = OpenInterval(Float32.(interval)...))

        lft, rgt = limits = Tuple(Float32.(limits))

        Id = inverse ∘ forward
        lft ≈ Id(lft) || throw(ArgumentError("Invalid inverse transform: $lft !≈ $(Id(lft))"))
        rgt ≈ Id(rgt) || throw(ArgumentError("Invalid inverse transform: $rgt !≈ $(Id(rgt))"))

        return new{typeof(forward), typeof(inverse), typeof(interval)}(forward, inverse, limits, interval, name)
    end
end

(s::ReversibleScale)(args...) = s.forward(args...) # functor
Base.show(io::IO, s::ReversibleScale) = print(io, "ReversibleScale($(s.name))")
Base.show(io::IO, ::MIME"text/plain", s::ReversibleScale) = print(io, "ReversibleScale($(s.name))")

# Float32 conversions
struct LinearScaling
    scale::Vec{3, Float64}
    offset::Vec{3, Float64}
end
struct Float32Convert
    scaling::Observable{LinearScaling}
    resolution::Float32
end
