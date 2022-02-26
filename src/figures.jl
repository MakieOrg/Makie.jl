#=
Figures are supposed to fill the gap that Scenes in combination with Layoutables leave.
A scene is supposed to be a generic canvas on which plot objects can be placed and drawn.
Layoutables always require one specific type of scene, with a PixelCamera, in order to draw
their visual components there.
Figures also have layouts, which scenes do not have.
This is because every figure needs a layout, while not every scene does.
Figures keep track of the Layoutables that are created inside them, which scenes don't.

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

const _current_figure = Ref{Union{Nothing, Figure}}(nothing)
"Returns the current active figure (or the last figure that got created)"
current_figure() = _current_figure[]
"Set `fig` as the current active scene"
current_figure!(fig) = (_current_figure[] = fig)

"Returns the current active axis (or the last axis that got created)"
current_axis() = current_axis(current_figure())
current_axis(fig::Figure) = fig.current_axis[]
"Set `ax` as the current active axis in `fig`"
function current_axis!(fig::Figure, ax)
    if ax.parent !== fig
        error("This axis' parent is not the given figure")
    end
    fig.current_axis[] = ax
    ax
end
function current_axis!(fig::Figure, ::Nothing)
    fig.current_axis[] = nothing
end
function current_axis!(ax)
    fig = ax.parent
    if !(fig isa Figure)
        error("Axis parent is not a figure but a $(typeof(ax.parent)). Only axes in figures can have current_axis! called on them.")
    end

    current_axis!(fig, ax)
    # if the current axis is in a different figure, we switch to that as well
    # so that current_axis and current_figure are not out of sync
    current_figure!(fig)
    ax
end

to_rectsides(n::Number) = to_rectsides((n, n, n, n))
to_rectsides(t::Tuple{Any, Any, Any, Any}) = GridLayoutBase.RectSides{Float32}(t...)

function Figure(; kwargs...)

    kwargs_dict = Dict(kwargs)
    padding = pop!(kwargs_dict, :figure_padding, current_default_theme()[:figure_padding])
    scene = Scene(; camera=campixel!, kwargs_dict...)
    padding = padding isa Observable ? padding : Observable{Any}(padding)

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
    f
end

export Figure, current_axis, current_figure, current_axis!, current_figure!


function Base.getindex(fig::Figure, rows, cols, side = GridLayoutBase.Inner())
    fig.layout[rows, cols, side]
end

function Base.setindex!(fig::Figure, obj, rows, cols, side = GridLayoutBase.Inner())
    fig.layout[rows, cols, side] = obj
    obj
end

function Base.setindex!(fig::Figure, obj::AbstractArray, rows, cols)
    fig.layout[rows, cols] = obj
    obj
end

Base.lastindex(f::Figure, i) = lastindex(f.layout, i)

# for now just redirect figure display/show to the internal scene
Base.show(io::IO, fig::Figure) = show(io, fig.scene)
Base.show(io::IO, ::MIME"text/plain", fig::Figure) = print(io, "Figure()")
# Base.show(io::IO, ::MIME"image/svg+xml", fig::Figure) = show(io, MIME"image/svg+xml"(), fig.scene)


get_figure(gsp::GridLayoutBase.GridSubposition) = get_figure(gsp.parent)
function get_figure(gp::GridLayoutBase.GridPosition)
    top_parent = GridLayoutBase.top_parent(gp.layout)
    if top_parent isa Figure
        top_parent
    else
        nothing
    end
end

events(fig::Figure) = events(fig.scene)
events(fap::FigureAxisPlot) = events(fap.figure.scene)

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
function resize_to_layout!(fig::Figure)
    bbox = GridLayoutBase.tight_bbox(fig.layout)
    new_size = (widths(bbox)...,)
    resize!(fig.scene, widths(bbox)...)
    new_size
end

Base.isopen(fap::FigureAxisPlot) = Base.isopen(fap.plot)
