using Makie.ComputePipeline

################################################################################
### Util, delete later
################################################################################

function missing_uniforms(robj, inputs, input2name)
    @info "Verifying uniforms"
    inputset = Set([get(input2name, k, k) for k in inputs])
    uniformset = union(
        keys(robj.vertexarray.program.uniformloc),
        Symbol.(collect(keys(robj.vertexarray.buffers))),
        [:visible]
    )
    # Set by other means
    skip = [
        :resolution, :projection, :projectionview, :view, :upvector, :eyeposition, :view_direction,
        :objectid,
        :ambient, :light_color, :light_direction
    ]
    for k in setdiff(uniformset, inputset)
        k in skip && continue
        printstyled("Missing uniform $k\n", color = :red)
    end
    for k in setdiff(inputset, uniformset)
        k in [:indices, :instances, :fxaa] && continue
        printstyled("Discard input $k\n", color = :yellow)
    end
end

################################################################################
### Generic (more or less)
################################################################################

function update_robjs!(robj, args::NamedTuple, changed::NamedTuple, gl_names::Dict{Symbol,Symbol})
    for name in keys(args)
        changed[name] || continue
        value = args[name]
        gl_name = get(gl_names, name, name)
        if name === :visible
            robj.visible = value
        elseif gl_name === :indices
            if robj.vertexarray.indices isa GLAbstraction.GPUArray
                GLAbstraction.update!(robj.vertexarray.indices, value)
            else
                robj.vertexarray.indices = value
            end
        elseif gl_name === :instances
            # TODO: Is this risky since postprocessors are variable?
            robj.postrenderfunction.n_instances[] = value
        elseif haskey(robj.uniforms, gl_name)
            if robj.uniforms[gl_name] isa GLAbstraction.GPUArray
                GLAbstraction.update!(robj.uniforms[gl_name], value)
            else
                robj.uniforms[gl_name] = value
            end
        elseif haskey(robj.vertexarray.buffers, string(gl_name))
            GLAbstraction.update!(robj.vertexarray.buffers[string(gl_name)], value)
        else
            # println("Could not update ", name)
        end
    end
end

function add_color_attributes!(data, color, colormap, colornorm)
    needs_mapping = !(colornorm isa Nothing)
    _color = needs_mapping ? nothing : color
    intensity = needs_mapping ? color : nothing

    data[:color_map] = needs_mapping ? colormap : nothing
    if _color isa Matrix{RGBAf} || _color isa ShaderAbstractions.Sampler
        data[:image] = _color
        data[:color] = RGBAf(1,1,1,1)
    else
        data[:color] = _color
    end
    data[:intensity] = intensity
    data[:color_norm] = colornorm
    return nothing
end

function add_color_attributes_lines!(data, color, colormap, colornorm)
    needs_mapping = !(colornorm isa Nothing)
    data[:color_map] = needs_mapping ? colormap : nothing
    data[:color] = color
    data[:color_norm] = colornorm
    return nothing
end

function add_camera_attributes!(data, screen, camera, space)
    # TODO: This doesn't allow dynamic space, markerspace (regression)
    #       Are we ok with this?
    # Make sure to protect these from cleanup in destroy!(renderobject)
    data[:resolution] = Makie.get_ppu_resolution(camera, screen.px_per_unit[])
    data[:projection] = Makie.get_projection(camera, space)
    data[:projectionview] = Makie.get_projectionview(camera, space)
    data[:view] = Makie.get_view(camera, space)
    data[:upvector] = camera.upvector
    data[:eyeposition] = camera.eyeposition
    data[:view_direction] = camera.view_direction
    return data
end

# For use with register!(...)

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


function generate_clip_planes!(attr, scene, target_space::Symbol = :world, modelname = :model_f32c)
    inputs = [:clip_planes, :space]
    target_space == :model && push!(inputs, modelname)
    if target_space == :clip
        if !haskey(attr, :projectionview)
            # is projectionview enough to trigger on scene resize in all cases?
            add_input!(attr, :projectionview, scene.camera.projectionview)
        end
        push!(inputs, :projectionview)
    end

    register_computation!(attr, inputs, [:gl_clip_planes, :gl_num_clip_planes]) do input, changed, last
        output = isnothing(last) ?  Vector{Vec4f}(undef, 8) : last.gl_clip_planes
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

# TODO: handle these on the scene level once and reuse them
function add_light_attributes!(screen, scene, data, attr)
    haskey(attr, :shading) || return

    shading = attr[:shading][]
    if shading == FastShading

        dirlight = Makie.get_directional_light(scene)

        if isnothing(dirlight)
            data[:light_direction] = Observable(Vec3f(0))
            data[:light_color] = Observable(RGBf(0,0,0))
        else
            data[:light_direction] = if dirlight.camera_relative
                map(data[:view], dirlight.direction) do view, dir
                    return normalize(inv(view[Vec(1,2,3), Vec(1,2,3)]) * dir)
                end
            else
                map(normalize, dirlight.direction)
            end

            data[:light_color] = dirlight.color
        end

        ambientlight = Makie.get_ambient_light(scene)
        if !isnothing(ambientlight)
            data[:ambient] = ambientlight.color
        else
            data[:ambient] = Observable(RGBf(0,0,0))
        end

    elseif shading == MultiLightShading

        handle_lights(data, screen, scene.lights)

    end
end

function generic_robj_setup(screen::Screen, scene::Scene, plot::Plot)
    attr = plot.args[1]::ComputeGraph
    return attr
end

