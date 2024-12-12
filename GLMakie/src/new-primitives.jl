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

function update_robjs!(robj, args, changed, gl_names)
    for (name, arg, has_changed) in zip(gl_names, args, changed)
        if has_changed
            if name === :visible
                robj.visible = arg[]
            elseif name === :indices
                if robj.vertexarray.indices isa GLAbstraction.GPUArray
                    GLAbstraction.update!(robj.vertexarray.indices, arg[])
                else
                    robj.vertexarray.indices = arg[]
                end
            elseif haskey(robj.uniforms, name)
                if robj.uniforms[name] isa GLAbstraction.GPUArray
                    GLAbstraction.update!(robj.uniforms[name], arg[])
                else
                    robj.uniforms[name] = arg[]
                end
            elseif haskey(robj.vertexarray.buffers, string(name))
                GLAbstraction.update!(robj.vertexarray.buffers[string(name)], arg[])
            else
                # println("Could not update ", name)
            end
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

function generate_clip_planes!(attr, target_space::Symbol = :data)

    if target_space === :data

        register_computation!(attr, [:clip_planes, :space], [:gl_clip_planes, :gl_num_clip_planes]) do input, changed, cached
            output = isnothing(cached) ?  Vector{Vec4f}(undef, 8) : cached[1][]
            planes = input[1][]

            if length(planes) > 8
                @warn("Only up to 8 clip planes are supported. The rest are ignored!", maxlog = 1)
            end

            if Makie.is_data_space(input[2][])
                N = min(8, length(planes))
                for i in 1:N
                    output[i] = Makie.gl_plane_format(planes[i])
                end
                for i in N+1 : 8
                    output[i] = Vec4f(0, 0, 0, -1e9)
                end
            else
                output .= Ref(Vec4f(0, 0, 0, -1e9))
                N = 0
            end

            return (output, Int32(N))
        end

    elseif target_space === :clip

        register_computation!(attr,
            [:clip_planes, :space, :projectionview],
            [:gl_clip_planes, :gl_num_clip_planes]
        ) do input, changed, cached

            output = isnothing(cached) ?  Vector{Vec4f}(undef, 8) : cached[1][]
            planes = input[1][]

            if length(planes) > 8
                @warn("Only up to 8 clip planes are supported. The rest are ignored!", maxlog = 1)
            end

            if Makie.is_data_space(input[2][])
                N = min(8, length(planes))
                planes = Makie.to_clip_space(input[3][], planes) # this got added
                for i in 1:N
                    output[i] = Makie.gl_plane_format(planes[i])
                end
                for i in N+1 : 8
                    output[i] = Vec4f(0, 0, 0, -1e9)
                end
            else
                output .= Ref(Vec4f(0, 0, 0, -1e9))
                N = 0
            end

            return (output, Int32(N))
        end

    else
        # model for volume, voxels
        error("TODO")

    end

    return
end

################################################################################
### Scatter
################################################################################

function assemble_scatter_robj(
        add_uniforms!,
        atlas, marker,
        space, markerspace, # TODO: feels incomplete to me... Do matrices react correctly? What about markerspace with FastPixel?
        scene, screen,
        positions, # TODO: can probably be avoided by rewriting draw_scatter()
        colormap, color, colornorm,
        marker_shape
    )

    camera = scene[].camera
    fast_pixel = marker isa FastPixel
    pspace = fast_pixel ? space : markerspace
    distancefield = marker_shape[] === Cint(DISTANCEFIELD) ? get_texture!(atlas) : nothing
    data = Dict(
        :vertex => positions[],
        :indices => length(positions[]),
        :preprojection => Makie.get_preprojection(camera, space, markerspace),
        :distancefield => distancefield,
        :px_per_unit => screen[].px_per_unit,   # technically not const?
        :ssao => false,                         # shader compilation const
        :shape => marker_shape[],
    )

    add_color_attributes!(data, color[], colormap[], colornorm[])
    add_camera_attributes!(data, screen[], camera, pspace)

    add_uniforms!(data)

    if fast_pixel
        return draw_pixel_scatter(screen[], positions[], data)
    else
        # pass nothing to avoid going into image generating functions
        return draw_scatter(screen[], (nothing, positions[]), data)
    end
