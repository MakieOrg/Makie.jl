Makie.plot!(plot::ShaderToy) = plot
point_iterator(p::ShaderToy) = decompose(Point3f, p.rect[])
convert_arguments(::Type{<:ShaderToy}, args...) = args
