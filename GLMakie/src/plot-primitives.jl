using Makie: FastPixel

Makie.el32convert(x::GLAbstraction.Texture) = x

# PlotList can "become" atomic if no plots are inserted
# In that case, we should simply not draw it!
draw_atomic(::Screen, ::Scene, ::PlotList) = nothing

function Base.insert!(screen::Screen, scene::Scene, @nospecialize(x::Plot))
    gl_switch_context!(screen.glscreen)
    add_scene!(screen, scene)
    # poll inside functions to make wait on compile less prominent
    if isempty(x.plots) # if no plots inserted, this truly is an atomic
        draw_atomic(screen, scene, x)
    elseif x isa Text
        draw_atomic(screen, scene, x)
        insert!(screen, scene, x.plots[1])
    else
        foreach(x.plots) do x
            insert!(screen, scene, x)
        end
    end
    return
end

using Makie.ComputePipeline

################################################################################
### Util, delete later
################################################################################

function missing_uniforms(robj, inputs, input2name)
    inputset = Set([get(input2name, k, k) for k in inputs])
    uniformset = union(
        keys(robj.vertexarray.program.uniformloc),
        Symbol.(collect(keys(robj.vertexarray.buffers))),
        [:visible]
    )
    skip = [:objectid]
    for k in setdiff(uniformset, inputset)
        k in skip && continue
        printstyled("Missing uniform $k\n", color = :red)
    end
    for k in setdiff(inputset, uniformset)
        k in [:indices, :instances, :fxaa] && continue
        printstyled("Discard input $k\n", color = :yellow)
    end
    return
end


function flag_float64(robj)
    banned_types = Union{
        Float64, VecTypes{N, Float64} where {N},
        AbstractArray{Float64},
        AbstractArray{<:VecTypes{N, Float64}} where {N},
        Observable,
    }
    for (k, v) in robj.vertexarray.buffers
        v isa banned_types && error("$k in vertexarray is a banned type $(typeof(v))")
    end
    for (k, v) in robj.uniforms
        v isa banned_types && error("$k in uniforms is a banned type: $(typeof(v))")
    end
    return
end

################################################################################
### Generic (more or less)
################################################################################

function update_robjs!(robj, args::NamedTuple, changed::NamedTuple, gl_names::Dict{Symbol, Symbol})
    for name in keys(args)
        changed[name] || continue
        value = args[name]
        gl_name = get(gl_names, name, name)
        # println("Updating ", name)
        if name === :visible
            robj.visible = value
        elseif gl_name === :indices || gl_name === :faces
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
                converted = GLAbstraction.gl_convert(robj.context, value)
                if typeof(robj.uniforms[gl_name]) !== typeof(converted)
                    @error("Uniforms can not change their type. uniforms[$gl_name]::$(typeof(robj.uniforms[gl_name])) = $name = $converted::$(typeof(converted))")
                end
                robj.uniforms[gl_name] = converted
            end
        elseif haskey(robj.vertexarray.buffers, string(gl_name))
            GLAbstraction.update!(robj.vertexarray.buffers[string(gl_name)], value)
        else
            # println("Could not update ", name)
        end
    end
    return
end

function add_color_attributes!(screen, attr, data, color, colormap, colornorm)
    needs_mapping = !(colornorm isa Nothing)
    _color = needs_mapping ? nothing : color
    intensity = needs_mapping ? color : nothing

    interp = attr.color_mapping_type[] === Makie.continuous ? :linear : :nearest
    data[:color_map] = needs_mapping ? Texture(screen.glscreen, colormap, minfilter = interp) : nothing

    if _color isa Matrix{RGBAf} || _color isa ShaderAbstractions.Sampler
        data[:image] = _color
        data[:color] = RGBAf(1, 1, 1, 1)
    else
        data[:color] = _color
    end
    data[:intensity] = intensity
    data[:color_norm] = colornorm
    return nothing
end

function add_color_attributes_lines!(screen, attr, data, color, colormap, colornorm)
    needs_mapping = !(colornorm isa Nothing)
    interp = attr.color_mapping_type[] === Makie.continuous ? :linear : :nearest
    data[:color_map] = needs_mapping ? Texture(screen.glscreen, colormap, minfilter = interp) : nothing
    data[:color] = color
    data[:color_norm] = colornorm
    return nothing
end