function register_robj!(constructor, screen, scene, plot, inputs, uniforms, input2glname)
    attr = plot.args[1]

    # These must always be there!
    push!(uniforms, :gl_clip_planes, :gl_num_clip_planes, :depth_shift, :visible, :fxaa)
    push!(input2glname, :gl_clip_planes => :clip_planes, :gl_num_clip_planes => :num_clip_planes)

    merged_inputs = [inputs; uniforms;]
    @assert allunique(merged_inputs) "Duplicate robj inputs detected in $merged_inputs."

    register_computation!(attr, merged_inputs, [:gl_renderobject]) do args, changed, last
        if isnothing(last)
            # Generate complex defaults
            # TODO: Should we add an initializer in ComputePipeline to extract this?
            # That would simplify this code and remove attr, uniforms from the enclosed variables here
            _robj = constructor(screen, scene, attr, args, uniforms, input2glname)
        else
            _robj = last.gl_renderobject
            update_robjs!(_robj, args, changed, input2glname)
        end
        screen.requires_update = true
        return (_robj,)
    end

    robj = attr[:gl_renderobject][]
    screen.cache2plot[robj.id] = plot
    screen.cache[objectid(plot)] = robj
    push!(screen, scene, robj)

    # TODO: for debugging/checking uniforms, remove later
    # missing_uniforms(robj, [inputs; uniforms;], input2glname)

    return robj
end

################################################################################
### Scatter
################################################################################

function assemble_scatter_robj(screen::Screen, scene::Scene, attr, args, uniforms, input2glname)
    camera = scene.camera
    space = attr[:space][]
    markerspace = attr[:markerspace][]
    fast_pixel = attr[:marker][] isa FastPixel
    pspace = fast_pixel ? space : markerspace
    colormap = args.alpha_colormap
    color = args.scaled_color
    colornorm = args.scaled_colorrange
    marker_shape = args.sdf_marker_shape
    distancefield = marker_shape === Cint(DISTANCEFIELD) ? get_texture!(screen.glscreen, args.atlas) : nothing

    data = Dict(
        :preprojection => Makie.get_preprojection(camera, space, markerspace),
        :distancefield => distancefield,
        :px_per_unit => screen.px_per_unit,   # technically not const?
        :ssao => false,                       # shader compilation const
        :transparency => attr[:transparency][],
        :overdraw => attr[:overdraw][],
        :shape => marker_shape,
    )

    add_color_attributes!(data, color, colormap, colornorm)
    add_camera_attributes!(data, screen, camera, pspace)

    # Correct the name mapping
    if !isnothing(get(data, :intensity, nothing))
        input2glname[:scaled_color] = :intensity
    end
    if !isnothing(get(data, :image, nothing))
        input2glname[:scaled_color] = :image
    end
    for name in uniforms
        data[get(input2glname, name, name)] = args[name]
    end
    if fast_pixel
        return draw_pixel_scatter(screen, data[:position], data)
    else
        # pass nothing to avoid going into image generating functions
        return draw_scatter(screen, (nothing, data[:position]), data)
    end
end


function depthsort!(positions, depth_vals, indices, pvm)
    pvm24 = pvm[Vec(3, 4), Vec(1, 2, 3, 4)] # only calculate zw
    resize!(depth_vals, length(positions))
    resize!(indices, length(positions))
    map!(depth_vals, positions) do p
        p4d = pvm24 * to_ndim(Point4f, to_ndim(Point3f, p, 0.0f0), 1.0f0)
        return p4d[1] / p4d[2]
    end
    sortperm!(indices, depth_vals; rev=true)
    indices .-= 1
    return depth_vals, indices
end


