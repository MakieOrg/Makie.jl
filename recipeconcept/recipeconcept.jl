using Makie, MakieLayout
using AbstractPlotting: px
using GLFW; GLFW.WindowHint(GLFW.FLOATING, 1)
using KernelDensity
using StatsBase
using DataFrames

function defaultaxis(T::Type, args...)
    error("No default axis type defined for plot type $T.")
end

defaultaxis(T::Type{Lines}, args...) = LAxis

struct CreatesLayout end
struct CreatesNoLayout end

struct MarginDensityScatter end

createslayout(x::T) where T = error("""createslayout is not defined for type $T but this trait
    dispatch function is necessary for all recipe types.""")
createslayout(::Type{Lines}) = CreatesNoLayout()
createslayout(::Type{MarginDensityScatter}) = CreatesLayout()

"""Non-mutating general signature before layout trait dispatch"""
function myplot(T::Type, args...; kwargs...)
    myplot(createslayout(T), T, args...; kwargs...)
end

"""Mutating general signature before layout trait dispatch"""
function myplot!(T::Type, args...; kwargs...)
    myplot!(createslayout(T), T, args...; kwargs...)
end

"""
Recipes that don't create a layout, without scene or layout.
Returns created scene, layout, axis and plot object.
"""
function myplot(::CreatesNoLayout, T::Type, args...; kwargs...)
    scene, layout = layoutscene()
    ax = defaultaxis(T, args...)(scene)
    layout[1, 1] = ax
    plotobj = plot!(ax, T, args...)
    (scene = scene, layout = layout, axis = ax, plot = plotobj)
end


"""
Recipes that don't create a layout, scene and layout position.
Returns created axis and plot object.
"""
function myplot!(::CreatesNoLayout, T::Type, scene::Scene, gp::GridPosition, args...; kwargs...)
    ax = defaultaxis(T, args...)(scene)
    gp[] = ax
    plotobj = plot!(ax, T, args...)
    (axis = ax, plot = plotobj)
end

"""
Recipes that don't create a layout, mutating into axis.
Returns created plot object.
"""
function myplot!(::CreatesNoLayout, T::Type, ax::LAxis, args...; kwargs...)
    plotobj = plot!(ax, T, args...)
    plotobj
end

"""
Recipes that create a layout, without scene or layout.
Returns created scene, top layout, plot layout, axes and plot objects.
"""
function myplot(::CreatesLayout, T::Type, args...; kwargs...)
    scene, layout = layoutscene()
    result = myplot!(CreatesLayout(), T, scene, layout[1, 1], args...; kwargs...)
    # (scene = scene, layout = layout, axis)
    (scene = scene, toplayout = layout, layout = result.layout, axes = result.axes, plots = result.plots)
end


"""
Recipes that create a layout, with scene and layout position.
"""
function myplot!(::CreatesLayout, T::Type, scene::Scene, gp::GridPosition, args...; kwargs...)

    axs, layout = create_axes_and_layout(scene, T(), args...)
    gp[] = layout

    plots = myplot!(T, axs, args...; kwargs...)
    # (scene = scene, layout = layout, axis)
    (layout = layout, axes = axs, plots = plots)
end

function Base.display(nt::NamedTuple{(:scene, :layout, :axis, :plot), Tuple{S,G,A,P}}) where {S<:SceneLike, G, A, P}
    display(nt.scene)
end
function Base.display(nt::NamedTuple{(:scene, :toplayout, :layout, :axes, :plots), Tuple{S,TG,G,A,P}}) where {S<:SceneLike, TG,G, A, P}
    display(nt.scene)
end
function Base.display(nt::NamedTuple{(:scene, :axis, :plot), Tuple{S,A,P}}) where {S<:SceneLike, A, P}
    display(nt.scene)
end

function create_axes_and_layout(scene, type::T, args...) where T
    error("create_axes_and_layout is not defined for type $T but that function is necessary for CreatesLayout recipes.")
end

function create_axes_and_layout(scene, ::MarginDensityScatter, args...; xlabel = " ", ylabel = " ")
    mainax = LAxis(scene, xlabel = xlabel, ylabel = ylabel)
    topax = LAxis(scene; xlabelvisible = false, xticklabelsvisible = false, xticksvisible = false)
    rightax = LAxis(scene; ylabelvisible = false, yticklabelsvisible = false, yticksvisible = false)

    linkxaxes!(mainax, topax)
    linkyaxes!(mainax, rightax)

    tightlimits!(topax, Bottom())
    tightlimits!(rightax, Left())

    layout = GridLayout(2, 2; rowsizes = [Relative(1/4), Auto()], colsizes = [Auto(), Relative(1/4)])

    layout[2, 1] = mainax
    layout[1, 1] = topax
    layout[2, 2] = rightax

    (axes = (main = mainax, top = topax, right = rightax), layout = layout)
end

function create_axes_and_layout(scene, ::MarginDensityScatter, df::DataFrame)
    if size(df, 2) != 2
        error("2 columns needed")
    end

    create_axes_and_layout(scene, MarginDensityScatter();
        xlabel = string(names(df)[1]), ylabel = string(names(df)[2]))
end


"""

"""
function myplot!(::Type{MarginDensityScatter}, axs, x, y; kwargs...)

    xkde = kde(x; npoints = 300)
    ykde = kde(y; npoints = 300)

    scat = scatter!(axs.main, x, y; markersize = 10px, color = :red, strokecolor = :black, strokewidth = 1)
    kde1 = poly!(axs.top, Point2f0.(xkde.x, xkde.density), color = (:red, 0.5))
    kde2 = poly!(axs.right, Point2f0.(ykde.density, ykde.x), color = (:red, 0.5))

    autolimits!(axs.main)

    (scatter = scat, xkde = kde1, ykde = kde2)
end

function myplot!(::Type{MarginDensityScatter}, axs, df::DataFrame; kwargs...)
    myplot!(MarginDensityScatter, axs, df[!, 1], df[!, 2])
end


##

scene, toplayout, layout, axs, plotobjs = myplot(MarginDensityScatter, randn(200), randn(200))
myplot!(MarginDensityScatter, scene, toplayout[1, 2], randn(200), randn(200))
ax, line  = myplot!(Lines, scene, toplayout[2, 1:2], randn(100))
myplot!(Lines, ax, randn(100) .+ 5)
scene


##
df = DataFrame(xvalues = randn(100), yvalues = randn(100))
scene, topl, layout, axs, plotobjs = myplot(MarginDensityScatter, df)
myplot!(MarginDensityScatter, axs, randn(100) .+ 3, randn(100) .+ 3)
myplot!(MarginDensityScatter, axs, randn(100) .+ 5, randn(100) .+ 5)
scene

myplot!(MarginDensityScatter, scene, topl[1, 2], randn(100), randn(100));
