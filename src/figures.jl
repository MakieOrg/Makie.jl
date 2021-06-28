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

A non-mutating plotting command that references a FigurePosition or a FigureSubposition creates an axis at that position and returns an AxisPlot, which can be splatted into axis and plot.

All mutating plotting commands return AbstractPlots.
They can either reference a FigurePosition or a FigureSubposition, in which case it is looked up
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

    scene = Scene(; camera = campixel!, kwargs_dict...)

    padding = padding isa Observable ? padding : Observable{Any}(padding)

    alignmode = lift(Outside ∘ to_rectsides, padding)

    layout = GridLayout(scene)

    on(alignmode) do al
        layout.alignmode[] = al
        GridLayoutBase.update!(layout)
    end
    notify(alignmode)

    Figure(
        scene,
        layout,
        [],
        Attributes(),
        Ref{Any}(nothing)
    )
end

export Figure, current_axis, current_figure, current_axis!, current_figure!

# the FigurePosition is used to plot into a specific part of a figure and create
# an axis there, like `scatter(fig[1, 2], ...)`
struct FigurePosition
    fig::Figure
    gp::GridLayoutBase.GridPosition
end

function Base.getindex(fig::Figure, rows, cols, side = GridLayoutBase.Inner())
    FigurePosition(fig, fig.layout[rows, cols, side])
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
Base.lastindex(f::FigurePosition, i) = lastindex(f.fig, i)

# for now just redirect figure display/show to the internal scene
Base.show(io::IO, fig::Figure) = show(io, fig.scene)
Base.show(io::IO, ::MIME"text/plain", fig::Figure) = print(io, "Figure()")
# Base.show(io::IO, ::MIME"image/svg+xml", fig::Figure) = show(io, MIME"image/svg+xml"(), fig.scene)

# a FigureSubposition is just a deeper nested position in a figure's layout, and it doesn't
# necessarily have to refer to an existing layout either, because those can be created
# when it becomes necessary
struct FigureSubposition{T}
    parent::T
    rows
    cols
    side::GridLayoutBase.Side
end

# fp[1, 2] creates a FigureSubposition, a nested version of FigurePosition
# currently, because at the time of creation there is not necessarily a gridlayout
# at all nested locations, the end+1 syntax doesn't work, because it's not known how many
# rows/cols the nested grid has if it doesn't exist yet
function Base.getindex(parent::Union{FigurePosition,FigureSubposition},
        rows, cols, side = GridLayoutBase.Inner())
    FigureSubposition(parent, rows, cols, side)
end

function Base.setindex!(parent::Union{FigurePosition,FigureSubposition}, obj,
    rows, cols, side = GridLayoutBase.Inner())
    layout = get_layout_at!(parent, createmissing = true)
    isnothing(layout) && error("No single GridLayout could be found or created at this FigureSubposition. This means that there are at least two GridLayouts at this position already and it's unclear which one is meant.")
    layout[rows, cols, side] = obj
    obj
end

function Base.setindex!(parent::FigurePosition, obj)
    parent.gp[] = obj
    obj
end

function Base.setindex!(parent::FigureSubposition, obj)
    layout = get_layout_at!(parent.parent, createmissing = true)
    isnothing(layout) && error("No single GridLayout could be found or created at this FigureSubposition. This means that there are at least two GridLayouts at this position already and it's unclear which one is meant.")
    layout[parent.rows, parent.cols, parent.side] = obj
    obj
end


# to power a simple syntax for plotting into nested grids like
# `scatter(fig[1, 1][2, 3], ...)` we need to either find the only gridlayout that
# sits at that position, or we create all the ones that are missing along the way
# as a convenience, so that users don't have to manually create gridlayouts all that often
function get_layout_at!(fp::FigurePosition; createmissing = false)
    c = contents(fp.gp, exact = true)
    layouts = filter(x -> x isa GridLayoutBase.GridLayout, c)
    if isempty(layouts) && createmissing
        fp.gp[] = GridLayoutBase.GridLayout()
    elseif length(layouts) == 1
        first(layouts)::GridLayoutBase.GridLayout
    else
        nothing
    end
end

function get_layout_at!(fsp::FigureSubposition; createmissing = false)
    layout = get_layout_at!(fsp.parent; createmissing = createmissing)

    if isnothing(layout)
        return nothing
    end

    gp = layout[fsp.rows, fsp.cols, fsp.side]

    c = contents(gp, exact = true)
    layouts = filter(x -> x isa GridLayoutBase.GridLayout, c)
    if isempty(layouts) && createmissing
        gp[] = GridLayoutBase.GridLayout()
    elseif length(layouts) == 1
        first(layouts)::GridLayoutBase.GridLayout
    else
        nothing
    end
end

get_figure(fsp::FigureSubposition) = get_figure(fsp.parent)
get_figure(fp::FigurePosition) = fp.fig

function GridLayoutBase.contents(f::FigurePosition; exact = false)
    GridLayoutBase.contents(f.gp, exact = exact)
end

function GridLayoutBase.contents(f::FigureSubposition; exact = false)
    layout = get_layout_at!(f.parent, createmissing = false)
    isnothing(layout) && return []
    GridLayoutBase.contents(layout[f.rows, f.cols, f.side], exact = exact)
end

function GridLayoutBase.content(f::FigurePosition)
    content(f.gp)
end

function GridLayoutBase.content(f::FigureSubposition)
    cs = contents(f, exact = true)
    if length(cs) == 1
        return cs[1]
    else
        error("There is not exactly one object at the given FigureSubposition")
    end
end

events(fig::Figure) = events(fig.scene)
events(fap::FigureAxisPlot) = events(fap.figure.scene)