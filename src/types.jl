# this is a bit of a weird name, but all scenes and plots are transformable
# so that's what they all have in common. This might be better expressed as traits
abstract type Transformable end

abstract type AbstractPlot{Typ} <: Transformable end
abstract type AbstractScene <: Transformable end
abstract type ScenePlot{Typ} <: AbstractPlot{Typ} end

const SceneLike = Union{AbstractScene, ScenePlot}
# const Attributes = Dict{Symbol, Any}

abstract type AbstractCamera end

# placeholder if no camera is present
struct EmptyCamera <: AbstractCamera end

@enum RaymarchAlgorithm IsoValue Absorption MaximumIntensityProjection AbsorptionRGBA IndexedAbsorptionRGBA

const RealVector{T} = AbstractVector{T} where T <: Number

const Node = Observable

const Rect{N, T} = HyperRectangle{N, T}
const Rect2D{T} = HyperRectangle{2, T}
const FRect2D = Rect2D{Float32}

const Rect3D{T} = Rect{3, T}
const FRect3D = Rect3D{Float32}
const IRect3D = Rect3D{Int}


const IRect2D = Rect2D{Int}

const Point2d{T} = NTuple{2, T}
const Vec2d{T} = NTuple{2, T}
const VecTypes{N, T} = Union{StaticVector{N, T}, NTuple{N, T}}
const NVec{N} = Union{StaticVector{N}, NTuple{N, Any}}
const RGBAf0 = RGBA{Float32}
const RGBf0 = RGB{Float32}


abstract type AbstractScreen <: AbstractDisplay end


function IRect(x, y, w, h)
    HyperRectangle{2, Int}(Vec(round(Int, x), round(Int, y)), Vec(round(Int, w), round(Int, h)))
end
function IRect(xy::VecTypes, w, h)
    IRect(xy[1], xy[2], w, h)
end
function IRect(x, y, wh::VecTypes)
    IRect(x, y, wh[1], wh[2])
end
function IRect(xy::VecTypes, wh::VecTypes)
    IRect(xy[1], xy[2], wh[1], wh[2])
end

function IRect(xy::NamedTuple{(:x, :y)}, wh::NamedTuple{(:width, :height)})
    IRect(xy.x, xy.y, wh.width, wh.height)
end

function positive_widths(rect::HyperRectangle{N, T}) where {N, T}
    mini, maxi = minimum(rect), maximum(rect)
    realmin = min.(mini, maxi)
    realmax = max.(mini, maxi)
    HyperRectangle{N, T}(realmin, realmax .- realmin)
end

function FRect(x, y, w, h)
    HyperRectangle{2, Float32}(Vec2f0(x, y), Vec2f0(w, h))
end
function FRect(r::SimpleRectangle)
    FRect(r.x, r.y, r.w, r.h)
end
function FRect(r::Rect)
    FRect(minimum(r), widths(r))
end
function FRect(xy::VecTypes, w, h)
    FRect(xy[1], xy[2], w, h)
end
function FRect(x, y, wh::VecTypes)
    FRect(x, y, wh[1], wh[2])
end
function FRect(xy::VecTypes, wh::VecTypes)
    FRect(xy[1], xy[2], wh[1], wh[2])
end

function FRect3D(x::Tuple{Tuple{<: Number, <: Number}, Tuple{<: Number, <: Number}})
    FRect3D(Vec3f0(x[1]..., 0), Vec3f0(x[2]..., 0))
end
function FRect3D(x::Tuple{Tuple{<: Number, <: Number, <: Number}, Tuple{<: Number, <: Number, <: Number}})
    FRect3D(Vec3f0(x[1]...), Vec3f0(x[2]...))
end

function FRect3D(x::Rect2D)
    FRect3D(Vec3f0(minimum(x)..., 0), Vec3f0(widths(x)..., 0.0))
end
# For now, we use Reactive.Signal as our Node type. This might change in the future
const Node = Observable

include("interaction/iodevices.jl")

struct Events
    window_area::Node{IRect2D}
    window_dpi::Node{Float64}
    window_open::Node{Bool}

    mousebuttons::Node{Set{Mouse.Button}}
    mouseposition::Node{Point2d{Float64}}
    mousedrag::Node{Mouse.DragEnum}
    scroll::Node{Vec2d{Float64}}

    keyboardbuttons::Node{Set{Keyboard.Button}}

    unicode_input::Node{Vector{Char}}
    dropped_files::Node{Vector{String}}
    hasfocus::Node{Bool}
    entered_window::Node{Bool}
end

function Events()
    Events(
        node(:window_area, IRect(0, 0, 0, 0)),
        node(:window_dpi, 100.0),
        node(:window_open, false),

        node(:mousebuttons, Set{Mouse.Button}()),
        node(:mouseposition, (0.0, 0.0)),
        node(:mousedrag, Mouse.notpressed),
        node(:scroll, (0.0, 0.0)),

        node(:keyboardbuttons, Set{Keyboard.Button}()),

        node(:unicode_input, Char[]),
        node(:dropped_files, String[]),
        node(:hasfocus, false),
        node(:entered_window, false),
    )
