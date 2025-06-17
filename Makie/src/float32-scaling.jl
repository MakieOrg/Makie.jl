################################################################################
### LinearScaling
################################################################################

# For reference:
# struct LinearScaling
#     scale::Vec{3, Float64}
#     offset::Vec{3, Float64}
# end

# muladd is no better than a * b + c etc
# Don't apply Float32 here so we can still work with full precision by calling these directly
@inline (ls::LinearScaling)(x::Real, dim::Integer) = ls.scale[dim] * x + ls.offset[dim]
@inline (ls::LinearScaling)(p::VecTypes, dim::Integer) = ls.scale[dim] * p[dim] + ls.offset[dim]
@inline (ls::LinearScaling)(p::VecTypes{2}) = ls.scale[Vec(1, 2)] .* p + ls.offset[Vec(1, 2)]
@inline (ls::LinearScaling)(p::VecTypes{3}) = ls.scale .* p + ls.offset


@inline function f32_convert(ls::LinearScaling, p::VecTypes{N}) where {N}
    # TODO Point{N, Float32}(::Point{N, Int}) doesn't work
    return to_ndim(Point{N, Float32}, ls(p), 0)
end
@inline function f32_convert(ls::LinearScaling, ps::AbstractArray{<:VecTypes{N}}) where {N}
    return [to_ndim(Point{N, Float32}, ls(p), 0) for p in ps]
end

@inline f32_convert(ls::LinearScaling, x::Union{Real, VecTypes}, dim::Integer) = Float32(ls(x, dim))
@inline function f32_convert(ls::LinearScaling, xs::AbstractArray{<:Union{Real, VecTypes}}, dim::Integer)
    return [Float32(ls(x, dim)) for x in xs]
end

@inline function f32_convert(ls::LinearScaling, r::Rect{N}) where {N}
    mini = ls(minimum(r))
    maxi = ls(maximum(r))
    return Rect{N, Float32}(mini, maxi - mini)
end

# TODO: Should this apply in world space? Should we split world space into world64 and world32?
@inline function f32_convert(ls::LinearScaling, data, space::Symbol)
    return Makie.is_data_space(space) ? f32_convert(ls, data) : f32_convert(nothing, data)
end
@inline function f32_convert(ls::LinearScaling, data, dim::Integer, space::Symbol)
    return Makie.is_data_space(space) ? f32_convert(ls, data, dim) : f32_convert(nothing, data, dim)
end


Base.inv(ls::LinearScaling) = LinearScaling(1.0 ./ ls.scale, - ls.offset ./ ls.scale)


function inv_f32_scale(ls::LinearScaling, v::VecTypes{3})
    return Vec3d(v) ./ ls.scale
end

@inline function inv_f32_convert(ls::LinearScaling, r::Rect{N}) where {N}
    ils = inv(ls)
    mini = ils(Vec{N, Float64}(minimum(r)))
    maxi = ils(Vec{N, Float64}(maximum(r)))
    return Rect{N, Float64}(mini, maxi - mini)
end

# For CairoMakie
function f32_convert_matrix(ls::LinearScaling)
    scale = to_ndim(Vec3d, ls.scale, 1)
    translation = to_ndim(Vec3d, ls.offset, 0)
    return transformationmatrix(translation, scale)
end
function f32_convert_matrix(ls::LinearScaling, space::Symbol)
    return is_data_space(space) ? f32_convert_matrix(ls) : Mat4d(I)
end
inv_f32_convert_matrix(ls::LinearScaling, space::Symbol) = f32_convert_matrix(inv(ls), space)

is_identity_transform(f32c::Float32Convert) = is_identity_transform(f32c.scaling[])
is_identity_transform(ls::LinearScaling) = (ls.scale == Vec3d(1)) && (ls.offset == Vec3d(0))
is_identity_transform(ls::Nothing) = true # Float32Convert with scaling == nothing is neutral/identity

# TODO: How do we actually judge this well?
function is_float_safe(scale, trans)
    resolution = 1.0e4
    return all(abs.(scale) .> resolution .* eps.(Float32.(trans)))
end

################################################################################
### Float32Convert
################################################################################

# For reference:
# struct Float32Convert
#     scaling::Observable{LinearScaling}
#     resolution::Float32
# end

"""
    Float32Convert([resolution = 1e4])

Creates a Float32Convert which acts as an additional conversion step when
attached to a `scene` as `scene.float32convert`. The optional `resolution`
controls the minimum number of individual values that the conversion keeps
available. I.e. the conversion ensures that
`(max - min) > resolution * max(eps(min), eps(max))` whenever `update_limits!`
is called. Note that resolution must be smaller than `1 / eps(Float32)`.
"""
function Float32Convert(resolution = 1.0e4)
    scaling = LinearScaling(Vec{3, Float64}(1.0), Vec{3, Float64}(0.0))
    return Float32Convert(Observable(scaling; ignore_equal_values = true), resolution)
end

# transformed space limits
update_limits!(::Nothing, lims::Rect) = false
function update_limits!(c::Float32Convert, lims::Rect)
    mini = to_ndim(Vec3d, minimum(lims), -1)
    maxi = to_ndim(Vec3d, maximum(lims), +1)
    return update_limits!(c, mini, maxi)
