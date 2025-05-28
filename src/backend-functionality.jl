
using ComputePipeline

add_computation!(attr::ComputeGraph, scene::Scene, symbols::Symbol...) =
    add_computation!(attr, scene::Scene, Val.(symbols)...)

add_computation!(attr::ComputeGraph, symbols::Symbol...) = add_computation!(attr, Val.(symbols)...)

function add_computation!(attr, ::Val{:gl_miter_limit})
    register_computation!(attr, [:miter_limit], [:gl_miter_limit]) do (miter,), changed, output
        return (Float32(cos(pi - miter)),)
    end
end

function add_computation!(attr, ::Val{:uniform_pattern}, ::Val{:uniform_pattern_length})
    # linestyle/pattern handling
    register_computation!(
        attr, [:linestyle], [:uniform_pattern, :uniform_pattern_length]
    ) do (linestyle,), changed, cached
        if isnothing(linestyle)
            sdf = fill(Float16(-1.0), 100) # compat for switching from linestyle to solid/nothing
            len = 1.0f0 # should be irrelevant, compat for strictly solid lines
        else
            sdf = Makie.linestyle_to_sdf(linestyle)
            len = Float32(last(linestyle) - first(linestyle))
        end
        if isnothing(cached)
            tex = ShaderAbstractions.Sampler(sdf, x_repeat = :repeat)
        else
            tex = cached.uniform_pattern
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

_xy_convert(x::AbstractArray, n) = copy(x)
_xy_convert(x::Makie.EndPoints, n) = [LinRange(extrema(x)..., n + 1);]

function add_computation!(attr, scene, ::Val{:heatmap_transform})
    # TODO: consider just using a grid of points?
    register_computation!(attr,
            [:x, :y, :image, :transform_func],
            [:x_transformed, :y_transformed]
        ) do (x, y, img, func), changed, last

        x1d = _xy_convert(x, size(img, 1))
        xps = apply_transform(func, Point2.(x1d, 0))

        y1d = _xy_convert(y, size(img, 2))
        yps = apply_transform(func, Point2.(0, y1d))

        return (xps, yps)
    end

    register_computation!(attr,
        [:x_transformed, :y_transformed, :model, :f32c],
        [:x_transformed_f32c, :y_transformed_f32c, :model_f32c]
    ) do (x, y, model, f32c), changed, cached
        # TODO: this should be done in one nice function
        # This is simplified, skipping what's commented out

        # trans, scale = decompose_translation_scale_matrix(model)
        # is_rot_free = is_translation_scale_matrix(model)
        if is_identity_transform(f32c) # && is_float_safe(scale, trans)
            m = changed.model ? Mat4f(model) : nothing
            xs = changed.x_transformed || changed.f32c ? el32convert(first.(x)) : nothing
            ys = changed.y_transformed || changed.f32c ? el32convert(last.(y)) : nothing
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
            xs = Vector{Float32}(undef, length(x))
            @inbounds for i in eachindex(xs)
                p4d = to_ndim(Point4d, to_ndim(Point3d, x[i], 0), 1)
                p4d = model * p4d
                xs[i] = f32_convert(f32c, p4d[Vec(1, 2, 3)], 1)
            end
            ys = Vector{Float32}(undef, length(y))
            @inbounds for i in eachindex(ys)
                p4d = to_ndim(Point4d, to_ndim(Point3d, y[i], 0), 1)
                p4d = model * p4d
                ys[i] = f32_convert(f32c, p4d[Vec(1, 2, 3)], 2)
            end
            m = isnothing(cached) || cached[3] != I ? Mat4f(I) : nothing
            return (xs, ys, m)
        end
    end
end

# Note: VERY similar to heatmap, but heatmap shader currently only allows 1D x, y
#       Could consider updating shader to accept matrix x, y and not always draw
#       rects but that might be a larger chunk of work...