end


function draw_atomic(screen::Screen, scene::Scene, plot::Scatter)
    attr = plot.args[1]
    add_input!(plot.args[1], :scene, scene)
    # We register the screen under a unique name. If the screen closes
    # Any computation that depens on screen gets removed
    atlas = gl_texture_atlas()
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
            pvm24 = pvm[Vec(3,4), Vec(1,2,3,4)] # only calculate zw
            if isnothing(cached)
                depth_vals = Vector{Float32}(undef, length(pos[]))
                indices = Vector{Cuint}(undef, length(pos[]))
            else
                depth_vals = resize!(cached[1][], length(pos[]))
                indices = resize!(cached[2][], length(pos[]))
            end
            map!(depth_vals, pos[]) do p
                p4d = pvm24 * to_ndim(Point4f, to_ndim(Point3f, p, 0f0), 1f0)
                p4d[1] / p4d[2]
            end
            sortperm!(indices, depth_vals, rev = true)
            indices .-= 1
            return (depth_vals, indices)
        end
    else
        register_computation!(attr, [:positions_transformed_f32c], [:gl_indices]) do (ps,), changed, last
            return (length(ps[]),)
        end
    end

    if attr[:marker][] isa FastPixel

        register_computation!(attr, [:markerspace], [:gl_markerspace]) do (space,), changed, last
            space[] == :pixel && return (Int32(0),)
            space[] == :data  && return (Int32(1),)
            return error("Unsupported markerspace for FastPixel marker: $space")
        end

        register_computation!(
            attr, [:marker], [:gl_marker_shape]
        ) do (marker,), changed, last
            return (marker[].marker_type,)
        end
        inputs = [
            # Special
            :scene, :gl_screen,
            # Needs explicit handling
            :positions_transformed_f32c,
            :alpha_colormap, :scaled_color, :scaled_colorrange,
            :gl_marker_shape,
            # Simple forwards
            :gl_markerspace, :quad_scale,
            :transparency, :fxaa, :visible,
            :model_f32c,
            :_lowclip, :_highclip, :nan_color,
            :gl_clip_planes, :gl_num_clip_planes, :depth_shift, :gl_indices
            # TODO: this should've gotten marker_offset when we separated marker_offset from quad_offste
        ]

    else

        # TODO: Probably shouldn't just drop uv_offset_width?
        register_computation!(attr,
            [:uv_offset_width, :marker, :font, :quad_scale],
            [:gl_marker_shape, :gl_uv, :gl_image]
        ) do (uv_off, m, f, scale), changed, last

            if m[] isa Matrix{<: Colorant} # single image marker

                return (Cint(RECTANGLE), Vec4f(0,0,1,1), m[])

            elseif m[] isa Vector{<: Matrix{<: Colorant}} # multiple image markers

                # TODO: Should we cache the RectanglePacker so we don't need to redo everything?
                if changed[2]
                    images = map(el32convert, m[])
                    isempty(images) && error("Can not display empty vector of images as primitive")
                    sizes = map(size, images)
                    if !all(x -> x == sizes[1], sizes)
                        # create texture atlas
                        maxdims = sum(map(Vec{2, Int}, sizes))
                        rectangles = map(x->Rect2(0, 0, x...), sizes)
                        rpack = RectanglePacker(Rect2(0, 0, maxdims...))
                        uv_coordinates = [push!(rpack, rect).area for rect in rectangles]
                        max_xy = mapreduce(maximum, (a,b)-> max.(a, b), uv_coordinates)
                        texture_atlas = Texture(eltype(images[1]), (max_xy...,))
                        for (area, img) in zip(uv_coordinates, images)
                            texture_atlas[area] = img # transfer to texture atlas
                        end
                        uvs = map(uv_coordinates) do uv
                            m = max_xy .- 1
                            mini = reverse((minimum(uv)) ./ m)
                            maxi = reverse((maximum(uv) .- 1) ./ m)
                            return Vec4f(mini..., maxi...)
                        end
                        images = texture_atlas
                    else
                        uvs = Vec4f(0,0,1,1)
                    end

                    return (Cint(RECTANGLE), uvs, images)
                else
                    # if marker is up to date don't update
                    return (nothing, nothing, nothing)
                end

            else # Char, BezierPath, Vectors thereof or Shapes (Rect, Circle)

                if changed[2] || changed[4]
                    shape = Cint(Makie.marker_to_sdf_shape(m[])) # expensive for arrays with abstract eltype?
                    if shape == 0 && !is_all_equal_scale(scale[])
                        shape = Cint(5)
                    end
                else
                    shape = last[1][]
                end

                if (shape == Cint(DISTANCEFIELD)) && (changed[2] || changed[3])
                    uv = Makie.primitive_uv_offset_width(atlas, m[], f[])
                elseif isnothing(last)
                    uv = Vec4f(0,0,1,1)
                else
                    uv = nothing # Is this even worth it?
                end

                return (shape, uv, nothing)
            end
        end

        inputs = [
            # Special
            :scene, :gl_screen,
            # Needs explicit handling
            :positions_transformed_f32c,
            :alpha_colormap, :scaled_color, :scaled_colorrange,
            :gl_marker_shape,
            # Simple forwards
            :gl_uv, :quad_scale, :quad_offset, :gl_image,
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
        :gl_marker_shape => :shape, :gl_uv => :uv_offset_width,
        :gl_markerspace => :markerspace,
        :quad_scale => :scale, :gl_image => :image,
        :strokecolor => :stroke_color, :strokewidth => :stroke_width,
        :glowcolor => :glow_color, :glowwidth => :glow_width,
        :model_f32c => :model, :transform_marker => :scale_primitive,
        :_lowclip => :lowclip, :_highclip => :highclip,
        :gl_clip_planes => :clip_planes, :gl_num_clip_planes => :num_clip_planes,
        :gl_indices => :indices
    )
    gl_names = Symbol[]

    register_computation!(attr, inputs, [:gl_renderobject]) do args, changed, last
        screen = args[2][]
        !isopen(screen) && return :deregister
        if isnothing(last)

            # Generate complex defaults
            robj = assemble_scatter_robj(atlas, attr.outputs[:marker][],
                attr.outputs[:space][], attr.outputs[:markerspace][], args[1:7]...) do data

                # Generate name mapping
                isnothing(get(data, :intensity, nothing)) || (input2glname[:scaled_color] = :intensity)
                isnothing(get(data, :image, nothing)) || (input2glname[:scaled_color] = :image)
                gl_names = get.(Ref(input2glname), inputs, inputs)

                # Simple defaults
                foreach(8:length(args)) do idx
                    data[gl_names[idx]] = args[idx][]
                end
                data[:overdraw] = attr.outputs[:overdraw][]

            end

        else

            robj = last[1][]
            if changed[3] # position
                haskey(robj.uniforms, :len) && (robj.uniforms[:len][] = length(args[3][]))
                robj.vertexarray.bufferlength = length(args[3][])
                # robj.vertexarray.indices = length(args[3][])
            end
            update_robjs!(robj, args[3:end], changed[3:end], gl_names[3:end])

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

