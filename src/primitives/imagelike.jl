function heatmap(x,y,z, kw_args)
    get!(kw_args, :color_norm, Vec2f0(ignorenan_extrema(z)))
    get!(kw_args, :color_map, Plots.make_gradient(cgrad()))
    delete!(kw_args, :intensity)
    I = GLVisualize.Intensity{Float32}
    heatmap = I[z[j,i] for i=1:size(z, 2), j=1:size(z, 1)]
    tex = GLAbstraction.Texture(heatmap, minfilter=:nearest)
    kw_args[:stroke_width] = 0f0
    kw_args[:levels] = 1f0
    visualize(tex, Style(:default), kw_args)
end
function image(img, kw_args)
    rect = kw_args[:primitive]
    kw_args[:primitive] = GeometryTypes.SimpleRectangle{Float32}(rect.x, rect.y, rect.h, rect.w) # seems to be flipped
    visualize(img, Style(:default), kw_args)
end
