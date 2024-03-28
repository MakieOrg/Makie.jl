################################################################################
### from data_limits
################################################################################

# TODO: boundingbox
# function data_limits(text::Text{<: Tuple{<: Union{GlyphCollection, AbstractVector{GlyphCollection}}}})
#     if is_data_space(text.markerspace[])
#         return boundingbox(text)
#     else
#         if text.position[] isa VecTypes
#             return Rect3d(text.position[])
#         else
#             # TODO: is this branch necessary?
#             return Rect3d(convert_arguments(PointBased(), text.position[])[1])
#         end
#     end
# end
# function data_limits(text::Text)
    # return data_limits(text.plots[1])
# end

# TODO: unused?
# function br_getindex(vector::AbstractVector, idx::CartesianIndex, dim::Int)
#     return vector[Tuple(idx)[dim]]
# end
# function br_getindex(matrix::AbstractMatrix, idx::CartesianIndex, dim::Int)
#     return matrix[idx]
# end

# TODO: boundingbox

# function foreach_transformed(f, point_iterator, model, trans_func)
#     for point in point_iterator
#         point_t = apply_transform(trans_func, point)
#         point_m = project(model, point_t)
#         f(point_m)
#     end
#     return
# end

# function foreach_transformed(f, plot)
#     points = point_iterator(plot)
#     t = transformation(plot)
#     model = model_transform(t)
#     trans_func = t.transform_func[]
#     # use function barrier since trans_func is Any
#     foreach_transformed(f, points, model, identity)
# end


# # TODO: What's your purpose?
# function point_iterator(list::AbstractVector)
#     if length(list) == 1
#         # save a copy!
#         return point_iterator(list[1])
#     else
#         points = Point3d[]
#         for elem in list
#             for point in point_iterator(elem)
#                 push!(points, to_ndim(Point3d, point, 0))
#             end
#         end
#         return points
#     end
# end


################################################################################
### from boundingboxes/text
################################################################################

#=
function project_widths(matrix, vec)
    pr = project(matrix, vec)
    zero = project(matrix, zeros(typeof(vec)))
    return pr - zero
end

_inkboundingbox(ext::GlyphExtent) = ext.ink_bounding_box

_is_latex_string(x::AbstractVector{<:LaTeXString}) = true
_is_latex_string(x::LaTeXString) = true
_is_latex_string(other) = false

"""
Calculate an approximation of a tight rectangle around a 2D rectangle rotated by `angle` radians.
This is not perfect but works well enough. Check an A vs X to see the difference.
"""
function rotatedrect(rect::Rect{2, T}, angle)::Rect{2, T} where T
    ox, oy = rect.origin
    wx, wy = rect.widths
    points = Mat{2, 4, T}(
        ox, oy,
        ox, oy+wy,
        ox+wx, oy,
        ox+wx, oy+wy
    )
    mrot = Mat{2, 2, T}(
        cos(angle), -sin(angle),
        sin(angle), cos(angle)
    )
    rotated = mrot * points

    rmins = minimum(rotated; dims=2)
    rmaxs = maximum(rotated; dims=2)

    return Rect2(rmins..., (rmaxs .- rmins)...)
end

=#