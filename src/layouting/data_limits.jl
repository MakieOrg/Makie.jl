#=
Hierarchy:
- boundingbox falls back on points_iterator of primitives
- points_iterator falls back on data_limits
- data_limits uses points_iterator for a few specific primitive plots

So overload both `data_limits` and `boundingbox`. You can use:
- `points_iterator(::Rect)` to decompose the Rect
- `_boundingbox(plot, ::Rect)` to transform the Rect using the plots transformations
=#

################################################################################
### data_limits
################################################################################

"""
    data_limits(scenelike[, exclude = plot -> false])

Returns the combined data limits of all plots collected under `scenelike` for
which `exclude(plot) == false`. This is solely based on the positional data of
a plot and thus does not include any transformations.

See also: [`boundingbox`](@ref)
"""
function data_limits(scenelike, exclude=(p)-> false)
    bb_ref = Base.RefValue(Rect3d())
    foreach_plot(scenelike) do plot
        if !exclude(plot)
            update_boundingbox!(bb_ref, data_limits(plot))
        end
    end
    return bb_ref[]
end

"""
    data_limits(plot::AbstractPlot)

Returns the bounding box of a plot based on just its position data.

See also: [`boundingbox`](@ref)
"""
function data_limits(plot::AbstractPlot)
    # Assume primitive plot
    if isempty(plot.plots)
        return Rect3d(point_iterator(plot))
    end

    # Assume combined plot
    bb_ref = Base.RefValue(data_limits(plot.plots[1]))
    for i in 2:length(plot.plots)
        update_boundingbox!(bb_ref, data_limits(plot.plots[i]))
    end

    return bb_ref[]
end

# A few overloads for performance
function data_limits(plot::Surface)
    mini_maxi = extrema_nan.((plot.x[], plot.y[], plot.z[]))
    mini = first.(mini_maxi)
    maxi = last.(mini_maxi)
    return Rect3d(mini, maxi .- mini)
end

function data_limits(plot::Union{Heatmap, Image})
    mini_maxi = extrema_nan.((plot.x[], plot.y[]))
    mini = Vec3d(first.(mini_maxi)..., 0)
    maxi = Vec3d(last.(mini_maxi)..., 0)
    return Rect3d(mini, maxi .- mini)
end

function data_limits(x::Volume)
    axes = (x[1][], x[2][], x[3][])
    extremata = extrema.(axes)
    return Rect3d(first.(extremata), last.(extremata) .- first.(extremata))
end

# We don't want pixel space line segments to be considered...
function data_limits(plot::Text)
    if plot.space[] == plot.markerspace[]
        return text_boundingbox(plot)
    else
        return Rect3d(point_iterator(plot))
    end
end

################################################################################
### point_iterator & data_limits
################################################################################


function point_iterator(plot::Union{Scatter, MeshScatter, Lines, LineSegments})
    return plot.positions[]
end

point_iterator(plot::Text) = point_iterator(plot.plots[1])
function point_iterator(plot::Text{<: Tuple{<: Union{GlyphCollection, AbstractVector{GlyphCollection}}}})
    return plot.position[]
end

point_iterator(mesh::GeometryBasics.Mesh) = decompose(Point, mesh)
point_iterator(plot::Mesh) = point_iterator(plot.mesh[])

# Fallback for other primitive plots, used in boundingbox
point_iterator(plot::AbstractPlot) = point_iterator(data_limits(plot))

# For generic usage
point_iterator(bbox::Rect) = unique(decompose(Point3d, bbox))


################################################################################
### Utilities
################################################################################


isfinite_rect(x::Rect) = all(isfinite, x.origin) &&  all(isfinite, x.widths)
_isfinite(x) = isfinite(x)
_isfinite(x::VecTypes) = all(isfinite, x)
scalarmax(x::Union{Tuple, AbstractArray}, y::Union{Tuple, AbstractArray}) = max.(x, y)
scalarmax(x, y) = max(x, y)
scalarmin(x::Union{Tuple, AbstractArray}, y::Union{Tuple, AbstractArray}) = min.(x, y)
scalarmin(x, y) = min(x, y)

extrema_nan(itr::Pair) = (itr[1], itr[2])
extrema_nan(itr::ClosedInterval) = (minimum(itr), maximum(itr))
function extrema_nan(itr)
    vs = iterate(itr)
    vs === nothing && return (NaN, NaN)
    v, s = vs
    vmin = vmax = v
    # find first finite value
    while vs !== nothing && !_isfinite(v)
        v, s = vs
        vmin = vmax = v
        vs = iterate(itr, s)
    end
    while vs !== nothing
        x, s = vs
        vs = iterate(itr, s)
        _isfinite(x) || continue
        vmax = scalarmax(x, vmax)
        vmin = scalarmin(x, vmin)
    end
    return (vmin, vmax)
end

# used in colorsampler.jl, datashader.jl
function distinct_extrema_nan(x)
    lo, hi = extrema_nan(x)
    lo == hi ? (lo - 0.5f0, hi + 0.5f0) : (lo, hi)
end

function update_boundingbox!(bb_ref, point)
    if all(isfinite, point)
        vec = to_ndim(Vec3d, point, 0.0)
        bb_ref[] = update(bb_ref[], vec)
    end
end

function update_boundingbox!(bb_ref, bb::Rect)
    # ref is uninitialized, so just set it to the first bb
    if !isfinite_rect(bb_ref[])
        bb_ref[] = bb
        return
    end
    # don't update if not finite
    !isfinite_rect(bb) && return
    # ok, update!
    bb_ref[] = union(bb_ref[], bb)
    return
end

# used in PolarAxis
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


foreach_plot(f, s::Scene) = foreach_plot(f, s.plots)
# foreach_plot(f, s::Figure) = foreach_plot(f, s.scene)
# foreach_plot(f, s::FigureAxisPlot) = foreach_plot(f, s.figure)
foreach_plot(f, list::AbstractVector) = foreach(f, list)
function foreach_plot(f, plot::Plot)
    if isempty(plot.plots)
        f(plot)
    else
        foreach_plot(f, plot.plots)
    end
end