function draw_atomic(screen::Screen, scene::Scene, plot::Scatter)
    attr = generic_robj_setup(screen, scene, plot)

    # We register the screen under a unique name. If the screen closes
    # Any computation that depens on screen gets removed
    atlas = gl_texture_atlas()
    if haskey(attr, :atlas)
        # TODO: Do we need to update this?
        Makie.update!(attr, atlas = atlas)
    else
        add_input!(attr, :atlas, atlas)
    end

    if attr[:depthsorting][]
        # is projectionview enough to trigger on scene resize in all cases?
        haskey(attr, :projectionview) || add_input!(attr, :projectionview, scene.camera.projectionview)

        register_computation!(attr,
            [:positions_transformed_f32c, :projectionview, :space, :model_f32c],
            [:gl_depth_cache, :gl_indices]
        ) do (pos, _, space, model), changed, last
            pvm = Makie.space_to_clip(scene.camera, space) * model
            depth_vals = isnothing(last) ? Float32[] : last.gl_depth_cache
            indices = isnothing(last) ? Cuint[] : last.gl_indices
            return depthsort!(pos[], depth_vals, indices, pvm)
        end
    else
        register_computation!(attr, [:positions_transformed_f32c], [:gl_indices]) do (ps,), changed, last
            return (length(ps),)
        end
    end

    register_computation!(attr, [:positions_transformed_f32c], [:gl_len]) do (ps,), changed, last
        return (Int32(length(ps)),)
    end

    inputs = [
        # Special
        :atlas,
        # Needs explicit handling
        :alpha_colormap, :scaled_color, :scaled_colorrange,
        :sdf_marker_shape
    ]
    if attr[:marker][] isa FastPixel
        register_computation!(attr, [:markerspace], [:gl_markerspace]) do (space,), changed, last
            space == :pixel && return (Int32(0),)
            space == :data  && return (Int32(1),)
            return error("Unsupported markerspace for FastPixel marker: $space")
        end

        register_computation!(attr, [:marker], [:sdf_marker_shape]) do (marker,), changed, last
            return (marker.marker_type,)
        end

        uniforms = [
            :positions_transformed_f32c,
            :gl_markerspace, :quad_scale, :model_f32c,
            :lowclip_color, :highclip_color, :nan_color, :gl_indices, :gl_len
            # TODO: this should've gotten marker_offset when we separated marker_offset from quad_offset
        ]

    else
        Makie.all_marker_computations!(attr, 2048, 64)

        # Simple forwards
        uniforms = [
            :positions_transformed_f32c,
            :sdf_uv, :quad_scale, :quad_offset,
            :image, :lowclip_color, :highclip_color, :nan_color,
            :strokecolor, :strokewidth, :glowcolor, :glowwidth,
            :model_f32c, :rotation, :transform_marker,
            :gl_indices, :gl_len, :marker_offset
        ]
    end

    generate_clip_planes!(attr, scene)

    # TODO:
    # - rotation -> billboard missing
    # - px_per_unit (that can update dynamically via record, right?)
    # - intensity_convert

    # To take the human error out of the bookkeeping of two lists
    # Could also consider using this in computation since Dict lookups are
    # O(1) and only takes ~4ns
    input2glname = Dict{Symbol, Symbol}(
        :positions_transformed_f32c => :position,
        :alpha_colormap => :color_map,
        :scaled_colorrange => :color_norm,
        :scaled_color => :color,
        :sdf_marker_shape => :shape,
        :sdf_uv => :uv_offset_width,
        :gl_markerspace => :markerspace,
        :quad_scale => :scale, :gl_image => :image,
        :strokecolor => :stroke_color, :strokewidth => :stroke_width,
        :glowcolor => :glow_color, :glowwidth => :glow_width,
        :model_f32c => :model, :transform_marker => :scale_primitive,
        :lowclip_color => :lowclip, :highclip_color => :highclip,
        :gl_indices => :indices, :gl_len => :len
    )

    robj = register_robj!(assemble_scatter_robj, screen, scene, plot, inputs, uniforms, input2glname)

    return robj
end

################################################################################
### MeshScatter
################################################################################

function assemble_meshscatter_robj(screen::Screen, scene::Scene, attr, args, uniforms, input2glname)
    camera = scene.camera

    data = Dict{Symbol, Any}(
        # Compile time variable
        :transparency => attr[:transparency][],
        :overdraw => attr[:overdraw][],
        :shading => attr[:shading][],
        :ssao => attr[:ssao][],
    )

    if args.packed_uv_transform isa Vector{Vec2f}
        data[:uv_transform] = TextureBuffer(screen.glscreen, args.packed_uv_transform)
    else
        data[:uv_transform] = args.packed_uv_transform
    end

    add_color_attributes!(data, args.scaled_color, args.alpha_colormap, args.scaled_colorrange)
    add_camera_attributes!(data, screen, camera, attr[:space][])
    add_light_attributes!(screen, scene, data, attr)

    # Correct the name mapping
    if !isnothing(get(data, :intensity, nothing))
        input2glname[:scaled_color] = :intensity
    end
    if !isnothing(get(data, :image, nothing))
        input2glname[:scaled_color] = :image
    end
    if !isnothing(get(data, :color, nothing))
        input2glname[:scaled_color] = :color
    end

    for name in uniforms
        data[get(input2glname, name, name)] = args[name]
    end

    marker = attr[:marker][]
    positions = data[:position]
    return draw_mesh_particle(screen, (marker, positions), data)
end

function draw_atomic(screen::Screen, scene::Scene, plot::MeshScatter)
    attr = generic_robj_setup(screen, scene, plot)

    generate_clip_planes!(attr, scene)
    Makie.add_computation!(attr, scene, Val(:pattern_uv_transform))
    Makie.add_computation!(attr, scene, Val(:uv_transform_packing), :pattern_uv_transform)
    Makie.add_computation!(attr, scene, Val(:meshscatter_f32c_scale))
    Makie.register_world_normalmatrix!(attr)

    register_computation!(attr, [:positions_transformed_f32c], [:instances, :gl_len]) do (pos, ), changed, cached
        return (length(pos), Int32(length(pos)))
    end

    inputs = [
        # Special
        :space,
        # Needs explicit handling
        :alpha_colormap, :scaled_color, :scaled_colorrange,
        :packed_uv_transform,
    ]
    uniforms = [
        :positions_transformed_f32c, :markersize, :rotation, :f32c_scale, :instances,
        :lowclip_color, :highclip_color, :nan_color, :matcap,
        :fetch_pixel, :model_f32c,
        :diffuse, :specular, :shininess, :backlight, :world_normalmatrix,
        :gl_len, :transform_marker
    ]

    input2glname = Dict{Symbol, Symbol}(
        :positions_transformed_f32c => :position, :markersize => :scale,
        :packed_uv_transform => :uv_transform,
        :alpha_colormap => :color_map, :scaled_colorrange => :color_norm,
        :scaled_color => :color, :lowclip_color => :lowclip, :highclip_color => :highclip,
        :model_f32c => :model, :gl_len => :len, :transform_marker => :scale_primitive,
    )

    robj = register_robj!(assemble_meshscatter_robj, screen, scene, plot, inputs, uniforms, input2glname)

    return robj
end

################################################################################
### Lines
################################################################################