function register_light_attributes!(screen, scene, attr, uniforms)
    # plot does not support shading
    haskey(attr, :shading) || return

    # On re-display these are already registered. To allow compiling shaders
    # with different light settings we need to clear old computations
    if haskey(attr, :ambient)
        if haskey(attr, :gl_renderobject)
            error("Try to register lights that have already been registered. Is the renderobject getting created twice?")
        else
            for key in [:ambient, :light_color, :light_direction, :N_lights, :light_types, :light_colors, :light_parameters]
                if haskey(attr, key)
                    delete!(attr, key, force = true)
                end
            end
        end
    end

    # Nothing to generate if we don't shade
    shading = Makie.get_shading_mode(scene)
    if !attr[:shading][] || (shading == NoShading)
        return
    end

    add_input!(attr, :ambient, scene.compute[:ambient_color]::Computed)

    if shading == FastShading

        add_input!(attr, :light_color, scene.compute[:dirlight_color])
        add_input!(attr, :light_direction, scene.compute[:dirlight_final_direction])
        push!(uniforms, :ambient, :light_color, :light_direction)

    elseif shading == MultiLightShading

        MAX_LIGHTS = screen.config.max_lights
        MAX_PARAMS = screen.config.max_light_parameters

        Makie.register_multi_light_computation(scene, MAX_LIGHTS, MAX_PARAMS)

        names = [:N_lights, :light_types, :light_colors, :light_parameters]
        for key in names
            add_input!(attr, key, scene.compute[key]::Computed)
        end
        push!(uniforms, :ambient, names...)
    end

    return
end

function generic_robj_setup(screen::Screen, scene::Scene, plot::Plot)
    attr = plot.attributes::ComputeGraph
    return attr
end

function construct_robj(constructor!, screen, scene, attr, args, uniforms, input2glname)
    data = Dict{Symbol, Any}(
        :ssao => attr[:ssao][],
        :fxaa => attr[:fxaa][],
        :transparency => attr[:transparency][],
        :overdraw => attr[:overdraw][],
        :num_clip_planes => 0, # default for in-shader resolution of clip planes
    )

    if haskey(attr, :shading)
        data[:shading] = attr[:shading][] ? Makie.get_shading_mode(scene) : NoShading
    end

    for name in uniforms
        data[get(input2glname, name, name)] = args[name]
    end

    return constructor!(data, screen, attr, args, input2glname)
end

function register_robj!(constructor!, screen, scene, plot, inputs, uniforms, input2glname)
    attr = plot.attributes

    # These must always be there!
    push!(uniforms, :uniform_clip_planes, :uniform_num_clip_planes, :depth_shift, :visible, :fxaa)
    push!(uniforms, :resolution, :projection, :projectionview, :view, :upvector, :eyeposition, :view_direction)
    haskey(attr, :preprojection) && push!(uniforms, :preprojection)
    push!(input2glname, :uniform_clip_planes => :clip_planes)
    get!(input2glname, :uniform_num_clip_planes, :num_clip_planes) # don't overwrite

    # triggers if shading is present
    register_light_attributes!(screen, scene, attr, uniforms)

    merged_inputs = [inputs; uniforms;]
    if !allunique(merged_inputs)
        unique_inputs = Set{Symbol}()
        duplicates = Set{Symbol}()
        for k in merged_inputs
            if k in unique_inputs
                push!(duplicates, k)
            else
                push!(unique_inputs, k)
            end
        end
        error("Duplicate robj inputs detected in $merged_inputs: $duplicates")
    end

    register_computation!(attr, merged_inputs, [:gl_renderobject]) do args, changed, last
        if isnothing(last)
            # Generate complex defaults
            # TODO: Should we add an initializer in ComputePipeline to extract this?
            # That would simplify this code and remove attr, uniforms from the enclosed variables here
            _robj = construct_robj(constructor!, screen, scene, attr, args, uniforms, input2glname)
        else
            _robj = last.gl_renderobject
            update_robjs!(_robj, args, changed, input2glname)
            # names = ([k for (k, v) in pairs(changed) if v])
            # @info "updating robj $(robj.id) due to changes in: $names"
        end
        screen.requires_update = true
        return (_robj,)
    end
    robj = attr[:gl_renderobject][]

    flag_float64(robj)

    screen.cache2plot[robj.id] = plot
    screen.cache[objectid(plot)] = robj
    push!(screen, scene, robj)

    # For debugging/checking uniforms
    # missing_uniforms(robj, [inputs; uniforms;], input2glname)

    return robj
end

