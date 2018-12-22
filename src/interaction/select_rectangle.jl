using Makie, AbstractPlotting

using AbstractPlotting: absrect, is_mouseinside
scene = scatter(rand(10), rand(10))


function select_rectangle(scene)
    key = Mouse.left
    waspressed = Node(false)
    rect = Node(FRect())

    # Create an initially hidden rectangle
    rect_vis = lines!(
        scene,
        rect,
        linestyle = :dot,
        linewidth = 0.1,
        color = (:black, 0.4),
        visible = false,
        raw = true
    ).plots[end] # Why do I have to do .plots[end] ???

    selected_rect = on(events(scene).mousedrag) do drag

        if ispressed(scene, key) && is_mouseinside(scene)
            mp = mouseposition(scene)
            if drag == Mouse.down
                waspressed[] = true
                rect_vis[:visible] = true # start displaying
                rect[] = FRect(mp, 0.0, 0.0)

                # What does this line do???
                rect_vis[1] = rect[]

            elseif drag == Mouse.pressed
                mini = minimum(rect[])
                rect[] = FRect(mini, mp - mini)

                # What does this line do???
                rect_vis[1] = rect[]
            end

        else
            if drag == Mouse.up && waspressed[] # User has selected the rectangle
                waspressed[] = false
                r = absrect(rect[])
                w, h = widths(r)

                if w > 0.0 && h > 0.0 # Ensure that the rectangle has non0 size.
                    rect[] = r
                end
            end
            # always hide if not the right key is pressed
            rect_vis[:visible] = false # make the plotted rectangle invisible
        end

        return rect
    end
    return selected_rect
end

rect = select_rectangle(scene)

println("rect = $(rect[].origin) + $(rect[].widths)")