function assemble_lines_robj(screen::Screen, scene::Scene, attr, args, uniforms, input2glname)

    positions = args[1] # changes name, so we use positional
    linestyle = attr[:linestyle][]
    camera = scene.camera

    data = Dict{Symbol, Any}(
        :fast => isnothing(linestyle),
        # :fast == true removes pattern from the shader so we don't need
        #               to worry about this
        :vertex => positions, # Needs to be set before draw_lines()
        :transparency => attr[:transparency][],
        :overdraw => attr[:overdraw][],
        :ssao => false,
        :debug => attr[:debug][],
    )

    add_camera_attributes!(data, screen, camera, args.space)
    add_color_attributes_lines!(data, args.scaled_color, args.alpha_colormap, args.scaled_colorrange)

    if !isnothing(get(data, :intensity, nothing))
        input2glname[:scaled_color] = :intensity
    end

    # Transfer over uniforms
    for name in uniforms
        data[get(input2glname, name, name)] = args[name]
    end

    return draw_lines(screen, positions, data)
end

# Observables removed and adjusted to fit Compute Pipeline
# Observables removed and adjusted to fit Compute Pipeline
function generate_indices(ps, indices=Cuint[], valid=Float32[])
    empty!(indices)
    resize!(valid, length(ps))

    # can't draw a line with less than 2 points so there are no indices to generate
    # and valid is irrelevant
    if length(ps) < 2
        valid .= 0 # just in case random data is problematic
        return (indices, valid)
    end

    sizehint!(indices, length(ps) + 2)

    # This loop identifies sections of line points A B C D E F bounded by
    # the start/end of the list ps or by NaN and generates indices for them:
    # if A == F (loop):      E A B C D E F B 0
    # if A != F (no loop):   0 A B C D E F 0
    # where 0 is NaN
    # It marks vertices as invalid (0) if they are NaN, valid (1) if they
    # are part of a continuous line section, or as ghost edges (2) used to
    # cleanly close a loop. The shader detects successive vertices with
    # 1-2-0 and 0-2-1 validity to avoid drawing ghost segments (E-A from
    # 0-E-A-B and F-B from E-F-B-0 which would duplicate E-F and A-B)

    last_start_pos = eltype(ps)(NaN)
    last_start_idx = -1

    for (i, p) in enumerate(ps)
        not_nan = isfinite(p)
        valid[i] = not_nan

        if not_nan
            if last_start_idx == -1
                # place nan before section of line vertices
                # (or duplicate ps[1])
                push!(indices, max(1, i - 1))
                last_start_idx = length(indices) + 1
                last_start_pos = p
            end
            # add line vertex
            push!(indices, i)

            # case loop (loop index set, loop contains at least 3 segments, start == end)
        elseif (last_start_idx != -1) &&
            (length(indices) - last_start_idx > 2) &&
            (ps[max(1, i - 1)] ≈ last_start_pos)

            # add ghost vertices before an after the loop to cleanly connect line
            indices[last_start_idx - 1] = max(1, i - 2)
            push!(indices, indices[last_start_idx + 1], i)
            # mark the ghost vertices
            valid[i - 2] = 2
            valid[indices[last_start_idx + 1]] = 2
            # not in loop anymore
            last_start_idx = -1

            # non-looping line end
        elseif (last_start_idx != -1) # effective "last index not NaN"
            push!(indices, i)
            last_start_idx = -1
            # else: we don't need to push repeated NaNs
        end
    end

    # treat ps[end+1] as NaN to correctly finish the line
    if (last_start_idx != -1) && (length(indices) - last_start_idx > 2) && (ps[end] ≈ last_start_pos)
        indices[last_start_idx - 1] = length(ps) - 1
        push!(indices, indices[last_start_idx + 1])
        valid[end - 1] = 2
        valid[indices[last_start_idx + 1]] = 2
    elseif last_start_idx != -1
        push!(indices, length(ps))
    end

    indices .-= Cuint(1)

    return (indices, valid)
end

function generate_indices(positions::NamedTuple, changed::NamedTuple, cached)
    if isnothing(cached)
        indices = Cuint[]
        valid = Float32[]
    else
        indices = empty!(cached[1])
        valid = cached[2]
    end
    ps = positions[1]
    return generate_indices(ps, indices, valid)
end

