function serialize_three(scene::Scene, plot::Union{Lines, LineSegments})
    Makie.@converted_attribute plot (linewidth, color)
    uniforms = Dict(
        :pattern_length => 1f0,
        :model => plot.model,
        :is_valid => Vec4f(1),
    )
    attributes = Dict{Symbol, Any}(
        :linepoint => lift(serialize_buffer_attribute, plot[1])
    )
    for (name, attr) in [:color => color, :linewidth => linewidth]
        if Makie.is_scalar_attribute(to_value(attr))
            uniforms[Symbol("$(name)_start")] = attr
            uniforms[Symbol("$(name)_end")] = attr
        else
            attributes[name] = lift(serialize_buffer_attribute, attr)
        end
    end
    attr = Dict(
        :name => string(Makie.plotkey(plot)) * "-" * string(objectid(plot)),
        :visible => plot.visible,
        :uuid => js_uuid(plot),
        :plot_type => :lines,
        :cam_space => plot.space[],
        :is_linesegments => plot isa LineSegments,

        :uniforms => serialize_uniforms(uniforms),
        :attributes => attributes
    )
    return attr
end
