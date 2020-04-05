const makie_linetype = Dict{Symbol, Any}(
    :auto => nothing,
    :solid => nothing,
    :dash => :dash,
    :dot => :dot,
    :dashdot => :dashdot,
    :dashdotdot => [0.4, 0.2, 0.1, 0.2, 0.4]
)

function makie_color(c)
    if color === :match
        return AbstractPlotting.Colors.colorant"blue"
    end
    convert(AbstractPlotting.RGBA, c)
end
makie_seriestype_map = Dict{Symbol, Type}(
    :path => AbstractPlotting.Lines,
    :path3d => AbstractPlotting.Lines,
    :scatter => AbstractPlotting.Scatter,
    :linesegments => AbstractPlotting.LineSegments,
    :heatmap => AbstractPlotting.Heatmap,
    :image => AbstractPlotting.Image,
    :spy => AbstractPlotting.Spy,
    :surface => AbstractPlotting.Surface,
    :shape => AbstractPlotting.Poly,
    :contour => AbstractPlotting.Contour,
    # TODO: line, contour,
)