function draw_atomic(screen::Screen, scene::Scene, plot::Lines)
    attr = generic_robj_setup(screen, scene, plot)

    Makie.add_computation!(attr, :gl_miter_limit)
    Makie.add_computation!(attr, :gl_pattern, :gl_pattern_length)

    haskey(attr, :px_per_unit) || add_input!(attr, :px_per_unit, screen.px_per_unit)
    haskey(attr, :viewport) || add_input!(attr, :viewport, scene.viewport)
    register_computation!(
        attr, [:px_per_unit, :viewport], [:scene_origin, :resolution]
    ) do (ppu, viewport), changed, output
        return (Vec2f(ppu * origin(viewport)), Vec2f(ppu * widths(viewport)))
    end

    # position calculations for patterned lines
    # is projectionview enough to trigger on scene resize in all cases?
    haskey(attr, :projectionview) || add_input!(attr, :projectionview, scene.camera.projectionview)
    register_computation!(
        attr, [:projectionview, :model, :f32c, :space], [:gl_pvm32]
    ) do (_, model, f32c, space), changed, output
        pvm = Makie.space_to_clip(scene.camera, space) *
            Makie.f32_convert_matrix(f32c, space) * model
        return (pvm,)
    end
    register_computation!(
        attr, [:gl_pvm32, :positions_transformed], [:gl_projected_positions]
    ) do (pvm32, positions), changed, last
        output = isnothing(last) ? Point4f[] : last.gl_projected_positions
        resize!(output, length(positions))
        map!(output, positions) do pos
            return pvm32 * to_ndim(Point4d, to_ndim(Point3d, pos, 0.0), 1.0)
        end
        return (output,)
    end

    haskey(attr, :debug) || add_input!(attr, :debug, false)

    generate_clip_planes!(attr, scene, :clip) # requires projectionview

    if isnothing(plot.linestyle[])
        positions = :positions_transformed_f32c
    else
        positions = :gl_projected_positions
    end

    # Derived vertex attributes
    register_computation!(generate_indices, attr, [positions], [:gl_indices, :gl_valid_vertex])
    register_computation!(attr, [:gl_indices], [:gl_total_length]) do (indices,), changed, cached
        return (Int32(length(indices) - 2),)
    end
    register_computation!(attr, [positions, :resolution], [:gl_last_length]) do (pos, res), changed, cached
        return (sumlengths(pos, res),)
    end

    inputs = [
        # relevant to creation time decisions
        positions,
        :space,
        :scaled_color, :alpha_colormap, :scaled_colorrange
    ]
        # uniforms getting passed through
    uniforms = [
        :gl_indices, :gl_valid_vertex, :gl_total_length, :gl_last_length,
        :gl_pattern, :gl_pattern_length, :linecap, :gl_miter_limit, :joinstyle, :linewidth,
        :scene_origin, :px_per_unit, :model_f32c,
        :lowclip_color, :highclip_color, :nan_color, :debug
    ]

    input2glname = Dict(
        positions => :vertex, :gl_indices => :indices, :gl_valid_vertex => :valid_vertex,
        :gl_total_length => :total_length, :gl_last_length => :lastlen,
        :gl_miter_limit => :miter_limit, :linewidth => :thickness,
        :gl_pattern => :pattern, :gl_pattern_length => :pattern_length,
        :scaled_color => :color, :alpha_colormap => :color_map, :scaled_colorrange => :color_norm,
        :model_f32c => :model,
        :lowclip_color => :lowclip, :highclip_color => :highclip,
    )

    robj = register_robj!(assemble_lines_robj, screen, scene, plot, inputs, uniforms, input2glname)

    return robj
end

################################################################################
### LineSegments
################################################################################

function assemble_linesegments_robj(screen::Screen, scene::Scene, attr, args, uniforms, input2glname)
    linestyle = attr[:linestyle][]
    camera = scene.camera

    data = Dict{Symbol, Any}(
        :transparency => attr[:transparency][],
        :overdraw => attr[:overdraw][],
        :debug => attr[:debug][],
        :ssao => false,
    )

    add_camera_attributes!(data, screen, camera, args.space)
    add_color_attributes_lines!(data, args.scaled_color, args.alpha_colormap, args.scaled_colorrange)

    if !isnothing(get(data, :intensity, nothing))
        input2glname[:scaled_color] = :intensity
    end

    # Transfer over uniforms
    for name in uniforms
        data[get(input2glname, name, name)] = args[name]
    end

    # Here we do need to be careful with pattern because :fast does not
    # exist as a compile time switch
    # Running this after add_uniforms overwrites
    if isnothing(linestyle)
        data[:pattern] = nothing
    end
    return draw_linesegments(screen, data[:vertex], data) # TODO: extract positions
end

function draw_atomic(screen::Screen, scene::Scene, plot::LineSegments)
    attr = generic_robj_setup(screen, scene, plot)

    haskey(attr, :px_per_unit) || add_input!(attr, :px_per_unit, screen.px_per_unit)
    haskey(attr, :viewport) || add_input!(attr, :viewport, scene.viewport)
    register_computation!(
        attr, [:px_per_unit, :viewport], [:scene_origin]
    ) do (ppu, viewport), changed, output
        return (Vec2f(ppu * origin(viewport)),)
    end

    # linestyle/pattern handling
    Makie.add_computation!(attr, :gl_pattern, :gl_pattern_length)
    haskey(attr, :debug) || add_input!(attr, :debug, false)
    haskey(attr, :projectionview) || add_input!(attr, :projectionview, scene.camera.projectionview)
    generate_clip_planes!(attr, scene)

    register_computation!(attr, [:positions_transformed_f32c], [:indices]) do (positions,), changed, cached
        return (length(positions),)
    end

    inputs = [
        :space,
        :scaled_color, :alpha_colormap, :scaled_colorrange
    ]
    uniforms = [
        :positions_transformed_f32c, :indices,
        :gl_pattern, :gl_pattern_length, :linecap, :synched_linewidth,
        :scene_origin, :px_per_unit, :model_f32c,
        :lowclip_color, :highclip_color, :nan_color, :debug
    ]

    input2glname = Dict{Symbol, Symbol}(
        :positions_transformed_f32c => :vertex,
        :synched_linewidth => :thickness, :model_f32c => :model,
        :gl_pattern => :pattern, :gl_pattern_length => :pattern_length,
        :scaled_color => :color, :alpha_colormap => :color_map, :scaled_colorrange => :color_norm,
        :lowclip_color => :lowclip, :highclip_color => :highclip,
    )

    robj = register_robj!(assemble_linesegments_robj, screen, scene, plot, inputs, uniforms, input2glname)

    return robj
end

################################################################################
### Image
################################################################################

