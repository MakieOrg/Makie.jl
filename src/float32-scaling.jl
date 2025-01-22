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


@inline function f32_convert(ls::LinearScaling, p::VecTypes{N}) where N
    # TODO Point{N, Float32}(::Point{N, Int}) doesn't work
    return to_ndim(Point{N, Float32}, ls(p), 0)
end
@inline function f32_convert(ls::LinearScaling, ps::AbstractArray{<: VecTypes{N}}) where N
    return [to_ndim(Point{N, Float32}, ls(p), 0) for p in ps]
end

@inline f32_convert(ls::LinearScaling, x::Union{Real, VecTypes}, dim::Integer) = Float32(ls(x, dim))
@inline function f32_convert(ls::LinearScaling, xs::AbstractArray{<: Union{Real, VecTypes}}, dim::Integer)
    return [Float32(ls(x, dim)) for x in xs]
end

@inline function f32_convert(ls::LinearScaling, r::Rect{N}) where {N}
    mini = ls(minimum(r))
    maxi = ls(maximum(r))
    return Rect{N, Float32}(mini, maxi - mini)
end

# TODO: Should this apply in world space? Should we split world space into world64 and world32?
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
    # maybe :world?
    return space in (:data, :transformed) ? f32_convert_matrix(ls) : Mat4d(I)
end
inv_f32_convert_matrix(ls::LinearScaling, space::Symbol) = f32_convert_matrix(inv(ls), space)

is_identity_transform(ls::LinearScaling) = (ls.scale == Vec3d(1)) && (ls.offset == Vec3d(0))
is_identity_transform(ls::Nothing) = true # Float32Convert with scaling == nothing is neutral/identity

"""
    patch_model(plot)
    patch_model(plot, f32c, model)

The (default) order of operations is: 

1. `plot.transformation.transform_func`
2. `plot.transformation.model`
3. `scene.float32convert`
4. `camera.projectionview`

But we want to apply the `float32convert` before `model` so that that can be 
applied on the GPU. This function evaluates if this is possible and returns an 
adjusted `LinearScaling` Observable for `apply_transform_and_f32_conversion()`
and an adjusted `model` matrix Observable for the GPU.
"""
patch_model(@nospecialize(plot)) = patch_model(plot, f32_conversion(plot), plot.model)

function patch_model(@nospecialize(plot), f32c::Nothing, model::Observable)
    return Observable(nothing), map(Mat4f, model)
end

# TODO: How do we actually judge this well?
function is_float_safe(scale, trans)
    resolution = 1e4
    return all(abs.(scale) .> resolution .* eps.(Float32.(trans)))
end

function patch_model(@nospecialize(plot), f32c::Float32Convert, model::Observable) # Observable{Any} :(
    f32c_obs  = Observable{LinearScaling}(f32c.scaling[], ignore_equal_values = true)
    model_obs = Observable{Mat4f}(Mat4f(I), ignore_equal_values = true)

    onany(plot, f32c.scaling, model, update = true) do f32c, model
        # Neutral f32c can mean that data and model cancel each other and we 
        # still have Float32 preicsion issues in between.

        # works with rotation component as well, but drops signs on scale
        trans, scale = decompose_translation_scale_matrix(model)
        is_rot_free = is_translation_scale_matrix(model)

        if is_float_safe(scale, trans) && is_identity_transform(f32c)
            # model should not have Float32 Problems and f32c can be skipped
            # (model can have rotation here)
            f32c_obs[] = f32c
            model_obs[] = Mat4f(model)

        elseif is_float_safe(scale, trans) && is_rot_free
            # model can be applied on GPU and we can pull f32c through the 
            # model matrix. This can be merged with the option below, but 
            # keeping them separate improves compatibility with transform_marker
            scale = Vec3d(model[1, 1], model[2, 2], model[3, 3]) # existing scale is missing signs
            f32c_obs[] = Makie.LinearScaling(
                f32c.scale, ((f32c.scale .- 1) .* trans .+ f32c.offset) ./ scale
            )
            model_obs[] = model
        
        elseif is_rot_free
            # Model has no rotation so we can extract scale + translation and move 
            # it to the f32c.
            scale = Vec3d(model[1, 1], model[2, 2], model[3, 3]) # existing scale is missing signs
            f32c_obs[] = Makie.LinearScaling(
                scale * f32c.scale, f32c.scale * trans + f32c.offset
            )
            model_obs[] = Mat4f(I)

        else
            # We have float32 Problems and the model matrix contains rotation,
            # so we cannot pull f32c through it. Instead we must apply it on the
            # CPU side
            f32c_obs[] = f32c
            model_obs[] = Mat4f(I)
        end

        return
    end

    return f32c_obs, model_obs
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
function Float32Convert(resolution = 1e4)
    scaling = LinearScaling(Vec{3, Float64}(1.0), Vec{3, Float64}(0.0))
    return Float32Convert(Observable(scaling), resolution)
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
        any((abs.(low) .< f32min) .& (abs.(high) .< f32min)) ||
        any((abs.(low) .> f32max) .& (abs.(high) .> f32max))

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