end

"""
    update_limits!(c::Union{Float32Convert, Nothing}, lims::Rect)
    update_limits!(c::Union{Float32Convert, Nothing}, min::VecTypes{3, Float64}, max::VecTypes{3, Float64})

This function is used to report a limit update to `Float32Convert`. If the
conversion applied to the given limits results in a range not representable
with Float32 to high enough precision, the conversion will update. After the
update update the converted range will be -1 .. 1.

The function returns true if an update has occurred. If `Nothing` is passed, the
function always returns false.
"""
function update_limits!(c::Float32Convert, mini::VecTypes{3, Float64}, maxi::VecTypes{3, Float64})
    linscale = c.scaling[]

    low = linscale(mini)
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
        any((abs.(low) .< f32min) .& (abs.(high) .< f32min)) ||
        any((abs.(low) .> f32max) .& (abs.(high) .> f32max))

    if needs_update
        # Vec{N}(+1) = scale * maxi + offset
        # Vec{N}(-1) = scale * mini + offset
        scale = 2.0 ./ (maxi - mini)
        offset = 1.0 .- scale * maxi
        c.scaling[] = LinearScaling(scale, offset)

        return true
    end

    return false
end

@inline f32_convert(::Nothing, x::Real) = Float32(x)
@inline f32_convert(::Nothing, x::VecTypes{N}) where {N} = to_ndim(Point{N, Float32}, x, 0)
@inline f32_convert(::Nothing, x::AbstractArray) = f32_convert.(nothing, x)

@inline f32_convert(::Nothing, x::Real, dim::Integer) = Float32(x)
@inline f32_convert(::Nothing, x::VecTypes, dim::Integer) = Float32(x[dim])
@inline f32_convert(::Nothing, x::AbstractArray, dim::Integer) = f32_convert.(nothing, x, dim)

@inline f32_convert(c::Nothing, data, ::Symbol) = f32_convert(c, data)
@inline f32_convert(c::Nothing, data, dim::Integer, ::Symbol) = f32_convert(c, data, dim)

@inline f32_convert(c::Float32Convert, args...) = f32_convert(c.scaling[], args...)
@inline f32_convert(x::SceneLike, args...) = f32_convert(f32_conversion(x), args...)

@inline inv_f32_convert(c::Nothing, args...) = inv_f32_convert(c::Nothing, args)
@inline inv_f32_convert(::Nothing, x::Real) = Float64(x)
@inline inv_f32_convert(::Nothing, x::VecTypes{N}) where {N} = to_ndim(Point{N, Float64}, x, 0)


@inline inv_f32_convert(c::Float32Convert, x::Real) = inv(c.scaling[])(Float64(x))
@inline inv_f32_convert(c::Float32Convert, x::VecTypes{N}) where {N} = inv(c.scaling[])(to_ndim(Point{N, Float64}, x, 0))
@inline inv_f32_convert(c::Union{Nothing, Float32Convert}, x::AbstractArray) = inv_f32_convert.((c,), x)
@inline inv_f32_convert(ls::Float32Convert, r::Rect) = inv_f32_convert(ls.scaling[], r)
@inline inv_f32_convert(x::SceneLike, args...) = inv_f32_convert(f32_conversion(x), args...)
@inline inv_f32_convert(::Nothing, array::AbstractVector) = array

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
# f32_conversion_obs(plot::AbstractPlot) = f32_conversion_obs(parent_scene(plot))
# f32_conversion_obs(plot::AbstractPlot) = plot.attributes[:_f32_conversion]

f32_conversion(plot::AbstractPlot) = f32_conversion(parent_scene(plot))
f32_conversion(scene::Scene) = scene.float32convert

#=
If markerspace == :data in Scatter, we consider markersize, marker_offset
and quad_offset to be given in the pre-float32convert coordinate system.
Therefore we need to apply float32convert.scale (offset is already
applied in positions). Since this is only a multiplication (whose result
is in float safe units) we can apply it on the GPU

The same goes for MeshScatter based on `space == :data`. Here only
markersize is affected

Note that if `transform_marker = true` the model matrix should apply to
marker attributes. When the model matrix is not float safe it gets merged
into float32convert if possible. This is the difference between "old_f32c"
(no model) and "new_f32c" (maybe with model scale + trans) here.

Merging is only possible without rotation in model. If there is rotation
the model matrix should be applied on the CPU, but isn't yet. This will
require shader rewrites if it's not too niche to ignore.
=#
function add_f32c_scale!(uniforms, scene::Scene, plot::Plot, f32c)
    if !isnothing(scene.float32convert)
        uniforms[:f32c_scale] = lift(
            plot,
            f32c, scene.float32convert.scaling,
            plot.transform_marker, get(plot, :markerspace, plot.space)
        ) do new_f32c, old_f32c, transform_marker, markerspace
            if markerspace == :data
                return Vec3f(transform_marker ? new_f32c.scale : old_f32c.scale)
            else
                return Vec3f(1)
            end
        end
    else
        uniforms[:f32c_scale] = Vec3f(1)
    end
    return
end
