function serialize_three(scene::Scene, plot::Union{Lines, LineSegments})
    Makie.@converted_attribute plot (linewidth, color)
    uniforms = Dict(
        :pattern_length => 1f0,
        :model => plot.model,
        :is_valid => Vec4f(1),
        :linewidth => linewidth,
        :color => color
    )

    attr = Dict(
        :name => string(Makie.plotkey(plot)) * "-" * string(objectid(plot)),
        :visible => plot.visible,
        :uuid => js_uuid(plot),
        :plot_type => :lines,
        :cam_space => plot.space[],
        :is_linesegments => plot isa LineSegments,
        :positions => lift(x-> collect(reinterpret(Float32, x)), plot[1]),
        :uniforms => serialize_uniforms(uniforms),
    )
    return attr
end
