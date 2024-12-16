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
        uniforms[:colormap] = Sampler(attr.alpha_colormap[])
        uniforms[:colorrange] = attr.scaled_colorrange[]
        uniforms[:highclip] = attr._highclip[]
        uniforms[:lowclip] = attr._lowclip[]
        uniforms[:nan_color] = attr.nan_color[]
        color = attr.scaled_color[]
    else
        for name in [:nan_color, :highclip, :lowclip]
            uniforms[name] = RGBAf(0, 0, 0, 0)
        end
        uniforms[:colormap] = false
        uniforms[:colorrange] = false
        color = attr.color[]
    end
    points = attr.positions_transformed_f32c[]
    positions = serialize_buffer_attribute(points)

    attributes = Dict{Symbol,Any}(
        :linepoint => Observable(positions),
        :lineindex => Observable(serialize_buffer_attribute(collect(UInt32(1):UInt32(length(points))))),
        :lastlen => Observable(serialize_buffer_attribute(zeros(Float32, length(points))))
    )

    for (name, vals) in [:color => color, :linewidth => attr.linewidth[]]
        if Makie.is_scalar_attribute(to_value(vals))
            uniforms[Symbol("$(name)_start")] = vals
            uniforms[Symbol("$(name)_end")] = vals
        else
            # TODO: to js?
            # duplicates per vertex attributes to match positional duplication
            # min(idxs, end) avoids update order issues here
            attributes[name] = Observable(serialize_buffer_attribute(vals))
        end
    end

    uniforms[:num_clip_planes] = 0
    uniforms[:clip_planes] = [Vec4f(0, 0, 0, -1e9) for _ in 1:8]

    return Dict(
        :visible => Observable(attr.visible[]),
        :plot_type => islines ? "lines" : "linesegments",
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
    :color,
    :scaled_color,
    :alpha_colormap,
    :scaled_colorrange,
    # Auto
    :positions_transformed_f32c,
    :linecap,
    :linestyle,
    :gl_pattern,
    :gl_pattern_length,
    :linewidth,
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
    inputs = copy(LINE_INPUTS)
    if islines
        push!(inputs, :joinstyle, :gl_miter_limit)
    end
    return (create_lines_data(islines, (; zip(inputs, args)...)),)
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

    register_computation!((args...)-> create_lines_robj(islines, args...), attr, inputs, [:wgl_renderobject])
    dict = attr[:wgl_renderobject][]
    dict[:uuid] = js_uuid(plot)
    dict[:name] = string(Makie.plotkey(plot)) * "-" * string(objectid(plot))
    dict[:uniform_updater] = uniform_updater(plot, dict[:uniforms])
    return dict
end
