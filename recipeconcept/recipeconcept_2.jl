using Makie
using MakieLayout
using AbstractPlotting: px
using KernelDensity
using StatsBase
using GLFW; GLFW.WindowHint(GLFW.FLOATING, 1)
using StatsMakie
using DataFrames
using Colors


struct Infrastructure{T<:NamedTuple}
    content::T
end

function Base.getproperty(infra::Infrastructure, sym::Symbol)
    if sym in fieldnames(Infrastructure)
        getfield(infra, sym)
    else
        infra.content[sym]
    end
end

function create_infrastructure(T::Type, scene::Scene, args...; kwargs...)
    error("create_infrastructure not defined for type $T.")
end

function myplot(T::Type, args...; kwargs...)
    dkwargs = Dict(kwargs)
    scenekw = pop!(dkwargs, :scene, NamedTuple())
    layoutkw = pop!(dkwargs, :layout, NamedTuple())

    scene, layout = layoutscene(; scenekw..., layoutkw...)
    infrastructure, plots = myplot(T, layout[1, 1], args...; dkwargs...)
    (scene = scene, layout = layout, infra = infrastructure, plots = plots)
end

function myplot(T::Type, scene::Scene, args...; kwargs...)
    dkwargs = Dict(kwargs)
    scenekw = pop!(dkwargs, :scene, NamedTuple())
    layoutkw = pop!(dkwargs, :layout, NamedTuple())

    layout = GridLayout(scene; alignmode = Outside(30), scenekw..., layoutkw...)
    infrastructure, plots = myplot(T, layout[1, 1], args...; dkwargs...)
    (layout = layout, infra = infrastructure, plots = plots)
end

function get_layout_top_scene(layout::GridLayout)
    if isnothing(layout.layoutobservables.gridcontent)
        return layout.parentscene
    else
        parentgrid = layout.layoutobservables.gridcontent.parent
        if isnothing(parentgrid)
            return layout.parentscene
        else
            return get_layout_top_scene(parentgrid)
        end
    end 
end

abstract type InfrastructureType end
struct SingleAxis <: InfrastructureType end
struct FacetAxes <: InfrastructureType end

infrastructure_type(any::Type) = any # if nothing is set, just use the type directly
infrastructure_type(::Type{Scatter}) = SingleAxis
infrastructure_type(::Type{Lines}) = SingleAxis

function myplot(T::Type, gp::GridPosition, args...; kwargs...)
    scene = get_layout_top_scene(gp.layout)
    if isnothing(scene)
        error("Could not retrieve a parent scene from the layout's tree. Can't plot using a GridLayout without top level parent scene.")
    end

    dkwargs = Dict(kwargs)
    infrakw = pop!(dkwargs, :infra, NamedTuple())

    infrastructure = create_infrastructure(
        infrastructure_type(T),
        scene, args...; infrakw...)

    gp[] = infrastructure.layout
    plots = myplot(T, infrastructure, args...; dkwargs...)
    infrastructure, plots
end

function myplot(T::Type, infra::Infrastructure, args...; kwargs...)
    error("myplot not defined for type $T")
end


function create_infrastructure(::Type{SingleAxis}, scene::Scene, args...; kwargs...)
    dkwargs = Dict(kwargs)
    axiskw = pop!(dkwargs, :axis, NamedTuple())
    layoutkw = pop!(dkwargs, :layout, NamedTuple())

    layout = GridLayout(;layoutkw...)
    axis = layout[1, 1] = LAxis(scene; axiskw...)
    Infrastructure((axis = axis, layout = layout))
end

function create_infrastructure(::Union{Type{Heatmap}, Type{Image}}, scene::Scene, args...; kwargs...)
    infra = create_infrastructure(SingleAxis, scene, args...; kwargs...)
    tightlimits!(infra.axis)
    infra
end

function Base.display(nt::NamedTuple{(:scene, :layout, :infra, :plots), Tuple{S,G,I,P}}) where {S<:SceneLike, G, I, P}
    display(nt.scene)
end

function myplot(::Type{Scatter}, infra::Infrastructure, args...; kwargs...)
    scat = scatter!(infra.axis, args...; kwargs...)
end

function myplot(::Type{Lines}, infra::Infrastructure, args...; kwargs...)
    lin = lines!(infra.axis, args...; kwargs...)
end

function myplot(::Type{Heatmap}, infra::Infrastructure, args...; kwargs...)
    hm = heatmap!(infra.axis, args...; kwargs...)
end

function myplot(::Type{Image}, infra::Infrastructure, args...; kwargs...)
    hm = image!(infra.axis, args...; kwargs...)
end

##
scene, layout, _ = myplot(Heatmap, rand(100, 100), infra = (;axis = (;aspect = DataAspect(), xlabel = "helloo"))); scene
myplot(Lines, layout[1, 2], 1:10, sin.(1:10))
scene
##

myplot(Scatter, Group(color = rand(1:3, 100)), rand(100), rand(100), markersize = 20px)



struct MarginDensityScatter end