end

mutable struct Camera
    view::Node{Mat4f0}
    projection::Node{Mat4f0}
    projectionview::Node{Mat4f0}
    resolution::Node{Vec2f0}
    eyeposition::Node{Vec3f0}
    steering_nodes::Vector{Any}
end

struct Transformation <: Transformable
    translation::Node{Vec3f0}
    scale::Node{Vec3f0}
    rotation::Node{Quaternionf0}
    model::Node{Mat4f0}
    flip::Node{NTuple{3, Bool}}
    align::Node{Vec2f0}
    func::Node{Any}
end

#
struct Attributes
    attributes::Dict{Symbol, Node}
end
Base.broadcastable(x::AbstractScene) = Ref(x)
Base.broadcastable(x::AbstractPlot) = Ref(x)
Base.broadcastable(x::Attributes) = Ref(x)


value_convert(@nospecialize(x)) = x
value_convert(x::NamedTuple) = Attributes(x)
value_convert(x::Observables.AbstractObservable) = Observables.observe(x)


node_pairs(pair::Union{Pair, Tuple{Any, Any}}) = (pair[1] => to_node(Any, value_convert(pair[2]), pair[1]))
node_pairs(pairs) = (node_pairs(pair) for pair in pairs)
Base.convert(::Type{<: Node}, x) = Node(x)
Base.convert(::Type{T}, x::T) where T <: Node = x

Attributes(; kw_args...) = Attributes(Dict{Symbol, Node}(node_pairs(kw_args)))
Attributes(pairs::Pair...) = Attributes(Dict{Symbol, Node}(node_pairs(pairs)))
Attributes(pairs::AbstractVector) = Attributes(Dict{Symbol, Node}(node_pairs.(pairs)))
Attributes(pairs::Iterators.Pairs) = Attributes(collect(pairs))
Attributes(nt::NamedTuple) = Attributes(; nt...)

Base.keys(x::Attributes) = keys(x.attributes)
Base.values(x::Attributes) = values(x.attributes)
Base.iterate(x::Attributes) = iterate(x.attributes)
Base.iterate(x::Attributes, state) = iterate(x.attributes, state)
Base.copy(x::Attributes) = Attributes(copy(x.attributes))
Base.filter(f, x::Attributes) = Attributes(filter(f, x.attributes))
Base.empty!(x::Attributes) = (empty!(x.attributes); x)
Base.length(x::Attributes) = length(x.attributes)

function Base.merge!(x::Attributes...)
    ret = x[1]
    for i in 2:length(x)
        merge_attributes_doublebang!(x[i], ret)
    end
    ret
end
Base.merge(x::Attributes...) = merge!(copy.(x)...)

@generated hasfield(x::T, ::Val{key}) where {T, key} = :($(key in fieldnames(T)))

@inline function Base.getproperty(x::T, key::Symbol) where T <: Transformable
    if hasfield(x, Val(key))
        getfield(x, key)
    else
        getindex(x, key)
    end
end
@inline function Base.setproperty!(x::T, key::Symbol, value) where T <: Transformable
    if hasfield(x, Val(key))
        setfield!(x, key, value)
    else
        setindex!(x, value, key)
    end
end


function getindex(x::Attributes, key::Symbol)
    x = x.attributes[key]
    to_value(x) isa Attributes ? to_value(x) : x
end
function setindex!(x::Attributes, value, key::Symbol)
    if haskey(x, key)
        x.attributes[key][] = value
    else
        x.attributes[key] = to_node(Any, value, key)
    end
end
function setindex!(x::Attributes, value::Node, key::Symbol)
    if haskey(x, key)
        # error("You're trying to update an attribute node with a new node. This is not supported right now.
        # You can do this manually like this:
        # lift(val-> attributes[$key] = val, node::$(typeof(value)))
        # ")
        return x.attributes[key] = value
    else
        #TODO make this error. Attributes should be sort of immutable
        return x.attributes[key] = value
    end
end

# There are only two types of plots. Atomic Plots, which are the most basic building blocks.
# Then you can combine them to form more complex plots in the form of a Combined plot.
struct Atomic{Typ, T} <: AbstractPlot{Typ}
    parent::SceneLike
    transformation::Transformation
    attributes::Attributes
    input_args::Tuple # we push new values to this
    converted::Tuple # these are the arguments we actually work with in the backend/recipe
end

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
# the plot itself.
getindex(plot::AbstractPlot, idx::Integer) = plot.converted[idx]
getindex(plot::AbstractPlot, idx::UnitRange{<:Integer}) = plot.converted[idx]
setindex!(plot::AbstractPlot, value, idx::Integer) = (plot.input_args[idx][] = value)



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
        x.attributes[key] = to_node(value)
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

basetype(::Type{<: Combined}) = Combined
basetype(::Type{<: Atomic}) = Atomic




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

    sub
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


const Vecf0{N} = Vec{N, Float32}
const Pointf0{N} = Point{N, Float32}
export Vecf0, Pointf0
const NativeFont = Vector{Ptr{FreeType.FT_FaceRec}}
