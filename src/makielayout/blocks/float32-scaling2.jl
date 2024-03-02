#=
New file to keep the old version around

# Notes
Conversion chain:

| from        | using             | to           | change in data                   |
| ----------- | ----------------- | ------------ | -------------------------------- |
| input       | convert_arguments | converted    | structure normalization          |
| converted   | transform_func    | transformed  | apply generic transformation     |
| transformed | float32scaling    | f32scaled    | Float32 convert + scaling        |
| f32scaled   | model             | world space  | placement in world               |
| world space | view              | view space   | to camera coordinate system      |
| view space  | projection        | clip space   | to -1..1 space (+ projection)    |
| clip space  | (viewport)        | screen space | to pixel units (OpenGL internal) |

- model, view, projection should be FLoat32 on GPU, so:
    - input, converted, transformed can be whatever type
    - f32scaled needs to be Float32
    - float32scaling needs to make f32scaled, model, view, projection float save
    - this requires translations and scaling to be extracted from at least projectionview
- when float32scaling applies convert_arguments should have been handled, so
  splitting dimensions is extra work
- -1..1 = -1e0 .. 1e0 is equally far from -floatmax and +floatmax, and also
  exponentially the same distance from floatmin and floatmax, so it should be
  a good target range to avoid frequent updates
=#

struct LinearScaling{N}
    scale::Vec{N, Float64}
    offset::Vec{N, Float64}
end

# muladd is no better than a * b + c etc
@inline apply(ls::LinearScaling, p::VecTypes) = ls(p)
@inline (ls::LinearScaling{N})(p::VecTypes{N}) where N = ls.scale .* p + ls.offset
@inline function (ls::LinearScaling{N})(p::VecTypes{M}) where {N, M}
    return ls.scale[SOneTo(M)] .* p + ls.offset[SOneTo(M)]
end

struct Float32Convert{N}
    scaling::Observable{LinearScaling{N}}
    resolution::Float32
end

function Float32Convert{N}() where N
    scaling = LinearScaling{N}(Vec{N, Float64}(1.0), Vec{N, Float64}(0.0))
    return Float32Convert{N}(Observable(scaling), 1e4)
end

# transformed space limits
function update_limits!(c::Float32Convert{N}, lims::Rect{N, Float64}) where {N}
    return update_limits!(c, minimum(lims), maximum(lims))
end
function update_limits!(c::Float32Convert{N}, mini::VecTypes{N, Float64}, maxi::VecTypes{N, Float64}) where {N}
    linscale = c.scaling[]

    low  = linscale(mini)
    high = linscale(maxi)
    @assert all(low .<= high) # TODO: Axis probably does that

    delta = high - low
    max_eps = eps(Float32) * max.(abs.(low), abs.(high))
    min_resolved = delta ./ max_eps

    # Could we have less than c.resolution floats in the given range?
    needs_update = any(min_resolved .< c.resolution)
    # Are we outside the range (floatmin, floatmax) that Float32 can resolve?
    needs_update = needs_update || any(delta .< 1e-35) || any(delta .> 1e35)

    if needs_update
        # Vec{N}(+1) = scale * maxi + offset
        # Vec{N}(-1) = scale * mini + offset
        scale  = 2.0 ./ (maxi - mini)
        offset = 1.0 .- scale * maxi
        c.scaling[] = LinearScaling(scale, offset)

        return true
    end

    return false
end

@inline apply(c::Float32Convert, p::VecTypes) = apply(c.scaling[], p)
@inline apply(c::Float32Convert, ps::AbstractArray{<: VecTypes}) = apply.((c.scaling[],), ps)