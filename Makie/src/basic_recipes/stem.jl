"""
    stem(xs, ys, [zs]; kwargs...)

Plots markers at the given positions with stem lines extending from `offset`.
All stems are connected to a trunk line.

The conversion trait of `stem` is `PointBased`.
"""
@recipe Stem begin
    "Sets the color of stem lines. Can be a Symbol, Colorant, Real or Vector thereof."
    stemcolor = @inherit linecolor
    "Sets the colormap for stem lines which maps numbers to colors."
    stemcolormap = @inherit colormap
    "Sets the colorrange for stem lines which limits the value range for colormapping."
    stemcolorrange = automatic
    "Sets the linewidth of stems."
    stemwidth = @inherit linewidth
    "Sets the linestyle of stem lines. See `?lines`."
    stemlinestyle = nothing

    "Sets the linewidth for the trunk line."
    trunkwidth = @inherit linewidth
    "Sets the linestyle for the trunk line."
    trunklinestyle = nothing
    "Sets the color for the trunk line."
    trunkcolor = @inherit linecolor
    "Sets the colormap for the trunk line."
    trunkcolormap = @inherit colormap
    "Sets the colorrange for the trunk line."
    trunkcolorrange = automatic

    """
    Offsets the trunk and stem startpoint from 0.
    Can be a number, in which case it sets `y` for 2D, and `z` for 3D stems.
    It can be a `Point2` for 2D plots, as well as a `Point3` for 3D plots.
    It can also be an iterable of any of these at the same length as `xs`, `ys`, `zs`.
    """
    offset = 0
    "Sets the marker used for the endpoints of stems"
    marker = :circle
    "Sets the size of markers in pixel units."
    markersize = @inherit markersize
    "Sets the color of markers."
    color = @inherit markercolor
    "Sets the colormap of markers."
    colormap = @inherit colormap
    "Sets the colorrange for markers."
    colorrange = automatic
    "Sets the strokecolor of markers."
    strokecolor = @inherit markerstrokecolor
    "Sets the strokewidth of markers."
    strokewidth = @inherit markerstrokewidth

    mixin_generic_plot_attributes()...
    "Sets the colorscale function for the trunk, stems and markers."
    colorscale = identity
    """
    Sets which attributes to cycle when creating multiple plots. The values to
    cycle through are defined by the parent Theme. Multiple cycled attributes can
    be set by passing a vector. Elements can
    - directly refer to a cycled attribute, e.g. `:color`
    - map a cycled attribute to a palette attribute, e.g. `:linecolor => :color`
    - map multiple cycled attributes to a palette attribute, e.g. `[:linecolor, :markercolor] => :color`
    """
    cycle = [[:stemcolor, :color, :trunkcolor] => :color]
end


conversion_trait(::Type{<:Stem}) = PointBased()


trunkpoint(stempoint::P, offset::Number) where {P <: Point2} = P(stempoint[1], offset)
trunkpoint(stempoint::P, offset::Point2) where {P <: Point2} = P(offset...)
trunkpoint(stempoint::P, offset::Number) where {P <: Point3} = P(stempoint[1], stempoint[2], offset)
trunkpoint(stempoint::P, offset::Point3) where {P <: Point3} = P(offset...)


function plot!(s::Stem{<:Tuple{<:AbstractVector{<:Point}}})

    map!(s, [:converted_1, :offset], :stemtuples) do ps, to
        tuple.(trunkpoint.(ps, to), ps)
    end

    map!(s, [:stemtuples], :trunkpoints) do st
        return first.(st)
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
