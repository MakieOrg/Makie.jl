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
function current_figure!(fig)
    lock(CURRENT_FIGURE_LOCK) do
        CURRENT_FIGURE[] = fig
    end
    return fig
end

function cleanup_current_figure()
    lock(CURRENT_FIGURE_LOCK) do
        CURRENT_FIGURE[] = nothing
    end
    return
end

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
    Figure(; kwargs...)

Construct a `Figure` which allows to place `Block`s like [`Axis`](@ref), [`Colorbar`](@ref) and [`Legend`](@ref) inside.

## Keyword Arguments

- `size`: Figure size as `(width, height)` tuple (default: `(800, 600)`)
- `figure_padding`: Padding around the figure content. Either a single number or tuple `(left, right, bottom, top)`
- `backgroundcolor`: Background color of the figure

### Automatic Legend and Colorbar

- `legend`: Automatic legend from labeled plots. `true`, `false`, or `NamedTuple` with options like `(position=:lt, title="Legend")`.
  Position can be a Symbol (`:lt`, `:rt`, `:lb`, `:rb`) for overlay or grid position like `[1, 2]`.
- `colorbar`: Automatic colorbar from colormapped plots. `true`, `false`, or `NamedTuple` with options like `(position=[1,2], label="Values")`.

### Hover Bar

- `gui`: Enable hover bar with save/copy/reset buttons. `true`, `false`, or `NamedTuple` with style options.

## Examples

```julia
f = Figure(size=(800, 600))
f = Figure(; legend=(position=:lt,))
f = Figure(; colorbar=(position=[1, 2], label="Values"))
f = Figure(; gui=true)
```
"""
function Figure end

"""
    normalize_gui_option(value, name::Symbol) -> Union{Nothing, Dict{Symbol,Any}}

Normalize GUI options (gui/hovermenu, legend, colorbar) to a consistent format.
- `false` or `nothing` returns `nothing` (disabled)
- `true` returns empty Dict (enabled with defaults)
- NamedTuple/Attributes/Dict are converted to Dict{Symbol,Any}
"""
function normalize_gui_option(value, name::Symbol)
    if value === false || isnothing(value)
        return nothing
    elseif value === true
        return Dict{Symbol, Any}()
    elseif value isa NamedTuple
        return Dict{Symbol, Any}(pairs(value))
    elseif value isa Attributes
        return Dict{Symbol, Any}(k => to_value(v) for (k, v) in value)
    elseif value isa Dict
        return Dict{Symbol, Any}(value)
    else
        error("Invalid `$name` option: expected Bool, NamedTuple, Attributes, or Dict, got $(typeof(value))")
    end
end

"""
    get_gui_options(kwargs_dict, figure_theme, name::Symbol) -> Union{Nothing, Dict{Symbol,Any}}

Extract and normalize a GUI option from kwargs (with fallback to Figure theme).
Pops the option from kwargs_dict if present.
"""
function get_gui_options(kwargs_dict::Dict{Symbol, Any}, figure_theme::Attributes, name::Symbol)
    kwarg_opt = pop!(kwargs_dict, name, nothing)
    theme_opt = haskey(figure_theme, name) ? to_value(figure_theme[name]) : nothing
    opt = !isnothing(kwarg_opt) ? kwarg_opt : theme_opt
    return isnothing(opt) ? nothing : normalize_gui_option(opt, name)
end

function Figure(; kwargs...)
    kwargs_dict = Dict{Symbol, Any}(kwargs)
    padding = pop!(kwargs_dict, :figure_padding, theme(:figure_padding))

    # Check Figure theme for GUI options (set_theme!(Figure=(; gui=true, ...)))
    figure_theme = theme(:Figure; default = Attributes())::Attributes

    # Extract and normalize GUI options: kwargs > Figure theme
    hovermenu_options = get_gui_options(kwargs_dict, figure_theme, :gui)
    legend_options = get_gui_options(kwargs_dict, figure_theme, :legend)
    colorbar_options = get_gui_options(kwargs_dict, figure_theme, :colorbar)

    # Create GUIState with normalized options
    gui_state = GUIState(; hovermenu_options, legend_options, colorbar_options)

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
        Ref{Any}(nothing),
        gui_state
    )
    current_figure!(f)
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
