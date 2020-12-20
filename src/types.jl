abstract type AbstractCamera end

# placeholder if no camera is present
struct EmptyCamera <: AbstractCamera end

@enum RaymarchAlgorithm begin
    IsoValue # 0
    Absorption # 1
    MaximumIntensityProjection # 2
    AbsorptionRGBA # 3
    AdditiveRGBA # 4
    IndexedAbsorptionRGBA # 5
end

include("interaction/iodevices.jl")

"""
This struct provides accessible `Observable`s to monitor the events
associated with a Scene.

## Fields
$(TYPEDFIELDS)
"""
struct Events
    """
    The area of the window in pixels, as a `Rect2D`.
    """
    window_area::Node{IRect2D}
    """
    The DPI resolution of the window, as a `Float64`.
    """
    window_dpi::Node{Float64}
    """
    The state of the window (open => true, closed => false).
    """
    window_open::Node{Bool}

    """
    The pressed mouse buttons.
    Updates when a mouse button is pressed.

    See also [`ispressed`](@ref).
    """
    mousebuttons::Node{Set{Mouse.Button}}
    """
    The position of the mouse as a `NTuple{2, Float64}`.
    Updates whenever the mouse moves.
    """
    mouseposition::Node{NTuple{2, Float64}}
    """
The state of the mouse drag, represented by an enumerator of `DragEnum`.
    """
    mousedrag::Node{Mouse.DragEnum}
    """
    The direction of scroll
    """
    scroll::Node{NTuple{2, Float64}}

    """
    See also [`ispressed`](@ref).
    """
    keyboardbuttons::Node{Set{Keyboard.Button}}

    unicode_input::Node{Vector{Char}}
    dropped_files::Node{Vector{String}}
    """
    Whether the Scene window is in focus or not.
    """
    hasfocus::Node{Bool}
    entered_window::Node{Bool}
end

function Events()
    return Events(
        Node(IRect(0, 0, 0, 0)),
        Node(100.0),
        Node(false),

        Node(Set{Mouse.Button}()),
        Node((0.0, 0.0)),
        Node(Mouse.notpressed),
        Node((0.0, 0.0)),

        Node(Set{Keyboard.Button}()),

        Node(Char[]),
        Node(String[]),
        Node(false),
        Node(false),
    )
end

mutable struct Camera
    pixel_space::Node{Mat4f0}
    view::Node{Mat4f0}
    projection::Node{Mat4f0}
    projectionview::Node{Mat4f0}
    resolution::Node{Vec2f0}
    eyeposition::Node{Vec3f0}
    steering_nodes::Vector{Any}
end

"""
Holds the transformations for Scenes.

## Fields
$(TYPEDFIELDS)
"""
struct Transformation <: Transformable
    parent::RefValue{Transformable}
    translation::Node{Vec3f0}
    scale::Node{Vec3f0}
    rotation::Node{Quaternionf0}
    model::Node{Mat4f0}
    flip::Node{NTuple{3, Bool}}
    align::Node{Vec2f0}
    # data conversion node, for e.g. log / log10 etc
    transform_func::Node{Any}
    function Transformation(translation, scale, rotation, model, flip, align, transform_func)
        return new(
            RefValue{Transformable}(),
            translation, scale, rotation, model, flip, align, transform_func
        )
    end
end

struct Combined{Typ, T} <: ScenePlot{Typ}
    parent::SceneLike
    transformation::Transformation
    attributes::Attributes
    input_args::Tuple
    converted::Tuple
    plots::Vector{AbstractPlot}
end

function Base.show(io::IO, plot::Combined)
    print(io, typeof(plot))
end

parent(x::AbstractPlot) = x.parent

function func2string(func::F) where F <: Function
    string(F.name.mt.name)
end

plotkey(::Type{<: AbstractPlot{Typ}}) where Typ = Symbol(lowercase(func2string(Typ)))
plotkey(::T) where T <: AbstractPlot = plotkey(T)

plotfunc(::Type{<: AbstractPlot{Func}}) where Func = Func
plotfunc(::T) where T <: AbstractPlot = plotfunc(T)
plotfunc(f::Function) = f

func2type(x::T) where T = func2type(T)
func2type(x::Type{<: AbstractPlot}) = x
func2type(f::Function) = Combined{f}


"""
Billboard attribute to always have a primitive face the camera.
Can be used for rotation.
"""
struct Billboard end

"""
Type to indicate that an attribute will get calculated automatically
"""
struct Automatic end

"""
Singleton instance to indicate that an attribute will get calculated automatically
"""
const automatic = Automatic()


"""
`PlotSpec{P<:AbstractPlot}(args...; kwargs...)`

Object encoding positional arguments (`args`), a `NamedTuple` of attributes (`kwargs`)
as well as plot type `P` of a basic plot.
"""
struct PlotSpec{P<:AbstractPlot}
    args::Tuple
    kwargs::NamedTuple
    PlotSpec{P}(args...; kwargs...) where {P<:AbstractPlot} = new{P}(args, values(kwargs))
end

PlotSpec(args...; kwargs...) = PlotSpec{Combined{Any}}(args...; kwargs...)

Base.getindex(p::PlotSpec, i::Int) = getindex(p.args, i)
Base.getindex(p::PlotSpec, i::Symbol) = getproperty(p.kwargs, i)

to_plotspec(::Type{P}, args; kwargs...) where {P} =
    PlotSpec{P}(args...; kwargs...)

to_plotspec(::Type{P}, p::PlotSpec{S}; kwargs...) where {P, S} =
    PlotSpec{plottype(P, S)}(p.args...; p.kwargs..., kwargs...)

plottype(::PlotSpec{P}) where {P} = P
