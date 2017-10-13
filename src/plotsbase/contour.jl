
function contour(x, y, z, kw_args)
    if kw_args[:fillrange] != nothing
        delete!(kw_args, :intensity)
        I = GLVisualize.Intensity{Float32}
        main = [I(z[j,i]) for i=1:size(z, 2), j=1:size(z, 1)]
        return visualize(main, Style(:default), kw_args)
    else
        h = kw_args[:levels]
        T = eltype(z)
        levels = Contour.contours(map(T, x), map(T, y), z, h)
        result = Point2f0[]
        zmin, zmax = get(kw_args, :limits, Vec2f0(ignorenan_extrema(z)))
        cmap = get(kw_args, :color_map, get(kw_args, :color, RGBA{Float32}(0,0,0,1)))
        colors = RGBA{Float32}[]
        for c in levels.contours
            for elem in c.lines
                append!(result, elem.vertices)
                push!(result, Point2f0(NaN32))
                col = GLVisualize.color_lookup(cmap, c.level, zmin, zmax)
                append!(colors, fill(col, length(elem.vertices) + 1))
            end
        end
        kw_args[:color] = colors
        kw_args[:color_map] = nothing
        kw_args[:color_norm] = nothing
        kw_args[:intensity] = nothing
        return visualize(result, Style(:lines),kw_args)
    end
end