################################################################################
### Scatter
################################################################################

function assemble_scatter_robj!(data, screen::Screen, attr, args, input2glname)
    fast_pixel = attr[:marker][] isa FastPixel
    colormap = args.alpha_colormap
    color = args.scaled_color
    colornorm = args.scaled_colorrange
    marker_shape = args.sdf_marker_shape

    # TODO: allowing user supplied atlas for e.g. sprite animations would be nice...
    data[:distancefield] = marker_shape === Cint(DISTANCEFIELD) ? get_texture!(screen.glscreen, Makie.get_texture_atlas()) : nothing
    data[:shape] = marker_shape

    add_color_attributes!(screen, attr, data, color, colormap, colornorm)

    # Correct the name mapping
    if !isnothing(get(data, :intensity, nothing))
        input2glname[:scaled_color] = :intensity
    end
    if !isnothing(get(data, :image, nothing))
        input2glname[:scaled_color] = :image
    end

    if fast_pixel
        return draw_pixel_scatter(screen, data[:position], data)
    else
        # pass nothing to avoid going into image generating functions
        return draw_scatter(screen, position, data)
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
    sortperm!(indices, depth_vals; rev = true)
    indices .-= 1
    return depth_vals, indices
end


function draw_atomic(screen::Screen, scene::Scene, plot::Scatter)
    attr = generic_robj_setup(screen, scene, plot)

    Makie.add_computation!(attr, scene, Val(:meshscatter_f32c_scale))

    if attr[:depthsorting][]
        # is projectionview enough to trigger on scene resize in all cases?
        register_computation!(
            attr,
            [:positions_transformed_f32c, :projectionview, :model_f32c],
            [:gl_depth_cache, :gl_indices]
        ) do (pos, projectionview, model), changed, last
            pvm = projectionview * model
            depth_vals = isnothing(last) ? Float32[] : last.gl_depth_cache
            indices = isnothing(last) ? Cuint[] : last.gl_indices
            return depthsort!(pos, depth_vals, indices, pvm)
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
        # Needs explicit handling
        :alpha_colormap, :scaled_color, :scaled_colorrange,
        :sdf_marker_shape,
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
            :gl_markerspace, :quad_scale, :model_f32c, :f32c_scale,
            :lowclip_color, :highclip_color, :nan_color, :gl_indices, :gl_len,
            :marker_offset,
        ]

    else
        Makie.all_marker_computations!(attr)

        # Simple forwards
        uniforms = [
            :positions_transformed_f32c,
            :sdf_uv, :quad_scale, :quad_offset,
            :image, :lowclip_color, :highclip_color, :nan_color,
            :strokecolor, :strokewidth, :glowcolor, :glowwidth,
            :model_f32c, :converted_rotation, :billboard, :transform_marker,
            :gl_indices, :gl_len, :marker_offset, :f32c_scale,
        ]
    end

    Makie.add_computation!(attr, Val(:uniform_clip_planes))

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
        :gl_indices => :indices, :gl_len => :len,
        :converted_rotation => :rotation
    )

    robj = register_robj!(assemble_scatter_robj!, screen, scene, plot, inputs, uniforms, input2glname)

    return robj
end


################################################################################
### Text
################################################################################

function assemble_text_robj!(data, screen::Screen, attr, args, input2glname)
    data[:distancefield] = get_texture!(screen.glscreen, Makie.get_texture_atlas())
    data[:shape] = Cint(DISTANCEFIELD)
    data[:image] = nothing
    data[:rotation] = args.text_rotation

    # pass nothing to avoid going into image generating functions
    return draw_scatter(screen, (nothing, data[:position]), data)
end

