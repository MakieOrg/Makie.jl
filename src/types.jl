"""
    abstract type Transformable
This is a bit of a weird name, but all scenes and plots are transformable,
so that's what they all have in common. This might be better expressed as traits.
"""
abstract type Transformable end

abstract type AbstractPlot{Typ} <: Transformable end
abstract type AbstractScene <: Transformable end
abstract type ScenePlot{Typ} <: AbstractPlot{Typ} end
abstract type AbstractScreen <: AbstractDisplay end

const SceneLike = Union{AbstractScene, ScenePlot}

abstract type AbstractCamera end

# placeholder if no camera is present
struct EmptyCamera <: AbstractCamera end

@enum RaymarchAlgorithm begin
    IsoValue
    Absorption
    MaximumIntensityProjection
    AbsorptionRGBA
    IndexedAbsorptionRGBA
end

const RealVector{T} = AbstractVector{T} where T <: Number
const Node = Observable# For now, we use Reactive.Signal as our Node type. This might change in the future
const Point2d{T} = NTuple{2, T}
const Vec2d{T} = NTuple{2, T}
const VecTypes{N, T} = Union{StaticVector{N, T}, NTuple{N, T}}
const NVec{N} = Union{StaticVector{N}, NTuple{N, Any}}
const RGBAf0 = RGBA{Float32}
const RGBf0 = RGB{Float32}
const Vecf0{N} = Vec{N, Float32}
const Pointf0{N} = Point{N, Float32}
export Vecf0, Pointf0
const NativeFont = FreeTypeAbstraction.FTFont


include("interaction/iodevices.jl")

"""
This struct provides accessible `Observable`s to monitor the events
associated with a Scene.

## Fields
$(TYPEDFIELDS)
"""
struct Events
    """
    The area of the window in pixels, as an [`IRect2D`](@ref).
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
    The position of the mouse as a [`Point2`](@ref).
    Updates whenever the mouse moves.
    """
    mouseposition::Node{Point2d{Float64}}
    """
The state of the mouse drag, represented by an enumerator of [`DragEnum`](@ref).
    """
    mousedrag::Node{Mouse.DragEnum}
    """
    The direction of scroll
    """
    scroll::Node{Vec2d{Float64}}

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

"""
"""
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
    data_func::Node{Any}
    function Transformation(translation, scale, rotation, model, flip, align, data_func)
        return new(
            RefValue{Transformable}(),
            translation, scale, rotation, model, flip, align, data_func
        )
    end
end

"""
Main structure for holding attributes, for theming plots etc!
Will turn all values into nodes, so that they can be updated.
"""
struct Attributes
    attributes::Dict{Symbol, Node}
end
Base.broadcastable(x::AbstractScene) = Ref(x)
Base.broadcastable(x::AbstractPlot) = Ref(x)
Base.broadcastable(x::Attributes) = Ref(x)

# The rules that we use to convert values to a Node in Attributes
value_convert(x::Observables.AbstractObservable) = Observables.observe(x)
value_convert(@nospecialize(x)) = x

# We transform a tuple of observables into a Observable(tuple(values...))
function value_convert(x::NTuple{N, Union{Any, Observables.AbstractObservable}}) where N
    result = Observable(to_value.(x))
    onany((args...)-> args, x...)
    return result
end

value_convert(x::NamedTuple) = Attributes(x)

node_pairs(pair::Union{Pair, Tuple{Any, Any}}) = (pair[1] => convert(Node{Any}, value_convert(pair[2])))
node_pairs(pairs) = (node_pairs(pair) for pair in pairs)


Attributes(; kw_args...) = Attributes(Dict{Symbol, Node}(node_pairs(kw_args)))
Attributes(pairs::Pair...) = Attributes(Dict{Symbol, Node}(node_pairs(pairs)))
Attributes(pairs::AbstractVector) = Attributes(Dict{Symbol, Node}(node_pairs.(pairs)))
Attributes(pairs::Iterators.Pairs) = Attributes(collect(pairs))
Attributes(nt::NamedTuple) = Attributes(; nt...)
attributes(x::Attributes) = getfield(x, :attributes)
Base.keys(x::Attributes) = keys(x.attributes)
Base.values(x::Attributes) = values(x.attributes)
function Base.iterate(x::Attributes, state...)
    s = iterate(keys(x), state...)
    s === nothing && return nothing
    return (s[1] => x[s[1]], s[2])
end

function Base.copy(attributes::Attributes)
    result = Attributes()
    for (k, v) in attributes
        # We need to create a new Signal to have a real copy
        result[k] = copy(v)
    end
    return result
end
Base.filter(f, x::Attributes) = Attributes(filter(f, attributes(x)))
Base.empty!(x::Attributes) = (empty!(attributes(x)); x)
Base.length(x::Attributes) = length(attributes(x))

function Base.merge!(target::Attributes, args::Attributes...)
    for elem in args
        merge_attributes!(target, elem)
    end
    return target
end

Base.merge(target::Attributes, args::Attributes...) = merge!(copy(target), args...)

@generated hasfield(x::T, ::Val{key}) where {T, key} = :($(key in fieldnames(T)))

@inline function Base.getproperty(x::T, key::Symbol) where T <: Union{Attributes, Transformable}
    if hasfield(x, Val(key))
        getfield(x, key)
    else
        getindex(x, key)
    end
end

@inline function Base.setproperty!(x::T, key::Symbol, value) where T <: Union{Attributes, Transformable}
    if hasfield(x, Val(key))
        setfield!(x, key, value)
    else
        setindex!(x, value, key)
    end
