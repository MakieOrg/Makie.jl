Makie.plot!(plot::ShaderToy) = plot
point_iterator(p::ShaderToy) = decompose(Point3f, p.rect[])
convert_arguments(::Type{<:ShaderToy}, args...) = args
convert_arguments(::Type{<:ShaderToy}, frag::String) = (Rect2f(-1, -1, 2, 2), frag)

needs_tight_limits(::ShaderToy) = true