function draw_atomic(screen::Screen, scene::Scene, plot::Text)
    attr = generic_robj_setup(screen, scene, plot)

    if haskey(attr, :depthsorting) && attr[:depthsorting][]
        # is projectionview enough to trigger on scene resize in all cases?
        register_computation!(
            attr,
            [:positions_transformed_f32c, :projectionview, :model_f32c],
            [:gl_depth_cache, :gl_indices]
        ) do (pos, projectionview, space, model), changed, last
            pvm = projectionview * model
            depth_vals = isnothing(last) ? Float32[] : last.gl_depth_cache
            indices = isnothing(last) ? Cuint[] : last.gl_indices
            return depthsort!(pos, depth_vals, indices, pvm)
        end
    else
        register_computation!(attr, [:positions_transformed_f32c], [:gl_indices]) do (ps,), changed, last
            return (length(ps),)
        end
    end

    register_computation!(attr, [:positions_transformed_f32c], [:gl_len]) do (ps,), changed, last
        return (Int32(length(ps)),)
    end

    Makie.add_computation!(attr, scene, Val(:meshscatter_f32c_scale))

    inputs = Symbol[]

    # Simple forwards
    uniforms = [
        :positions_transformed_f32c,
        :text_color, :text_strokecolor, :text_rotation,
        :marker_offset, :quad_offset, :sdf_uv, :quad_scale,
        :lowclip_color, :highclip_color, :nan_color,
        :strokewidth, :glowcolor, :glowwidth,
        :model_f32c, :transform_marker,
        :gl_indices, :gl_len, :f32c_scale,
    ]


    Makie.add_computation!(attr, Val(:uniform_clip_planes))

    # TODO: text_strokewidth doesn't work because the shader only accepts a uniform float
    # this is also true on master

    # To take the human error out of the bookkeeping of two lists
    # Could also consider using this in computation since Dict lookups are
    # O(1) and only takes ~4ns
    input2glname = Dict{Symbol, Symbol}(
        :text_rotation => :rotation,
        :positions_transformed_f32c => :position,
        :text_color => :color,
        :sdf_uv => :uv_offset_width,
        :gl_markerspace => :markerspace,
        :quad_scale => :scale,
        :quad_offset => :quad_offset,
        :marker_offset => :marker_offset,
        :text_strokecolor => :stroke_color, :strokewidth => :stroke_width,
        :glowcolor => :glow_color, :glowwidth => :glow_width,
        :model_f32c => :model, :transform_marker => :scale_primitive,
        :lowclip_color => :lowclip, :highclip_color => :highclip,
        :gl_indices => :indices, :gl_len => :len,
    )

    robj = register_robj!(assemble_text_robj!, screen, scene, plot, inputs, uniforms, input2glname)

    return robj
end

################################################################################
### MeshScatter
################################################################################

function assemble_meshscatter_robj!(data, screen::Screen, attr, args, input2glname)
    if args.packed_uv_transform isa Vector{Vec2f}
        data[:uv_transform] = TextureBuffer(screen.glscreen, args.packed_uv_transform)
    else
        data[:uv_transform] = args.packed_uv_transform
    end

    add_color_attributes!(screen, attr, data, args.scaled_color, args.alpha_colormap, args.scaled_colorrange)

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

    return draw_mesh_particle(screen, data)
end

function draw_atomic(screen::Screen, scene::Scene, plot::MeshScatter)
    attr = generic_robj_setup(screen, scene, plot)

    Makie.add_computation!(attr, Val(:disassemble_mesh), :marker)
    Makie.add_computation!(attr, Val(:uniform_clip_planes))
    Makie.add_computation!(attr, scene, Val(:uv_transform_packing))
    Makie.add_computation!(attr, scene, Val(:meshscatter_f32c_scale))
    Makie.register_world_normalmatrix!(attr)
    Makie.register_view_normalmatrix!(attr)

    register_computation!(attr, [:positions_transformed_f32c], [:instances, :gl_len]) do (pos,), changed, cached
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
        :vertex_position, :faces, :normal, :uv,
        :lowclip_color, :highclip_color, :nan_color, :matcap,
        :fetch_pixel, :model_f32c,
        :diffuse, :specular, :shininess, :backlight, :world_normalmatrix, :view_normalmatrix,
        :gl_len, :transform_marker,
    ]

    input2glname = Dict{Symbol, Symbol}(
        :positions_transformed_f32c => :position, :markersize => :scale,
        :vertex_position => :vertices, :normal => :normals, :uv => :texturecoordinates,
        :packed_uv_transform => :uv_transform,
        :alpha_colormap => :color_map, :scaled_colorrange => :color_norm,
        :scaled_color => :color, :lowclip_color => :lowclip, :highclip_color => :highclip,
        :model_f32c => :model, :gl_len => :len, :transform_marker => :scale_primitive,
    )

    robj = register_robj!(assemble_meshscatter_robj!, screen, scene, plot, inputs, uniforms, input2glname)

    return robj
end

################################################################################
### Lines
################################################################################