function assemble_image_robj(screen::Screen, scene::Scene, attr, args, uniforms, input2glname)
    r = Rect2f(0,0,1,1)

    data = Dict{Symbol, Any}(
        :faces => decompose(GLTriangleFace, r),
        :texturecoordinates => decompose_uv(r),

        # Compile time variable/constants
        :picking_mode => "#define PICKING_INDEX_FROM_UV",
        :transparency => attr[:transparency][],
        :overdraw => attr[:overdraw][],
        :ssao => false,
    )

    camera = scene.camera
    add_camera_attributes!(data, screen, camera, args.space)

    colormap = args.alpha_colormap
    color = args.scaled_color
    colornorm = args.scaled_colorrange
    add_color_attributes!(data, color, colormap, colornorm)

    # always use :image with specific interpolation settings, so remove:
    pop!(data, :image, nothing)
    pop!(data, :intensity, nothing)

    # Correct the name mapping
    input2glname[:scaled_color] = :image
    interp = attr[:interpolate][] ? :linear : :nearest
    data[:image] = Texture(screen.glscreen, color; minfilter = interp)

    # Transfer over uniforms
    for name in uniforms
        data[get(input2glname, name, name)] = args[name]
    end

    return draw_mesh(screen, data)
end


function draw_atomic(screen::Screen, scene::Scene, plot::Image)
    return draw_atomic_as_image(screen, scene, plot)
end

function draw_atomic_as_image(screen::Screen, scene::Scene, plot)
    attr = generic_robj_setup(screen, scene, plot)

    generate_clip_planes!(attr, scene)

    inputs = [
        # Special
        :space,
        # Needs explicit handling
        :alpha_colormap, :scaled_color, :scaled_colorrange,
    ]
    uniforms = [
        :positions_transformed_f32c,
        :lowclip_color, :highclip_color, :nan_color,
        :model_f32c, :uv_transform,
    ]

    input2glname = Dict{Symbol, Symbol}(
        :positions_transformed_f32c => :vertices,
        :alpha_colormap => :color_map, :scaled_colorrange => :color_norm,
        :lowclip_color => :lowclip, :highclip_color => :highclip,
        :scaled_color => :image, :model_f32c => :model,
    )

    robj = register_robj!(assemble_image_robj, screen, scene, plot, inputs, uniforms, input2glname)

    return robj
end

################################################################################
### Heatmap
################################################################################

function assemble_heatmap_robj(screen::Screen, scene::Scene, attr, args, uniforms, input2glname)
    data = Dict{Symbol, Any}(
        :position_x => Texture(screen.glscreen, args[1], minfilter = :nearest),
        :position_y => Texture(screen.glscreen, args[2], minfilter = :nearest),
        # Compile time variable, Constants
        :transparency => attr[:transparency][],
        :overdraw => attr[:overdraw][],
        :ssao => false,
    )

    camera = scene.camera
    add_camera_attributes!(data, screen, camera, args.space)
    colormap = args.alpha_colormap
    color = args.scaled_color
    colornorm = args.scaled_colorrange
    add_color_attributes!(data, color, colormap, colornorm)

    # always use :image with specific interpolation settings, so remove:
    pop!(data, :image, nothing)
    pop!(data, :intensity, nothing)

    # Correct the name mapping
    input2glname[:scaled_color] = :intensity
    interp = attr[:interpolate][] ? :linear : :nearest
    if color isa ShaderAbstractions.Sampler
        data[:intensity] = color
    else
        data[:intensity] = Texture(screen.glscreen, color; minfilter = interp)
    end

    # Transfer over uniforms
    for name in uniforms
        data[get(input2glname, name, name)] = args[name]
    end

    return draw_heatmap(screen, data)
end

function draw_atomic(screen::Screen, scene::Scene, plot::Heatmap)
    attr = plot.args[1]

    # TODO: requires position transforms in Makie
    # # Fast path for regular heatmaps
    # t = Makie.transform_func_obs(plot)
    # if attr[:x][] isa Makie.EndPoints && attr[:y][] isa Makie.EndPoints && Makie.is_identity_transform(t[])
    #     return draw_atomic_as_image(screen, scene, plot)
    # end

    generic_robj_setup(screen, scene, plot)

    generate_clip_planes!(attr, scene)

    Makie.add_computation!(attr, scene, Val(:heatmap_transform))

    register_computation!(attr, [:x_transformed_f32c, :y_transformed_f32c], [:instances]) do (x, y), changed, cached
        return ((length(x) - 1) * (length(y) - 1), )
    end

    inputs = [
        :x_transformed_f32c, :y_transformed_f32c,
        # Special
        :space,
        # Needs explicit handling
        :alpha_colormap, :scaled_color, :scaled_colorrange
    ]
    uniforms = [
        :lowclip_color, :highclip_color, :nan_color,
        :model_f32c, :instances,
    ]

    input2glname = Dict{Symbol, Symbol}(
        :x_transformed_f32c => :position_x, :y_transformed_f32c => :position_y,
        :alpha_colormap => :color_map, :scaled_colorrange => :color_norm,
        :lowclip_color => :lowclip, :highclip_color => :highclip,
        :scaled_color => :image,
        :model_f32c => :model,
    )

    robj = register_robj!(assemble_heatmap_robj, screen, scene, plot, inputs, uniforms, input2glname)

    return robj
end

################################################################################
### Surface
################################################################################

function assemble_surface_robj(screen::Screen, scene::Scene, attr, args, uniforms, input2glname)
    data = Dict{Symbol, Any}(
        # Compile time variable, Constants
        :transparency => attr[:transparency][],
        :overdraw => attr[:overdraw][],
        :shading => attr[:shading][],
        :ssao => attr[:ssao][],
    )

    colorname = add_mesh_color_attributes!(
        screen, data,
        args.scaled_color,
        args.alpha_colormap,
        args.scaled_colorrange,
        attr[:interpolate][]
    )
    @assert colorname == :image

    camera = scene.camera
    add_camera_attributes!(data, screen, camera, args.space)
    add_light_attributes!(screen, scene, data, attr)

    # Transfer over uniforms
    for name in uniforms
        data[get(input2glname, name, name)] = args[name]
    end

    return draw_surface(screen, data[:image], data)
