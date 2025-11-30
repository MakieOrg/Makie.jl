# @reference_test "Poly fast paths $yscale"
function build_poly_refimg(yscale; kwargs...)
    # We have the following groups funneling into one method each:
    # - Circle, Vector{<:Point2} and Vector{<:Vector{<:Point2}}
    # - Rect2, Vector{Rect2}, BezierPath, Vector{BezierPath}
    # - Polygon, MultiPolygon, Vector{Polygon}, Vector{MultiPolygon}

    function to_bezier(ps)
        path = Any[MoveTo(ps[1])]
        append!(path, [LineTo(ps[i]) for i in 2:length(ps)])
        push!(path, ClosePath())
        return BezierPath(path)
    end

    f = Figure()

    Label(f[1, 1], "outline based", tellwidth = false)
    ax = Axis(f[2, 1], yscale = yscale)
    ps = [(1.0, 1.0), (2.0, 1.0), (1.5, 1.5), (2.0, 2.0), (1.0, 2.0)]
    poly!(ax, ps; kwargs...)
    p = poly!(ax, [ps, [p .+ (2, 0) for p in ps]]; kwargs...)
    translate!(p, 0, 1, 0)
    poly!(ax, Circle(Point2f(3, 1.5), 0.25); kwargs...)

    Label(f[1, 2], "Rect/BezierPath", tellwidth = false)
    ax = Axis(f[2, 2], yscale = yscale)
    poly!(ax, Rect2f(0, 0.5, 1, 1); kwargs...)
    poly!(ax, [Rect2f(0, 2, 1, 1), Rect2f(0, 3, 1, 1)], strokewidth = 1; kwargs...)
    p = poly!(ax, to_bezier(ps); kwargs...)
    translate!(p, 2, 0, 0)
    # Cairo allows this but the recipe doesn't
    # poly!(ax, [to_bezier([p .+ (2, 2) for p in ps]), to_bezier([p .+ (2, 4) for p in ps])])

    Label(f[1, 3], "Polygon", tellwidth = false)
    ax = Axis(f[2, 3], yscale = yscale)
    ps = to_ndim.(Point2f, ps, 0)
    poly!(ax, Polygon(ps); kwargs...)
    polys = [Polygon(ps .+ Ref(Point2f(2, 0))), Polygon(ps .+ Ref(Point2f(3, 0)))]
    poly!(ax, polys; kwargs...)
    p = poly!(ax, MultiPolygon(polys); kwargs...)
    translate!(p, 0, 2, 0)
    p = poly!(ax, [MultiPolygon(polys), MultiPolygon([Polygon(ps)])]; kwargs...)
    translate!(p, 0, 4, 0)

    return f
end

@reference_test "poly fast paths" begin
    build_poly_refimg(identity)
end

@reference_test "poly fast paths with transform_func" begin
    # translate applies after log10, so some plots move more than maybe expected
    build_poly_refimg(log10)
end

@reference_test "poly fast paths - linestyle" begin
    build_poly_refimg(
        identity, linestyle = :dash, strokewidth = 5, strokecolor = :black
    )
end

@reference_test "poly fast paths - line join and cap" begin
    build_poly_refimg(
        identity,
        linecap = :butt, joinstyle = :round,
        strokewidth = 10, strokecolor = :black
    )
end

@reference_test "poly fast paths - miter limits" begin
    build_poly_refimg(
        identity,
        joinstyle = :miter, miter_limit = 2pi/3,
        strokewidth = 10, strokecolor = :black
    )
end