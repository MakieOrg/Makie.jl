#=
TODO: remove this and add some cleaner documentation

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

################################################################################
### LinearScaling
################################################################################

# muladd is no better than a * b + c etc
# Don't apply Float32 here so we can still work with full precision by calling these directly
@inline (ls::LinearScaling)(x::Real, dim::Integer) = ls.scale[dim] * x + ls.offset[dim]
@inline (ls::LinearScaling)(p::VecTypes{2}) = ls.scale[Vec(1, 2)] .* p + ls.offset[Vec(1, 2)]
@inline (ls::LinearScaling)(p::VecTypes{3}) = ls.scale .* p + ls.offset


@inline function f32_convert(ls::LinearScaling, p::VecTypes{N}) where N
    # TODO Point{N, Float32}(::Point{N, Int}) doesn't work
    return to_ndim(Point{N, Float32}, ls(p), 0)
end
@inline function f32_convert(ls::LinearScaling, ps::AbstractArray{<: VecTypes{N}}) where N
    return [to_ndim(Point{N, Float32}, ls(p), 0) for p in ps]
end

@inline f32_convert(ls::LinearScaling, x::Real, dim::Integer) = Float32(ls(x, dim))
@inline function f32_convert(ls::LinearScaling, xs::AbstractArray{<: Real}, dim::Integer)
    return [Float32(ls(x, dim)) for x in xs]
end

@inline function f32_convert(ls::LinearScaling, r::Rect{N}) where {N}
    mini = ls(minimum(r))
    maxi = ls(maximum(r))
    return Rect{N, Float32}(mini, maxi - mini)
end

@inline function f32_convert(ls::LinearScaling, data, space::Symbol)
    return space in (:data, :transformed) ? f32_convert(ls, data) : f32_convert(nothing, data)
end
@inline function f32_convert(ls::LinearScaling, data, dim::Integer, space::Symbol)
    return space in (:data, :transformed) ? f32_convert(ls, data, dim) : f32_convert(nothing, data, dim)
end


Base.inv(ls::LinearScaling) = LinearScaling(1.0 ./ ls.scale, - ls.offset ./ ls.scale)


function inv_f32_scale(ls::LinearScaling, v::VecTypes{3})
    return Vec3d(v) ./ ls.scale
end

# For CairoMakie
function f32_convert_matrix(ls::LinearScaling)
    scale = to_ndim(Vec3d, ls.scale, 1)
    translation = to_ndim(Vec3d, ls.offset, 0)
    return transformationmatrix(translation, scale)
end
function f32_convert_matrix(ls::LinearScaling, space::Symbol)
    # maybe :world?
    return space in (:data, :transformed) ? f32_convert_matrix(ls) : Mat4d(I)
end
inv_f32_convert_matrix(ls::LinearScaling, space::Symbol) = f32_convert_matrix(inv(ls), space)


# returns Matrix R such that M * ls = ls * R
patch_model(::Nothing, M::Mat4d) = Mat4f(M)
function patch_model(ls::LinearScaling, M::Mat4d)
    return Mat4f(f32_convert_matrix(ls) * M * f32_convert_matrix(inv(ls)))
end


################################################################################
### Float32Convert
################################################################################


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
    max_eps = Float64(eps(Float32)) * max.(abs.(low), abs.(high))
    min_resolved = delta ./ max_eps
    f32min = Float64(floatmin(Float32)) * c.resolution
    f32max = Float64(floatmax(Float32)) / c.resolution

    # Could we have less than c.resolution floats in the given range?
    needs_update = any(min_resolved .< c.resolution)
    # Are we outside the range (floatmin, floatmax) that Float32 can resolve?
    needs_update = needs_update ||
        any(abs.(low) .< f32min .&& abs.(high) .< f32min) ||
        any(abs.(low) .> f32max .&& abs.(high) .> f32max)

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

@inline f32_convert(::Nothing, x::Real) = Float32(x)
@inline f32_convert(::Nothing, x::VecTypes{N}) where N = to_ndim(Point{N, Float32}, x, 0)
@inline f32_convert(::Nothing, x::AbstractArray) = f32_convert.(nothing, x)

@inline f32_convert(::Nothing, x::Real, dim::Integer) = Float32(x)
@inline f32_convert(::Nothing, x::VecTypes, dim::Integer) = Float32(x[dim])
@inline f32_convert(::Nothing, x::AbstractArray, dim::Integer) = f32_convert.(nothing, x, dim)