end

function draw_atomic(screen::Screen, scene::Scene, plot::Surface)
    attr = plot.args[1]

    generic_robj_setup(screen, scene, plot)
    generate_clip_planes!(attr, scene)
    Makie.add_computation!(attr, scene, Val(:surface_transform))
    Makie.register_world_normalmatrix!(attr)
    Makie.add_computation!(attr, scene, Val(:pattern_uv_transform))

    register_computation!(attr, [:z], [:instances]) do (z,), changed, cached
        return ((size(z,1)-1) * (size(z,2)-1), )
    end

    # TODO: not part of the conversion pipeline on master... but shouldn't it be?
    register_computation!(attr, [:z], [:z_converted]) do (z,), changed, cached
        return (el32convert(z), )
    end

    inputs = [
        # Special
        :space,
        # Needs explicit handling
        :alpha_colormap, :scaled_color, :scaled_colorrange
    ]
    uniforms = [
        :x_transformed_f32c, :y_transformed_f32c, :z_converted,
        :lowclip_color, :highclip_color, :nan_color, :matcap,
        :model_f32c, :instances,
        :diffuse, :specular, :shininess, :backlight, :world_normalmatrix,
        :invert_normals, :pattern_uv_transform, :fetch_pixel
    ]

    input2glname = Dict{Symbol, Symbol}(
        :x_transformed_f32c => :position_x, :y_transformed_f32c => :position_y,
        :z_converted => :position_z,
        :alpha_colormap => :color_map, :scaled_colorrange => :color_norm,
        :scaled_color => :image,
        :lowclip_color => :lowclip, :highclip_color => :highclip,
        :model_f32c => :model,
        :pattern_uv_transform => :uv_transform
    )

    robj = register_robj!(assemble_surface_robj, screen, scene, plot, inputs, uniforms, input2glname)

    return robj
end

################################################################################
### Mesh
################################################################################

# mesh_inner part 1
function add_mesh_color_attributes!(screen, data, color, colormap, colornorm, interpolate)
    # Note: assuming el32convert, Pattern convert to happen in Makie or earlier elsewhere
    interp = interpolate ? :linear : :nearest
    colorname = :vertex_color

    if color isa Colorant
        data[:vertex_color] = color
        colorname = :vertex_color
    elseif color isa ShaderAbstractions.Sampler
        data[:image] = color
        colorname = :image
    elseif color isa AbstractMatrix{<:Colorant}
        data[:image] = Texture(screen.glscreen, color, minfilter = interp)
        colorname = :image
    elseif color isa AbstractVector{<: Colorant}
        data[:vertex_color] = color
        colorname = :vertex_color

    else # colormapped

        data[:color_map] = colormap
        data[:color_norm] = colornorm

        if color isa Union{AbstractMatrix{<: Real}, AbstractArray{<: Real, 3}}
            data[:image] = Texture(screen.glscreen, color, minfilter = interp)
            colorname = :image
        elseif color isa AbstractVector{<: Real}
            data[:vertex_color] = color
            colorname = :vertex_color
        else
            error("Unsupported color type: $(typeof(to_value(color)))")
        end
    end

    # TODO: adjust input2glname[:scaled_color] = colorname
    # (name of input may change?)
    return colorname
end


function assemble_mesh_robj(screen::Screen, scene::Scene, attr, args, uniforms, input2glname)
    camera = scene.camera

    data = Dict{Symbol, Any}(
        # Compile time variable, Constants
        :transparency => attr[:transparency][],
        :overdraw => attr[:overdraw][],
        :shading => attr[:shading][],
        :ssao => attr[:ssao][],
    )

    add_camera_attributes!(data, screen, camera, args.space)

    input2glname[:scaled_color] = add_mesh_color_attributes!(
        screen, data,
        args.scaled_color,
        args.alpha_colormap,
        args.scaled_colorrange,
        attr[:interpolate][]
    )

    add_light_attributes!(screen, scene, data, attr)

    # Transfer over uniforms
    for name in uniforms
        data[get(input2glname, name, name)] = args[name]
    end

    data[:normals] === nothing && delete!(data, :normals)
    data[:texturecoordinates] === nothing && delete!(data, :texturecoordinates)

    return draw_mesh(screen, data)
end

function draw_atomic(screen::Screen, scene::Scene, plot::Mesh)
    attr = plot.args[1]

    generic_robj_setup(screen, scene, plot)
    generate_clip_planes!(attr, scene)
    Makie.register_world_normalmatrix!(attr)
    Makie.add_computation!(attr, scene, Val(:pattern_uv_transform); colorname = :mesh_color)

    # TODO: normalmatrices, lighting, poly plot!() overwrite for vector of meshes

    inputs = [
        # Special
        :space,
        # Needs explicit handling
        :alpha_colormap, :scaled_color, :scaled_colorrange,
    ]
    uniforms = [
        :positions_transformed_f32c, :faces, :normals, :texturecoordinates,
        :lowclip_color, :highclip_color, :nan_color, :model_f32c, :matcap,
        :diffuse, :specular, :shininess, :backlight, :world_normalmatrix,
        :pattern_uv_transform, :fetch_pixel
    ]

    input2glname = Dict{Symbol, Symbol}(
        :positions_transformed_f32c => :vertices,
        :alpha_colormap => :color_map, :scaled_colorrange => :color_norm,
        :lowclip_color => :lowclip, :highclip_color => :highclip,
        :scaled_color => :image, :model_f32c => :model,
        :pattern_uv_transform => :uv_transform
    )

    robj = register_robj!(assemble_mesh_robj, screen, scene, plot, inputs, uniforms, input2glname)

    return robj