function assemble_lines_robj(
        add_uniforms!, space, scene, screen,
        positions,
        color, colormap, colornorm,
        linestyle,
    )

    camera = scene[].camera
    data = Dict{Symbol, Any}(
        :ssao => false,
        :fast => isnothing(linestyle[]),
        # :fast == true removes pattern from the shader so we don't need
        #               to worry about this
        :vertex => positions[], # Needs to be set before draw_lines()
    )

    add_camera_attributes!(data, screen[], camera, space[])
    add_color_attributes_lines!(data, color[], colormap[], colornorm[])
    add_uniforms!(data)

    return draw_lines(screen[], positions[], data)
end

# Observables removed and adjusted to fit Compute Pipeline
function generate_indices(positions, changed, cached)
    if isnothing(cached)
        indices = Cuint[]
        valid = Float32[]
    else
        indices = empty!(cached[1][])
        valid = cached[2][]
    end

    ps = positions[1][]
    sizehint!(indices, length(ps) + 2)
    resize!(valid, length(ps))

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
                push!(indices, i-1)
                last_start_idx = length(indices) + 1
                last_start_pos = p
            end
            # add line vertex
            push!(indices, i)

        # case loop (loop index set, loop contains at least 3 segments, start == end)
        elseif (last_start_idx != -1) && (length(indices) - last_start_idx > 2) &&
                (ps[max(1, i-1)] ≈ last_start_pos)

            # add ghost vertices before an after the loop to cleanly connect line
            indices[last_start_idx-1] = max(1, i-2)
            push!(indices, indices[last_start_idx+1], i)
            # mark the ghost vertices
            valid[i-2] = 2
            valid[indices[last_start_idx+1]] = 2
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
    if (last_start_idx != -1) && (length(indices) - last_start_idx > 2) &&
            (ps[end] ≈ last_start_pos)

        indices[last_start_idx-1] = length(ps) - 1
        push!(indices, indices[last_start_idx+1])
        valid[end-1] = 2
        valid[indices[last_start_idx+1]] = 2
    elseif last_start_idx != -1
        push!(indices, length(ps))
    end

    indices .-= Cuint(1)

    return (indices, valid)