@inline f32_convert(c::Nothing, data, ::Symbol) = f32_convert(c, data)
@inline f32_convert(c::Nothing, data, dim::Integer, ::Symbol) = f32_convert(c, data, dim)

@inline f32_convert(c::Float32Convert, args...) = f32_convert(c.scaling[], args...)
@inline f32_convert(x::SceneLike, args...) = f32_convert(f32_conversion(x), args...)

@inline inv_f32_convert(c::Nothing, args...) = f32_convert(c, args...)
@inline inv_f32_convert(c::Float32Convert, x::Real) = inv(c.scaling[])(Float64(x))
@inline inv_f32_convert(c::Float32Convert, x::VecTypes{N}) where N = inv(c.scaling[])(to_ndim(Point{N, Float64}, x, 0))
@inline inv_f32_convert(c::Float32Convert, x::AbstractArray) = inv_f32_convert.((c,), x)
@inline inv_f32_convert(x::SceneLike, args...) = inv_f32_convert(f32_conversion(x), args...)

@inline inv_f32_scale(c::Nothing, v::VecTypes{3}) = Vec3d(v)
@inline inv_f32_scale(c::Float32Convert, v::VecTypes{3}) = inv_f32_scale(c.scaling[], v)
@inline inv_f32_scale(x::SceneLike, args...) = inv_f32_scale(f32_conversion(x), args...)


# For CairoMakie & project
f32_convert_matrix(::Nothing, ::Symbol) = Mat4d(I)
f32_convert_matrix(c::Float32Convert, space::Symbol) = f32_convert_matrix(c.scaling[], space)
f32_convert_matrix(x, space::Symbol) = f32_convert_matrix(f32_conversion(x), space)

inv_f32_convert_matrix(::Nothing, ::Symbol) = Mat4d(I)
inv_f32_convert_matrix(c::Float32Convert, space::Symbol) = f32_convert_matrix(inv(c.scaling[]), space)
inv_f32_convert_matrix(x, space::Symbol) = inv_f32_convert_matrix(f32_conversion(x), space)

# For GLMakie, WGLMakie, maybe RPRMakie
function f32_conversion_obs(scene::Scene)
    if isnothing(scene.float32convert)
        return Observable(nothing)
    else
        return scene.float32convert.scaling
    end
end
f32_conversion_obs(plot::AbstractPlot) = f32_conversion_obs(parent_scene(plot))

f32_conversion(plot::AbstractPlot) = f32_conversion(parent_scene(plot))
f32_conversion(scene::Scene) = scene.float32convert

# TODO consider mirroring f32convert to plot attributes
function apply_transform_and_f32_conversion(
        scene::Scene, plot::AbstractPlot, data,
        space::Observable = get(plot, :space, Observable(:data))
    )
    return map(
        apply_transform_and_f32_conversion, plot,
        f32_conversion_obs(scene), transform_func_obs(plot), data, space
    )
end

# For Vector{<: Real} applying to x/y/z dimension
function apply_transform_and_f32_conversion(
        scene::Scene, plot::AbstractPlot, data, dim::Integer,
        space::Observable = get(plot, :space, Observable(:data))
    )
    return map(
        apply_transform_and_f32_conversion, plot,
        f32_conversion_obs(scene), transform_func_obs(plot), data, dim, space
    )
end

function apply_transform_and_f32_conversion(
        float32convert::Union{Nothing, Float32Convert, LinearScaling},
        transform_func, data, space::Symbol
    )
    tf = space == :data ? transform_func : identity
    f32c = space in (:data, :transformed) ? float32convert : nothing
    # avoid intermediate arrays. TODO: Is transform_func strictly per element?
    return [Makie.f32_convert(f32c, apply_transform(tf, x)) for x in data]
end

function apply_transform_and_f32_conversion(
        float32convert::Union{Nothing, Float32Convert, LinearScaling},
        transform_func, data, dim::Integer, space::Symbol
    )
    tf = space == :data ? transform_func : identity
    f32c = space in (:data, :transformed) ? float32convert : nothing
    if dim == 1
        return [Makie.f32_convert(f32c, apply_transform(tf, Point2(x, 0))[1], dim) for x in data]
    elseif dim == 2
        return [Makie.f32_convert(f32c, apply_transform(tf, Point2(0, x))[2], dim) for x in data]
    elseif dim == 3
        return [Makie.f32_convert(f32c, apply_transform(tf, Point3(0, 0, x))[3], dim) for x in data]
    else
        error("The transform_func and float32 conversion can only be applied along dimensions 1, 2 or 3, not $dim")
    end
end
