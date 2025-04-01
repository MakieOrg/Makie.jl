function create_lines_data(islines, attr)
    uniforms = Dict(
        :model => attr.model_f32c[],
        :depth_shift => attr.depth_shift[],
        :picking => false,
        :linecap => attr.linecap[],
        :scene_origin => attr.scene_origin[],
    )
    if islines
        uniforms[:joinstyle] = attr.joinstyle[]
        uniforms[:miter_limit] = attr.gl_miter_limit[]
    end

    if isnothing(attr.linestyle[])
        uniforms[:pattern] = false
        uniforms[:pattern_length] = 1.0f0
    else
        uniforms[:pattern] = Sampler(attr.gl_pattern[]; x_repeat=:repeat)
        uniforms[:pattern_length] = attr.gl_pattern_length[]
    end

    if !isnothing(attr.scaled_colorrange[])
        cm_minfilter = attr.colormapping_type[] === Makie.continuous ? :linear : :nearest
        uniforms[:colormap] = Sampler(attr.alpha_colormap[], minfilter = cm_minfilter)
        uniforms[:colorrange] = attr.scaled_colorrange[]
        uniforms[:highclip] = attr._highclip[]
        uniforms[:lowclip] = attr._lowclip[]
        uniforms[:nan_color] = attr.nan_color[]
        color = attr.synched_color[]
    else
        for name in [:nan_color, :highclip, :lowclip]
            uniforms[name] = RGBAf(0, 0, 0, 0)
        end
        uniforms[:colormap] = false
        uniforms[:colorrange] = false
        color = attr.synched_color[]
    end

    attributes = Dict{Symbol,Any}(
        :linepoint => serialize_buffer_attribute(attr.positions_transformed_f32c[]),
    )

    for (name, vals) in [:color => color, :linewidth => attr.synched_linewidth[]]
        if Makie.is_scalar_attribute(to_value(vals))
            uniforms[name] = vals
        else
            # TODO: to js?
            # duplicates per vertex attributes to match positional duplication
            # min(idxs, end) avoids update order issues here
            attributes[name] = serialize_buffer_attribute(vals)
        end
    end

    uniforms[:num_clip_planes] = 0
    uniforms[:clip_planes] = [Vec4f(0, 0, 0, -1e9) for _ in 1:8]
    return Dict(
        :visible => Observable(attr.visible[]),
        :is_segments => !islines,
        :plot_type => "Lines",
        :cam_space => attr.space[],
        :uniforms => serialize_uniforms(uniforms),
        :attributes => attributes,
        :transparency => attr.transparency[],
        :overdraw => false, # TODO
        :zvalue => 0,
    )
end

const LINE_INPUTS = [
    # relevant to compile time decisions
    :space,
    :synched_color,
    :alpha_colormap,
    :scaled_colorrange,
    # Auto
    :positions_transformed_f32c,
    :linecap,
    :linestyle,
    :gl_pattern,
    :gl_pattern_length,
    :synched_linewidth,
    :scene_origin,
    :transparency,
    :visible,
    :model_f32c,
    :_lowclip,
    :_highclip,
    :nan_color,
    :depth_shift,
]

function create_lines_robj(islines, args, changed, last)
    r = Dict(
        :image => :uniform_color,
        :scaled_colorrange => :colorrange,
        :synched_color => :color,
        :synched_linewidth => :linewidth,
        :positions_transformed_f32c => :linepoint,
        :_highclip => :highclip,
        :_lowclip => :lowclip,
        :data_limit_points_transformed => :position,
        :model_f32c => :model,
    )
    if isnothing(last)
        return (create_lines_data(islines, args), Observable([]))
    else
        updater = last[2][]
        update_values!(updater, plot_updates(args, changed, r))
        return nothing
    end
end

function serialize_three(scene::Scene, plot::Union{Lines, LineSegments})
    attr = plot.args[1]

    Makie.add_computation!(attr, scene, :scene_origin)
    Makie.add_computation!(attr, :gl_pattern, :gl_pattern_length)

    islines = plot isa Lines
    inputs = copy(LINE_INPUTS)

    if islines
        Makie.add_computation!(attr, :gl_miter_limit)
        push!(inputs, :joinstyle, :gl_miter_limit)
    end

    register_computation!(
        (args...) -> create_lines_robj(islines, args...),
        attr,
        inputs,
        [:wgl_renderobject, :wgl_update_obs],
    )

    dict = attr[:wgl_renderobject][]
    dict[:uuid] = js_uuid(plot)
    dict[:name] = string(Makie.plotkey(plot)) * "-" * string(objectid(plot))
    dict[:updater] = attr[:wgl_update_obs][]
    on(attr.onchange) do _
        attr[:wgl_renderobject][]
        return
    end
    return dict
end
