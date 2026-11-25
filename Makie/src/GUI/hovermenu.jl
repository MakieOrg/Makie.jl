function initialize_block!(g::HoverMenu)
    fig = g.parent
    if !(fig isa Figure)
        # parent can be a Scene if HoverMenu(scene, ...) is used to create this,
        # if HoverMenu is created in a Container-like Block or if it is created
        # within a Block recipe.
        error("HoverMenu block must be a child of a Figure.")
    end

    init_layout!(g)
    Box(g[1, 1:3]; g.box..., height = g.height, width = g.width)
    save_button = Button(g[1, 1]; g.button..., label = "Save", width = 60)
    copy_button = Button(g[1, 2]; g.button..., label = "Copy", width = 60)
    reset_button = Button(g[1, 3]; g.button..., label = "Reset", width = 60)

    colgap!(g.layout, 8)

    # Reset button
    on(g.blockscene, reset_button.clicks) do _
        g.blockscene.visible[] = false
        ax = g.target_axis[]
        if !isnothing(ax)
            reset_limits!(ax)
        end
    end

    # Save button
    on(g.blockscene, save_button.clicks) do _
        g.blockscene.visible[] = false
        file = save_file_dialogue()
        isnothing(file) || save(file, fig; update = false)
    end

    on(g.blockscene, copy_button.clicks) do _
        g.blockscene.visible[] = false
        ImageClipboard.clipboard_img(colorbuffer(fig; update = false))
    end

    on(g.blockscene, fig.scene.events.mouseposition) do mp
        vp = fig.scene.viewport[]
        hover_height = 60
        rect = Rect2f(0, widths(vp)[2] - hover_height, widths(vp)[1], hover_height)
        g.blockscene.visible[] = mp in rect
    end

    return
end

free(g::HoverMenu) = clear!(g.layout)
