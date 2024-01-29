function serialize_three(scene::Scene, plot::Union{Lines, LineSegments})
    Makie.@converted_attribute plot (linewidth,)
    uniforms = Dict(
        :model => plot.model,
        :depth_shift => plot.depth_shift,
        :picking => false,
    )

    color = plot.calculated_colors
    if color[] isa Makie.ColorMapping
        uniforms[:colormap] = Sampler(color[].colormap)
        uniforms[:colorrange] = color[].colorrange_scaled
        uniforms[:highclip] = Makie.highclip(color[])
        uniforms[:lowclip] = Makie.lowclip(color[])
        uniforms[:nan_color] = color[].nan_color
        color = color[].color_scaled
    else
        for name in [:nan_color, :highclip, :lowclip]
            uniforms[name] = RGBAf(0, 0, 0, 0)
        end
        get!(uniforms, :colormap, false)
        get!(uniforms, :colorrange, false)
    end
    points_transformed = lift(plot, transform_func_obs(plot), plot[1], plot.space) do tf, ps, space
        output = apply_transform(tf, ps, space)
        # TODO: Do this in javascript?
        pushfirst!(output, output[1])
        push!(output, output[end])
        return output
    end
    positions = lift(serialize_buffer_attribute, plot, points_transformed)
    attributes = Dict{Symbol, Any}(:linepoint => positions)
    for (name, attr) in [:color => color, :linewidth => linewidth]
        if Makie.is_scalar_attribute(to_value(attr))
            uniforms[Symbol("$(name)_start")] = attr
            uniforms[Symbol("$(name)_end")] = attr
        else
            attributes[name] = lift(plot, attr) do vals
                # TODO: in js?
                serialize_buffer_attribute([first(vals); vals; last(vals)])
            end
        end
    end

    @info typeof(plot)
    @info attributes

    attr = Dict(
        :name => string(Makie.plotkey(plot)) * "-" * string(objectid(plot)),
        :visible => plot.visible,
        :uuid => js_uuid(plot),
        :plot_type => plot isa LineSegments ? "linesegments" : "lines",
        :cam_space => plot.space[],
        :uniforms => serialize_uniforms(uniforms),
        :uniform_updater => uniform_updater(plot, uniforms),
        :attributes => attributes
    )
    return attr
end