end

function getindex(x::Attributes, key::Symbol)
    x = attributes(x)[key]
    # We unpack Attributes, even though, for consistency, we store them as nodes
    # this makes it easier to create nested attributes
    return x[] isa Attributes ? x[] : x
end

function setindex!(x::Attributes, value, key::Symbol)
    if haskey(x, key)
        x.attributes[key][] = value
    else
        x.attributes[key] = convert(Node{Any}, value)
    end
end

function setindex!(x::Attributes, value::Node, key::Symbol)
    if haskey(x, key)
        # error("You're trying to update an attribute node with a new node. This is not supported right now.
        # You can do this manually like this:
        # lift(val-> attributes[$key] = val, node::$(typeof(value)))
        # ")
        return x.attributes[key] = convert(Node{Any}, value)
    else
        #TODO make this error. Attributes should be sort of immutable
        return x.attributes[key] = convert(Node{Any}, value)
    end
    return x
end

function Base.show(io::IO,::MIME"text/plain", attr::Attributes)
    d = Dict()
    for p in pairs(attr.attributes)
        d[p.first] = to_value(p.second)
    end
    show(IOContext(io, :limit => false), MIME"text/plain"(), d)

end

Base.show(io::IO, attr::Attributes) = show(io, MIME"text/plain"(), attr)

struct Combined{Typ, T} <: ScenePlot{Typ}
    parent::SceneLike
    transformation::Transformation
    attributes::Attributes
    input_args::Tuple
    converted::Tuple
    plots::Vector{AbstractPlot}
end

theme(x::AbstractPlot) = x.attributes
isvisible(x) = haskey(x, :visible) && to_value(x[:visible])

#dict interface
const AttributeOrPlot = Union{AbstractPlot, Attributes}
Base.pop!(x::AttributeOrPlot, args...) = pop!(x.attributes, args...)
haskey(x::AttributeOrPlot, key) = haskey(x.attributes, key)
delete!(x::AttributeOrPlot, key) = delete!(x.attributes, key)
function get!(f::Function, x::AttributeOrPlot, key::Symbol)
    if haskey(x, key)
        return x[key]
    else
        val = f()
        x[key] = val
        return x[key]
    end
end

get!(x::AttributeOrPlot, key::Symbol, default) = get!(()-> default, x, key)
get(f::Function, x::AttributeOrPlot, key::Symbol) = haskey(x, key) ? x[key] : f()
get(x::AttributeOrPlot, key::Symbol, default) = get(()-> default, x, key)

# This is a bit confusing, since for a plot it returns the attribute from the arguments
# and not a plot for integer indexing. But, we want to treat plots as "atomic"
# so from an interface point of view, one should assume that a plot doesn't contain subplots
# Combined plots break this assumption in some way, but the way to look at it is,
# that the plots contained in a Combined plot are not subplots, but _are_ actually
# the plot itself.
getindex(plot::AbstractPlot, idx::Integer) = plot.converted[idx]
getindex(plot::AbstractPlot, idx::UnitRange{<:Integer}) = plot.converted[idx]
setindex!(plot::AbstractPlot, value, idx::Integer) = (plot.input_args[idx][] = value)
Base.length(plot::AbstractPlot) = length(plot.converted)


function getindex(x::AbstractPlot, key::Symbol)
    argnames = argument_names(typeof(x), length(x.converted))
    idx = findfirst(isequal(key), argnames)
    if idx == nothing
        return x.attributes[key]
    else
        x.converted[idx]
    end
end

function getindex(x::AttributeOrPlot, key::Symbol, key2::Symbol, rest::Symbol...)
    dict = to_value(x[key])
    dict isa Attributes || error("Trying to access $(typeof(dict)) with multiple keys: $key, $key2, $(rest)")
    dict[key2, rest...]
end

function setindex!(x::AttributeOrPlot, value, key::Symbol, key2::Symbol, rest::Symbol...)
    dict = to_value(x[key])
    dict isa Attributes || error("Trying to access $(typeof(dict)) with multiple keys: $key, $key2, $(rest)")
    dict[key2, rest...] = value
end

function setindex!(x::AbstractPlot, value, key::Symbol)
    argnames = argument_names(typeof(x), length(x.converted))
    idx = findfirst(isequal(key), argnames)
    if idx == nothing && haskey(x.attributes, key)
        return x.attributes[key][] = value
    elseif !haskey(x.attributes, key)
        x.attributes[key] = convert(Node, value)
    else
        return setindex!(x.converted[idx], value)
    end
end

function setindex!(x::AbstractPlot, value::Node, key::Symbol)
    argnames = argument_names(typeof(x), length(x.converted))
    idx = findfirst(isequal(key), argnames)
    if idx == nothing
        if haskey(x, key)
            # error("You're trying to update an attribute node with a new node. This is not supported right now.
            # You can do this manually like this:
            # lift(val-> attributes[$key] = val, node::$(typeof(value)))
            # ")
            return x.attributes[key] = value
        else
            return x.attributes[key] = value
        end
    else
        return setindex!(x.converted[idx], value)
    end
end

parent(x::AbstractPlot) = x.parent

"""
Remove `combined` from the current parent, and add it to a new subscene of the
parent scene. Returns the new parent.
"""
function detach!(x::Combined)
    p1 = parent(x)
    filter!(p-> p != x, p1.plots) # remove from parent

    p2 = parent_scene(x) # first scene that parents this node

    sub = Scene(p2, pixelarea(p2)) # subscene
    push!(x.plots, x)

    return sub
end


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
