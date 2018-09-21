const PlotTypes{Typ, Arg} = Union{Atomic{Typ, Arg}, Combined{Typ, Arg}}

argtypes(x::PlotTypes{T, A}) where {T, A} = A
argtypes(x) = Any

function data_limits(x)
    error("No datalimits for $(typeof(x)) and $(argtypes(x))")
end
"""
Data limits calculate a minimal boundingbox from the data points in a plot.
This doesn't include any transformations, markers etc.
"""
data_limits(x::Atomic{Typ, <: Tuple{Arg1}}) where {Typ, Arg1} = FRect3D(value(x[1]))
# TODO makes this generically work
data_limits(x::Atomic{Typ, <: Tuple{<: AbstractVector{<: NTuple{N, <: Number}}}}) where {Typ, N} = FRect3D(Point{N, Float32}.(value(x[1])))
function data_limits(x::Atomic{Typ, <: Tuple{<: AbstractVector{<: NTuple{2, T}}}}) where {Typ, T <: VecTypes}
    FRect3D(reinterpret(T, value(x[1])))
end

function data_limits(x::Atomic{Typ, <: Tuple{X, Y, Z}}) where {Typ, X, Y, Z}
    _boundingbox(value.(x[1:3])...)
end

function data_limits(x::Atomic{Typ, <: Tuple{X, Y}}) where {Typ, X, Y}
    _boundingbox(value.(x[1:2])...)
end

_isfinite(x) = isfinite(x)
_isfinite(x::VecTypes) = all(isfinite, x)
scalarmax(x::AbstractArray, y::AbstractArray) = max.(x, y)
scalarmax(x, y) = max(x, y)
scalarmin(x::AbstractArray, y::AbstractArray) = min.(x, y)
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


function _boundingbox(x, y, z = (0 => 0))
    minmax = extrema_nan.((x, y, z))
    mini, maxi = first.(minmax), last.(minmax)
    FRect3D(mini, maxi .- mini)
end

const ImageLike{Arg} = Union{Heatmap{Arg}, Image{Arg}}
function data_limits(x::ImageLike{<: Tuple{X, Y, Z}}) where {X, Y, Z}
    _boundingbox(value.((x[1], x[2]))...)
end

function data_limits(x::Volume)
    _boundingbox(value.((x[1], x[2], x[3]))...)
end


function text_limits(x::VecTypes)
    p = to_ndim(Vec3f0, x, 0.0)
    FRect3D(p, p)
end
function text_limits(x::AbstractVector)
    FRect3D(x)
end
function data_limits(x::Text)
    boundingbox(x)
end

function data_limits(x::Annotations)
    # data limits is supposed to not include any transformation.
    # for the annotation, we use the model matrix directly, so we need to
    # to inverse that transformation for the correct limits
    bb = data_limits(x.plots[1])
    inv(value(x[:model])) * bb
end

Base.isfinite(x::Rect) = all(isfinite.(minimum(x))) &&  all(isfinite.(maximum(x)))

function data_limits(plots::Vector)
    isempty(plots) && return FRect3D(Vec3f0(0), Vec3f0(0))
    bb = FRect3D()
    plot_idx = iterate(plots)
    while plot_idx !== nothing
        plot, idx = plot_idx
        plot_idx = iterate(plots, idx)
        # axis shouldn't be part of the data limit
        isaxis(plot) && continue
        isa(plot, Legend) && continue
        bb2 = data_limits(plot)
        isfinite(bb) || (bb = bb2)
        isfinite(bb2) || continue
        bb = union(bb, bb2)
    end
    bb
end

data_limits(s::Scene) = data_limits(plots_from_camera(s))
data_limits(plot::Combined) = data_limits(plot.plots)
