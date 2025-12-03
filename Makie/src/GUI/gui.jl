using ImageClipboard

include("file-dialogue.jl")
include("hovermenu.jl")

# GUIState is defined in scenes.jl before Figure

"""
    create_gui_legend!(fig::Figure, ax, plot::AbstractPlot, options::Dict{Symbol,Any})

Create a legend for the plot if it has labeled elements.

## Options (in Dict)
- `position`: Position - either Symbol (`:rt`, `:lt`, etc) for overlay or `[row, col]` for grid (default: `:rt`)
- `margin`: Margin around the legend for overlay positioning (default: `(6, 6, 6, 6)`) - only valid with Symbol position
- `unique`: Only show unique labels (default: `false`)
- `merge`: Merge plots with the same label (default: `false`)
- `title`: Legend title (default: `nothing`)
- Any other options are passed to `Legend`

Returns the Legend object or `nothing` if no labeled plots exist.
"""
function create_gui_legend!(fig::Figure, ax, plot::AbstractPlot, options::Dict{Symbol,Any})
    position = get(options, :position, :rt)

    # Check if there are any labeled plots
    unique_labels = get(options, :unique, false)
    merge_labels = get(options, :merge, false)
    plots, labels = Makie.get_labeled_plots(ax; unique=unique_labels, merge=merge_labels)
    isempty(plots) && return nothing

    # Validate margin usage
    if haskey(options, :margin) && !(position isa Symbol)
        error("`margin` is only valid for overlay positioning (Symbol like :rt). For grid positions, use padding on the layout instead.")
    end

    # Use Legend(ax; ...) for overlay, Legend(fig[pos...], ...) for grid
    if position isa Symbol
        return Legend(ax; options...)
    else
        legend_options = filter(kv -> kv.first != :position, options)
        title = get(options, :title, nothing)
        return Legend(fig[position...], plots, labels, title; legend_options...)
    end
end

"""
    create_gui_colorbar!(fig::Figure, ax, plot::AbstractPlot, options::Dict{Symbol,Any})

Create a colorbar for the plot if it has a colormap.

## Options (in Dict)
- `position`: Position - either Symbol (`:rt`, `:lt`, etc) for overlay or `[row, col]` for grid (default: `[1, 2]`)
- `margin`: Margin around the colorbar for overlay positioning (default: `(6, 6, 6, 6)`) - only valid with Symbol position
- Any other options are passed to `Colorbar`

Returns the Colorbar object or `nothing` if no colormap exists.
"""
function create_gui_colorbar!(fig::Figure, ax, plot::AbstractPlot, options::Dict{Symbol,Any})
    position = get(options, :position, [1, 2])
    options = filter(((name, _),) -> name != :position, options)

    # Check if plot has a colormap
    cmap = nothing
    try
        cmap = Makie.extract_colormap_recursive(plot)
    catch
        return nothing
    end
    isnothing(cmap) && return nothing
    # Validate margin usage
    if haskey(options, :margin) && !(position isa Symbol)
        error("`margin` is only valid for overlay positioning (Symbol like :rt). For grid positions, use padding on the layout instead.")
    end
    # Use Colorbar(ax, plot; position=...) for overlay, Colorbar(fig[pos...], plot; ...) for grid
    if position isa Symbol
        return Colorbar(ax, plot; position=position, options...)
    else
        return Colorbar(fig[position...], plot; options...)
    end
end