function assemble_lines_robj!(data, screen::Screen, attr, args, input2glname)
    positions = args[1] # changes name, so we use positional
    linestyle = attr[:linestyle][]

    data[:fast] = isnothing(linestyle)
    # :fast == true removes pattern from the shader so we don't need
    #               to worry about this
    data[:vertex] = positions # Needs to be set before draw_lines()
    data[:debug] = attr[:debug][]

    add_color_attributes_lines!(screen, attr, data, args.scaled_color, args.alpha_colormap, args.scaled_colorrange)

    if !isnothing(get(data, :intensity, nothing))
        input2glname[:scaled_color] = :intensity
    end

    return draw_lines(screen, positions, data)
end

# Observables removed and adjusted to fit Compute Pipeline
# Observables removed and adjusted to fit Compute Pipeline
function generate_indices(ps, indices = Cuint[], valid = Float32[])
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
    Makie.add_computation!(attr, :uniform_pattern, :uniform_pattern_length)

    # TODO: Is this useful for other backends?
    map!(*, attr, [:projectionview, :model_f32c], :gl_pvm32)
    register_computation!(
        attr, [:gl_pvm32, :positions_transformed_f32c], [:gl_projected_positions]
    ) do (pvm32, positions), changed, last
        output = isnothing(last) ? Point4f[] : last.gl_projected_positions
        resize!(output, length(positions))
        map!(output, positions) do pos
            return pvm32 * to_ndim(Point4d, to_ndim(Point3d, pos, 0.0), 1.0)
        end
        return (output,)
    end

    # TODO: This is a compile time constant that should be settable from the plot.
    # No point in making it an input here, since this is just before compilation.
    # Keeping `haskey()` in case add_constant is handled differently in the future
    haskey(attr, :debug) || add_constant!(attr, :debug, false)

    Makie.add_computation!(attr, Val(:uniform_clip_planes), :clip)

    if isnothing(plot.linestyle[])
        positions = :positions_transformed_f32c
        # unused dummy data
        map!(pos -> collect(Float32.(eachindex(pos))), attr, positions, :gl_last_length)
    else
        positions = :gl_projected_positions
        register_computation!(attr, [positions, :resolution], [:gl_last_length]) do (pos, res), changed, cached
            return (sumlengths(pos, res),)
        end
    end

    # Derived vertex attributes
    register_computation!(generate_indices, attr, [positions], [:gl_indices, :gl_valid_vertex])
    register_computation!(attr, [:gl_indices], [:gl_total_length]) do (indices,), changed, cached
        return (Int32(length(indices) - 2),)
    end


    inputs = [
        # relevant to creation time decisions
        positions,
        :space,
        :scaled_color, :alpha_colormap, :scaled_colorrange,
    ]
    # uniforms getting passed through
    uniforms = [
        :gl_indices, :gl_valid_vertex, :gl_total_length, :gl_last_length,
        :uniform_pattern, :uniform_pattern_length, :linecap, :gl_miter_limit, :joinstyle, :uniform_linewidth,
        :scene_origin, :model_f32c,
        :lowclip_color, :highclip_color, :nan_color, :debug,
    ]

    input2glname = Dict(
        positions => :vertex, :gl_indices => :indices, :gl_valid_vertex => :valid_vertex,
        :gl_total_length => :total_length, :gl_last_length => :lastlen,
        :gl_miter_limit => :miter_limit, :uniform_linewidth => :thickness,
        :uniform_pattern => :pattern, :uniform_pattern_length => :pattern_length,
        :scaled_color => :color, :alpha_colormap => :color_map, :scaled_colorrange => :color_norm,
        :model_f32c => :model, :uniform_num_clip_planes => :_num_clip_planes,
        :lowclip_color => :lowclip, :highclip_color => :highclip,
    )

    robj = register_robj!(assemble_lines_robj!, screen, scene, plot, inputs, uniforms, input2glname)

    return robj
end

################################################################################
### LineSegments
################################################################################

function assemble_linesegments_robj!(data, screen::Screen, attr, args, input2glname)
    data[:debug] = attr[:debug][]

    # add_camera_attributes!(data, screen, camera, args.space)
    add_color_attributes_lines!(screen, attr, data, args.scaled_color, args.alpha_colormap, args.scaled_colorrange)

    if !isnothing(get(data, :intensity, nothing))
        input2glname[:scaled_color] = :intensity
    end

    # Here we do need to be careful with pattern because :fast does not
    # exist as a compile time switch
    # Running this after add_uniforms overwrites
    if isnothing(attr[:linestyle][])
        data[:pattern] = nothing
    end
    return draw_linesegments(screen, data[:vertex], data)
