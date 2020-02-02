using Makie
using MakieLayout
using AbstractPlotting: px
using KernelDensity
using StatsBase


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
    infrastructure, plots = myplot!(T, scene, layout[1, 1], args...; dkwargs...)
    scene, layout, infrastructure, plots
end

function myplot!(T::Type, scene::Scene, args...; kwargs...)
    dkwargs = Dict(kwargs)
    scenekw = pop!(dkwargs, :scene, NamedTuple())
    layoutkw = pop!(dkwargs, :layout, NamedTuple())

    layout = GridLayout(scene; alignmode = Outside(30), scenekw..., layoutkw...)
    infrastructure, plots = myplot!(T, scene, layout[1, 1], args...; dkwargs...)
    layout, infrastructure, plots
end

function myplot!(T::Type, scene::Scene, gp::GridPosition, args...; kwargs...)
    dkwargs = Dict(kwargs)
    infrakw = pop!(dkwargs, :infra, NamedTuple())

    infrastructure = create_infrastructure(T, scene, args...; infrakw...)
    gp[] = infrastructure.layout
    plots = myplot!(T, infrastructure, args...; dkwargs...)
    infrastructure, plots
end

function myplot!(T::Type, infra::Infrastructure, args...; kwargs...)
    error("myplot! not defined for type $T")
end



function create_infrastructure(::Type{Scatter}, scene::Scene, args...; kwargs...)
    dkwargs = Dict(kwargs)
    axiskw = pop!(dkwargs, :axis, NamedTuple())
    layoutkw = pop!(dkwargs, :layout, NamedTuple())

    layout = GridLayout(;layoutkw...)
    axis = layout[1, 1] = LAxis(scene; axiskw...)
    Infrastructure((axis = axis, layout = layout))
end

function myplot!(::Type{Scatter}, infra::Infrastructure, args...; kwargs...)
    scat = scatter!(infra.axis, args...; kwargs...)
end

scene, layout, infra, plots = myplot(Scatter, 1:10, rand(10), markersize = 20px, color = :red);
scene

myplot!(Scatter, scene, layout[1, 2], 1:10, rand(10), markersize = 10px)
myplot!(Scatter, scene, layout[2, 1:2], 1:10, rand(10), markersize = 10px)
myplot!(Scatter, infra, 1:10, rand(10); color = :red, markersize = 10px)

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

function myplot!(::Type{MarginDensityScatter}, infra::Infrastructure, x, y; kwargs...)

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

scene, layout = layoutscene()

for i in 1:3, j in 1:3
    myplot!(MarginDensityScatter, scene, layout[i, j], randn(100), randn(100);
        color = rand(RGBAf0),
        infra = (
            marginfraction = 0.2,
            xlabel = "$i & $j",
            gap = Fixed(10)
        ))
end

scene



function test(;kwargs...)
    kwargs = Dict(kwargs)
    @show kwargs
    scenekw = pop!(kwargs, :scene, NamedTuple())
    @show kwargs
    nothing
end

test(scen = 1, b = 3)