using ComputePipeline

add_computation!(attr::ComputeGraph, scene::Scene, symbols::Symbol...) =
    add_computation!(attr, scene::Scene, Val.(symbols)...)

add_computation!(attr::ComputeGraph, symbols::Symbol...) = add_computation!(attr, Val.(symbols)...)

function add_computation!(attr, ::Val{:gl_miter_limit})
    return map!(miter -> Float32(cos(pi - miter)), attr, :miter_limit, :gl_miter_limit)
end

function add_computation!(attr, ::Val{:uniform_pattern}, ::Val{:uniform_pattern_length})
    # linestyle/pattern handling
    if attr[:linestyle][] === nothing
        add_constants!(attr, uniform_pattern = nothing, uniform_pattern_length = 1.0f0)
    else
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
    return
end


_xy_convert(x::AbstractArray, n) = copy(x)
_xy_convert(x::Makie.EndPoints, n) = [LinRange(extrema(x)..., n + 1);]

function add_computation!(attr, scene, ::Val{:heatmap_transform})
    # TODO: consider just using a grid of points?
    map!(
        attr,
        [:x, :y, :image, :transform_func],
        [:x_transformed, :y_transformed]
    ) do x, y, img, func

        x1d = _xy_convert(x, size(img, 1))
        xps = apply_transform(func, Point2.(x1d, 0))

        y1d = _xy_convert(y, size(img, 2))
        yps = apply_transform(func, Point2.(0, y1d))

        return (xps, yps)
    end

    register_model_f32c!(attr)

    return register_computation!(
        attr,
        [:x_transformed, :y_transformed, :model, :f32c, :space],
        [:x_transformed_f32c, :y_transformed_f32c]
    ) do (x, y, model, f32c, space), changed, cached
        # TODO: this should be done in one nice function
        # This is simplified, skipping what's commented out

        trans, scale = decompose_translation_scale_matrix(model)
        # is_rot_free = is_translation_scale_matrix(model)
        if !is_data_space(space) || isnothing(f32c) || (is_identity_transform(f32c) && is_float_safe(scale, trans))
            xs = changed.x_transformed || changed.f32c ? el32convert(first.(x)) : nothing
            ys = changed.y_transformed || changed.f32c ? el32convert(last.(y)) : nothing
            return (xs, ys)
        elseif false # is_identity_transform(f32c) && !is_float_safe(scale, trans)
            # edge case: positions not float safe, model not float safe but result in float safe range
            # (this means positions -> world not float safe, but appears float safe)
        elseif false # is_float_safe(scale, trans) && is_rot_free
            # fast path: can swap order of f32c and model, i.e. apply model on GPU
        elseif false # is_rot_free
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
            return (xs, ys)
        end
    end
end

# Note: VERY similar to heatmap, but heatmap shader currently only allows 1D x, y
#       Could consider updating shader to accept matrix x, y and not always draw
#       rects but that might be a larger chunk of work...

