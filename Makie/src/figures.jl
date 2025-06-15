#=
Figures are supposed to fill the gap that Scenes in combination with Blocks leave.
A scene is supposed to be a generic canvas on which plot objects can be placed and drawn.
Blocks always require one specific type of scene, with a PixelCamera, in order to draw
their visual components there.
Figures also have layouts, which scenes do not have.
This is because every figure needs a layout, while not every scene does.
Figures keep track of the Blocks that are created inside them, which scenes don't.

The idea is there are three types of plotting commands.
They can return either:
    - a FigureAxisPlot (figure, axis and plot)
    - an AxisPlot (axis and plot)
    - or an AbstractPlot (only plot)

This is needed so that users can without much boilerplate create the necessary structures and access them accordingly.

A normal plotting command creates a FigureAxisPlot, which can be splatted into figure, axis and plot. It displays like a figure, so that simple plots show up immediately.

A non-mutating plotting command that references a GridPosition or a GridSubposition creates an axis at that position and returns an AxisPlot, which can be splatted into axis and plot.

All mutating plotting commands return AbstractPlots.
They can either reference a GridPosition or a GridSubposition, in which case it is looked up
if an axis is placed at that position (if not it errors) or it can reference an axis directly to plot into.
=#

get_scene(fig::Figure) = fig.scene
get_scene(fap::FigureAxisPlot) = fap.figure.scene
get_scene(gp::GridLayoutBase.GridPosition) = get_scene(get_figure(gp))
get_scene(gp::GridLayoutBase.GridSubposition) = get_scene(get_figure(gp))


const CURRENT_FIGURE = Ref{Union{Nothing, Figure}}(nothing)
const CURRENT_FIGURE_LOCK = Base.ReentrantLock()

"""
    current_figure()

Returns the current active figure (or the last figure created).
Returns `nothing` if there is no current active figure.
"""
current_figure() = lock(() -> CURRENT_FIGURE[], CURRENT_FIGURE_LOCK)

"""
    current_figure!(fig)

Set `fig` as the current active figure.
"""
current_figure!(fig) = lock(() -> (CURRENT_FIGURE[] = fig), CURRENT_FIGURE_LOCK)

"""
    current_axis()

Returns the current active axis (or the last axis created). Returns `nothing` if there is no current active axis.
"""
current_axis() = current_axis(current_figure())
current_axis(::Nothing) = nothing
current_axis(fig::Figure) = fig.current_axis[]
"""
    current_axis!(fig::Figure, ax)

Set `ax` as the current active axis in `fig`.
"""
function current_axis!(fig::Figure, ax)
    if ax.parent !== fig
        error("This axis' parent is not the given figure")
    end
    fig.current_axis[] = ax
    return ax
end

function current_axis!(fig::Figure, ::Nothing)
    return fig.current_axis[] = nothing
end

"""
    current_axis!(ax)

Set an axis `ax`, which must be part of a figure, as the figure's current active axis.
"""
function current_axis!(ax)
    fig = ax.parent
    if !(fig isa Figure)
        error("Axis parent is not a figure but a $(typeof(ax.parent)). Only axes in figures can have current_axis! called on them.")
    end

    current_axis!(fig, ax)
    # if the current axis is in a different figure, we switch to that as well
    # so that current_axis and current_figure are not out of sync
    current_figure!(fig)
    return ax
end

to_rectsides(n::Number) = to_rectsides((n, n, n, n))
to_rectsides(t::Tuple{Any, Any, Any, Any}) = GridLayoutBase.RectSides{Float32}(t...)

