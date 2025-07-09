"""
    hspan(ys_low, ys_high; xmin = 0.0, xmax = 1.0, attrs...)
    hspan(ys_lowhigh; xmin = 0.0, xmax = 1.0, attrs...)

Create horizontal bands spanning across a `Scene` with 2D projection.
The bands will be placed from `ys_low` to `ys_high` in data coordinates and `xmin` to `xmax`
in scene coordinates (0 to 1). All four of these can have single or multiple values because
they are broadcast to calculate the final spans.
Both bounds can be passed together as an interval `ys_lowhigh`.
"""
@recipe HSpan (low, high) begin
    "The start of the bands in relative axis units (0 to 1) along the x dimension."
    xmin = 0
    "The end of the bands in relative axis units (0 to 1) along the x dimension."
    xmax = 1
    documented_attributes(Poly)...
    cycle = [:color => :patchcolor]
end

"""
    vspan(xs_low, xs_high; ymin = 0.0, ymax = 1.0, attrs...)
    vspan(xs_lowhigh; ymin = 0.0, ymax = 1.0, attrs...)

Create vertical bands spanning across a `Scene` with 2D projection.
The bands will be placed from `xs_low` to `xs_high` in data coordinates and `ymin` to `ymax`
in scene coordinates (0 to 1). All four of these can have single or multiple values because
they are broadcast to calculate the final spans.
Both bounds can be passed together as an interval `xs_lowhigh`.
"""
@recipe VSpan (low, high) begin
    "The start of the bands in relative axis units (0 to 1) along the y dimension."
    ymin = 0
    "The end of the bands in relative axis units (0 to 1) along the y dimension."
    ymax = 1
    documented_attributes(Poly)...
    cycle = [:color => :patchcolor]
end

function Makie.plot!(p::Union{HSpan, VSpan})
    mi = p isa HSpan ? :xmin : :ymin
    ma = p isa HSpan ? :xmax : :ymax
    add_axis_limits!(p)
    map!(
        p.attributes, [:axis_limits_transformed, :low, :high, mi, ma, :transform_func], :rects
    ) do lims, lows, highs, mi, ma, transf
        rects = Rect2d[]
        min_x, min_y = minimum(lims)
        max_x, max_y = maximum(lims)
        broadcast_foreach(lows, highs, mi, ma) do low, high, mi, ma
            if p isa HSpan
                x_mi = min_x + (max_x - min_x) * mi
                x_ma = min_x + (max_x - min_x) * ma
                low = _apply_y_transform(transf, low)
                high = _apply_y_transform(transf, high)
                push!(rects, Rect2d(Point2(x_mi, low), Vec2(x_ma - x_mi, high - low)))
            elseif p isa VSpan
                y_mi = min_y + (max_y - min_y) * mi
                y_ma = min_y + (max_y - min_y) * ma
                low = _apply_x_transform(transf, low)
                high = _apply_x_transform(transf, high)
                push!(rects, Rect2d(Point2(low, y_mi), Vec2(high - low, y_ma - y_mi)))
            end
        end
        return rects
    end

    poly!(p, Attributes(p), p.rects, transformation = :inherit_model)
    return p
end

_apply_x_transform(t::Tuple, v) = apply_transform(t[1], v)
_apply_x_transform(::typeof(identity), v) = v
_apply_x_transform(other, v) = error("x transform not defined for transform function $(typeof(other))")
_apply_y_transform(t::Tuple, v) = apply_transform(t[2], v)
_apply_y_transform(other, v) = error("y transform not defined for transform function $(typeof(other))")
_apply_y_transform(::typeof(identity), v) = v


function data_limits(p::HSpan)
    ymin = minimum(p[1][])
    ymax = maximum(p[2][])
    return Rect3d(Point3d(NaN, ymin, 0), Vec3d(NaN, ymax - ymin, 0))
end

function data_limits(p::VSpan)
    xmin = minimum(p[1][])
    xmax = maximum(p[2][])
    return Rect3d(Point3d(xmin, NaN, 0), Vec3d(xmax - xmin, NaN, 0))
end

boundingbox(p::Union{HSpan, VSpan}, space::Symbol = :data) = apply_transform_and_model(p, data_limits(p))

convert_arguments(P::Type{<:Union{HSpan, VSpan}}, x::Interval) = endpoints(x)
convert_arguments(P::Type{<:Union{HSpan, VSpan}}, x::AbstractVector{<:Interval}) = (leftendpoint.(x), rightendpoint.(x))
