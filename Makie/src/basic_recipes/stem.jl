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
    mixin_generic_plot_attributes()...
    cycle = [[:stemcolor, :color, :trunkcolor] => :color]
end


conversion_trait(::Type{<:Stem}) = PointBased()


trunkpoint(stempoint::P, offset::Number) where {P <: Point2} = P(stempoint[1], offset)
trunkpoint(stempoint::P, offset::Point2) where {P <: Point2} = P(offset...)
trunkpoint(stempoint::P, offset::Number) where {P <: Point3} = P(stempoint[1], stempoint[2], offset)
trunkpoint(stempoint::P, offset::Point3) where {P <: Point3} = P(offset...)


function plot!(s::Stem{<:Tuple{<:AbstractVector{<:Point}}})

    map!(s, [:converted_1, :offset], :stemtuples) do ps, to
        tuple.(ps, trunkpoint.(ps, to))
    end

    map!(s, [:stemtuples], :trunkpoints) do st
        return last.(st)
    end

    lines!(
        s, s.trunkpoints,
        linewidth = s.trunkwidth,
        color = s.trunkcolor,
        colormap = s.trunkcolormap,
        colorscale = s.colorscale,
        colorrange = s.trunkcolorrange,
        visible = s.visible,
        linestyle = s.trunklinestyle,
        inspectable = s.inspectable
    )
    linesegments!(
        s, s.stemtuples,
        linewidth = s.stemwidth,
        color = s.stemcolor,
        colormap = s.stemcolormap,
        colorscale = s.colorscale,
        colorrange = s.stemcolorrange,
        visible = s.visible,
        linestyle = s.stemlinestyle,
        inspectable = s.inspectable
    )
    scatter!(
        s, s[1],
        color = s.color,
        colormap = s.colormap,
        colorscale = s.colorscale,
        colorrange = s.colorrange,
        markersize = s.markersize,
        marker = s.marker,
        strokecolor = s.strokecolor,
        strokewidth = s.strokewidth,
        visible = s.visible,
        inspectable = s.inspectable
    )
    return s
end
