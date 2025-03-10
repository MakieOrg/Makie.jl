
using ComputePipeline

add_computation!(attr::ComputeGraph, scene::Scene, symbols::Symbol...) =
    add_computation!(attr, scene::Scene, Val.(symbols)...)

add_computation!(attr::ComputeGraph, symbols::Symbol...) = add_computation!(attr, Val.(symbols)...)

function add_computation!(attr, scene, ::Val{:scene_origin})
    add_input!(attr, :viewport, scene.viewport[])
    on(viewport -> Makie.update!(attr; viewport=viewport), scene.viewport) # TODO: This doesn't update immediately?
    register_computation!(attr, [:viewport], [:scene_origin]) do (viewport,), changed, last
        !changed[1] && return nothing
        new_val = Vec2f(origin(viewport[]))
        if !isnothing(last) && last[1][] == new_val
            return nothing
        else
            return (new_val,)
        end
    end
end

function add_computation!(attr, ::Val{:gl_miter_limit})
    register_computation!(attr, [:miter_limit], [:gl_miter_limit]) do (miter,), changed, output
        return (Float32(cos(pi - miter[])),)
    end
end

function add_computation!(attr, ::Val{:gl_pattern}, ::Val{:gl_pattern_length})
    # linestyle/pattern handling
    register_computation!(
        attr, [:linestyle], [:gl_pattern, :gl_pattern_length]
    ) do (linestyle,), changed, cached
        if isnothing(linestyle[])
            sdf = fill(Float16(-1.0), 100) # compat for switching from linestyle to solid/nothing
            len = 1.0f0 # should be irrelevant, compat for strictly solid lines
        else
            sdf = Makie.linestyle_to_sdf(linestyle[])
            len = Float32(last(linestyle[]) - first(linestyle[]))
        end
        if isnothing(cached)
            tex = ShaderAbstractions.Sampler(sdf, x_repeat = :repeat)
        else
            tex = cached[1][]
            ShaderAbstractions.update!(tex, sdf)
        end
        return (tex, len)
    end
end


function get_lastlen(points::Vector{Point2f}, pvm::Mat4, res::Vec2f, islines::Bool)
    !islines && zeros(Float32, length(points))
    isempty(points) && return Float32[]
    output = Vector{Float32}(undef, length(points))
    # clip -> pixel, but we can skip scene offset
    scale = Vec2f(0.5 * res[1], 0.5 * res[2])
    # position of start of first drawn line segment (TODO: deal with multiple nans at start)
    clip = pvm * to_ndim(Point4f, to_ndim(Point3f, points[2], 0.0f0), 1.0f0)
    prev = scale .* Point2f(clip) ./ clip[4]

    # calculate cumulative pixel scale length
    output[1] = 0.0f0   # duplicated point
    output[2] = 0.0f0   # start of first line segment
    output[end] = 0.0f0 # duplicated end point
    i = 3           # end of first line segment, start of second
    while i < length(points)
        if isfinite(points[i])
            clip = pvm * to_ndim(Point4f, to_ndim(Point3f, points[i], 0.0f0), 1.0f0)
            current = scale .* Point2f(clip) ./ clip[4]
            l = norm(current - prev)
            output[i] = output[i - 1] + l
            prev = current
            i += 1
        else
            # a vertex section (NaN, A, B, C) does not draw, so
            # norm(B - A) should not contribute to line length.
            # (norm(B - A) is 0 for capped lines but not for loops)
            output[i] = 0.0f0
            output[i + 1] = 0.0f0
            if i + 2 <= length(points)
                output[min(end, i + 2)] = 0.0f0
                clip = pvm * to_ndim(Point4f, to_ndim(Point3f, points[i + 2], 0.0f0), 1.0f0)
                prev = scale .* Point2f(clip) ./ clip[4]
            end
            i += 3
        end
    end
    return output
end

function add_computation!(attr, scene, ::Val{:heatmap_transform})
    xy_convert(x::AbstractArray, n) = copy(x)
    xy_convert(x::Makie.EndPoints, n) = [LinRange(extrema(x)..., n + 1);]

    # TODO: consider just using a grid of points?
    register_computation!(attr,
            [:x, :y, :image, :transform_func, :space],
            [:x_transformed, :y_transformed]
        ) do (x, y, img, func, space), changed, last

        x1d = xy_convert(x[], size(img[], 1))
        xps = apply_transform(func[], Point2.(x1d, 0), space[])

        y1d = xy_convert(y[], size(img[], 2))
        yps = apply_transform(func[], Point2.(0, y1d), space[])

        return (xps, yps)
    end

    # TODO: backends should rely on model_f32c if they use :positions_transformed_f32c
    register_computation!(attr,
        [:x_transformed, :y_transformed, :model, :f32c],
        [:x_transformed_f32c, :y_transformed_f32c, :model_f32c]
    ) do (x, y, model, f32c), changed, cached
        # TODO: this should be done in one nice function
        # This is simplified, skipping what's commented out

        # trans, scale = decompose_translation_scale_matrix(model)
        # is_rot_free = is_translation_scale_matrix(model)
        if is_identity_transform(f32c[]) # && is_float_safe(scale, trans)
            m = changed.model ? Mat4f(model[]) : nothing
            xs = changed.x_transformed || changed.f32c ? el32convert(first.(x[])) : nothing
            ys = changed.y_transformed || changed.f32c ? el32convert(last.(y[])) : nothing
            return (xs, ys, m)
        # elseif is_identity_transform(f32c) && !is_float_safe(scale, trans)
            # edge case: positions not float safe, model not float safe but result in float safe range
            # (this means positions -> world not float safe, but appears float safe)
        # elseif is_float_safe(scale, trans) && is_rot_free
            # fast path: can swap order of f32c and model, i.e. apply model on GPU
        # elseif is_rot_free
            # fast path: can merge model into f32c and skip applying model matrix on CPU
        else
            # TODO: avoid reallocating?
            xs = Vector{Float32}(undef, length(x[]))
            @inbounds for i in eachindex(output)
                p4d = to_ndim(Point4d, to_ndim(Point3d, x[][i], 0), 1)
                p4d = model[] * p4d
                xs[i] = f32_convert(f32c[], p4d[Vec(1, 2, 3)], 1)
            end
            ys = Vector{Float32}(undef, length(y[]))
            @inbounds for i in eachindex(output)
                p4d = to_ndim(Point4d, to_ndim(Point3d, y[][i], 0), 1)
                p4d = model[] * p4d
                ys[i] = f32_convert(f32c[], p4d[Vec(1, 2, 3)], 2)
            end
            m = isnothing(cached) || cached[3] != I ? Mat4f(I) : nothing
            return (xs, ys, m)
        end
    end
end