using Makie, MakieLayout
using AbstractPlotting: px
using GLFW; GLFW.WindowHint(GLFW.FLOATING, 1)
using KernelDensity
using StatsBase

function defaultaxis(T::Type, args...)
    error("No default axis type defined for plot type $T.")
end

defaultaxis(T::Type{Lines}, args...) = LAxis

struct CreatesLayout end
struct CreatesNoLayout end

struct MarginDensityScatter end

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
    gp.layout[gp.rows, gp.cols] = ax
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
    result = plot!(scene, layout[1, 1], T, args...; kwargs...)
    # (scene = scene, layout = layout, axis)
    (scene = scene, toplayout = layout, layout = result.layout, axes = result.axes, plots = result.plots)
end


"""
Recipes that create a layout, with scene and layout position.
"""
function myplot!(::CreatesLayout, T::Type, scene::Scene, gp::GridPosition, args...; kwargs...)

    result = plot!(scene, gp, T, args...; kwargs...)
    # (scene = scene, layout = layout, axis)
    result
end

function Base.display(nt::NamedTuple{(:scene, :layout, :axis, :plot), Tuple{S,G,A,P}}) where {S<:SceneLike, G, A, P}
    display(nt.scene)
end
function Base.display(nt::NamedTuple{(:scene, :toplayout, :layout, :axes, :plots), Tuple{S,G,A,P}}) where {S<:SceneLike, G, A, P}
    display(nt.scene)
end
function Base.display(nt::NamedTuple{(:scene, :axis, :plot), Tuple{S,A,P}}) where {S<:SceneLike, A, P}
    display(nt.scene)
end

function create_axes_and_layout(scene, ::MarginDensityScatter, args...)
    mainax = LAxis(scene)
    topax = LAxis(scene; xlabelvisible = false, xticklabelsvisible = false, xticksvisible = false)
    rightax = LAxis(scene; ylabelvisible = false, yticklabelsvisible = false, yticksvisible = false)

    linkxaxes!(mainax, topax)
    linkyaxes!(mainax, rightax)

    tightlimits!(topax, Bottom())
    tightlimits!(rightax, Left())

    layout = GridLayout(2, 2; rowsizes = [Relative(1/3), Auto()], colsizes = [Auto(), Relative(1/3)])

    layout[2, 1] = mainax
    layout[1, 1] = topax
    layout[2, 2] = rightax

    (axes = (main = mainax, top = topax, right = rightax), layout = layout)
end

function AbstractPlotting.plot!(scene::Scene, gp::GridPosition, ::Type{MarginDensityScatter}, x, y; kwargs...)

    axs, layout = create_axes_and_layout(scene, MarginDensityScatter(), x, y)

    gp.layout[gp.rows, gp.cols] = layout

    xkde = kde(x; npoints = 300)
    ykde = kde(y; npoints = 300)

    scat = scatter!(axs.main, x, y; markersize = 10px)
    kde1 = poly!(axs.top, Point2f0.(xkde.x, xkde.density))
    kde2 = poly!(axs.right, Point2f0.(ykde.density, ykde.x))

    autolimits!(axs.main)

    (scene = scene, layout = layout, axes = axs, plots = (scatter = scat, xkde = kde1, ykde = kde2))
end

# plot!(scene::Scene, gp::GridPosition)


##
# scene, layout, _ = myplot(Lines, rand(10))

scene, layout, axs, plotobjs = myplot(MarginDensityScatter, randn(200), randn(200))
myplot!(MarginDensityScatter, scene, layout[1, 2], randn(200), randn(200))
ax, line  = myplot!(Lines, scene, layout[2, 1:2], randn(100))
myplot!(Lines, ax, randn(100) .+ 5)
scene
