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
    elseif x isa Makie.PlotList
        # ignore unless not yet displayed
        Makie.for_each_atomic_plot(x) do plot
            if !haskey(screen.cache, objectid(plot))
                insert!(screen, scene, plot)
            end
        end
    else
        foreach(x.plots) do x
            insert!(screen, scene, x)
        end
    end
    screen.requires_update = true
    return
end

using Makie.ComputePipeline

################################################################################
### Util, delete later
################################################################################

function missing_uniforms(robj, inputs, input2name)
    inputset = Set([get(input2name, k, k) for k in inputs])
    vertexarray = robj.variants[:main]
    uniformset = union(
        keys(vertexarray.program.uniformloc),
        Symbol.(collect(keys(vertexarray.buffers))),
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
    for (k, v) in robj.buffers
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

struct RenderObjectUpdater <: Function
    screen::Screen
    robj::RenderObject
    gl_names::Dict{Symbol, Symbol}
end

function (updater::RenderObjectUpdater)(args::NamedTuple, changed::NamedTuple, @nospecialize(last))
    update_robjs!(updater.robj, args, changed, updater.gl_names)
    updater.screen.requires_update = true
    return (updater.robj,)
end

function update_robjs!(robj, args::NamedTuple, changed::NamedTuple, gl_names::Dict{Symbol, Symbol})
    for name in keys(args)
        changed[name] || continue
        value = args[name]
        gl_name = get(gl_names, name, name)
        # println("Updating ", name)
        if name === :visible
            robj.visible = value
        elseif gl_name === :indices || gl_name === :faces
            if robj.indices isa GLAbstraction.GPUArray
                GLAbstraction.update!(robj.indices, value)
            else
                robj.indices = value
            end
        elseif gl_name === :instances
            robj.instances = value
        elseif haskey(robj.uniforms, gl_name)
            if robj.uniforms[gl_name] isa GLAbstraction.GPUArray
                GLAbstraction.update!(robj.uniforms[gl_name], value)
            else
                converted = GLAbstraction.gl_convert(robj.context, value)
                if typeof(robj.uniforms[gl_name]) !== typeof(converted)
                    @error("Uniforms can not change their type.\n  uniforms[$gl_name]::$(typeof(robj.uniforms[gl_name])) = $name = $converted::$(typeof(converted))\n  in robj $(robj.id)")
                end
                robj.uniforms[gl_name] = converted
            end
        elseif haskey(robj.buffers, gl_name)
            GLAbstraction.update!(robj.buffers[gl_name], value)
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

    target = ifelse(needs_mapping, :intensity, :color)
    if _color isa Matrix{RGBAf} || _color isa ShaderAbstractions.Sampler
        data[:image] = _color
        data[:color] = RGBAf(1, 1, 1, 1)
        target = :image
    else
        data[:color] = _color
    end
    data[:intensity] = intensity
    data[:color_norm] = colornorm
    return target
end

function add_color_attributes_lines!(screen, attr, data, color, colormap, colornorm)
    needs_mapping = !(colornorm isa Nothing)
    interp = attr.color_mapping_type[] === Makie.continuous ? :linear : :nearest
    data[:color_map] = needs_mapping ? Texture(screen.glscreen, colormap, minfilter = interp) : nothing
    data[:color] = color
    data[:color_norm] = colornorm
    return nothing
end

# Everything register_light_attributes! below can add. Which of them a plot
# actually has says which shading mode it was registered for.
const LIGHT_ROBJ_UNIFORMS = (
    :ambient, :light_color, :light_direction,
    :N_lights, :light_types, :light_colors, :light_parameters,
)

function register_light_attributes!(screen, scene, attr, uniforms)
    # plot does not support shading
    haskey(attr, :shading) || return

    # On re-display these are already registered. To allow compiling shaders
    # with different light settings we need to clear old computations
    if haskey(attr, :ambient)
        if haskey(attr, :gl_renderobject)
            error("Try to register lights that have already been registered. Is the renderobject getting created twice?")
        else
            for key in LIGHT_ROBJ_UNIFORMS
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

function construct_robj(constructor!, screen, scene, attr, args, uniforms, input2glname)
    data = Dict{Symbol, Any}(
        :fxaa => attr[:fxaa][],
        :overdraw => attr[:overdraw][],
        :num_clip_planes => 0, # default for in-shader resolution of clip planes
        # TODO: integrate this into the OIT Render Stage
        :oit_scale => screen.config.transparency_weight_scale,
    )

    if haskey(attr, :shading)
        data[:shading] = attr[:shading][] ? Makie.get_shading_mode(scene) : NoShading
    end

    for name in uniforms
        data[get(input2glname, name, name)] = args[name]
    end

    return constructor!(data, screen, attr, args, input2glname)
end

# Leaves a render object needs beyond what register_render_leaves! returns. The
# camera leaves pushed below are not in here: register_camera! connects those
# from the scene, so a remote renderer supplies them itself.
const COMMON_ROBJ_UNIFORMS = (:uniform_clip_planes, :uniform_num_clip_planes, :depth_shift, :visible, :fxaa)

# Read straight off the plot while the render object is built -- by construct_robj
# and renders_in_stage below, and by SortPlots for :model -- rather than uploaded
# as an input. The same for every primitive, so they are declared here next to the
# code that reads them rather than in each primitive's leaves.
const ROBJ_CONSTRUCTION_ATTRIBUTES = (:overdraw, :ssao, :transparency, :shading, :model)


"""
    robj_inputs!(screen, scene, plot, inputs, uniforms, input2glname)

Every graph node the render object depends on, given what the primitive declared.
Adds the leaves that are always needed, the camera ones the scene supplies and
the lights, mutating `uniforms` and `input2glname` as it goes.

Touches no OpenGL, so a process that cannot render still gets the exact set --
that is what `RemoteScreen` ships, rather than describing it a second time.
"""
# Supplied by the scene a plot is drawn in, not by the plot. A remote renderer
# takes these from its own scene and gets them once per scene rather than once
# per render object -- one pan would otherwise resend them for every primitive.
const CAMERA_ROBJ_UNIFORMS = (
    :resolution, :projection, :projectionview, :view,
    :upvector, :eyeposition, :view_direction,
)

camera_robj_uniforms(attr) = haskey(attr, :preprojection) ?
    (CAMERA_ROBJ_UNIFORMS..., :preprojection) : CAMERA_ROBJ_UNIFORMS

function robj_inputs!(screen, scene, plot, inputs, uniforms, input2glname)
    attr = plot.attributes

    # These must always be there!
    append!(uniforms, COMMON_ROBJ_UNIFORMS)
    append!(uniforms, camera_robj_uniforms(attr))
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
    return merged_inputs
end

"""
    robj_args(plot, merged_inputs)

The values for `robj_inputs!`, ready to hand to `construct_robj`.
"""
function robj_args(plot, merged_inputs)
    attr = plot.attributes
    return NamedTuple(map(key -> key => getproperty(attr, key)[], merged_inputs))
end

function register_robj!(constructor!, screen, scene, plot, inputs, uniforms, input2glname)
    attr = plot.attributes
    merged_inputs = robj_inputs!(screen, scene, plot, inputs, uniforms, input2glname)

    robj = let
        args = robj_args(plot, merged_inputs)
        robj = construct_robj(constructor!, screen, scene, attr, args, uniforms, input2glname)
        initialize_renderobject!(screen, robj, plot)
        robj
    end

    # Filter out unused inputs and static attributes to prevent overwrite
    always_keep = Set([:visible, :indices, :faces, :instances, :fxaa])
    filter!(merged_inputs) do name
        glname = get(input2glname, name, name)
        if in(glname, always_keep)
            return true
        elseif any(kv -> (kv[1] !== name) && (kv[2] === name), input2glname)
            # something else is overwriting a direct passthrough
            # (e.g. color -> image for scatter)
            return false
        elseif haskey(robj.buffers, glname)
            return true
        elseif haskey(robj.uniforms, glname)
            is_static = isnothing(robj[glname])
            return !is_static
        else
            return false
        end
    end

    # TODO: clean this up
    # allows `constructor!` to remove inputs by making their name not appear in
    # uniforms so the filter above deletes it. This then removes the mapping
    # so it's not carried around with the callback
    filter!(p -> p[2] !== :unused, input2glname)

    flag_float64(robj)

    register_computation!(
        RenderObjectUpdater(screen, robj, input2glname),
        attr, merged_inputs, [:gl_renderobject]
    )

    ComputePipeline.unsafe_init!(attr.gl_renderobject, robj)

    # Initialize node (this is required for visible checks)
    attr.gl_renderobject[]

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
    fast_pixel = args.marker isa FastPixel
    colormap = args.alpha_colormap
    color = args.scaled_color
    colornorm = args.scaled_colorrange
    marker_shape = args.sdf_marker_shape

    # TODO: allowing user supplied atlas for e.g. sprite animations would be nice...
    data[:distancefield] = marker_shape === Cint(DISTANCEFIELD) ? get_texture!(screen.glscreen, Makie.get_texture_atlas()) : nothing
    data[:shape] = marker_shape

    colortarget = add_color_attributes!(screen, attr, data, color, colormap, colornorm)

    # Correct the name mapping
    if args.marker isa Union{AbstractMatrix, AbstractVector{<:AbstractMatrix}}
        input2glname[:scaled_color] = :unused
    else
        input2glname[:scaled_color] = colortarget
    end

    if fast_pixel
        return draw_pixel_scatter(screen, data[:position], data)
    else
        # pass nothing to avoid going into image generating functions
        return draw_scatter(screen, position, data)
    end
end


function gl_render_spec(plot::Scatter, inputs)
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
        :quad_scale => :scale,
        :strokecolor => :stroke_color, :strokewidth => :stroke_width,
        :glowcolor => :glow_color, :glowwidth => :glow_width,
        :model_f32c => :model, :transform_marker => :scale_primitive,
        :lowclip_color => :lowclip, :highclip_color => :highclip,
        :gl_indices => :indices, :gl_len => :len,
        :converted_rotation => :rotation
    )

    return assemble_scatter_robj!, input2glname
