function _poly(scene::makie, attributes::Dict)
    attributes = poly_defaults(scene, attributes)
    bigmesh = lift_node(attributes[:positions]) do p
        polys = GeometryTypes.split_intersections(p)
        merge(GLPlainMesh.(polys))
    end
    mesh(scene, bigmesh, color = attributes[:color])
    line = lift_node(attributes[:positions]) do p
        Point2f0[p; p[1:1]]
    end
    lines(scene, line,
        color = attributes[:linecolor], linestyle = attributes[:linestyle],
        linewidth = attributes[:linewidth]
    )
    return Scene(scene, attributes, :poly)
end
function poly(scene::makie, points::AbstractVector{Point2f0}, attributes::Dict)
    attributes[:positions] = points
    _poly(scene, attributes)
end
function poly(scene::makie, x::AbstractVector{<: Number}, y::AbstractVector{<: Number}, attributes::Dict)
    attributes[:x] = x
    attributes[:y] = y
    _poly(scene, attributes)
end

function poly(scene::makie, x::AbstractVector{T}, attributes::Dict) where T <: Union{Circle, Rectangle}
    position = lift_node(to_node(x)) do rects
        map(rects) do rect
            minimum(rect) .+ (widths(rect) ./ 2f0)
        end
    end
    scale = lift_node(to_node(x)) do rects
        widths.(rects)
    end
    scatter(scene, position; markersize = scale, marker = T, attributes...)
end
