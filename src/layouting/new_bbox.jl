# Note:
# This is from before the other changes and may not fit in directly...

################################################################################
### BoundingBox Util
################################################################################

nanmin(a::VecTypes, b::VecTypes) = nanmin(to_ndim(Vec3f, a, NaN32), to_ndim(Vec3f, b, NaN32))
nanmin(a::VecTypes{3}, b::VecTypes{3}) = nanmin.(a, b)
function nanmin(a::Real, b::Real)
    isnan(b) && return a
    isnan(a) && return b
    return min(a, b)
end

nanmax(a::VecTypes, b::VecTypes) = nanmax(to_ndim(Vec3f, a, NaN32), to_ndim(Vec3f, b, NaN32))
nanmax(a::VecTypes{3}, b::VecTypes{3}) = nanmax.(a, b)
function nanmin(a::Real, b::Real)
    isnan(b) && return a
    isnan(a) && return b
    return max(a, b)
end


function boundingbox(positions::AbstractVector)
    N = length(positions)
    low = Point3f(NaN)
    high = Point3f(NaN)

    # Seek first non-nan element so we can set low and high to something finite
    # and avoid left isnan checks during iteration
    i = 1
    @inbounds while i < N
        if !isnan(positions[i])
            low = to_ndim(Point3f, positions[i], NaN32)
            high = to_ndim(Point3f, positions[i], NaN32)
            break
        end
        i += 1
    end

    @inbounds for j in i+1:N
        p = positions[j]
        if !isnan(p)
            low = min.(low, p)
            high = max.(high, p)
        end
    end

    return Rec3f(low, high - low)
end

function boundingbox(a::Rect3, b::Rect3)
    min = nanmin(minimum(a), minimum(b))
    max = nanmax(maximum(a), maximum(b))
    return Rect3f(min, max)
end


################################################################################
### get positions
################################################################################


function positions(plot::Union{Scatter, MeshScatter, Lines, LineSegments})
    return plot.positions[]
end

function positions(plot::Text) #TODO: is this ok?
    if isempty(plot.plots)
        return plot.positions[]
    else
        return positions(plot.plots[1])
    end
end

positions(mesh::GeometryBasics.Mesh) = decompose(Point, mesh)
positions(plot::Mesh) = positions(plot.mesh[])

function positions(plot::Union{Image, Heatmap, Surface, Volume})
    rect = data_limits(plot)
    return unique(decompose(Point3f, rect))
end

# Generic
function positions(@nospecialize(plot::Combined))
    output = Point3f[]
    for p in plot.plots
        append!(output, positions(p))
    end
    return output
end


################################################################################
### get bbox of positions
################################################################################


function data_limits(plot::Union{Image, Heatmap})
    xmin, xmax = extrema(plot[1][])
    ymin, ymax = extrema(plot[2][])
    return Rect3f(Point3f(xmin, ymin, 0), Vec3f(xmax - xmin, ymax - ymin, 0))
end

function data_limits(plot::Union{Surface, Volume})
    xmin, xmax = extrema(plot[1][])
    ymin, ymax = extrema(plot[2][])
    zmin, zmax = extrema(plot[3][])
    return Rect3f(Point3f(xmin, ymin, zmin), Vec3f(xmax - xmin, ymax - ymin, zmax - zmin))
end

# Generic
data_limits(@nospecialize(plot::Combined)) = boundingbox(position(plot))


################################################################################
### Generic boundingbox methods
################################################################################

# User entrypoint
# scenes & plots
function boundingbox(@nospecialize(obj::SceneLike); transform = false, project = false)
    return _boundingbox(obj, project, transform)
end

function _boundingbox(@nospecialize(obj::SceneLike), project::Bool, transform::Bool)
    if isempty(obj.plots)
        bbox = _boundingbox(obj, project)
        if transform
            ps = corners(bbox)
            ps = apply_transform(obj, ps)
            return boundingbox(ps)
        else
            return bbox
        end
    else
        final_bbox = Rect3f()
        for plot in obj.plots
            bbox = _boundingbox(plot, project, transform)
            final_bbox = boundingbox(final_bbox, bbox)
        end
        return final_bbox
    end
end


################################################################################
### Primitive boundingbox methods
################################################################################


function _boundingbox(@nospecialize(plot::Scatter), project::Bool)
    if project
        bbox = Rect3f()
        # ...
        N = length(plot)
        N0 = findfirst(!isnan, plot.positions[])
        if !isnothing(N0)
            # TODO: always project, never transform for scatter
            bbox = _boundingbox(plot, N0)
            for i in N0+1 : N
                bbox = boundingbox(bbox, _boundingbox(plot, i))
            end
        end
        return bbox
    else
        return data_limits(plot)
    end
end

function _boundingbox(@nospecialize(plot::Union{Lines, Linesegments}), project::Bool)
    return data_limits(plot)
end

function _boundingbox(@nospecialize(plot::MeshScatter), project::Bool)
    if project
        # TODO
    else
        return data_limits(plot)
    end
end

function _boundingbox(@nospecialize(plot::Text), project::Bool)
    if project
        # TODO
    else
        return data_limits(plot)
    end
end

_boundingbox(@nospecialize(plot::Mesh), project::Bool) = data_limits(plot)

function _boundingbox(@nospecialize(plot::Union{Image, Heatmap, Surface, Volume}), project::Bool)
    return data_limits(plot)
end


################################################################################
### Element versions
################################################################################

# Very TODO stil...
# - general: maybe split off marker_boundingbox
# - general: boundingbox(plot, idx) should also project, transform
#    - this lends itself to doing `projectionview * model` and `pvm * local_model`?
# - text: maybe add bbox to glyphcollection

function _boundingbox(@nospecialize(plot::Scatter), idx::Integer, project::Bool)
    p = plot.positions[][i]
    return Rect3f(p)

    m_p = project(plot, p, plot.space[], plot.markerspace[])
    m_size = Vec2f(attr_broadcast_getindex(plot.markersize, idx))
    m_offset = Vec2f(attr_broadcast_getindex(plot.marker_offset))
    m_bbox = boundingbox(attr_broadcast_getindex(plot.marker[]))

    # TODO: transform_marker
    # TODO: 2D vs 3D
    m_bbox = m_bbox * m_size + m_p + m_offset

    # decompose, inverse transform, boundingbox return
end

function _boundingbox(@nospecialize(plot::Text), idx::Integer, project::Bool)
    _boundingbox(plot.plots[1], idx, project)
end
function _boundingbox(@nospecialize(plot::Text{<:Tuple{<:GlyphCollection}}), idx::Integer, project::Bool)
    idx == 1 || throw(BoundsError("Text plot only contains one string."))

end
function _boundingbox(@nospecialize(plot::Text{<:Tuple{<:AbstractArray{<:GlyphCollection}}}), idx::Integer, project::Bool)

end