end

function draw_atomic(screen::Screen, scene::Scene, plot::LineSegments)
    attr = generic_robj_setup(screen, scene, plot)

    # linestyle/pattern handling
    Makie.add_computation!(attr, :uniform_pattern, :uniform_pattern_length)
    haskey(attr, :debug) || add_constant!(attr, :debug, false) # see Lines
    # could use world space, but clip space fits better with other backends
    # costs ~1µs per clip plane
    Makie.add_computation!(attr, Val(:uniform_clip_planes), :clip)

    register_computation!(attr, [:positions_transformed_f32c], [:indices]) do (positions,), changed, cached
        return (length(positions),)
    end

    inputs = [
        :space,
        :scaled_color, :alpha_colormap, :scaled_colorrange,
    ]
    uniforms = [
        :positions_transformed_f32c, :indices,
        :uniform_pattern, :uniform_pattern_length, :linecap, :uniform_linewidth,
        :scene_origin, :model_f32c,
        :lowclip_color, :highclip_color, :nan_color, :debug,
    ]

    input2glname = Dict{Symbol, Symbol}(
        :positions_transformed_f32c => :vertex,
        :uniform_linewidth => :thickness, :model_f32c => :model,
        :uniform_pattern => :pattern, :uniform_pattern_length => :pattern_length,
        :scaled_color => :color, :alpha_colormap => :color_map, :scaled_colorrange => :color_norm,
        :lowclip_color => :lowclip, :highclip_color => :highclip, :uniform_num_clip_planes => :_num_clip_planes,
    )

    robj = register_robj!(assemble_linesegments_robj!, screen, scene, plot, inputs, uniforms, input2glname)

    return robj
end

################################################################################
### Image
################################################################################

function assemble_image_robj!(data, screen::Screen, attr, args, input2glname)
    r = Rect2f(0, 0, 1, 1)

    data[:faces] = decompose(GLTriangleFace, r)
    data[:texturecoordinates] = decompose_uv(r)
    data[:picking_mode] = "#define PICKING_INDEX_FROM_UV"

    colormap = args.alpha_colormap
    color = args.scaled_color
    colornorm = args.scaled_colorrange
    add_color_attributes!(screen, attr, data, color, colormap, colornorm)

    # always use :image with specific interpolation settings, so remove:
    pop!(data, :image, nothing)
    pop!(data, :intensity, nothing)

    # Correct the name mapping
    input2glname[:scaled_color] = :image
    interp = attr[:interpolate][] ? :linear : :nearest
    data[:image] = Texture(screen.glscreen, color; minfilter = interp)

    return draw_mesh(screen, data)
end


function draw_atomic(screen::Screen, scene::Scene, plot::Image)
    return draw_atomic_as_image(screen, scene, plot)
end

function draw_atomic_as_image(screen::Screen, scene::Scene, plot)
    attr = generic_robj_setup(screen, scene, plot)

    Makie.add_computation!(attr, Val(:uniform_clip_planes))

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

    robj = register_robj!(assemble_image_robj!, screen, scene, plot, inputs, uniforms, input2glname)

    return robj
end

################################################################################
### Heatmap
################################################################################

function assemble_heatmap_robj!(data, screen::Screen, attr, args, input2glname)
    data[:position_x] = Texture(screen.glscreen, args[1], minfilter = :nearest)
    data[:position_y] = Texture(screen.glscreen, args[2], minfilter = :nearest)

    # add_camera_attributes!(data, screen, camera, args.space)
    colormap = args.alpha_colormap
    color = args.scaled_color
    colornorm = args.scaled_colorrange
    add_color_attributes!(screen, attr, data, color, colormap, colornorm)

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

    return draw_heatmap(screen, data)
end