@inline inv_f32_convert(c::Nothing, args...) = inv_f32_convert(c::Nothing, args)
@inline inv_f32_convert(::Nothing, x::Real) = Float64(x)
@inline inv_f32_convert(::Nothing, x::VecTypes{N}) where N = to_ndim(Point{N, Float64}, x, 0)


@inline inv_f32_convert(c::Float32Convert, x::Real) = inv(c.scaling[])(Float64(x))
@inline inv_f32_convert(c::Float32Convert, x::VecTypes{N}) where N = inv(c.scaling[])(to_ndim(Point{N, Float64}, x, 0))
@inline inv_f32_convert(c::Union{Nothing, Float32Convert}, x::AbstractArray) = inv_f32_convert.((c,), x)
@inline inv_f32_convert(ls::Float32Convert, r::Rect) = inv_f32_convert(ls.scaling[], r)
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
# f32_conversion_obs(plot::AbstractPlot) = f32_conversion_obs(parent_scene(plot))
# f32_conversion_obs(plot::AbstractPlot) = plot.attributes[:_f32_conversion]

f32_conversion(plot::AbstractPlot) = f32_conversion(parent_scene(plot))
f32_conversion(scene::Scene) = scene.float32convert

patch_model(scene::SceneLike, M::Mat4d) = patch_model(f32_conversion(scene), M)


# TODO consider mirroring f32convert to plot attributes
function apply_transform_and_f32_conversion(
        plot::AbstractPlot, f32c, data,
        space::Observable = get(plot, :space, Observable(:data)),
        model::Observable = plot[:model]
    )
    return map(
        apply_transform_and_f32_conversion, plot,
        f32c, transform_func_obs(plot), model, data, space
    )
end

# For Vector{<: Real} applying to x/y/z dimension
function apply_transform_and_f32_conversion(
        plot::AbstractPlot, f32c, data, dim::Integer,
        space::Observable = get(plot, :space, Observable(:data)),
        model::Observable = plot[:model]
    )
    return map(
        apply_transform_and_f32_conversion, plot,
        f32c, transform_func_obs(plot), model, data, dim, space
    )
end

function apply_transform_and_f32_conversion(
        float32convert::Nothing, transform_func, model::Mat4d, data, space::Symbol
    )
    return f32_convert(nothing, apply_transform(transform_func, data, space))
end

function apply_transform_and_f32_conversion(
        float32convert::LinearScaling,
        transform_func, model::Mat4d, data, space::Symbol
    )
    # TODO:
    # - Optimization: avoid intermediate arrays 
    # - Is transform_func strictly per element?

    trans, scale = decompose_translation_scale_matrix(model)
    if is_float_safe(scale, trans) && is_identity_transform(float32convert)
        # model applied on GPU, float32convert skippable
        transformed = apply_transform(transform_func, data, space)
        return f32_convert(nothing, transformed)

    elseif is_translation_scale_matrix(model)
        # translation and scale of model have been moved to f32convert, so just apply that
        transformed = apply_transform(transform_func, data, space)
        return f32_convert(float32convert, to_ndim.(Point3d, transformed, 0), space)

    else
        # model contains rotation which stops us from applying f32convert 
        # before model
        transformed = apply_transform_and_model(model, transform_func, data, space)
        return f32_convert(float32convert, transformed)
    end
end

function apply_transform_and_f32_conversion(
        float32convert::Nothing,
        transform_func, model::Mat4d, data, dim::Integer, space::Symbol
    )
    tf = space == :data ? transform_func : identity
    if dim == 1
        return Float32[apply_transform(tf, Point2(x, 0))[1] for x in data]
    elseif dim == 2
        return Float32[apply_transform(tf, Point2(0, x))[2] for x in data]
    elseif dim == 3
        return Float32[apply_transform(tf, Point3(0, 0, x))[3] for x in data]
    else
        error("The transform_func and float32 conversion can only be applied along dimensions 1, 2 or 3, not $dim")
    end
end

function apply_transform_and_f32_conversion(
        float32convert::Union{Nothing, Float32Convert, LinearScaling},
        transform_func, model::Mat4d, data, dim::Integer, space::Symbol
    )
    
    dim in (1, 2, 3) || error("The transform_func and float32 conversion can only be applied along dimensions 1, 2 or 3, not $dim")
    
    dimpoints = if dim == 1
        Point2.(data, 0)
    elseif dim == 2
        Point2.(0, data)
    else
        Point3.(0, 0, data)
    end

    trans, scale = decompose_translation_scale_matrix(model)
    if is_float_safe(scale, trans) && is_identity_transform(float32convert)
        # model applied on GPU, float32convert skippable
        transformed = apply_transform(transform_func, dimpoints, space)
        return [Float32(p[dim]) for p in transformed]
    
    elseif is_translation_scale_matrix(model)
        # translation and scale of model have been moved to f32convert, so just apply that
        transformed = apply_transform(transform_func, dimpoints, space)
        return f32_convert(float32convert, transformed, dim, space)

    else
        # model contains rotation which stops us from applying f32convert before model
        # also stops us from separating dimensions
        @error("Cannot correctly transform 1D data when a model matrix with rotation needs to be applied on the CPU.")
        transformed = apply_transform_and_model(model, transform_func, dimpoints, space)
        return f32_convert(float32convert, transformed, dim, space)
    end
end