"""
    Figure(; [figure_padding,] kwargs...)

Construct a `Figure` which allows to place `Block`s like [`Axis`](@ref), [`Colorbar`](@ref) and [`Legend`](@ref) inside.
The outer padding of the figure (the distance of the content to the edges) can be set by passing either
one number or a tuple of four numbers for left, right, bottom and top paddings via the `figure_padding` keyword.

All other keyword arguments such as `size` and `backgroundcolor` are forwarded to the
[`Scene`](@ref) owned by the figure which acts as the container for all other visual objects.
"""
function Figure(; kwargs...)

    kwargs_dict = Dict(kwargs)
    padding = pop!(kwargs_dict, :figure_padding, theme(:figure_padding))
    scene = Scene(; camera = campixel!, clear = true, kwargs_dict...)
    padding = convert(Observable{Any}, padding)
    alignmode = lift(Outside ∘ to_rectsides, padding)

    layout = GridLayout(scene)

    on(alignmode) do al
        layout.alignmode[] = al
        GridLayoutBase.update!(layout)
    end
    notify(alignmode)

    f = Figure(
        scene,
        layout,
        [],
        Attributes(),
        Ref{Any}(nothing)
    )
    # set figure as layout parent so GridPositions can refer to the figure
    # if connected correctly
    layout.parent = f
    return f
end

export Figure, current_axis, current_figure, current_axis!, current_figure!


function Base.getindex(fig::Figure, rows, cols, side = GridLayoutBase.Inner())
    return fig.layout[rows, cols, side]
end

function Base.setindex!(fig::Figure, obj, rows, cols, side = GridLayoutBase.Inner())
    fig.layout[rows, cols, side] = obj
    return obj
end

function Base.setindex!(fig::Figure, obj::AbstractArray, rows, cols)
    fig.layout[rows, cols] = obj
    return obj
end

Base.lastindex(f::Figure, i) = lastindex(f.layout, i)
Base.firstindex(f::Figure, i) = firstindex(f.layout, i)

# for now just redirect figure display/show to the internal scene
Base.show(io::IO, fig::Figure) = show(io, fig.scene)
Base.show(io::IO, ::MIME"text/plain", fig::Figure) = print(io, "Figure()")
# Base.show(io::IO, ::MIME"image/svg+xml", fig::Figure) = show(io, MIME"image/svg+xml"(), fig.scene)


get_figure(gsp::GridLayoutBase.GridSubposition) = get_figure(gsp.parent)
function get_figure(gp::GridLayoutBase.GridPosition)
    top_parent = GridLayoutBase.top_parent(gp.layout)
    return if top_parent isa Figure
        top_parent
    else
        nothing
    end
end

"""
    resize_to_layout!(fig::Figure)

Resize `fig` so that it fits the current contents of its top `GridLayout`.
If a `GridLayout` contains fixed-size content or aspect-constrained
columns, for example, it is likely that the solved size of the `GridLayout`
differs from the size of the `Figure`. This can result in superfluous
whitespace at the borders, or content clipping at the figure edges.
Once resized, all content should fit the available space, including
the `Figure`'s outer padding.
"""
function resize_to_layout!(fig::Figure = current_figure())
    # it is assumed that all plot objects have been added at this point,
    # but it's possible the limits have not been updated, yet,
    # so without `update_state_before_display!` it's possible that the layout
    # is optimized for the wrong ticks
    update_state_before_display!(fig)
    bbox = GridLayoutBase.tight_bbox(fig.layout)
    new_size = (widths(bbox)...,)
    resize!(fig.scene, widths(bbox)...)
    return new_size
end

function Base.empty!(fig::Figure)
    empty!(fig.scene)
    empty!(fig.scene.events)
    foreach(GridLayoutBase.remove_from_gridlayout!, reverse(fig.layout.content))
    trim!(fig.layout)
    empty!(fig.content)
    fig.current_axis[] = nothing
    return
end

# Allow figures to be directly resized by resizing their internal Scene.
# Layouts are already hooked up to this, so it's very simple.
"""
    resize!(fig::Figure, width, height)
Resizes the given `Figure` to the size given by `width` and `height`.
If you want to resize the figure to its current layout content, use `resize_to_layout!(fig)` instead.
"""
Makie.resize!(figure::Figure, width::Integer, height::Integer) = resize!(figure.scene, width, height)
