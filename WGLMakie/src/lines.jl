function serialize_three(scene::Scene, plot::Union{Lines, LineSegments})
    uniforms = Dict(
        :opacity => 1.0,
        :linewidth => plot.linewidth[],
        :diffuse => Vec3f(0, 0, 0),
        :model => plot.model
    )
    color = to_color(plot.color[])
    if color isa Colorant
        uniforms[:color] = serialize_three(color)
    else
        uniforms[:color] = serialize_three(to_color(:black))
    end
    attr = Dict(
        :name => string(Makie.plotkey(plot)) * "-" * string(objectid(plot)),
        :visible => plot.visible,
        :uuid => js_uuid(plot),
        :plot_type => :lines,
        :cam_space => plot.space[],
        :is_linesegments => plot isa LineSegments,
        :positions => collect(reinterpret(Float32, plot[1][])),
        :uniforms => serialize_uniforms(uniforms)
    )

    return attr
end
