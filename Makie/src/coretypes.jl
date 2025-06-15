"""
    abstract type Transformable
This is a bit of a weird name, but all scenes and plots are transformable,
so that's what they all have in common. This might be better expressed as traits.
"""
abstract type Transformable end

abstract type AbstractPlot{Typ} <: Transformable end
abstract type AbstractScene <: Transformable end
abstract type ScenePlot{Typ} <: AbstractPlot{Typ} end


"""
Screen constructors implemented by all backends:

```julia
# Constructor aimed at showing the plot in a window.
Screen(scene::Scene; screen_config...)

# Screen to save a png/jpeg to file or io
Screen(scene::Scene, io::IO, mime; screen_config...)

# Screen that is efficient for `colorbuffer(screen, format)`
Screen(scene::Scene, format::Makie.ImageStorageFormat; screen_config...)
```

Interface implemented by all backends:

```julia
# Needs to be overload:
size(screen) # Size in pixel
empty!(screen) # empties screen state to reuse the screen, or to close it

# Optional
wait(screen) # waits as long window is open

# Provided by Makie:
push_screen!(scene, screen)
```
"""
abstract type MakieScreen <: AbstractDisplay end

const SceneLike = Union{AbstractScene, ScenePlot}

"""
Main structure for holding attributes, for theming plots etc!
Will turn all values into observables, so that they can be updated.
"""
struct Attributes
    attributes::Dict{Symbol, Any}
end

"""
    Plot{PlotFunc}(args::Tuple, kw::Dict{Symbol, Any})

Creates a Plot corresponding to the recipe function `PlotFunc`.
Each recipe defines an alias for `Plot{PlotFunc}`.
Example:
```julia
const Scatter = Plot{scatter} # defined in the scatter recipe
Plot{scatter}((1:4,), Dict{Symbol, Any}(:color => :red)) isa Scatter
# Same as:
Scatter((1:4,), Dict{Symbol, Any}(:color => :red))
```
"""
mutable struct Plot{PlotFunc, T} <: ScenePlot{PlotFunc}
    transformation::Union{Nothing, Transformable}
    # Unprocessed arguments directly from the user command e.g. `plot(args...; kw...)``
    kw::Dict{Symbol, Any}
    # Converted and processed arguments
    attributes::ComputeGraph

    plots::Vector{Plot}
    deregister_callbacks::Vector{Observables.ObserverFunction}
    parent::Union{AbstractScene, Plot}

    function Plot{Typ, T}(
            kw::Dict{Symbol, Any}, attr::ComputeGraph,
            deregister_callbacks::Vector{Observables.ObserverFunction} = Observables.ObserverFunction[]
        ) where {Typ, T}
        return new{Typ, T}(nothing, kw, attr, Plot[], deregister_callbacks)
    end
end

function Base.show(io::IO, plot::Plot)
    return print(io, typeof(plot))
end

Base.parent(x::AbstractPlot) = x.parent

struct Key{K} end
macro key_str(arg)
    return :(Key{$(QuoteNode(Symbol(arg)))})
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
Billboard() = Billboard(0.0f0)
Billboard(angle::Real) = Billboard(Float32(angle))
Billboard(angles::Vector) = Billboard(Float32.(angles))

@enum ShadingAlgorithm begin
    NoShading
    FastShading
    MultiLightShading
end

const RealArray{T, N} = AbstractArray{T, N} where {T <: Real}
const RealVector{T} = RealArray{1}
const RealMatrix{T} = RealArray{2}
const FloatType = Union{Float32, Float64}

# This could be simply a tuple or ClosedInterval
# But ClosedInterval doesn't support all operations/constructions we need
# And a plain tuple does not work, since for heatmap we need a final type that spans the corners.
# E.g. (0, 3) becomes (-0.5, 3.5) for a 3x3 heatmap, so if we have a tuple as input we need to do this calculation
# And only if it's an EndPoint type, we can be sure its already in the correct format.
struct EndPoints{T} <: AbstractVector{T}
    data::NTuple{2, T}
end
EndPoints(a::Number, b::Number) = EndPoints((a, b))
EndPoints{T}(a::Number, b::Number) where {T} = EndPoints{T}((T(a), T(b)))
Base.size(::EndPoints) = (2,)
Base.getindex(e::EndPoints, i::Int) = e.data[i]
Base.broadcasted(f, e::EndPoints) = EndPoints(f.(e.data))
Base.broadcasted(f, a::EndPoints, b) = EndPoints(f.(a.data, b))
Base.broadcasted(f, a, b::EndPoints) = EndPoints(f.(a, b.data))
Base.:(==)(a::EndPoints, b::NTuple{2}) = a.data == b
# Something we can convert to an EndPoints type
const EndPointsLike = Union{ClosedInterval, Tuple{Real, Real}}
