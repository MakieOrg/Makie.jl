argtypes(x::Combined{T, A}) where {T, A} = A
argtypes(x) = Any

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

function xyz_boundingbox(transform_func, mesh::GeometryBasics.Mesh)
    xyz_boundingbox(transform_func, decompose(Point, mesh))
end

function xyz_boundingbox(transform_func, xyz)
    isempty(xyz) && return Rect3f()
    mini, maxi = extrema_nan((apply_transform(transform_func, point) for point in xyz))
    w = maxi .- mini
    return Rect3f(to_ndim(Vec3f, mini, 0), to_ndim(Vec3f, w, 0))
end

const NumOrArray = Union{AbstractArray, Number}

function xyz_boundingbox(transform_func, x::AbstractVector, y::AbstractVector, z::NumOrArray=0)
    # use lazy variant of broadcast!
    points = Base.broadcasted(Point3, x, y', z)
    return xyz_boundingbox(transform_func, points)
end

function xyz_boundingbox(transform_func, x::NumOrArray, y::NumOrArray, z::NumOrArray = 0)
    # use lazy variant of broadcast!
    points = Base.broadcasted(Point3, x, y, z)
    return xyz_boundingbox(transform_func, points)
end

function xyz_boundingbox(transform_func, x, y, z = 0)
    isempty(x) && return Rect3f()
    minmax = extrema_nan.(apply_transform.((transform_func,), (x, y, z)))
    mini, maxi = Vec(first.(minmax)), Vec(last.(minmax))
    w = maxi .- mini
    return Rect3f(to_ndim(Vec3f, mini, 0), to_ndim(Vec3f, w, 0))
end

const ImageLike{Arg} = Union{Heatmap{Arg}, Image{Arg}}
function data_limits(x::ImageLike{<: Tuple{X, Y, Z}}) where {X, Y, Z}
    xyz_boundingbox(identity, to_value.((x[1], x[2]))...)
end

function data_limits(x::Volume)
    _to_interval(r) = ((lo, hi) = extrema(r); lo..hi)
    axes = (x[1], x[2], x[3])
    xyz_boundingbox(identity, _to_interval.(to_value.(axes))...)
end

function text_limits(x::VecTypes)
    p = to_ndim(Vec3f, x, 0.0)
    return Rect3f(p, p)
end

function text_limits(x::AbstractVector)
    return Rect3f(x)
end

FRect3D_from_point(p::VecTypes{2}) = Rect3f(Point3f(p..., 0), Point3f(0, 0, 0))
FRect3D_from_point(p::VecTypes{3}) = Rect3f(Point3f(p...), Point3f(0, 0, 0))

function atomic_limits(x::Text{<:Tuple{<:GlyphCollection}})
    if x.space[] == :data
        boundingbox(x)
    elseif x.space[] == :screen
        FRect3D_from_point(x.position[])
    else
        error()
    end
end

function atomic_limits(x::Text{<:Tuple{<:AbstractArray{<:GlyphCollection}}})
    if x.space[] == :data
        boundingbox(x)
    elseif x.space[] == :screen
        if isempty(x.position[])
            Rect3f()
        else
            bb = FRect3D_from_point(x.position[][1])
            for p in x.position[][2:end]
                bb = union(bb, FRect3D_from_point(p))
            end
            bb
        end
    else
        error()
    end
end

isfinite_rect(x::Rect) = all(isfinite.(minimum(x))) &&  all(isfinite.(maximum(x)))

data_limits(s::Scene) = data_limits(plots_from_camera(s))
data_limits(s::Figure) = data_limits(s.scene)
data_limits(s::FigureAxisPlot) = data_limits(s.figure)
data_limits(plot::Combined) = data_limits(plot.plots)

function point_iterator(plot::Combined)
    return Iterators.flatten((point_iterator(p) for p in plot.plots))
end

function point_iterator(plot::Union{Scatter, MeshScatter, Lines, LineSegments})
    return plot.positions[]
end

point_iterator(mesh::GeometryBasics.Mesh) = decompose(Point, mesh)

function point_iterator(list::AbstractVector)
    Iterators.flatten((point_iterator(elem) for elem in list))
end

point_iterator(plot::Mesh) = point_iterator(plot.mesh[])

function point_iterator(plot::Surface)
    X = plot.x[]
    Y = plot.y[]
    Z = plot.z[]
    indices = CartesianIndices(Z)
    function get_points(linidx)
        i, j = Tuple(indices[linidx])
        x = X[i]
        y = Y[j]
        z = Z[linidx]
        return Point(x, y, z)
    end
    return (get_points(idx) for idx in 1:length(Z))
end

function point_iterator(plot::Heatmap)
    X = plot.x[]
    Y = plot.y[]
    Z = plot[3][]
    zsize = size(Z) .+ 1
    indices = CartesianIndices(zsize)
    function get_points(linidx)
        i, j = Tuple(indices[linidx])
        x = X[i]
        y = Y[j]
        return Point(x, y, 0.0)
    end
    return (get_points(idx) for idx in 1:prod(zsize))
end

function point_iterator(x::Volume)
    axes = (x[1], x[2], x[3])
    extremata = map(extrema∘to_value, axes)
    minpoint = Point3f(first.(extremata)...)
    widths = last.(extremata) .- first.(extremata)
    rect = Rect3f(minpoint, Vec3f(widths))
    return unique(decompose(Point, rect))
end

foreach_plot(f, s::Scene, keep=(x)-> true) = foreach_plot(f, s.plots, keep)
foreach_plot(f, s::Figure, keep=(x)-> true) = foreach_plot(f, s.scene, keep)
foreach_plot(f, s::FigureAxisPlot, keep=(x)-> true) = foreach_plot(f, s.figure, keep)
foreach_plot(f, plot::Combined, keep=(x)-> true) = foreach_plot(f, plot.plots, keep)

function foreach_plot(f, list::AbstractVector, keep=(x)-> true)
    for element in list
        if keep(element)
            f(element)
        end
    end
    return
end

function foreach_transformed(f, point_iterator, model, trans_func)
    for point in point_iterator
        point_t = apply_transform(trans_func, point)
        point_m = project(model, point_t)
        f(point_m)
    end
    return
end

function foreach_transformed(f, plot)
    points = point_iterator(plot)
    t = transformation(plot)
    model = model_transform(t)
    trans_func = t.transform_func[]
    # use function barrier since trans_func is Any
    foreach_transformed(f, points, model, trans_func)
end

function update_boundingbox!(bb_ref, point)
    if all(isfinite, point)
        vec = to_ndim(Vec3f0, point, 0.0)
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

function data_limits(plot::AbstractPlot)
    # Because of closure inference problems
    # we need to use a ref here which gets updated inplace
    bb_ref = Base.RefValue(Rect3f())
    foreach_transformed(plot) do point
        update_boundingbox!(bb_ref, point)
    end
    return bb_ref[]
end

function data_limits(scenelike::Scene)
    bb_ref = Base.RefValue(Rect3f())
    foreach_plot(scenelike) do plot
        update_boundingbox!(bb_ref, data_limits(plot))
    end
    return bb_ref[]
end
