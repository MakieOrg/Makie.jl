using SparseArrays
using Random

const ALL_PLOT_PRIMITIVES = [
    Scatter, Lines, LineSegments, Makie.Text, Mesh, MeshScatter, Image, Heatmap,
    Surface, Volume, Voxels
]
const ALL_PLOT_TYPES = vcat(ALL_PLOT_PRIMITIVES, [
    # skipped Annotations, Axis3D
    ABLines, Arc, Arrows, Band, Makie.BarPlot, Bracket, Contourf, Contour, Contour3d,
    DataShader, Errorbars, Rangebars, HLines, VLines, HSpan, VSpan, Pie, Poly,
    RainClouds, ScatterLines, Series, Spy, Stairs, Stem, StreamPlot, TimeSeries,
    Tooltip, Tricontourf, Triplot, VolumeSlices, Voronoiplot, Waterfall, Wireframe,
    BoxPlot, CrossBar, Density, QQPlot, QQNorm, ECDFPlot, Hexbin, Hist, Violin
])

"""
    testplot!(scenelike, PlotType[; kwargs...])

Creates a sample plot of type `PlotType` with random data in the given `scenelike`.
Any keyword arguments are passed to the plot function.

This is meant to simplify creating throw-away plots for testing attributes.
`ALL_PLOT_TYPES` may also be useful.
"""
function testplot!(scene, ::Type{PlotType}, kwargs...) where {PlotType <: Plot}
    CT = Makie.conversion_trait(PlotType)
    f = Makie.MakieCore.plotfunc!(PlotType)

    if CT === PointBased() || PlotType <: Union{Makie.Text, ABLines, BarPlot,
            HSpan, VSpan, Triplot, Voronoiplot, BoxPlot, QQPlot, QQNorm}
        return f(scene, rand(10), rand(10); kwargs...)

    elseif CT isa Union{Makie.GridBased, Makie.ImageLike}
        return f(scene, rand(10, 10); kwargs...)

    elseif CT isa Makie.VolumeLike || PlotType <: Voxels
        return f(scene, rand(10, 10, 10); kwargs...)

    elseif PlotType <: Violin # TODO: doesn't work with SampleBased() input
        return f(scene, rand(1:3, 100), rand(100); kwargs...)

    elseif CT isa Makie.SampleBased || PlotType <: Union{Density, ECDFPlot, Hist}
        return f(scene, rand(100); kwargs...)

    elseif PlotType <: Union{HLines, VLines, Pie}
        return f(scene, rand(10); kwargs...)

    elseif PlotType <: Union{Band, Errorbars, Rangebars, Tricontourf}
        return f(scene, 1:10, rand(10), 1 .+ rand(10); kwargs...)

    elseif PlotType <: Union{Mesh, Poly, Wireframe}
        return f(scene, Rect2f(rand(Point2f), rand(Vec2f)); kwargs...)

    elseif PlotType <: Arc
        return f(scene, rand(Point2f), rand(), minmax(rand(), rand())...; kwargs...)

    elseif PlotType <: Arrows
        return f(scene, rand(Point2f, 10), rand(Vec2f, 10); kwargs...)

    elseif PlotType <: Bracket
        return f(scene, rand(Point2f), rand(Point2f); kwargs...)

    elseif PlotType <: DataShader
        return f(scene, rand(Point2f, 100); kwargs...)

    elseif PlotType <: RainClouds
        return f(scene, rand(["A", "B", "C"], 100), rand(100); kwargs...)

    elseif PlotType <: Series # TODO: merge with GridBased, ImageLike once more than 7 categories work
        return f(scene, [rand(Point2f, 10) for _ in 1:3]; kwargs...)

    elseif PlotType <: Spy
        return f(scene, sparse(rand(10, 10) .< 0.5); kwargs...)

    elseif PlotType <: StreamPlot
        return f(scene, (x, y) -> rand(Point2f), -1..1, -1..1; kwargs...)

    elseif PlotType <: TimeSeries
        obs = Observable(rand())
        p = f(scene, obs; kwargs...)
        for _ in 1:10
            sleep(0.01)
            obs[] = rand()
        end
        return p

    elseif PlotType <: Tooltip
        return f(scene, rand(Point2f), randstring(20); kwargs...)

    elseif PlotType <: VolumeSlices
        return f(scene, 1:10, 1:10, 1:10, rand(10,10,10); kwargs...)

    elseif PlotType <: CrossBar
        return f(scene, 1:10, 0 .- rand(10), rand(10), 1 .+ rand(10); kwargs...)

    else
        error("$PlotType not recognized")
    end
    return
end

