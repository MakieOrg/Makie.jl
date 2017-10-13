
function poly(::makie, points, attributes::Dict)
    last(points) == first(points) && pop!(points)
    polys = GeometryTypes.split_intersections(points)
    result = []
    for poly in polys
        mesh = GLNormalMesh(poly) # make polygon
        if !isempty(GeometryTypes.faces(mesh)) # check if polygonation has any faces
            push!(result, GLVisualize.visualize(mesh, Style(:default), kw_args))
        else
            warn("Couldn't draw the polygon: $points")
        end
    end
    result
end


function shape(d, kw_args)
    points = Plots.extract_points(d)
    result = []
    for rng in iter_segments(d[:x], d[:y])
        ps = points[rng]
        meshes = poly(ps, kw_args)
        append!(result, meshes)
    end
    result
end
