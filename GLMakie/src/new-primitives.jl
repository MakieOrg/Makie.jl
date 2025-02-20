using Makie.ComputePipeline

################################################################################
### Util, delete later
################################################################################

function missing_uniforms(robj)
    for (key, value) in robj.vertexarray.program.uniformloc
        if !haskey(robj.uniforms, key)
            @info "Missing $key"
        end
    end
end

################################################################################
### Generic (more or less)
################################################################################

function update_robjs!(robj, args::NamedTuple, changed::NamedTuple, gl_names::Dict{Symbol,Symbol})
    for name in keys(args)
        changed[name] || continue
        value = args[name][]
        gl_name = get(gl_names, name, name)
        if name === :visible
            robj.visible = value
        elseif gl_name === :indices
            if robj.vertexarray.indices isa GLAbstraction.GPUArray
                GLAbstraction.update!(robj.vertexarray.indices, value)
            else
                robj.vertexarray.indices = value
            end
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
    if _color isa Matrix{RGBAf}
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


function generate_clip_planes!(attr, target_space::Symbol = :data)
    if !haskey(attr, :projectionview)
        scene = attr[:scene][]
        # is projectionview enough to trigger on scene resize in all cases?
        add_input!(attr, :projectionview, scene.camera.projectionview[])
        on(pv -> Makie.update!(attr, projectionview = pv), scene.camera.projectionview)
    end
    register_computation!(
        attr, [:clip_planes, :space, :projectionview], [:gl_clip_planes, :gl_num_clip_planes]
    ) do input, changed, cached
        output = isnothing(cached) ?  Vector{Vec4f}(undef, 8) : cached[1][]
        planes = input.clip_planes[]
        if target_space === :data
            if changed.projectionview && !changed.space && !changed.clip_planes
                return nothing # ignore projectionview
            end
            return generate_clip_planes(planes, input.space[], output)
        else
            return generate_clip_planes(input.projectionview[], planes, input.space[], output)
        end
    end
    return
end

################################################################################
### Scatter
################################################################################

