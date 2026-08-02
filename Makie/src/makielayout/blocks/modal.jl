function initialize_block!(m::Modal)
    blockscene = m.blockscene

    # Modal floats above the whole figure; it is constructed as `Modal(fig)`
    # without a grid position, so the blockscene's viewport is the full figure.
    is_open = lift(identity, blockscene, m.open)

    # Overlay scene: full-figure, translucent backdrop drawn as a plot, lifted
    # far above regular content. `captures_mouse = true` makes it the pointer
    # cover for the whole window while visible, so only the modal's own
    # subtree receives events (see `covers_pointer`).
    overlay = Scene(
        blockscene; clear = false,
        viewport = blockscene.viewport, visible = is_open
    )
    campixel!(overlay; absolute = true)
    translate!(overlay, 0, 0, 1000)
    overlay.captures_mouse = true
    m.overlay = overlay

    backdrop_rect = lift(vp -> Rect2f(vp), blockscene, blockscene.viewport)
    backdrop = poly!(overlay, backdrop_rect; color = m.backdrop_color, strokewidth = 0, inspectable = false)
    translate!(backdrop, 0, 0, -2)

    # Body sizing: content-driven (floored at min_size) unless width/height
    # are fixed numbers. The content autosize comes from the inner Subfigure.
    content_autosize = Observable(Vec2f(0, 0); ignore_equal_values = true)
    body_rect = lift(
        blockscene, blockscene.viewport, content_autosize,
        m.width, m.height, m.min_size, m.contentpadding, m.header_height
    ) do vp, asz, w, h, msz, pad, hh
        bw = w isa Number ? Float32(w) : max(Float32(msz[1]), asz[1] + 2pad)
        bh = h isa Number ? Float32(h) : max(Float32(msz[2]), asz[2] + hh + 2pad)
        bw = min(bw, Float32(widths(vp)[1]))
        bh = min(bh, Float32(widths(vp)[2]))
        x = vp.origin[1] + round((widths(vp)[1] - bw) / 2)
        y = vp.origin[2] + round((widths(vp)[2] - bh) / 2)
        return Rect2f(x, y, bw, bh)
    end

    body_poly = lift(blockscene, body_rect, m.cornerradius, m.cornersegments) do r, cr, cs
        return roundedrectvertices(r, min(Float32(cr), minimum(widths(r)) / 2), cs)
    end
    body = poly!(
        overlay, body_poly;
        color = m.color, strokecolor = m.strokecolor, strokewidth = m.strokewidth,
        inspectable = false
    )
    translate!(body, 0, 0, -1)

    # Header: title, separator line, close ×
    title_pos = lift(blockscene, body_rect, m.contentpadding, m.header_height) do r, pad, hh
        return Point2f(left(r) + pad, top(r) - hh / 2)
    end
    titleplot = text!(
        overlay, title_pos; text = m.title, font = m.titlefont,
        fontsize = m.titlesize, color = m.titlecolor,
        align = (:left, :center), inspectable = false
    )
    translate!(titleplot, 0, 0, 2)

    separator = lift(blockscene, body_rect, m.header_height) do r, hh
        y = top(r) - hh
        return Point2f[(left(r), y), (right(r), y)]
    end
    sep = lines!(overlay, separator; color = m.separator_color, linewidth = 1, inspectable = false)
    translate!(sep, 0, 0, 2)

    close_rect = lift(blockscene, body_rect, m.header_height) do r, hh
        inset = hh / 4
        sz = hh - 2inset
        return Rect2f(right(r) - hh + inset, top(r) - hh + inset, sz, sz)
    end
    close_segments = lift(blockscene, close_rect) do r
        pad = widths(r)[1] / 4
        x0, y0 = minimum(r) .+ pad
        x1, y1 = maximum(r) .- pad
        return Point2f[(x0, y0), (x1, y1), (x0, y1), (x1, y0)]
    end
    close_hovered = Observable(false; ignore_equal_values = true)
    close_color = lift(blockscene, close_hovered, m.closecolor, m.closecolor_hover) do h, c, ch
        return to_color(h ? ch : c)
    end
    closeplot = linesegments!(overlay, close_segments; color = close_color, linewidth = 1.5, inspectable = false)
    translate!(closeplot, 0, 0, 2)

    # Content: a Subfigure parented under the overlay, so it shares the
    # cover's subtree and keeps receiving events while the modal is open.
    # It also gives us scrolling for free when width/height are fixed.
    content_bbox = lift(blockscene, body_rect, m.contentpadding, m.header_height) do r, pad, hh
        return round_to_IRect2D(
            Rect2f(left(r) + pad, bottom(r) + pad, widths(r)[1] - 2pad, widths(r)[2] - hh - 2pad)
        )
    end
    sf = Subfigure(overlay; bbox = content_bbox, visible = is_open, contentpadding = 0)
    m.subfigure = sf
    # Forward `modal[row, col]` to the content layout.
    m.layout = sf.layout
    on(blockscene, sf.contentsize) do cs
        content_autosize[] = cs
        return
    end

    # Interaction: close on ×, optionally close on backdrop click. Registered
    # on the shared events; inert while closed.
    e = events(blockscene)
    on(blockscene, e.mouseposition; priority = 90) do mp
        is_open[] || return Consume(false)
        close_hovered[] = Point2f(mp) in close_rect[]
        return Consume(false)
    end
    on(blockscene, e.mousebutton; priority = 90) do ev
        (is_open[] && ev.button == Mouse.left && ev.action == Mouse.press) || return Consume(false)
        mp = Point2f(e.mouseposition[])
        if mp in close_rect[]
            close!(m)
            return Consume(true)
        elseif m.dismiss_on_backdrop_click[] && !(mp in body_rect[])
            close!(m)
            return Consume(true)
        end
        return Consume(false)
    end

    return
end

content_scene(m::Modal) = content_scene(m.subfigure)

"Show the modal."
open!(m::Modal) = (m.open = true; nothing)
"Hide the modal."
close!(m::Modal) = (m.open = false; nothing)
"Whether the modal is currently shown."
Base.isopen(m::Modal) = m.open[]

function update_state_before_display!(m::Modal)
    return update_state_before_display!(m.subfigure)
end
