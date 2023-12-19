using ImageClipboard

include("file-dialogue.jl")

function set_vis!(scene::Scene, v::Bool)
    return scene.visible[] = v
end

function set_vis!(block::Makie.Block, v::Bool)
    set_vis!(block.blockscene, v)
    return foreach(s -> set_vis!(s, v), block.blockscene.children)
end

function hoverbar(f, ax)
    gl = GridLayout(f[:, :]; tellwidth=false, tellheight=false, halign=:center, valign=:top)
    visible = Observable(false)
    box = gl[1, 1:3] = Box(f; height=45, width=200, color=(:white, 0.7), cornerradius=5)
    bstyle = (buttoncolor="gray", labelcolor=:white, font=:bold, fontsize=13)
    bsave = gl[1, 1] = Button(f; label="save", bstyle...)
    bcopy = gl[1, 2] = Button(f; label="copy", bstyle...)
    breset = gl[1, 3] = Button(f; label="↻", width=50, bstyle...)
    on(f.scene, visible; update=true) do v
        set_vis!(box, v)
        set_vis!(bsave, v)
        set_vis!(bcopy, v)
        return set_vis!(breset, v)
    end
    on(f.scene, breset.clicks) do _
        visible[] = false
        return reset_limits!(ax)
    end
    on(f.scene, bsave.clicks) do _
        visible[] = false
        file = save_file_dialogue()
        if !isnothing(file)
            save(file, f; update=false)
        end
    end
    on(f.scene, bcopy.clicks) do _
        visible[] = false
        img = colorbuffer(f; update=false)
        return ImageClipboard.clipboard_img(img)
    end
    on(f.scene, f.scene.events.mouseposition) do mp
        vp = f.scene.viewport[]
        rect = Rect2f(0, widths(vp)[2] - 70, widths(vp)[1], 70)
        if mp in rect
            visible[] = true
        else
            visible[] = false
        end
    end
    return
end

"""
    GUI(faxpl::Makie.FigureAxisPlot; legend=(;), colorbar=(;))

Automatically creates a legend and colorbar for the return value of `plot`.
Also adds a small UI to save/reset/copy the plot.
# Example

```julia
f, ax, pl = GUI(series(rand(7, 20)); legend=(position=:lt, title="legend"))
```
"""
function GUI(faxpl::Makie.FigureAxisPlot; legend=(;), colorbar=(;))
    f, ax, plot = faxpl
    hoverbar(f, ax)
    if legend isa NamedTuple
        plots, labels = Makie.get_labeled_plots(ax; unique=get(legend, :unique, false),
                                                merge=get(legend, :merge, false))
        if !isempty(plots)
            title = get(legend, :title, nothing)
            bbox = ax.scene.viewport
            margin = get(legend, :margin, (6, 6, 6, 6))
            position = get(legend, :position, :rt)
            pos_kw = Makie.legend_position_to_aligns(position)
            Legend(ax.parent, plots, labels, title; margin=margin, bbox=bbox, legend..., pos_kw...)
        end
    elseif !(legend isa Bool && legend == false)
        error("legend must be a NamedTuple with attributes passed to `axislegend` or false to disable automatic legend creation")
    end

    if colorbar isa NamedTuple
        try
            cmap = Makie.extract_colormap_recursive(plot)
            if !isnothing(cmap)
                Colorbar(f[1, 2]; colormap=cmap, colorbar...)
            end
        catch e

        end
    elseif !(colorbar isa Bool && colorbar == false)
        error("legend must be a NamedTuple with attributes passed to `axislegend` or false to disable automatic legend creation")
    end
    return faxpl
end