end

function draw_atomic(screen::Screen, scene::Scene, plot::Lines)
    attr = plot.args[1]
    add_input!(plot.args[1], :scene, scene)
    register_computation!(attr, [:miter_limit], [:gl_miter_limit]) do (miter,), changed, output
        return (Float32(cos(pi - miter[])),)
    end
    add_input!(attr, :screen, screen)
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
    on(pv -> Makie.update!(attr, projectionview = pv), scene.camera.projectionview)
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
        if isnothing(cached)
            output = Vector{Point4f}(undef, length(positions[]))
        else
            output = resize!(cached[1][], length(positions[]))
        end
        @inbounds for i in eachindex(positions[])
            output[i] = pvm32[] * to_ndim(Point4d, to_ndim(Point3d, positions[][i], 0.0), 1.0)
        end
        return (output,)
    end

    # linestyle/pattern handling
    register_computation!(
        attr, [:linestyle], [:gl_pattern, :gl_pattern_length]
    ) do (linestyle,), changed, cached
        if isnothing(linestyle[])
            sdf = fill(Float16(-1.0), 100) # compat for switching from linestyle to solid/nothing
            len = 1f0 # should be irrelevant, compat for strictly solid lines
        else
            sdf = Makie.linestyle_to_sdf(linestyle[])
            len = Float32(last(linestyle[]) - first(linestyle[]))
        end

        if isnothing(cached)
            tex = Texture(sdf, x_repeat = :repeat)
        else
            tex = cached[1][]
            GLAbstraction.update!(tex, sdf)
        end

        return (tex, len)
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
        # relevant to compile time decisions
        :space, :scene, :screen,
        positions,
        :scaled_color, :alpha_colormap, :scaled_colorrange,
        # Auto
        :gl_indices, :gl_valid_vertex, :gl_total_length, :gl_last_length,
        :gl_pattern, :gl_pattern_length, :linecap, :gl_miter_limit, :joinstyle, :linewidth,
        :scene_origin, :px_per_unit,
        :transparency, :fxaa, :debug, :visible,
        :model_f32c,
        :_lowclip, :_highclip, :nan_color,
        :gl_clip_planes, :gl_num_clip_planes, :depth_shift
    ]
    input2glname = Dict{Symbol, Symbol}(
        positions => :vertex, :gl_indices => :indices, :gl_valid_vertex => :valid_vertex,
        :gl_total_length => :total_length, :gl_last_length => :lastlen,
        :gl_miter_limit => :miter_limit, :linewidth => :thickness,
        :gl_pattern => :pattern, :gl_pattern_length => :pattern_length,
        :scaled_color => :color, :alpha_colormap => :color_map, :scaled_colorrange => :color_norm,
        :model_f32c => :model,
        :_lowclip => :lowclip, :_highclip => :highclip,
        :gl_clip_planes => :clip_planes, :gl_num_clip_planes => :_num_clip_planes
    )
    gl_names = Symbol[]

    register_computation!(attr, inputs, [:gl_renderobject]) do args, changed, output
        if isnothing(output)

            robj = assemble_lines_robj(args[1:7]..., attr[:linestyle]) do data

                # Generate name mapping
                isnothing(get(data, :intensity, nothing)) || (input2glname[:scaled_color] = :intensity)
                gl_names = get.(Ref(input2glname), inputs, inputs)

                # Simple defaults
                foreach(7:length(args)) do idx
                    data[gl_names[idx]] = args[idx][]
                end

                data[:overdraw] = attr.outputs[:overdraw][]

                return
            end

        else
            robj = output[1][]
            update_robjs!(robj, args[4:end], changed[4:end], gl_names[4:end])
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

