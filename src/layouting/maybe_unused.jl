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
# Utilities
################################################################################

# unused

#=
_isfinite(x) = isfinite(x)
_isfinite(x::VecTypes) = all(isfinite, x)
scalarmax(x::Union{Tuple, AbstractArray}, y::Union{Tuple, AbstractArray}) = max.(x, y)
scalarmax(x, y) = max(x, y)
scalarmin(x::Union{Tuple, AbstractArray}, y::Union{Tuple, AbstractArray}) = min.(x, y)
scalarmin(x, y) = min(x, y)


function distinct_extrema_nan(x)
    lo, hi = extrema_nan(x)
    lo == hi ? (lo - 0.5f0, hi + 0.5f0) : (lo, hi)
end


function _update_rect(rect::Rect{N, T}, point::VecTypes{N, T}) where {N, T}
    mi = minimum(rect)
    ma = maximum(rect)
    mis_mas = map(mi, ma, point) do _mi, _ma, _p
        (isnan(_mi) ? _p : _p < _mi ? _p : _mi), (isnan(_ma) ? _p : _p > _ma ? _p : _ma)
    end
    new_o = map(first, mis_mas)
    new_w = map(mis_mas) do (mi, ma)
        ma - mi
    end
    typeof(rect)(new_o, new_w)
end

=#




################################################################################
### from boundingboxes/text
################################################################################

#=
function project_widths(matrix, vec)
    pr = project(matrix, vec)
    zero = project(matrix, zeros(typeof(vec)))
    return pr - zero
end

function height_insensitive_boundingbox(ext::GlyphExtent)
    l = ext.ink_bounding_box.origin[1]
    w = ext.ink_bounding_box.widths[1]
    b = ext.descender
    h = ext.ascender
    return Rect2d((l, b), (w, h - b))
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