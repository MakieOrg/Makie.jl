"""
    stem(xs, ys, [zs]; kwargs...)

Plots markers at the given positions extending from `offset` along stem lines.

The conversion trait of `stem` is `PointBased`.
"""
@recipe Stem begin
    stemcolor = @inherit linecolor
    stemcolormap = @inherit colormap
    stemcolorrange = automatic
    stemwidth = @inherit linewidth
    stemlinestyle = nothing
    trunkwidth = @inherit linewidth
    trunklinestyle = nothing
    trunkcolor = @inherit linecolor
    trunkcolormap = @inherit colormap
    trunkcolorrange = automatic
    """
    Can be a number, in which case it sets `y` for 2D, and `z` for 3D stems.
    It can be a `Point2` for 2D plots, as well as a `Point3` for 3D plots.
    It can also be an iterable of any of these at the same length as `xs`, `ys`, `zs`.
    """
    offset = 0
    marker = :circle
    markersize = @inherit markersize
    color = @inherit markercolor
    colormap = @inherit colormap
    colorscale = identity
    colorrange = automatic
    strokecolor = @inherit markerstrokecolor
    strokewidth = @inherit markerstrokewidth
    MakieCore.mixin_generic_plot_attributes()...
    fxaa = false
    cycle = [[:stemcolor, :color, :trunkcolor] => :color]
end


conversion_trait(::Type{<:Stem}) = PointBased()


trunkpoint(stempoint::P, offset::Number) where P <: Point2 = P(stempoint[1], offset)
trunkpoint(stempoint::P, offset::Point2) where P <: Point2 = P(offset...)
trunkpoint(stempoint::P, offset::Number) where P <: Point3 = P(stempoint[1], stempoint[2], offset)
trunkpoint(stempoint::P, offset::Point3) where P <: Point3 = P(offset...)


function plot!(s::Stem{<:Tuple{<:AbstractVector{<:Point}}})
    points = s[1]

    stemtuples = lift(s, points, s.offset) do ps, to
        tuple.(ps, trunkpoint.(ps, to))
    end

    trunkpoints = lift(st -> last.(st), s, stemtuples)

    trunk_attr = shared_attributes(
        s, Lines, 
        linewidth = s.trunkwidth, linestyle = s.trunklinestyle, color = s.trunkcolor, 
        colormap = s.trunkcolormap, colorrange = s.trunkcolorrange, 
    )
    lines!(s, trunk_attr, trunkpoints)

    stem_attr = shared_attributes(
        s, LineSegments, 
        linewidth = s.stemwidth, linestyle = s.stemlinestyle,
        color = s.stemcolor, colormap = s.stemcolormap, colorrange = s.stemcolorrange
    )
    linesegments!(s, stem_attr, stemtuples)

    scatter!(s, shared_attributes(s, Scatter), s[1])

    return s
end
