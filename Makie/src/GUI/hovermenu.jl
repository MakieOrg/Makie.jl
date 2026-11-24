# HoverMenu block type is defined in makielayout/types.jl

function free(g::HoverMenu)
    !isnothing(g.box) && delete!(g.box)
    !isnothing(g.save_button) && delete!(g.save_button)
    !isnothing(g.copy_button) && delete!(g.copy_button)
    !isnothing(g.reset_button) && delete!(g.reset_button)
    return
end

function initialize_block!(g::HoverMenu)
    fig = g.parent
    if !(fig isa Figure)
        # parent can be a Scene if HoverMenu(scene, ...) is used to create this,
        # if HoverMenu is created in a Container-like Block or if it is created
        # within a Block recipe.
        error("HoverMenu block must be a child of a Figure.")
    end

    # Background box spanning the three buttons. `g[1, 1:3]` indexes the
    # block's forwarded layout directly.
    g.box = Box(
        g[1, 1:3];
        height = g.height,
        width = g.width,
        color = g.bar_color,
        cornerradius = g.corner_radius,
        strokewidth = 1,
        strokecolor = g.bar_strokecolor
    )

    # Button styling from block attributes (themed like every other Button,
    # so the bar is consistent with the rest of the widgets by default).
    bstyle = (
        buttoncolor = g.button_color,
        buttoncolor_hover = g.button_color_hover,
        buttoncolor_active = g.button_color_active,
        labelcolor = g.label_color,
        labelcolor_hover = g.label_color,
        labelcolor_active = g.label_color_active,
        font = g.font,
        fontsize = g.fontsize,
        cornerradius = 4,
    )

    g.save_button = Button(g[1, 1]; label = "Save", width = 60, bstyle...)
    g.copy_button = Button(g[1, 2]; label = "Copy", width = 60, bstyle...)
    g.reset_button = Button(g[1, 3]; label = "Reset", width = 60, bstyle...)

    colgap!(g.layout, 8)

    # Reset button
    on(g.blockscene, g.reset_button.clicks) do _
        g.blockscene.visible[] = false
        ax = g.target_axis[]
        if !isnothing(ax)
            reset_limits!(ax)
        end
    end

    # Save button
    on(g.blockscene, g.save_button.clicks) do _
        g.blockscene.visible[] = false
        if !isnothing(fig)
            file = save_file_dialogue()
            if !isnothing(file)
                save(file, fig; update = false)
            end
        end
    end

    # Copy button
    on(g.blockscene, g.copy_button.clicks) do _
        g.blockscene.visible[] = false
        if !isnothing(fig)
            img = colorbuffer(fig; update = false)
            ImageClipboard.clipboard_img(img)
        end
    end

    # Mouse hover detection - show bar when mouse is near top
    if !isnothing(fig)
        on(g.blockscene, fig.scene.events.mouseposition) do mp
            vp = fig.scene.viewport[]
            hover_height = 60
            rect = Rect2f(0, widths(vp)[2] - hover_height, widths(vp)[1], hover_height)
            g.blockscene.visible[] = mp in rect
        end
    end

    return
end
