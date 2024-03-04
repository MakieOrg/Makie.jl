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

struct LinearScaling
    scale::Vec{3, Float64}
    offset::Vec{3, Float64}
end

# muladd is no better than a * b + c etc
@inline apply(ls::LinearScaling, x::Real, dim::Integer) = ls(x, dim)
@inline apply(ls::LinearScaling, p::VecTypes) = ls(p)
@inline (ls::LinearScaling)(x::Real, dim::Integer) = ls.scale[dim] * x + ls.offset[dim]
@inline (ls::LinearScaling)(p::VecTypes{2}) = ls.scale[Vec(1, 2)] .* p + ls.offset[Vec(1, 2)]
@inline (ls::LinearScaling)(p::VecTypes{3}) = ls.scale .* p + ls.offset

struct Float32Convert
    scaling::Observable{LinearScaling}
    resolution::Float32
end

function Float32Convert()
    scaling = LinearScaling(Vec{3, Float64}(1.0), Vec{3, Float64}(0.0))
    return Float32Convert(Observable(scaling), 1e4)
end

# transformed space limits
update_limits!(::Nothing, lims::Rect) = false
function update_limits!(c::Float32Convert, lims::Rect)
    mini = to_ndim(Vec3d, minimum(lims), -1)
    maxi = to_ndim(Vec3d, maximum(lims), +1)
    return update_limits!(c, mini, maxi)
end
function update_limits!(c::Float32Convert, mini::VecTypes{3, Float64}, maxi::VecTypes{3, Float64})
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

@inline apply(::Nothing, x) = x
@inline apply(c::Float32Convert, p::VecTypes) = apply(c.scaling[], p)
@inline apply(c::Float32Convert, ps::AbstractArray{<: VecTypes}) = apply.((c.scaling[],), ps)

@inline apply(::Nothing, x, dim) = x
@inline apply(c::Float32Convert, x::Real, dim::Integer) = apply(c.scaling[], x, dim)
@inline function apply(c::Float32Convert, xs::AbstractArray{<: Real}, dim::Integer)
    return apply.((c.scaling[],), xs, dim)
end

@inline function apply(c::Float32Convert, r::T) where {T <: Rect}
    mini = apply(c.scaling[], minimum(r))
    maxi = apply(c.scaling[], maximum(r))
    return T(mini, maxi - mini)
end

f32_convert_matrix(::Nothing, ::Symbol) = Mat4d(I)
function f32_convert_matrix(c::Float32Convert, space::Symbol)
    if space in (:data, :transformed) # maybe :world?
        linear = c.scaling[]
        scale = to_ndim(Vec3d, linear.scale, 1)
        translation = to_ndim(Vec3d, linear.offset, 0)
        return transformationmatrix(translation, scale)
    else
        return Mat4d(I)
    end
end