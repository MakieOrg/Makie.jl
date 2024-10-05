Makie.plot!(plot::GLShader) = plot
point_iterator(p::GLShader) = decompose(Point3f, p.rect[])
convert_arguments(::Type{<:GLShader}, args...) = args