_surf_xyz_convert(x::AbstractArray, y::AbstractMatrix, z::AbstractMatrix) = Point3.(x, y, z)
_surf_xyz_convert(x::AbstractArray, y::AbstractVector, z::AbstractMatrix) = Point3.(x, y', z)
function add_computation!(attr, scene, ::Val{:surface_transform})
    # TODO: This is dropping fast paths for Range/Vector x, y w/o transform_func & f32c
    # TODO: If we're always creating a Matrix of Points GLMakie should just
    #       use that directly instead of going back to a x and y matrix representation
    map!(
        attr,
        [:x, :y, :z, :transform_func],
        :positions_transformed
    ) do x, y, z, func
        return apply_transform(func, _surf_xyz_convert(x, y, z))
    end

    register_positions_transformed_f32c!(attr)

    return map!(
        attr,
        :positions_transformed_f32c,
        [:x_transformed_f32c, :y_transformed_f32c, :z_transformed_f32c]
    ) do xyz
        return ntuple(i -> getindex.(xyz, i), Val(3))
    end
end

function add_computation!(attr, scene, ::Val{:voxel_model})
    return map!(attr, [:x, :y, :z, :chunk_u8, :model], :voxel_model) do xs, ys, zs, chunk, model
        mini = minimum.((xs, ys, zs))
        width = maximum.((xs, ys, zs)) .- mini
        m = Makie.transformationmatrix(Vec3f(mini), Vec3f(width ./ size(chunk)))
        return Mat4f(model * m)
    end
end

function add_computation!(attr, scene, ::Val{:uniform_model})
    return map!(attr, [:data_limits, :model], :uniform_model) do cube, model
        mini = minimum(cube)
        width = widths(cube)
        trans = Makie.transformationmatrix(Vec3f(mini), Vec3f(width))
        return Mat4f(model * trans)
    end
end

# repacks per-element uv_transform into Vec2's for wrapping in Texture/TextureBuffer for meshscatter
function add_computation!(attr, scene, ::Val{:uv_transform_packing})
    return map!(attr, :pattern_uv_transform, :packed_uv_transform) do uvt
        if uvt isa Vector
            # 3x Vec2 should match the element order of glsl mat3x2
            output = Vector{Vec2f}(undef, 3 * length(uvt))
            for i in eachindex(uvt)
                output[3 * (i - 1) + 1] = uvt[i][Vec(1, 2)]
                output[3 * (i - 1) + 2] = uvt[i][Vec(3, 4)]
                output[3 * (i - 1) + 3] = uvt[i][Vec(5, 6)]
            end
            return output
        else
            return uvt
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
    return map!(
        attr, [:f32c, :model, :model_f32c, :transform_marker, space], :f32c_scale
    ) do f32c, model, model_f32c, transform_marker, space
        if Makie.is_identity_transform(f32c)
            return Vec3f(1)
        else
            # f32c_scale * model_f32c should reproduce f32c.scale * model if transform_marker is true
            if is_data_space(space)
                if transform_marker
                    d3 = Vec(1, 6, 11)
                    scale = f32c.scale .* model[d3] ./ model_f32c[d3]
                    return Vec3f(scale)
                else
                    return Vec3f(f32c.scale)
                end
            else
                return Vec3f(1)
            end
        end
    end
end


function add_computation!(attr, ::Val{:disassemble_mesh}, name = :marker)
    map!(attr, name, [:vertex_position, :faces, :normal, :uv]) do mesh
        faces = decompose(GLTriangleFace, mesh)
        normals = decompose_normals(mesh)
        texturecoordinates = decompose_uv(mesh)
        positions = decompose(Point3f, mesh)
        return (positions, faces, normals, texturecoordinates)
    end
    return
end

function add_computation!(attr, scene, ::Val{:pattern_uv_transform}; kwargs...)
    return register_pattern_uv_transform!(attr; kwargs...)
end

function add_computation!(attr, scene, ::Val{:voxel_uv_transform})
    # TODO: Should this verify that color is a texture?
    return map!(attr, [:uvmap, :uv_transform], :packed_uv_transform) do uvmap, uvt
        if !isnothing(uvt)
            return pack_voxel_uv_transform(uvt)
        elseif !isnothing(uvmap)
            @warn "Voxel uvmap has been deprecated in favor of the more general `uv_transform`. Use `map(lrbt -> (Point2f(lrbt[1], lrbt[3]), Vec2f(lrbt[2] - lrbt[1], lrbt[4] - lrbt[3])), uvmap)`."
            raw_uvt = uvmap_to_uv_transform(uvmap)
            converted_uvt = convert_attribute(raw_uvt, key"uv_transform"())
            return pack_voxel_uv_transform(converted_uvt)
        else
            return nothing
        end
    end
end

# Note: This assumes to be called with data from ComputePipeline, i.e.
#       alpha and colorscale already applied
function sample_color(
        colormap::Vector{RGBAf}, value::Real, colorrange::VecTypes{2},
        lowclip::RGBAf = first(colormap), highclip::RGBAf = last(colormap),
        nan_color::RGBAf = RGBAf(0, 0, 0, 0), interpolation = Makie.continuous
    )
    isnan(value) && return nan_color
    value < colorrange[1] && return lowclip
    value > colorrange[2] && return highclip
    if interpolation === Makie.continuous
        return Makie.interpolated_getindex(colormap, value, colorrange)
    else
        return Makie.nearest_getindex(colormap, value, colorrange)
    end
end

function add_computation!(attr, ::Val{:computed_color}, color_name = :scaled_color; output_name = :computed_color, nan_color = :nan_color)
    return register_computation!(
        attr,
        [color_name, :scaled_colorrange, :alpha_colormap, nan_color, :lowclip_color, :highclip_color, :color_mapping_type],
        [output_name]
    ) do (color, colorrange, colormap, nan_color, lowclip, highclip, cmapping_type), changed, cached
        # colormapping
        if color isa AbstractArray{<:Real} || color isa Real
            output = map(color) do v
                # using linear interpolation - plot.interpolation refers to how pixels are sampled when rendering to a canvas
                # While sample_color's interpolate refers to how colors are sampled from the colormap
                return Makie.sample_color(colormap, v, colorrange, lowclip, highclip, nan_color, cmapping_type)
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
        for i in (N + 1):8
            output[i] = Vec4f(0, 0, 0, -1.0e9)
        end
    else
        fill!(output, Vec4f(0, 0, 0, -1.0e9))
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
    @assert (length(planes) == 0) || isapprox(modelinv[4, 4], 1, atol = 1.0e-6)
    planes = map(planes) do plane
        origin = modelinv * to_ndim(Point4f, plane.distance * plane.normal, 1)
        normal = transpose(model) * to_ndim(Vec4f, plane.normal, 0)
        return Plane3f(origin[Vec(1, 2, 3)] / origin[4], normal[Vec(1, 2, 3)])
    end
    return generate_clip_planes(planes, space, output)
end

function add_computation!(attr, ::Val{:uniform_clip_planes}, target_space::Symbol = :world, modelname = :model_f32c)
    inputs = [:clip_planes, :space]
    target_space == :model && push!(inputs, modelname)
    target_space == :clip && push!(inputs, :projectionview)

    register_computation!(attr, inputs, [:uniform_clip_planes, :uniform_num_clip_planes]) do input, changed, last
        # TODO
        # If we want to remove allocations
        # we need to check what has changed manually, since is_same(input, last) will always return false
        # So clip would be updated on any input change
        output = zeros(Vec4f, 8)
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

# TODO: maybe try optimizing this?
# We only need to update faces (and texture coordinates?) when the xy grid resizes
# We don't need the mesh either, if that's significant
function add_computation!(attr, ::Val{:surface_as_mesh})
    # Generate mesh from surface data and add its data to the compute graph.
    # Use that to draw surface as a mesh
    map!(
        attr,
        [:x, :y, :z, :transform_func, :invert_normals], [:positions_transformed, :faces, :texturecoordinates, :normals]
    ) do x, y, z, transform_func, invert_normals

        # (x, y, z) are generated after convert_arguments and dim_converts,
        # before apply_transform and f32c
        m = surface2mesh(x, y, z, transform_func)
        ns = normals(m)
        return coordinates(m), decompose(GLTriangleFace, m), texturecoordinates(m),
            invert_normals && !isnothing(ns) ? -ns : ns
    end

    # Get positions_transformed_f32c
    return register_positions_transformed_f32c!(attr)
end

function compute_colors!(attributes, color_name = :scaled_color)
    return Makie.add_computation!(attributes, Val(:computed_color), color_name)
end

function compute_colors(attributes, color_name = :scaled_color)
    compute_colors!(attributes, color_name)
    return attributes.computed_color[]
end