end

function draw_atomic(screen::Screen, scene::Scene, plot::Scatter)
    inputs, uniforms = register_render_leaves!(scene, plot)
    constructor!, input2glname = gl_render_spec(plot, inputs)
    return register_robj!(constructor!, screen, scene, plot, inputs, uniforms, input2glname)
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

function gl_render_spec(plot::Text, inputs)
    # TODO: text_strokewidth doesn't work because the shader only accepts a uniform float
    # this is also true on master
    # To take the human error out of the bookkeeping of two lists
    # Could also consider using this in computation since Dict lookups are
    # O(1) and only takes ~4ns
    input2glname = Dict{Symbol, Symbol}(
        :text_rotation => :rotation,
        :per_char_positions_transformed_f32c => :position,
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

    return assemble_text_robj!, input2glname
end

function draw_atomic(screen::Screen, scene::Scene, plot::Text)
    inputs, uniforms = register_render_leaves!(scene, plot)
    constructor!, input2glname = gl_render_spec(plot, inputs)
    return register_robj!(constructor!, screen, scene, plot, inputs, uniforms, input2glname)
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

    colortarget = add_color_attributes!(
        screen, attr, data, args.scaled_color, args.alpha_colormap,
        args.scaled_colorrange
    )

    # Correct the name mapping
    input2glname[:scaled_color] = colortarget

    return draw_mesh_particle(screen, data)
end

function gl_render_spec(plot::MeshScatter, inputs)
    input2glname = Dict{Symbol, Symbol}(
        :positions_transformed_f32c => :position, :markersize => :scale,
        :vertex_position => :vertices, :normal => :normals, :uv => :texturecoordinates,
        :packed_uv_transform => :uv_transform,
        :alpha_colormap => :color_map, :scaled_colorrange => :color_norm,
        :scaled_color => :color, :lowclip_color => :lowclip, :highclip_color => :highclip,
        :model_f32c => :model, :gl_len => :len, :transform_marker => :scale_primitive,
    )

    return assemble_meshscatter_robj!, input2glname
end

function draw_atomic(screen::Screen, scene::Scene, plot::MeshScatter)
    inputs, uniforms = register_render_leaves!(scene, plot)
    constructor!, input2glname = gl_render_spec(plot, inputs)
    return register_robj!(constructor!, screen, scene, plot, inputs, uniforms, input2glname)
end

################################################################################
### Lines
################################################################################

function assemble_lines_robj!(data, screen::Screen, attr, args, input2glname)
    positions = args[1] # changes name, so we use positional
    linestyle = args.linestyle

    data[:fast] = isnothing(linestyle)
    # :fast == true removes pattern from the shader so we don't need
    #               to worry about this
    data[:vertex] = positions # Needs to be set before draw_lines()
    data[:debug] = args.debug

    add_color_attributes_lines!(screen, attr, data, args.scaled_color, args.alpha_colormap, args.scaled_colorrange)

    if !isnothing(get(data, :intensity, nothing))
        input2glname[:scaled_color] = :intensity
    end

    return draw_lines(screen, positions, data)
end

function gl_render_spec(plot::Lines, inputs)
    # :positions_transformed_f32c or :gl_projected_positions depending on
    # linestyle; assemble_lines_robj! relies on it being first as well.
    positions = first(inputs)
    input2glname = Dict(
        positions => :vertex, :gl_indices => :indices, :gl_valid_vertex => :valid_vertex,
        :gl_total_length => :total_length, :gl_last_length => :lastlen,
        :gl_miter_limit => :miter_limit, :uniform_linewidth => :thickness,
        :uniform_pattern => :pattern, :uniform_pattern_length => :pattern_length,
        :scaled_color => :color, :alpha_colormap => :color_map, :scaled_colorrange => :color_norm,
        :model_f32c => :model, :uniform_num_clip_planes => :_num_clip_planes,
        :lowclip_color => :lowclip, :highclip_color => :highclip,
    )

    return assemble_lines_robj!, input2glname
end

function draw_atomic(screen::Screen, scene::Scene, plot::Lines)
    inputs, uniforms = register_render_leaves!(scene, plot)
    constructor!, input2glname = gl_render_spec(plot, inputs)
    return register_robj!(constructor!, screen, scene, plot, inputs, uniforms, input2glname)
end

################################################################################
### LineSegments
################################################################################

function assemble_linesegments_robj!(data, screen::Screen, attr, args, input2glname)
    data[:debug] = args.debug

    # add_camera_attributes!(data, screen, camera, args.space)
    add_color_attributes_lines!(screen, attr, data, args.scaled_color, args.alpha_colormap, args.scaled_colorrange)

    if !isnothing(get(data, :intensity, nothing))
        input2glname[:scaled_color] = :intensity
    end

    # Here we do need to be careful with pattern because :fast does not
    # exist as a compile time switch
    # Running this after add_uniforms overwrites
    if isnothing(args.linestyle)
        data[:pattern] = nothing
    end
    return draw_linesegments(screen, data[:vertex], data)
end

function gl_render_spec(plot::LineSegments, inputs)
    input2glname = Dict{Symbol, Symbol}(
        :positions_transformed_f32c => :vertex,
        :uniform_linewidth => :thickness, :model_f32c => :model,
        :uniform_pattern => :pattern, :uniform_pattern_length => :pattern_length,
        :scaled_color => :color, :alpha_colormap => :color_map, :scaled_colorrange => :color_norm,
        :lowclip_color => :lowclip, :highclip_color => :highclip, :uniform_num_clip_planes => :_num_clip_planes,
    )

    return assemble_linesegments_robj!, input2glname
end

function draw_atomic(screen::Screen, scene::Scene, plot::LineSegments)
    inputs, uniforms = register_render_leaves!(scene, plot)
    constructor!, input2glname = gl_render_spec(plot, inputs)
    return register_robj!(constructor!, screen, scene, plot, inputs, uniforms, input2glname)
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
    interp = args.interpolate ? :linear : :nearest
    data[:image] = Texture(screen.glscreen, color; minfilter = interp)

    return draw_mesh(screen, data)
end


# Image is drawn as a textured quad; the spec lives under its own name so a
# future Heatmap fast path can share it.
gl_render_spec(plot::Image, inputs) = gl_image_render_spec(plot, inputs)

function draw_atomic(screen::Screen, scene::Scene, plot::Image)
    return draw_atomic_as_image(screen, scene, plot)
end

function gl_image_render_spec(plot, inputs)
    input2glname = Dict{Symbol, Symbol}(
        :positions_transformed_f32c => :vertices,
        :alpha_colormap => :color_map, :scaled_colorrange => :color_norm,
        :lowclip_color => :lowclip, :highclip_color => :highclip,
        :scaled_color => :image, :model_f32c => :model,
    )

    return assemble_image_robj!, input2glname
end

function draw_atomic_as_image(screen::Screen, scene::Scene, plot)
    inputs, uniforms = register_image_render_leaves!(scene, plot)
    constructor!, input2glname = gl_image_render_spec(plot, inputs)
    return register_robj!(constructor!, screen, scene, plot, inputs, uniforms, input2glname)
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
    interp = args.interpolate ? :linear : :nearest
    if color isa ShaderAbstractions.Sampler
        data[:intensity] = color
    else
        data[:intensity] = Texture(screen.glscreen, color; minfilter = interp)
    end

    return draw_heatmap(screen, data)
end

function gl_render_spec(plot::Heatmap, inputs)
    input2glname = Dict{Symbol, Symbol}(
        :x_transformed_f32c => :position_x, :y_transformed_f32c => :position_y,
        :alpha_colormap => :color_map, :scaled_colorrange => :color_norm,
        :lowclip_color => :lowclip, :highclip_color => :highclip,
        :scaled_color => :image,
        :model_f32c => :model,
    )

    return assemble_heatmap_robj!, input2glname
end

function draw_atomic(screen::Screen, scene::Scene, plot::Heatmap)
    inputs, uniforms = register_render_leaves!(scene, plot)
    constructor!, input2glname = gl_render_spec(plot, inputs)
    return register_robj!(constructor!, screen, scene, plot, inputs, uniforms, input2glname)
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

function gl_render_spec(plot::Surface, inputs)
    input2glname = Dict{Symbol, Symbol}(
        :x_transformed_f32c => :position_x, :y_transformed_f32c => :position_y,
        :z_transformed_f32c => :position_z,
        :alpha_colormap => :color_map, :scaled_colorrange => :color_norm,
        :scaled_color => :image,
        :lowclip_color => :lowclip, :highclip_color => :highclip,
        :model_f32c => :model,
        :pattern_uv_transform => :uv_transform
    )

    return assemble_surface_robj!, input2glname
end

function draw_atomic(screen::Screen, scene::Scene, plot::Surface)
    inputs, uniforms = register_render_leaves!(scene, plot)
    constructor!, input2glname = gl_render_spec(plot, inputs)
    return register_robj!(constructor!, screen, scene, plot, inputs, uniforms, input2glname)
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

    return draw_mesh(screen, data)
end

function gl_render_spec(plot::Mesh, inputs)
    input2glname = Dict{Symbol, Symbol}(
        :positions_transformed_f32c => :vertices,
        :alpha_colormap => :color_map, :scaled_colorrange => :color_norm,
        :lowclip_color => :lowclip, :highclip_color => :highclip,
        :scaled_color => :image, :model_f32c => :model,
        :pattern_uv_transform => :uv_transform,
    )

    return assemble_mesh_robj!, input2glname
end

function draw_atomic(screen::Screen, scene::Scene, plot::Mesh)
    inputs, uniforms = register_render_leaves!(scene, plot)
    constructor!, input2glname = gl_render_spec(plot, inputs)
    return register_robj!(constructor!, screen, scene, plot, inputs, uniforms, input2glname)
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
        interp = args.interpolate ? :linear : :nearest
        data[:color] = Texture(screen.glscreen, args.voxel_color, minfilter = interp)
    end

    return draw_voxels(screen, voxel_id, data)
end

function gl_render_spec(plot::Voxels, inputs)
    input2glname = Dict{Symbol, Symbol}(
        :chunk_u8 => :voxel_id, :voxel_model => :model, :packed_uv_transform => :uv_transform,
        :voxel_colormap => :color_map, :voxel_color => :color,
        :uniform_num_clip_planes => :_num_clip_planes
    )

    return assemble_voxel_robj!, input2glname
end

function draw_atomic(screen::Screen, scene::Scene, plot::Voxels)
    inputs, uniforms = register_render_leaves!(scene, plot)
    constructor!, input2glname = gl_render_spec(plot, inputs)
    return register_robj!(constructor!, screen, scene, plot, inputs, uniforms, input2glname)
end


################################################################################
### Volume
################################################################################


function assemble_volume_robj!(data, screen::Screen, attr, args, input2glname)
    interp = args.interpolate ? :linear : :nearest

    data[:volumedata] = Texture(screen.glscreen, args.scaled_color, minfilter = interp)
    data[:enable_depth] = args.enable_depth

    if args.scaled_color isa AbstractArray{<:Real}
        data[:color_map] = args.alpha_colormap
        data[:color_norm] = args.scaled_colorrange
    end

    return draw_volume(screen, data)
end

function gl_render_spec(plot::Volume, inputs)
    input2glname = Dict{Symbol, Symbol}(
        :scaled_color => :volumedata, :uniform_model => :model,
        :alpha_colormap => :color_map, :scaled_colorrange => :color_norm,
        :uniform_num_clip_planes => :_num_clip_planes,
        :lowclip_color => :lowclip, :highclip_color => :highclip,
    )

    return assemble_volume_robj!, input2glname
end

function draw_atomic(screen::Screen, scene::Scene, plot::Volume)
    inputs, uniforms = register_render_leaves!(scene, plot)
    constructor!, input2glname = gl_render_spec(plot, inputs)
    return register_robj!(constructor!, screen, scene, plot, inputs, uniforms, input2glname)
end