function assemble_linesegments_robj(
    add_uniforms!,
    space, scene, screen,
    positions,
    color, colormap, colornorm,
    linestyle,
)
    camera = scene[].camera

    data = Dict{Symbol, Any}(
        :ssao => false,
        :vertex => positions[], # TODO: can be automated
    )

    add_camera_attributes!(data, screen[], camera, space[])
    add_color_attributes_lines!(data, color[], colormap[], colornorm[])

    add_uniforms!(data)

    # Here we do need to be careful with pattern because :fast does not
    # exist as a compile time switch
    # Running this after add_uniforms overwrites
    if isnothing(linestyle[])
        data[:pattern] = nothing
    end

    return draw_linesegments(screen[], positions[], data) # TODO: extract positions
end

function draw_atomic(screen::Screen, scene::Scene, plot::LineSegments)
    attr = plot.args[1]
    add_input!(plot.args[1], :scene, scene)
    add_input!(attr, :screen, screen)
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
    register_computation!(
        attr, [:linestyle], [:gl_pattern, :gl_pattern_length]
    ) do (linestyle,), changed, cached
        if isnothing(linestyle[])
            sdf = fill(Float16(-1.0), 100) # compat for switching from linestyle to solid/nothing
            len = 1f0 # should be irrelevant, compat for strictly solid lines
        else
            sdf = Makie.linestyle_to_sdf(linestyle[])
            len = Float32(last(linestyle[]) - first(linestyle[]))
        end

        if isnothing(cached)
            tex = Texture(sdf, x_repeat = :repeat)
        else
            tex = cached[1][]
            GLAbstraction.update!(tex, sdf)
        end

        return (tex, len)
    end

    add_input!(attr, :debug, false)

    generate_clip_planes!(attr)

    inputs = [
        :space, :scene, :screen,
        :positions_transformed_f32c,
        :synched_color, :alpha_colormap, :scaled_colorrange,
        # Auto
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
    gl_names = Symbol[]

    register_computation!(attr, inputs, [:gl_renderobject]) do args, changed, output
        if isnothing(output)
            robj = assemble_linesegments_robj(args[1:7]..., attr[:linestyle]) do data

                # Generate name mapping
                isnothing(get(data, :intensity, nothing)) || (input2glname[:synched_color] = :intensity)
                gl_names = get.(Ref(input2glname), inputs, inputs)

                # Simple defaults
                foreach(7:length(args)) do idx
                    data[gl_names[idx]] = args[idx][]
                end

                @assert gl_names[4] === :vertex
                data[:indices] = length(args[4][])
                data[:overdraw] = attr.outputs[:overdraw][]

                return
            end
        else
            robj = output[1][]
            if changed[4]
                @assert gl_names[4] === :vertex
                robj.vertexarray.indices = length(args[4][])
            end
            update_robjs!(robj, args[4:end], changed[4:end], gl_names[4:end])
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