_surf_xy_convert(x::AbstractArray, y::AbstractMatrix) = Point2.(x, y)
_surf_xy_convert(x::AbstractArray, y::AbstractVector) = Point2.(x, y')
function add_computation!(attr, scene, ::Val{:surface_transform})


    # TODO: Shouldn't this include transforming z?
    # TODO: If we're always creating a Matrix of Points the backends should just
    #       use that directly instead of going back to a x and y matrix representation
    register_computation!(attr,
            [:x, :y, :transform_func],
            [:xy_transformed]
        ) do (x, y, func), changed, last
        return (apply_transform(func, _surf_xy_convert(x, y)), )
    end

    register_computation!(attr,
        [:xy_transformed, :model, :f32c],
        [:x_transformed_f32c, :y_transformed_f32c, :model_f32c]
    ) do (xy, model, f32c), changed, cached
        # TODO: this should be done in one nice function
        # This is simplified, skipping what's commented out

        # trans, scale = decompose_translation_scale_matrix(model)
        # is_rot_free = is_translation_scale_matrix(model)
        if is_identity_transform(f32c) # && is_float_safe(scale, trans)
            m = changed.model ? Mat4f(model) : nothing
            if (changed.xy_transformed || changed.f32c) || isnothing(changed)
                xys = el32convert(xy)
                return (first.(xys), last.(xys), m)
            else
                return (nothing, nothing, m)
            end
        # elseif is_identity_transform(f32c) && !is_float_safe(scale, trans)
            # edge case: positions not float safe, model not float safe but result in float safe range
            # (this means positions -> world not float safe, but appears float safe)
        # elseif is_float_safe(scale, trans) && is_rot_free
            # fast path: can swap order of f32c and model, i.e. apply model on GPU
        # elseif is_rot_free
            # fast path: can merge model into f32c and skip applying model matrix on CPU
        else
            # TODO: avoid reallocating?
            xys = map(xy) do pos
                p4d = model * to_ndim(Point4d, to_ndim(Point3d, pos, 0), 1)
                return f32_convert(f32c, p4d[Vec(1, 2)])
            end
            m = isnothing(cached) || cached[3] != I ? Mat4f(I) : nothing
            return (first.(xys), last.(xys), m)
        end
    end
end

function add_computation!(attr, scene, ::Val{:voxel_model})
    register_computation!(attr, [:x, :y, :z, :chunk_u8, :model], [:voxel_model]) do (xs, ys, zs, chunk, model), changed, cached
        mini  = minimum.((xs, ys, zs))
        width = maximum.((xs, ys, zs)) .- mini
        m = Makie.transformationmatrix(Vec3f(mini), Vec3f(width ./ size(chunk)))
        return (Mat4f(model * m),)
    end
end

function add_computation!(attr, scene, ::Val{:uniform_model})
    register_computation!(attr, [:data_limits, :model], [:uniform_model]) do (cube, model), changed, cached
        mini = minimum(cube)
        width = widths(cube)
        trans = Makie.transformationmatrix(Vec3f(mini), Vec3f(width))
        return (Mat4f(model * trans),)
    end
end

# repacks per-element uv_transform into Vec2's for wrapping in Texture/TextureBuffer for meshscatter
function add_computation!(attr, scene, ::Val{:uv_transform_packing})
    register_computation!(attr, [:pattern_uv_transform], [:packed_uv_transform]) do (uvt,), changed, last
        if uvt isa Vector
            # 3x Vec2 should match the element order of glsl mat3x2
            output = Vector{Vec2f}(undef, 3 * length(uvt))
            for i in eachindex(uvt)
                output[3 * (i-1) + 1] = uvt[i][Vec(1, 2)]
                output[3 * (i-1) + 2] = uvt[i][Vec(3, 4)]
                output[3 * (i-1) + 3] = uvt[i][Vec(5, 6)]
            end
            return (output,)
        else
            return (uvt,)
        end
    end
end

function add_computation!(attr, scene, ::Val{:meshscatter_f32c_scale})
    # If the vertices of the scattered mesh, markersize and (if it applies) model
    # are float32 safe we should be able to just correct for any scaling from
    # float32convert in the shader, after those conversions.
    # We should also be fine as long as rotation = identity (also in model).
    # If neither is the case we would have to combine vertices with positions and
    # transform them to world space (post float32convert) on the CPU. We then can't
    # do instancing anymore, so meshscatter becomes pointless.
    space = haskey(attr, :markerspace) ? :markerspace : :space
    register_computation!(attr, [:f32c, :model, :model_f32c, :transform_marker, space], [:f32c_scale]
            ) do (f32c, model, model_f32c, transform_marker, space), changed, cached
        if Makie.is_identity_transform(f32c)
            return (Vec3f(1), )
        else
            # f32c_scale * model_f32c should reproduce f32c.scale * model if transform_marker is true
            if is_data_space(space)
                if transform_marker
                    d3 = Vec(1, 6, 11)
                    scale = f32c.scale .* model[d3] ./ model_f32c[d3]
                    return (Vec3f(scale), )
                else
                    return (Vec3f(f32c.scale), )
                end
            else
                return (Vec3f(1),)
            end
        end
    end
end

function add_computation!(attr, scene, ::Val{:pattern_uv_transform}; kwargs...)
    register_pattern_uv_transform!(attr; kwargs...)
end

function add_computation!(attr, scene, ::Val{:voxel_uv_transform})
    # TODO: can this be reused in WGLMakie?
    # TODO: Should this verify that color is a texture?
    register_computation!(attr, [:uvmap, :uv_transform], [:packed_uv_transform]) do (uvmap, uvt), changed, cached
        if !isnothing(uvt)
            return (Makie.pack_voxel_uv_transform(uvt),)
        elseif !isnothing(uvmap)
            @warn "Voxel uvmap has been deprecated in favor of the more general `uv_transform`. Use `map(lrbt -> (Point2f(lrbt[1], lrbt[3]), Vec2f(lrbt[2] - lrbt[1], lrbt[4] - lrbt[3])), uvmap)`."
            raw_uvt = Makie.uvmap_to_uv_transform(uvmap)
            converted_uvt = Makie.convert_attribute(raw_uvt, Makie.key"uv_transform"())
            return (Makie.pack_voxel_uv_transform(converted_uvt),)
        else
            return (nothing,)
        end
    end
end

# TODO: update Makie.Sampler to include lowclip, highclip, nan_color
#       and maybe also just RGBAf color types?
#       Or just move this to Makie as a more generic function?
# Note: This assumes to be called with data from ComputePipeline, i.e.
#       alpha and colorscale already applied
function sample_color(
        colormap::Vector{RGBAf}, value::Real, colorrange::VecTypes{2},
        lowclip::RGBAf = first(colormap), highclip::RGBAf = last(colormap),
        nan_color::RGBAf = RGBAf(0,0,0,0), interpolation = Makie.Linear
    )
    isnan(value) && return nan_color
    value < colorrange[1] && return lowclip
    value > colorrange[2] && return highclip
    if interpolation == Makie.Linear
        return Makie.interpolated_getindex(colormap, value, colorrange)
    else
        return Makie.nearest_getindex(colormap, value, colorrange)
    end
end

function add_computation!(attr, ::Val{:computed_color}, color_name = :scaled_color)
    register_computation!(attr,
            [color_name, :scaled_colorrange, :alpha_colormap, :nan_color, :lowclip_color, :highclip_color, :color_mapping_type],
            [:computed_color]
        ) do (color, colorrange, colormap, nan_color, lowclip, highclip, interpolation), changed, cached
        # colormapping
        if color isa AbstractArray{<:Real} || color isa Real
            output = map(color) do v
                return Makie.sample_color(colormap, v, colorrange, lowclip, highclip, nan_color, interpolation)
            end
            return (output,)
        else # Raw colors
            # Avoid update propagation if nothing changed
            !isnothing(cached) && !changed[1] && return nothing
            return (color,)
        end
    end
end


function generate_clip_planes(planes, space, output)
    if length(planes) > 8
        @warn("Only up to 8 clip planes are supported. The rest are ignored!", maxlog = 1)
    end
    if Makie.is_data_space(space)
        N = min(8, length(planes))
        for i in 1:N
            output[i] = Makie.gl_plane_format(planes[i])
        end
        for i in N+1 : 8
            output[i] = Vec4f(0, 0, 0, -1e9)
        end
    else
        fill!(output, Vec4f(0, 0, 0, -1e9))
        N = 0
    end
    return (output, Int32(N))
end

function generate_clip_planes(pvm, planes, space, output)
    planes = Makie.to_clip_space(pvm, planes)
    return generate_clip_planes(planes, space, output)
end

function generate_model_space_clip_planes(model, planes, space, output)
    modelinv = inv(model)
    @assert (length(planes) == 0) || isapprox(modelinv[4, 4], 1, atol = 1e-6)
    planes = map(planes) do plane
        origin = modelinv * to_ndim(Point4f, plane.distance * plane.normal, 1)
        normal = transpose(model) * to_ndim(Vec4f, plane.normal, 0)
        return Plane3f(origin[Vec(1,2,3)] / origin[4], normal[Vec(1,2,3)])
    end
    return generate_clip_planes(planes, space, output)
end

function add_computation!(attr, ::Val{:uniform_clip_planes}, target_space::Symbol = :world, modelname = :model_f32c)
    inputs = [:clip_planes, :space]
    target_space == :model && push!(inputs, modelname)
    target_space == :clip && push!(inputs, :projectionview)

    register_computation!(attr, inputs, [:uniform_clip_planes, :uniform_num_clip_planes]) do input, changed, last
        output = isnothing(last) ? Vector{Vec4f}(undef, 8) : last.uniform_clip_planes
        planes = input.clip_planes
        if target_space === :world
            return generate_clip_planes(planes, input.space, output)
        elseif target_space === :model
            return generate_model_space_clip_planes(getproperty(input, modelname), planes, input.space, output)
        elseif target_space === :clip
            return generate_clip_planes(input.projectionview, planes, input.space, output)
        else
            error("Unknown space $target_space.")
        end
    end
    return
end
