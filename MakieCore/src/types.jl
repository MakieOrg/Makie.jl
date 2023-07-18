
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
    attributes::Dict{Symbol, Observable}
end

struct Combined{Typ, T} <: ScenePlot{Typ}
    parent::SceneLike
    transformation::Transformable
    attributes::Attributes
    input_args::Tuple
    converted::Tuple
    plots::Vector{AbstractPlot}
    deregister_callbacks::Vector{Observables.ObserverFunction}
    function Combined{Typ, T}(
        parent::SceneLike, transformation::Transformable, attributes::Attributes,
        input_args::Tuple, converted::Tuple, plots::Vector{AbstractPlot}) where {Typ, T}
        return new(parent, transformation, attributes, input_args, converted, plots,
                   Observables.ObserverFunction[])
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
