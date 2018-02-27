function poly(scene::makie, x, y, attributes::Dict)
    attributes[:x] = x
    attributes[:y] = y
    attributes = lines_defaults(scene, attributes)
    polys, gl_data = poly_2glvisualize(attributes)
    result = []
    for poly in polys
        mesh = GLNormalMesh(poly) # make polygon
        if !isempty(GeometryTypes.faces(mesh)) # check if polygonation has any faces
            viz = visualize(mesh, :poly, color=attributes[:color]).children[]
            insert_scene!(scene, :poly, viz, attributes)
        else
            warn("Couldn't draw the polygon: $(attributes[:positions])")
        end
    end
    return scene
end

function poly_2glvisualize(attributes::Dict)
    points = attributes[:positions]
    last(points) == first(points) && pop!(points)
    polys = GeometryTypes.split_intersections(to_value(points))
    result = Dict{Symbol, Any}()
    for (k, v) in attributes

        k in (:mesh, :normals, :indices, :positions, always_skip...) && continue

        if k == :shading
            result[k] = to_value(v) # as signal not supported currently, will require shader signals
            continue
        end
        if k == :color && isa(v, AbstractVector)
            # normal colors pass through, vector of colors should be part of mesh already
            continue
        end
        result[k] = to_signal(v)
    end
    result[:visible] = true
    result[:fxaa] = true
    polys, result
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