"""
    add_gui!(faxpl::FigureAxisPlot) -> FigureAxisPlot
    add_gui!(fig::Figure, ax, plot::Union{AbstractPlot, Nothing}) -> nothing

Add GUI elements (hover bar, legend, colorbar) to a figure.
When `plot` is `nothing`, only the hover bar is added (legend and colorbar require a plot).
The GUI is only added once per figure - subsequent calls are ignored.

Options are read from:
1. Figure attributes: `Figure(; gui=true, legend=(...), colorbar=(...))`
2. Plot call: `scatter(...; figure=(; gui=true, legend=(...)))`
3. Theme: `set_theme!(Figure=(; gui=true, legend=(...)))`

## Arguments
- `faxpl`: A `FigureAxisPlot` returned from a plotting function
- Or: `fig::Figure`, `ax` (axis), `plot::AbstractPlot`

## Figure/Theme Options
- `gui`: Enable hover menu. Can be `true`, `false`, or a NamedTuple with:
  - `style`: NamedTuple with hover bar styling options
- `legend`: Legend configuration passed to `Legend`. Common options:
  - `position`: Position symbol (`:rt`, `:lt`, etc.) or grid position `[row, col]`
  - `margin`, `title`, `unique`, `merge`
  - Set to `false` to disable
- `colorbar`: Colorbar configuration passed to `Colorbar`. Common options:
  - `position`: Position symbol (`:rt`, `:lt`, etc.) or grid position `[row, col]`
  - `label`, `vertical`, `margin`
  - Set to `false` to disable

## Returns
- For `FigureAxisPlot`: Returns the same `FigureAxisPlot`
- For other inputs: Returns `nothing`

## Examples

```julia
# Via figure keyword
f, ax, pl = scatter(rand(10), color=1:10, label="Points";
    figure=(; gui=true, legend=(position=:lt,)))

# Via Figure constructor
f = Figure(; gui=true, legend=(position=:rt,))
ax = Axis(f[1,1])
scatter!(ax, rand(10), label="Data")

# Via theme (GUI added automatically on display)
set_theme!(Figure=(; gui=true))
scatter(rand(10), label="Auto GUI")

# Theme with legend/colorbar options
set_theme!(Figure=(; legend=(position=:lt,), colorbar=(position=:rt,)))
```
"""
function add_gui!(faxpl::FigureAxisPlot)
    f, ax, plot = faxpl
    add_gui!(f, ax, plot)
    return faxpl
end

function add_gui!(fig::Figure)
    ax = current_axis(fig)
    plot = (isnothing(ax) || isempty(ax.scene.plots)) ? nothing : first(ax.scene.plots)
    add_gui!(fig, ax, plot)
    return fig
end

function add_gui!(fig::Figure, ax::Union{AbstractAxis, Nothing}, plot::Union{AbstractPlot, Nothing})
    gui_state = fig.gui_state

    # Add HoverMenu block if enabled and not already added
    if !isnothing(gui_state.hovermenu_options) && isnothing(gui_state.hovermenu)
        # Create HoverMenu block with user options (using _block directly to avoid splatting)
        opts = copy(gui_state.hovermenu_options)
        opts[:target_axis] = ax
        gui_state.hovermenu = _block(HoverMenu, fig[:, :], Any[], opts)
    end

    # Add legend if enabled, not already added, and we have a plot
    if !isnothing(gui_state.legend_options) && isnothing(gui_state.legend) && !isnothing(plot) && ax !== nothing
        gui_state.legend = create_gui_legend!(fig, ax, plot, gui_state.legend_options)
    end

    # Add colorbar if enabled, not already added, and we have a plot
    if !isnothing(gui_state.colorbar_options) && isnothing(gui_state.colorbar) && !isnothing(plot) && ax !== nothing
        gui_state.colorbar = create_gui_colorbar!(fig, ax, plot, gui_state.colorbar_options)
    end

    return nothing
end

# Convenience method for tuple input
function add_gui!(fig_ax_plot::Tuple{Figure, Any, AbstractPlot})
    f, ax, plot = fig_ax_plot
    add_gui!(f, ax, plot)
    return fig_ax_plot
end

"""
    remove_gui!(fig::Figure)

Remove all GUI elements from a figure.
"""
function remove_gui!(fig::Figure)
    gui_state = fig.gui_state

    # Delete HoverMenu block if it exists
    if !isnothing(gui_state.hovermenu)
        delete!(gui_state.hovermenu)
        gui_state.hovermenu = nothing
    end

    # Delete legend if it exists
    if !isnothing(gui_state.legend)
        delete!(gui_state.legend)
        gui_state.legend = nothing
    end

    # Delete colorbar if it exists
    if !isnothing(gui_state.colorbar)
        delete!(gui_state.colorbar)
        gui_state.colorbar = nothing
    end

    return nothing
end