function assemble_scatter_robj(attr, args, uniforms, input2glname)
    positions = args[1][]
    screen = args.gl_screen[]
    camera = args.scene[].camera
    space = attr[:space][]
    markerspace = attr[:markerspace][]
    fast_pixel = attr[:marker][] isa FastPixel
    pspace = fast_pixel ? space : markerspace
    colormap = args.alpha_colormap[]
    color = args.scaled_color[]
    colornorm = args.scaled_colorrange[]
    marker_shape = args.sdf_marker_shape[]
    distancefield = marker_shape === Cint(DISTANCEFIELD) ? get_texture!(screen.glscreen, args.atlas[]) : nothing
    data = Dict(
        :vertex => positions,
        :indices => length(positions),
        :preprojection => Makie.get_preprojection(camera, space, markerspace),
        :distancefield => distancefield,
        :px_per_unit => screen.px_per_unit,   # technically not const?
        :ssao => false,                         # shader compilation const
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
        data[get(input2glname, name, name)] = args[name][]
    end
    if fast_pixel
        return draw_pixel_scatter(screen, positions, data)
    else
        # pass nothing to avoid going into image generating functions
        return draw_scatter(screen, (nothing, positions), data)
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
    attr = plot.args[1]
    add_input!(attr, :scene, scene)
    # We register the screen under a unique name. If the screen closes
    # Any computation that depens on screen gets removed
    atlas = gl_texture_atlas()
    add_input!(attr, :atlas, atlas)
    add_input!(attr, :gl_screen, screen) # TODO: how do we clean this up?

    if attr[:depthsorting][]
        # is projectionview enough to trigger on scene resize in all cases?
        add_input!(attr, :projectionview, scene.camera.projectionview[])
        on(pv -> Makie.update!(attr, projectionview = pv), scene.camera.projectionview)

        register_computation!(attr,
            [:positions_transformed_f32c, :projectionview, :space, :model_f32c],
            [:gl_depth_cache, :gl_indices]
        ) do (pos, _, space, model), changed, cached
            pvm = Makie.space_to_clip(scene.camera, space[]) * model[]
            depth_vals = isnothing(cached) ? Float32[] : cached[1][]
            indices = isnothing(cached) ? Cuint[] : cached[2][]
            return depthsort!(pos[], depth_vals, indices, pvm)
        end
    else
        register_computation!(attr, [:positions_transformed_f32c], [:gl_indices]) do (ps,), changed, last
            return (length(ps[]),)
        end
    end

    inputs = [
        :positions_transformed_f32c,
        # Special
        :scene, :gl_screen, :atlas,
        # Needs explicit handling
        :alpha_colormap, :scaled_color, :scaled_colorrange,
        :sdf_marker_shape
    ]
    if attr[:marker][] isa FastPixel
        register_computation!(attr, [:markerspace], [:gl_markerspace]) do (space,), changed, last
            space[] == :pixel && return (Int32(0),)
            space[] == :data  && return (Int32(1),)
            return error("Unsupported markerspace for FastPixel marker: $space")
        end

        register_computation!(attr, [:marker], [:sdf_marker_shape]) do (marker,), changed, last
            return (marker[].marker_type,)
        end

        uniforms = [
            :gl_markerspace, :quad_scale,
            :transparency, :fxaa, :visible,
            :model_f32c,
            :_lowclip, :_highclip, :nan_color,
            :gl_clip_planes, :gl_num_clip_planes, :depth_shift, :gl_indices
            # TODO: this should've gotten marker_offset when we separated marker_offset from quad_offste
        ]

    else
        Makie.all_marker_computations!(attr, 2048, 64)

        # Simple forwards
        uniforms = [
            :sdf_uv,
            :quad_scale,
            :quad_offset,
            :image,
            :transparency, :fxaa, :visible,
            :strokecolor, :strokewidth, :glowcolor, :glowwidth,
            :model_f32c, :rotation, :transform_marker,
            :_lowclip, :_highclip, :nan_color,
            :gl_clip_planes, :gl_num_clip_planes, :depth_shift, :gl_indices
        ]
    end

    generate_clip_planes!(attr)

    # TODO:
    # - rotation -> billboard missing
    # - px_per_unit (that can update dynamically via record, right?)
    # - intensity_convert

    # To take the human error out of the bookkeeping of two lists
    # Could also consider using this in computation since Dict lookups are
    # O(1) and only takes ~4ns
    input2glname = Dict{Symbol, Symbol}(
        :positions_transformed_f32c => :position,
        :alpha_colormap => :color_map, :scaled_colorrange => :color_norm,
        :scaled_color => :color,
        :sdf_marker_shape => :shape,
        :sdf_uv => :uv_offset_width,
        :gl_markerspace => :markerspace,
        :quad_scale => :scale, :gl_image => :image,
        :strokecolor => :stroke_color, :strokewidth => :stroke_width,
        :glowcolor => :glow_color, :glowwidth => :glow_width,
        :model_f32c => :model, :transform_marker => :scale_primitive,
        :_lowclip => :lowclip, :_highclip => :highclip,
        :gl_clip_planes => :clip_planes, :gl_num_clip_planes => :num_clip_planes,
        :gl_indices => :indices
    )

    register_computation!(attr, [inputs; uniforms;], [:gl_renderobject]) do args, changed, last
        screen = args.gl_screen[]
        if isnothing(last)
            # Generate complex defaults
            robj = assemble_scatter_robj(attr, args, uniforms, input2glname)
        else
            robj = last[1][]
            if changed[3] # position
                if haskey(robj.uniforms, :len)
                    robj.uniforms[:len][] = length(args[1][])
                end
                robj.vertexarray.bufferlength = length(args[1][])
                # robj.vertexarray.indices = length(args[3][])
            end
            update_robjs!(robj, args, changed, input2glname)
        end
        screen.requires_update = true
        return (robj,)
    end
    robj = attr[:gl_renderobject][]
    screen.cache2plot[robj.id] = plot
    screen.cache[objectid(plot)] = robj
    push!(screen, scene, robj)
    return robj
end

################################################################################
### Lines
################################################################################

function assemble_lines_robj(attr, args, uniforms, input2glname)

    positions = args[1][] # changes name, so we use positional
    linestyle = attr[:linestyle][]
    camera = args.scene[].camera
    data = Dict{Symbol, Any}(
        :ssao => false,
        :fast => isnothing(linestyle),
        # :fast == true removes pattern from the shader so we don't need
        #               to worry about this
        :vertex => positions, # Needs to be set before draw_lines()
        :overdraw => attr[:overdraw][]
    )

    add_camera_attributes!(data, args.gl_screen[], camera, args.space[])
    add_color_attributes_lines!(data, args.scaled_color[], args.alpha_colormap[], args.scaled_colorrange[])

    if !isnothing(get(data, :intensity, nothing))
        input2glname[:scaled_color] = :intensity
    end

    # Transfer over uniforms
    for name in uniforms
        data[get(input2glname, name, name)] = args[name][]
    end

    return draw_lines(args.gl_screen[], positions, data)
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
        indices = empty!(cached[1][])
        valid = cached[2][]
    end
    ps = positions[1][]
    return generate_indices(ps, indices, valid)
end

function draw_atomic(screen::Screen, scene::Scene, plot::Lines)
    attr = plot.args[1]

    add_input!(attr, :scene, scene)
    add_input!(attr, :gl_screen, screen)

    Makie.add_computation!(attr, :gl_miter_limit)
    Makie.add_computation!(attr, :gl_pattern, :gl_pattern_length)

    add_input!(attr, :px_per_unit, screen.px_per_unit[]) # TODO: probably needs update!()
    add_input!(attr, :viewport, scene.viewport[])
    on(viewport -> Makie.update!(attr, viewport = viewport), scene.viewport) # TODO: This doesn't update immediately?
    register_computation!(
        attr, [:px_per_unit, :viewport], [:scene_origin, :resolution]
    ) do (ppu, viewport), changed, output
        return (Vec2f(ppu[] * origin(viewport[])), Vec2f(ppu[] * widths(viewport[])))
    end

    # position calculations for patterned lines
    # is projectionview enough to trigger on scene resize in all cases?
    add_input!(attr, :projectionview, scene.camera.projectionview[])
    on(pv -> Makie.update!(attr, projectionview = pv), plot, scene.camera.projectionview)
    register_computation!(
        attr, [:projectionview, :model, :f32c, :space], [:gl_pvm32]
    ) do (_, model, f32c, space), changed, output
        pvm = Makie.space_to_clip(scene.camera, space[]) *
            Makie.f32_convert_matrix(f32c[], space[]) * model[]
        return (pvm,)
    end
    register_computation!(
        attr, [:gl_pvm32, :positions_transformed], [:gl_projected_positions]
    ) do (pvm32, positions), changed, cached
        output = isnothing(cached) ? Point4f[] : cached[1][]
        resize!(cached[1][], length(positions[]))
        map!(output, positions[]) do pos
            return pvm32[] * to_ndim(Point4d, to_ndim(Point3d, pos, 0.0), 1.0)
        end
        return (output,)
    end


    add_input!(attr, :debug, false)

    generate_clip_planes!(attr, :clip) # requires projectionview

    if isnothing(plot.linestyle[])
        positions = :positions_transformed_f32c
    else
        positions = :gl_projected_positions
    end

    # Derived vertex attributes
    register_computation!(generate_indices, attr, [positions], [:gl_indices, :gl_valid_vertex])
    register_computation!(attr, [:gl_indices], [:gl_total_length]) do (indices,), changed, cached
        return (Int32(length(indices[]) - 2),)
    end
    register_computation!(attr, [positions, :resolution], [:gl_last_length]) do (pos, res), changed, cached
        return (sumlengths(pos[], res[]),)
    end

    inputs = [
        # relevant to creation time decisions
        positions,
        :space, :scene, :gl_screen,
        :scaled_color, :alpha_colormap, :scaled_colorrange
    ]
        # uniforms getting passed through
    uniforms = [
        :gl_indices, :gl_valid_vertex, :gl_total_length, :gl_last_length,
        :gl_pattern, :gl_pattern_length, :linecap, :gl_miter_limit, :joinstyle, :linewidth,
        :scene_origin, :px_per_unit,
        :transparency, :fxaa, :debug, :visible,
        :model_f32c,
        :_lowclip, :_highclip, :nan_color,
        :gl_clip_planes, :gl_num_clip_planes, :depth_shift
    ]

    input2glname = Dict(
        positions => :vertex, :gl_indices => :indices, :gl_valid_vertex => :valid_vertex,
        :gl_total_length => :total_length, :gl_last_length => :lastlen,
        :gl_miter_limit => :miter_limit, :linewidth => :thickness,
        :gl_pattern => :pattern, :gl_pattern_length => :pattern_length,
        :scaled_color => :color, :alpha_colormap => :color_map, :scaled_colorrange => :color_norm,
        :model_f32c => :model,
        :_lowclip => :lowclip, :_highclip => :highclip,
        :gl_clip_planes => :clip_planes,
        :gl_num_clip_planes => :_num_clip_planes
    )

    register_computation!(attr, [inputs; uniforms;], [:gl_renderobject]) do args, changed, output
        if isnothing(output)
            robj = assemble_lines_robj(attr, args, uniforms, input2glname)
        else
            robj = output[1][]
            update_robjs!(robj, args, changed, input2glname)
        end
        screen.requires_update = true
        return (robj,)
    end

    robj = attr[:gl_renderobject][]
    screen.cache2plot[robj.id] = plot
    screen.cache[objectid(plot)] = robj
    push!(screen, scene, robj)
    return robj
end

################################################################################
### LineSegments
################################################################################

function assemble_linesegments_robj(attr, args, uniforms, input2glname)
    positions = args[1][] # changes name, so we use positional
    linestyle = attr[:linestyle][]
    camera = args.scene[].camera

    data = Dict{Symbol, Any}(
        :ssao => false,
        :vertex => positions, # TODO: can be automated
        :overdraw => attr[:overdraw][],
        :indices => length(positions)
    )
    screen = args.gl_screen[]
    add_camera_attributes!(data, screen, camera, args.space[])
    add_color_attributes_lines!(data, args.synched_color[], args.alpha_colormap[], args.scaled_colorrange[])
    if isnothing(get(data, :intensity, nothing))
        input2glname[:synched_color] = :intensity
    end
    # Transfer over uniforms
    for name in uniforms
        data[get(input2glname, name, name)] = args[name][]
    end

    # Here we do need to be careful with pattern because :fast does not
    # exist as a compile time switch
    # Running this after add_uniforms overwrites
    if isnothing(linestyle)
        data[:pattern] = nothing
    end
    return draw_linesegments(screen, positions, data) # TODO: extract positions
end

function draw_atomic(screen::Screen, scene::Scene, plot::LineSegments)
    attr = plot.args[1]
    add_input!(plot.args[1], :scene, scene)
    add_input!(attr, :gl_screen, screen)
    add_input!(attr, :px_per_unit, screen.px_per_unit[]) # TODO: probably needs update!()
    add_input!(attr, :viewport, scene.viewport[])
    on(viewport -> Makie.update!(attr, viewport = viewport), scene.viewport) # TODO: This doesn't update immediately?
    register_computation!(
        attr, [:px_per_unit, :viewport], [:scene_origin]
    ) do (ppu, viewport), changed, output
        return (Vec2f(ppu[] * origin(viewport[])),)
    end
    if !haskey(attr, :scene)
        add_input!(plot.args[1], :scene, scene)
    end

    # linestyle/pattern handling
    Makie.add_computation!(attr, :gl_pattern, :gl_pattern_length)
    add_input!(attr, :debug, false)
    add_input!(attr, :projectionview, scene.camera.projectionview[])
    on(pv -> Makie.update!(attr; projectionview=pv), plot, scene.camera.projectionview)
    generate_clip_planes!(attr)

    inputs = [
        :positions_transformed_f32c,
        :space, :scene, :gl_screen,
        :synched_color, :alpha_colormap, :scaled_colorrange
    ]
    uniforms = [
        :gl_pattern, :gl_pattern_length, :linecap, :synched_linewidth,
        :scene_origin, :px_per_unit, :model_f32c,
        :transparency, :fxaa, :debug,
        :visible,
        :gl_clip_planes, :gl_num_clip_planes, :depth_shift
    ]

    input2glname = Dict{Symbol, Symbol}(
        :positions_transformed_f32c => :vertex,
        :synched_linewidth => :thickness, :model_f32c => :model,
        :gl_pattern => :pattern, :gl_pattern_length => :pattern_length,
        :synched_color => :color, :alpha_colormap => :color_map, :scaled_colorrange => :color_norm,
        :_lowclip => :lowclip, :_highclip => :highclip,
        :gl_clip_planes => :clip_planes, :gl_num_clip_planes => :_num_clip_planes
    )

    register_computation!(attr, [inputs; uniforms;], [:gl_renderobject]) do args, changed, output
        if isnothing(output)
            robj = assemble_linesegments_robj(attr, args, uniforms, input2glname)
        else
            robj = output[1][]
            if changed[1]
                robj.vertexarray.indices = length(args[1][])
            end
            update_robjs!(robj, args, changed, input2glname)
        end
        screen.requires_update = true
        return (robj,)
    end

    robj = attr[:gl_renderobject][]
    screen.cache2plot[robj.id] = plot
    screen.cache[objectid(plot)] = robj
    push!(screen, scene, robj)
    return robj
end
