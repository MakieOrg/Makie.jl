
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

"""
Main structure for holding attributes, for theming plots etc!
Will turn all values into observables, so that they can be updated.
"""
struct Attributes
    attributes::Dict{Symbol, Observable{Any}}

    Attributes(dict::Dict{Symbol, Observable{Any}}) = new(dict)

    function Attributes(@nospecialize(iterable_of_pairs))
        result = Dict{Symbol, Observable{Any}}()
        for (k::Symbol, v) in iterable_of_pairs
            if v isa NamedTuple
                result[k] = Attributes(v)
            else
                obs = Observable{Any}(to_value(v))
                if v isa Observables.AbstractObservable
                    on(x-> obs[] = x, v)
                end
                result[k] = obs
            end
        end
        return new(result)
    end

end

struct Combined{Typ, T} <: ScenePlot{Typ}
    parent::SceneLike
    transformation::Transformable
    attributes::Attributes
    input_args::Tuple
    converted::Tuple
    plots::Vector{AbstractPlot}
end

function Base.getproperty(x::Combined, key::Symbol)
    if hasfield(typeof(x), key)
        getfield(x, key)
    else
        getindex(x, key)
    end
end

function Base.setproperty!(x::Combined, key::Symbol, value)
    if hasfield(typeof(x), key)
        setfield!(x, key, value)
    else
        setindex!(x, value, key)
    end
end

function Base.show(io::IO, plot::Combined)
    print(io, typeof(plot))
end

Base.parent(x::AbstractPlot) = x.parent

struct Key{K} end
macro key_str(arg)
    :(Key{$(QuoteNode(Symbol(arg)))})
end
Base.broadcastable(x::Key) = (x,)

"""
Type to indicate that an attribute will get calculated automatically
"""
struct Automatic end

"""
Singleton instance to indicate that an attribute will get calculated automatically
"""
const automatic = Automatic()

abstract type Unit{T} <: Number end

"""
Unit in pixels on screen.
This one is a bit tricky, since it refers to a static attribute (pixels on screen don't change)
but since every visual is attached to a camera, the exact scale might change.
So in the end, this is just relative to some normed camera - the value on screen, depending on the camera,
will not actually sit on those pixels. Only camera that guarantees the correct mapping is the
`:pixel` camera type.
"""
struct Pixel{T} <: Unit{T}
    value::T
end

const px = Pixel(1)

"""
    Billboard([angle::Real])
    Billboard([angles::Vector{<: Real}])

Billboard attribute to always have a primitive face the camera.
Can be used for rotation.
"""
struct Billboard{T <: Union{Float32, Vector{Float32}}}
    rotation::T
end
Billboard() = Billboard(0f0)
Billboard(angle::Real) = Billboard(Float32(angle))
Billboard(angles::Vector) = Billboard(Float32.(angles))
