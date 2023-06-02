function serialize_three(scene::Scene, plot::Union{Lines, LineSegments})
    uniforms = Dict(
        :opacity => 1.0,
        :linewidth => 2.0,
        :diffuse => Vec3f(0, 0, 0),
        :model => plot.model
    )
    return Dict(
        :name => string(Makie.plotkey(plot)) * "-" * string(objectid(plot)),
        :visible => plot.visible,
        :uuid => js_uuid(plot),
        :plot_type => :lines,
        :space => plot.space,

        :positions => collect(reinterpret(Float32, plot[1][])),
        :uniforms => serialize_uniforms(uniforms)
    )
end
