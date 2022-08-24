"""
    hspan(ys_low, ys_high; xmin = 0.0, xmax = 1.0, attrs...)

Create horizontal bands spanning across a `Scene` with 2D projection.
The bands will be placed from `ys_low` to `ys_high` in data coordinates and `xmin` to `xmax`
in scene coordinates (0 to 1). All four of these can have single or multiple values because
they are broadcast to calculate the final spans.

All style attributes are the same as for `Poly`.
"""
@recipe(HSpan) do scene
    Theme(;
        xautolimits = false,
        xmin = 0,
        xmax = 1,
        default_theme(Poly, scene)...,
        cycle = [:color => :patchcolor],
    )
    end

"""
    vspan(xs_low, xs_high; ymin = 0.0, ymax = 1.0, attrs...)

Create vertical bands spanning across a `Scene` with 2D projection.
The bands will be placed from `xs_low` to `xs_high` in data coordinates and `ymin` to `ymax`
in scene coordinates (0 to 1). All four of these can have single or multiple values because
they are broadcast to calculate the final spans.

All style attributes are the same as for `Poly`.
"""
@recipe(VSpan) do scene
    Theme(;
        yautolimits = false,
        ymin = 0,
        ymax = 1,
        default_theme(Poly, scene)...,
        cycle = [:color => :patchcolor],
    )
end

function Makie.plot!(p::Union{HSpan, VSpan})
    scene = Makie.parent_scene(p)
    transf = transform_func_obs(scene)

    limits = lift(projview_to_2d_limits, scene.camera.projectionview)

    rects = Observable(Rect2f[])

    mi = p isa HSpan ? p.xmin : p.ymin
    ma = p isa HSpan ? p.xmax : p.ymax
    
    onany(limits, p[1], p[2], mi, ma, transf) do lims, lows, highs, mi, ma, transf
        inv = inverse_transform(transf)
        empty!(rects[])
        min_x, min_y = minimum(lims)
        max_x, max_y = maximum(lims)
        broadcast_foreach(lows, highs, mi, ma) do low, high, mi, ma
            if p isa HSpan
                x_mi = min_x + (max_x - min_x) * mi
                x_ma = min_x + (max_x - min_x) * ma
                x_mi = _apply_x_transform(inv, x_mi)
                x_ma = _apply_x_transform(inv, x_ma)
                push!(rects[], Rect2f(Point2f(x_mi, low), Vec2f(x_ma - x_mi, high - low)))
            elseif p isa VSpan
                y_mi = min_y + (max_y - min_y) * mi
                y_ma = min_y + (max_y - min_y) * ma
                y_mi = _apply_y_transform(inv, y_mi)
                y_ma = _apply_y_transform(inv, y_ma)
                push!(rects[], Rect2f(Point2f(low, y_mi), Vec2f(high - low, y_ma - y_mi)))
            end
        end
        notify(rects)
    end

    notify(p[1])

    poly!(p, rects; p.attributes...)
    p
end

_apply_x_transform(t::Tuple, v) = apply_transform(t[1], v)
_apply_x_transform(::typeof(identity), v) = v
_apply_x_transform(other, v) = error("x transform not defined for transform function $(typeof(other))")
_apply_y_transform(t::Tuple, v) = apply_transform(t[2], v)
_apply_y_transform(other, v) = error("y transform not defined for transform function $(typeof(other))")
_apply_y_transform(::typeof(identity), v) = v
