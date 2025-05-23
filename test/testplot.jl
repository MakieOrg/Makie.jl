using SparseArrays
using Random

const ALL_PLOT_PRIMITIVES = [
    Scatter, Lines, LineSegments, Makie.Text, Makie.Mesh, MeshScatter, Image, Heatmap,
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
    f = Makie.MakieCore.plotfunc!(PlotType)
    return f(scene, sample_args(PlotType)...; kwargs...)
end

function testplot!(scene, ::Type{<: TimeSeries}, kwargs...)
    obs = Observable(rand())
    p = timeseries!(scene, obs; kwargs...)
    for _ in 1:10
        sleep(0.01)
        obs[] = rand()
    end
    return p
end

function sample_args(::Type{PlotType}) where {PlotType <: Plot}
    CT = Makie.conversion_trait(PlotType)
    try
        return sample_args(CT)
    catch e
        @error "Failed to produce sample args for $PlotType with conversion trait $CT:"
        rethrow(e)
    end
end


function sample_args(::Type{<: Union{Makie.Text, ABLines, BarPlot, HSpan, VSpan, Triplot, Voronoiplot, BoxPlot, QQPlot, QQNorm}})
    return (rand(10), rand(10))
end
sample_args(::Type{<: Union{HLines, VLines, Pie}}) = (rand(10),)
sample_args(::Type{<: Union{Band, Errorbars, Rangebars, Tricontourf}}) = (1:10, rand(10), 1 .+ rand(10))
sample_args(::Type{<: Union{Makie.Mesh, Poly, Wireframe}}) = (Rect2f(rand(Point2f), rand(Vec2f)),)

sample_args(::Type{<: Arc}) = (rand(Point2f), rand(), minmax(rand(), rand())...)
sample_args(::Type{<: Arrows}) = (rand(Point2f, 10), rand(Vec2f, 10))
sample_args(::Type{<: Bracket}) = (rand(Point2f), rand(Point2f))
sample_args(::Type{<: DataShader}) = (rand(Point2f, 100),)
sample_args(::Type{<: Spy}) = (sparse(rand(10, 10) .< 0.5),)
sample_args(::Type{<: StreamPlot}) = ((x, y) -> rand(Point2f), -1..1, -1..1)
sample_args(::Type{<: Tooltip}) = (rand(Point2f), randstring(20))
sample_args(::Type{<: VolumeSlices}) = (1:10, 1:10, 1:10, rand(10,10,10))
sample_args(::Type{<: CrossBar}) = (1:10, 0 .- rand(10), rand(10), 1 .+ rand(10))
sample_args(::Type{<: Voxels}) = (rand(10, 10, 10),)
sample_args(::Type{<: Violin}) = (rand(1:3, 100), rand(100)) # TODO: doesn't work with SampleBased() input
sample_args(::Type{<: Union{Density, ECDFPlot, Hist}}) = (rand(100), ) # TODO: Should be SampleBased()?
sample_args(::Type{<: RainClouds}) = (rand(["A", "B", "C"], 100), rand(100))
sample_args(::Type{<: Series}) = ([rand(Point2f, 10) for _ in 1:3], )
sample_args(::Type{<: TimeSeries}) = error("TimeSeries args are time sensitive. To produce a valid plot, use testplot!(). If you don't care, use `timeseries(0.0)`.")

sample_args(::PointBased) = (rand(10), rand(10))
sample_args(::Union{GridBased, ImageLike}) = (rand(10, 10), )
sample_args(::VolumeLike) = (rand(10, 10, 10), )
sample_args(::Makie.SampleBased) = (rand(100), )