function create_infrastructure(::Type{MarginDensityScatter}, scene::Scene, args...; kwargs...)

    dkwargs = Dict(kwargs)

    mainax = LAxis(scene, xlabel = get(dkwargs, :xlabel, " "), ylabel = get(dkwargs, :ylabel, " "))
    topax = LAxis(scene; xlabelvisible = false, xticklabelsvisible = false, xticksvisible = false)
    rightax = LAxis(scene; ylabelvisible = false, yticklabelsvisible = false, yticksvisible = false)

    linkxaxes!(mainax, topax)
    linkyaxes!(mainax, rightax)

    tightlimits!(topax, Bottom())
    tightlimits!(rightax, Left())

    marginfraction = get(dkwargs, :marginfraction, 1/4)
    gap = get(dkwargs, :gap, Fixed(20))

    layout = GridLayout(2, 2; rowsizes = [Relative(marginfraction), Auto()],
        colsizes = [Auto(), Relative(marginfraction)], addedcolgaps = gap, addedrowgaps = gap)

    layout[2, 1] = mainax
    layout[1, 1] = topax
    layout[2, 2] = rightax

    Infrastructure((axes = (main = mainax, top = topax, right = rightax), layout = layout))
end

function myplot(::Type{MarginDensityScatter}, infra::Infrastructure, x, y; kwargs...)

    dkwargs = Dict(kwargs)

    xkde = kde(x; npoints = 300)
    ykde = kde(y; npoints = 300)

    color = get(dkwargs, :color, :red)

    scat = scatter!(infra.axes.main, x, y; markersize = get(dkwargs, :markersize, 10px), color = color, strokecolor = get(dkwargs, :strokecolor, :black), strokewidth = get(dkwargs, :strokewidth, 1))
    kde1 = poly!(infra.axes.top, Point2f0.(xkde.x, xkde.density), color = color)
    kde2 = poly!(infra.axes.right, Point2f0.(ykde.density, ykde.x), color = color)

    autolimits!(infra.axes.main)

    (scatter = scat, xkde = kde1, ykde = kde2)
end

##
scene, layout = layoutscene()

for i in 1:3, j in 1:3
    myplot(MarginDensityScatter, layout[i, j], randn(100), randn(100);
        color = rand(RGBAf0),
        infra = (
            marginfraction = 0.2,
            xlabel = "$i & $j",
            gap = Fixed(10)
        ))
end

scene
##

##
scene, layout = layoutscene()
myplot(Scatter, layout[1, 1], rand(100), rand(100), markersize = 20px, color = :green, strokecolor = :black, strokewidth = 1)
myplot(Scatter, layout[2, 1], rand(100), rand(100), markersize = 20px, color = :red, strokecolor = :black, strokewidth = 1)
myplot(Scatter, layout[1:2, 2], rand(100), rand(100), markersize = 20px, color = :blue, strokecolor = :black, strokewidth = 1)
myplot(MarginDensityScatter, layout[1:2, 3:4], randn(100), randn(100))
scene
##

struct FacetPlot end

function create_infrastructure(::Type{FacetPlot}, scene::Scene, plottype, rows, cols, args...; kwargs...)

    dkwargs = Dict(kwargs)

    axiskw = pop!(dkwargs, :axes, NamedTuple())
    layoutkw = pop!(dkwargs, :layout, NamedTuple())

    nrows = length(unique(rows))
    ncols = length(unique(cols))

    layout = GridLayout(; layoutkw...)

    axs = [LAxis(scene; axiskw...) for x in CartesianIndices((nrows, ncols))]

    layout[] = axs

    for ax in axs[:, 2:end]
        ax.ylabelvisible = false
        ax.yticklabelsvisible = false
        ax.yticksvisible[] = false
    end

    for ax in axs[1:end-1, :]
        ax.xlabelvisible[] = false
        ax.xticklabelsvisible = false
        ax.xticksvisible[] = false
    end


    linkxaxes!(axs...)
    linkyaxes!(axs...)

    Infrastructure((axes = axs, layout = layout))
end


function myplot(::Type{FacetPlot}, infra::Infrastructure, plottype, rows, cols, x, y; kwargs...)

    dkwargs = Dict(kwargs)

    df = DataFrame(rows = rows, cols = cols, x = x, y = y)

    for (ax, sdf) in zip(infra.axes, groupby(df, [:rows, :cols]))
        myplot(plottype, Infrastructure((axis = ax,)), sdf.x, sdf.y; kwargs...)
    end

    autolimits!(infra.axes[1])
end


##

msize = Node(10px)
scene, layout, infra = myplot(FacetPlot, Scatter,
    rand(1:3, 1000), rand(1:4, 1000), randn(1000), randn(1000), markersize = msize, color = :orange, strokewidth = 1, strokecolor = :black, infra = (; axes = (;backgroundcolor = Gray(0.9))))
myplot(FacetPlot, infra, Lines,
    rand(1:3, 1000), rand(1:4, 1000), randn(1000), randn(1000); color = :red)

for c in 1:infra.layout.ncols
    infra.layout[1, c, Top()] = LRect(scene, color = Gray(0.8))
    infra.layout[1, c, Top()] = LText(scene, "Column $c", padding = (0, 0, 10, 10))
end

for r in 1:infra.layout.nrows
    infra.layout[r, end, Right()] = LRect(scene, color = Gray(0.8))
    infra.layout[r, end, Right()] = LText(scene, "Row $r", rotation = -pi/2, padding = (10, 10, 0, 0))
end

layout[0, :] = LRect(scene, color = Gray(0.7))
layout[1, :] = LText(scene, "Columns", padding = (0, 0, 10, 10))
layout.content[end].content.width = Auto(false)

foreach(LAxis, layout) do ax; tight_ticklabel_spacing!(ax); end