end


################################################################################
### Voxels
################################################################################


function assemble_voxel_robj(screen::Screen, scene::Scene, attr, args, uniforms, input2glname)
    camera = scene.camera

    voxel_id = Texture(screen.glscreen, args.chunk_u8, minfilter = :nearest)
    uvt = args.packed_uv_transform
    data = Dict{Symbol, Any}(
        :voxel_id => voxel_id,
        :uv_transform => isnothing(uvt) ? nothing : Texture(screen.glscreen, uvt, minfilter = :nearest),
        # Compile time variable, Constants
        :transparency => attr[:transparency][],
        :overdraw => attr[:overdraw][],
        :shading => attr[:shading][],
        :ssao => attr[:ssao][],
    )

    add_camera_attributes!(data, screen, camera, args.space)
    add_light_attributes!(screen, scene, data, attr)

    if haskey(args, :voxel_color)
        interp = attr[:interpolate][] ? :linear : :nearest
        data[:color] = Texture(screen.glscreen, args.voxel_color, minfilter = interp)
    end

    # Transfer over uniforms
    for name in uniforms
        data[get(input2glname, name, name)] = args[name]
    end

    return draw_voxels(screen, voxel_id, data)
end

function draw_atomic(screen::Screen, scene::Scene, plot::Voxels)
    attr = plot.args[1]

    generic_robj_setup(screen, scene, plot)
    Makie.add_computation!(attr, scene, Val(:voxel_model))
    generate_clip_planes!(attr, scene, :model, :voxel_model)

    Makie.register_world_normalmatrix!(attr, :voxel_model)

    register_computation!(attr, [:chunk_u8, :gap], [:instances]) do (chunk, gap), changed, cached
        N = sum(size(chunk))
        return (ifelse(gap > 0.01, 2 * N, N + 3),)
    end

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

    inputs = [
        # Special
        :space,
        # Needs explicit handling
        :chunk_u8, :packed_uv_transform
    ]
    uniforms = [
        :instances, :voxel_model, :gap, :depthsorting,
        :diffuse, :specular, :shininess, :backlight, :world_normalmatrix,
    ]

    haskey(attr, :voxel_color) && push!(inputs, :voxel_color) # needs interpolation handling
    haskey(attr, :voxel_colormap) && push!(uniforms, :voxel_colormap)

    input2glname = Dict{Symbol, Symbol}(
        :chunk_u8 => :voxel_id, :voxel_model => :model, :packed_uv_transform => :uv_transform,
        :voxel_colormap => :color_map, :voxel_color => :color,
    )

    robj = register_robj!(assemble_voxel_robj, screen, scene, plot, inputs, uniforms, input2glname)

    return robj
end


################################################################################
### Volume
################################################################################


function assemble_volume_robj(screen::Screen, scene::Scene, attr, args, uniforms, input2glname)
    interp = attr[:interpolate][] ? :linear : :nearest
    volume_data = Texture(screen.glscreen, args.volume, minfilter = interp)

    data = Dict{Symbol, Any}(
        # Compile time variable, Constants
        :transparency => attr[:transparency][],
        :overdraw => attr[:overdraw][],
        :shading => attr[:shading][],
        :ssao => attr[:ssao][],
        :enable_depth => attr[:enable_depth][],
    )

    camera = scene.camera
    add_camera_attributes!(data, screen, camera, args.space)
    add_light_attributes!(screen, scene, data, attr)

    if args.volume isa AbstractArray{<:Real}
        data[:color_map] = args.alpha_colormap
        data[:color_norm] = args.scaled_colorrange
    end

    # Transfer over uniforms
    for name in uniforms
        data[get(input2glname, name, name)] = args[name]
    end

    return draw_volume(screen, volume_data, data)
end

function draw_atomic(screen::Screen, scene::Scene, plot::Volume)
    attr = plot.args[1]

    generic_robj_setup(screen, scene, plot)
    Makie.add_computation!(attr, scene, Val(:uniform_model)) # bit different from voxel_model

    # TODO: check if this should be the normal model matrix (for voxel too)
    generate_clip_planes!(attr, scene, :model, :uniform_model) # <--

    # TODO: reuse in clip planes
    register_computation!(attr, [:uniform_model], [:modelinv]) do (model,), changed, cached
        return (Mat4f(inv(model)),)
    end

    inputs = [
        # Special
        :space,
        # Needs explicit handling
        :alpha_colormap, :scaled_colorrange
    ]
    uniforms = [
        :volume, :modelinv, :algorithm, :absorption, :isovalue, :isorange,
        :diffuse, :specular, :shininess, :backlight,
        # :lowclip_color, :highclip_color, :nan_color,
        :uniform_model,
    ]

    haskey(attr, :voxel_colormap) && push!(uniforms, :voxel_colormap)
    haskey(attr, :voxel_color) && push!(inputs, :voxel_color) # needs interpolation handling

    input2glname = Dict{Symbol, Symbol}(
        :volume => :volumedata, :uniform_model => :model,
        :alpha_colormap => :color_map, :scaled_colorrange => :color_norm,
    )

    robj = register_robj!(assemble_volume_robj, screen, scene, plot, inputs, uniforms, input2glname)

    return robj
end