function draw_atomic(screen::Screen, scene::Scene, plot::Heatmap)
    attr = plot.attributes

    # TODO: requires position transforms in Makie
    # # Fast path for regular heatmaps
    # t = Makie.transform_func_obs(plot)
    # if attr[:x][] isa Makie.EndPoints && attr[:y][] isa Makie.EndPoints && Makie.is_identity_transform(t[])
    #     return draw_atomic_as_image(screen, scene, plot)
    # end

    generic_robj_setup(screen, scene, plot)

    Makie.add_computation!(attr, Val(:uniform_clip_planes))

    Makie.add_computation!(attr, scene, Val(:heatmap_transform))

    register_computation!(attr, [:x_transformed_f32c, :y_transformed_f32c], [:instances]) do (x, y), changed, cached
        return ((length(x) - 1) * (length(y) - 1),)
    end

    inputs = [
        :x_transformed_f32c, :y_transformed_f32c,
        # Special
        :space,
        # Needs explicit handling
        :alpha_colormap, :scaled_color, :scaled_colorrange,
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

    robj = register_robj!(assemble_heatmap_robj!, screen, scene, plot, inputs, uniforms, input2glname)

    return robj
end

################################################################################
### Surface
################################################################################

function assemble_surface_robj!(data, screen::Screen, attr, args, input2glname)
    colorname = add_mesh_color_attributes!(
        screen, attr, data,
        args.scaled_color,
        args.alpha_colormap,
        args.scaled_colorrange,
    )
    @assert colorname == :image

    return draw_surface(screen, data[:image], data)
end

function draw_atomic(screen::Screen, scene::Scene, plot::Surface)
    attr = plot.attributes

    generic_robj_setup(screen, scene, plot)
    Makie.add_computation!(attr, Val(:uniform_clip_planes))
    Makie.add_computation!(attr, scene, Val(:surface_transform))
    Makie.register_world_normalmatrix!(attr)
    Makie.register_view_normalmatrix!(attr)
    Makie.add_computation!(attr, scene, Val(:pattern_uv_transform))

    register_computation!(attr, [:z], [:instances]) do (z,), changed, cached
        return ((size(z, 1) - 1) * (size(z, 2) - 1),)
    end

    inputs = [
        # Special
        :space,
        # Needs explicit handling
        :alpha_colormap, :scaled_color, :scaled_colorrange,
    ]
    uniforms = [
        :x_transformed_f32c, :y_transformed_f32c, :z_transformed_f32c,
        :lowclip_color, :highclip_color, :nan_color, :matcap,
        :model_f32c, :instances,
        :diffuse, :specular, :shininess, :backlight, :world_normalmatrix,
        :view_normalmatrix,
        :invert_normals, :pattern_uv_transform, :fetch_pixel,
    ]

    input2glname = Dict{Symbol, Symbol}(
        :x_transformed_f32c => :position_x, :y_transformed_f32c => :position_y,
        :z_transformed_f32c => :position_z,
        :alpha_colormap => :color_map, :scaled_colorrange => :color_norm,
        :scaled_color => :image,
        :lowclip_color => :lowclip, :highclip_color => :highclip,
        :model_f32c => :model,
        :pattern_uv_transform => :uv_transform
    )

    robj = register_robj!(assemble_surface_robj!, screen, scene, plot, inputs, uniforms, input2glname)

    return robj
end

################################################################################
### Mesh
################################################################################

# mesh_inner part 1
function add_mesh_color_attributes!(screen, attr, data, color, colormap, colornorm)
    # Note: assuming el32convert, Pattern convert to happen in Makie or earlier elsewhere
    interp = attr[:interpolate][] ? :linear : :nearest
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
    elseif color isa AbstractVector{<:Colorant}
        data[:vertex_color] = color
        colorname = :vertex_color

    else # colormapped

        cm_interp = attr.color_mapping_type[] === Makie.continuous ? :linear : :nearest
        data[:color_map] = Texture(screen.glscreen, colormap, minfilter = cm_interp)
        data[:color_norm] = colornorm

        if color isa Union{AbstractMatrix{<:Real}, AbstractArray{<:Real, 3}}
            data[:image] = Texture(screen.glscreen, color, minfilter = interp)
            colorname = :image
        elseif color isa Union{Real, AbstractVector{<:Real}}
            data[:vertex_color] = color
            colorname = :vertex_color
        else
            error("Unsupported color type: $(typeof(to_value(color)))")
        end
    end

    return colorname
end


function assemble_mesh_robj!(data, screen::Screen, attr, args, input2glname)
    input2glname[:scaled_color] = add_mesh_color_attributes!(
        screen, attr, data,
        args.scaled_color,
        args.alpha_colormap,
        args.scaled_colorrange
    )

    data[:normals] === nothing && delete!(data, :normals)
    data[:texturecoordinates] === nothing && delete!(data, :texturecoordinates)

    return draw_mesh(screen, data)
end

function draw_atomic(screen::Screen, scene::Scene, plot::Mesh)
    attr = plot.attributes

    generic_robj_setup(screen, scene, plot)
    Makie.add_computation!(attr, Val(:uniform_clip_planes))
    Makie.register_world_normalmatrix!(attr)
    Makie.register_view_normalmatrix!(attr)

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
        :view_normalmatrix, :pattern_uv_transform, :fetch_pixel,
        :interpolate_in_fragment_shader,
    ]

    input2glname = Dict{Symbol, Symbol}(
        :positions_transformed_f32c => :vertices,
        :alpha_colormap => :color_map, :scaled_colorrange => :color_norm,
        :lowclip_color => :lowclip, :highclip_color => :highclip,
        :scaled_color => :image, :model_f32c => :model,
        :pattern_uv_transform => :uv_transform,
    )

    robj = register_robj!(assemble_mesh_robj!, screen, scene, plot, inputs, uniforms, input2glname)

    return robj
