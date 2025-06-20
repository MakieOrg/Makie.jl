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
        return Colors.colorant"blue"
    end
    return convert(RGBA, c)
end

makie_seriestype_map = Dict{Symbol, Type}(
    :path => Lines,
    :path3d => Lines,
    :scatter => Scatter,
    :linesegments => LineSegments,
    :heatmap => Heatmap,
    :image => Image,
    :spy => Spy,
    :surface => Surface,
    :shape => Poly,
    :contour => Contour,
    :curves => Bezier,
    :bar => BarPlot,
    # TODO: line, contour,
)
