function serialize_three(scene::Scene, plot::Union{Lines, LineSegments})

    uniforms = Dict(
        # :linewidth => plot.linewidth[],
        :pattern_length => 1f0,
        :model => plot.model,
        :is_valid => Vec4f(1),
        :thickness_start => plot.linewidth[],
        :thickness_end => plot.linewidth[]
    )
    color = to_color(plot.color[])

    c = color isa Colorant ? serialize_three(color) : serialize_three(RGBAf(0, 0, 0, 1))

    uniforms[:color_start] = c
    uniforms[:color_end] = c

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