end


################################################################################
### Voxels
################################################################################


function assemble_voxel_robj!(data, screen::Screen, attr, args, input2glname)
    voxel_id = Texture(screen.glscreen, args.chunk_u8)
    uvt = args.packed_uv_transform
    data[:voxel_id] = voxel_id
    data[:uv_transform] = isnothing(uvt) ? nothing : Texture(screen.glscreen, uvt, minfilter = :nearest)

    if haskey(args, :voxel_color)
        interp = attr[:interpolate][] ? :linear : :nearest
        data[:color] = Texture(screen.glscreen, args.voxel_color, minfilter = interp)
    end

    return draw_voxels(screen, voxel_id, data)
end

function draw_atomic(screen::Screen, scene::Scene, plot::Voxels)
    attr = plot.attributes

    generic_robj_setup(screen, scene, plot)
    Makie.add_computation!(attr, scene, Val(:voxel_model))
    Makie.add_computation!(attr, Val(:uniform_clip_planes), :model, :voxel_model)

    Makie.register_world_normalmatrix!(attr, :voxel_model)

    register_computation!(attr, [:chunk_u8, :gap], [:instances]) do (chunk, gap), changed, cached
        N = sum(size(chunk))
        return (ifelse(gap > 0.01, 2 * N, N + 3),)
    end

    Makie.add_computation!(attr, scene, Val(:voxel_uv_transform))

    inputs = [
        # Special
        :space,
        # Needs explicit handling
        :chunk_u8, :packed_uv_transform,
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
        :uniform_num_clip_planes => :_num_clip_planes
    )

    robj = register_robj!(assemble_voxel_robj!, screen, scene, plot, inputs, uniforms, input2glname)

    return robj
end


################################################################################
### Volume
################################################################################


function assemble_volume_robj!(data, screen::Screen, attr, args, input2glname)
    interp = attr[:interpolate][] ? :linear : :nearest

    data[:volumedata] = Texture(screen.glscreen, args.scaled_color, minfilter = interp)
    data[:enable_depth] = attr[:enable_depth][]

    if args.scaled_color isa AbstractArray{<:Real}
        data[:color_map] = args.alpha_colormap
        data[:color_norm] = args.scaled_colorrange
    end

    return draw_volume(screen, data)
end

function draw_atomic(screen::Screen, scene::Scene, plot::Volume)
    attr = plot.attributes

    generic_robj_setup(screen, scene, plot)
    Makie.add_computation!(attr, scene, Val(:uniform_model)) # bit different from voxel_model

    # TODO: check if this should be the normal model matrix (for voxel too)
    Makie.add_computation!(attr, Val(:uniform_clip_planes), :model, :uniform_model)

    # TODO: reuse in clip planes
    register_computation!(attr, [:uniform_model], [:modelinv]) do (model,), changed, cached
        return (Mat4f(inv(model)),)
    end

    inputs = [
        # Special
        :space,
        # Needs explicit handling
        :alpha_colormap, :scaled_colorrange,
    ]
    uniforms = [
        :scaled_color, :modelinv, :algorithm, :absorption, :isovalue, :isorange,
        :diffuse, :specular, :shininess, :backlight,
        # :lowclip_color, :highclip_color, :nan_color,
        :uniform_model,
    ]

    input2glname = Dict{Symbol, Symbol}(
        :scaled_color => :volumedata, :uniform_model => :model,
        :alpha_colormap => :color_map, :scaled_colorrange => :color_norm,
        :uniform_num_clip_planes => :_num_clip_planes
    )

    robj = register_robj!(assemble_volume_robj!, screen, scene, plot, inputs, uniforms, input2glname)

    return robj
end
