"""
Everything the card draws, in the order the layers stack: the card body's
rounded rect, the header bar on top of it, then the selection outline. Kept
together so `initialize_block!` reads as geometry-then-behaviour.
"""
struct CardVisuals
    card::Observable{Vector{Point2f}}
    header::Observable{Vector{Point2f}}
    outline::Observable{Vector{Point2f}}
end

"""
Recursively `hide!`/`unhide!` every block placed inside `gl`.

Blocks that CONTAIN blocks (`ParamForm`, `Container`, another `Card`) keep them
in a layout of their own, and every one of those has its own blockscene — so
hiding the container's scene leaves its children drawing. A hidden card whose
sliders kept painting over the card below it is what this recursion is for.

A nested `Card` is left to its own `hide!`, which knows whether that card is
folded or filtered out and must not be overridden from outside.
"""
function set_content_visible!(gl::GridLayout, visible::Bool)
    for gc in gl.content
        c = gc.content
        if c isa GridLayout
            set_content_visible!(c, visible)
        elseif c isa Card
            visible ? unhide!(c) : hide!(c)
        elseif c isa Block
            visible ? unhide!(c) : hide!(c)
            inner = getfield(c, :layout)
            inner isa GridLayout && set_content_visible!(inner, visible)
        end
    end
    return
end

"""
    Card(fig_or_scene; title = "Card", kwargs...)

A titled, foldable container: a header bar with a fold arrow, a title and an
accessory cell, over a body you fill like any layout — `Slider(card[1, 1];
...)`, `card[2, 1] = GridLayout()`, and so on. Put widgets in the header with
[`card_accessory`](@ref).

Two independent pieces of state, and the difference between them is the point
of this block:

  * `open` folds the BODY away. The header stays, so the card is still there to
    click on. This is disclosure.
  * `visible` takes the whole card out. Unlike `hide!`, which only stops a block
    from drawing and leaves its row sitting there at full height, a card with
    `visible = false` reports zero height to its parent layout, so the cards
    below it move up and close the hole. This is filtering.

The spacing BELOW a card is part of the card (`spacing`), not a gap in the
parent layout — so a hidden card takes its spacing with it and a filtered list
has no double gaps. Build the stack with `default_rowgap = 0` and let the cards
space themselves — `rowgap!(stack, 0)` only sets the gaps that exist when it is
called, so a card added later comes back with the default gap above it and one
hidden card's hole reopens.

```julia
fig = Figure()
stack = GridLayout(fig[1, 1]; valign = :top, default_rowgap = 0)
cards = [Card(stack[i, 1]; title = "Effect \$i") for i in 1:5]
Slider(cards[1][1, 1]; range = 0:0.01:1)
cards[3].visible = false     # rows 4 and 5 move up
cards[2].open = false        # header stays, body folds away
```

`headerclicks` counts presses on the header (after the fold arrow has had its
chance), which is what a list selects on.
"""
@Block Card begin
    # The card sizes to its content: header + (body when open) + spacing, all
    # forwarded to the parent layout through the block's own layout.
    @forwarded_layout
    scene::Scene                     # the whole card's scene — see `initialize_block!`
    bodyscene::Scene                 # nested under it, visible only while unfolded
    body::GridLayout                 # what `card[i, j]` indexes
    header::GridLayout               # the header's accessory cell
    headerclicks::Observable{Int}    # presses on the header bar, for selection
    userheight::Base.RefValue{Any}   # the `height` the user asked for, kept across a collapse
    @attributes begin
        "The card's title, drawn in the header bar."
        title = "Card"
        "Whether the body is unfolded. Folding leaves the header in place."
        open = true
        "Whether the card is shown AT ALL. `false` collapses it: no height, no spacing, no events."
        visible = true
        "Whether clicking the header folds and unfolds the card."
        foldable = true
        "Draw the card as selected — tinted header and an accent outline."
        selected = false
        "Background color of the card body."
        backgroundcolor = RGBf(0.16, 0.16, 0.18)
        "Background color of the header bar."
        headercolor = RGBf(0.22, 0.22, 0.25)
        "Background color of the header bar while selected."
        headercolor_selected = RGBf(0.26, 0.30, 0.40)
        "Color of the card's border."
        strokecolor = RGBf(0.30, 0.30, 0.34)
        "Width of the card's border."
        strokewidth = 1
        "Color of the outline drawn when `selected`."
        selectioncolor = RGBf(0.40, 0.62, 1.00)
        "Width of the selection outline."
        selectionwidth = 2
        "Corner radius of the card and its header."
        cornerradius = 6
        "Height of the header bar in pixels."
        headerheight = 26
        "Color of the title text."
        titlecolor = RGBf(0.92, 0.92, 0.94)
        "Font of the title text."
        titlefont = :bold
        "Size of the title text."
        titlesize = 13
        "Left inset of the fold arrow and title, in pixels."
        titleoffset = 9
        "Color of the fold arrow."
        arrowcolor = RGBf(0.72, 0.72, 0.76)
        "Padding inside the body, as a number or a (left, right, bottom, top) tuple."
        bodypadding = (10, 10, 10, 8)
        "Vertical space below the card. Part of the card, so hiding it removes the space too."
        spacing = 8
        "Controls if the parent layout can adjust to this element's width."
        tellwidth = false
        "Controls if the parent layout can adjust to this element's height."
        tellheight = true
        "The width setting of the card."
        width = nothing
        "The height setting of the card. `Auto()` sizes it to its content; a
        card that reported `nothing` here would tell its parent layout nothing
        at all, and the stack would have no height to give it."
        height = Auto()
    end
end

"""
    filter_cards!(predicate, stack::GridLayout, cards)

Set each card's `visible` to `predicate(card)`, relayouting `stack` ONCE
instead of once per card. This is how a filter box over a card list should
run: cards whose state does not change are not touched at all.

Measured on a stack of 100 cards, toggling 50: 147 ms one at a time, 14 ms
through here — and 433 ms to throw the cards away and build them again, which
is what makes rebuilding on every keystroke the wrong shape.

```julia
filter_cards!(stack, cards) do card
    occursin(query[], lowercase(card.title[]))
end
```
"""
function filter_cards!(predicate, stack::GridLayout, cards)
    GridLayoutBase.with_updates_suspended(stack) do
        for c in cards
            want = predicate(c)::Bool
            c.visible[] == want || (c.visible = want)
        end
    end
    return
end

"""
    card_accessory(card) -> GridPosition

Where a header widget goes: `Button(card_accessory(card); label = "×")`. The
accessory cell is right-aligned in the header bar and grows to the left, so a
row of them stays clear of the title.
"""
card_accessory(c::Card) = c.header[1, 1]

function initialize_block!(c::Card)
    blockscene = c.blockscene

    # `@forwarded_layout` had `_block` create this and connect its autosize to
    # the block's, so what the card reports upward is what its content measures.
    layout = c.layout
    c.body = GridLayout(layout[2, 1])
    c.headerclicks = Observable(0)
    c.userheight = Base.RefValue{Any}(c.height[])

    is_visible = lift(identity, blockscene, c.visible)

    # The header is a Fixed row so the bar has the same height whether or not
    # anything is in its accessory cell. The card's bottom margin is padding on
    # the card's own layout rather than a gap in the parent's — that is what
    # makes the spacing travel with the card when it is hidden.
    rowsize!(layout, 1, Fixed(c.headerheight[]))
    on(blockscene, c.headerheight) do h
        rowsize!(layout, 1, Fixed(h))
        return
    end
    on(blockscene, c.spacing; update = true) do s
        layout.alignmode[] = Outside(0.0f0, 0.0f0, Float32(s), 0.0f0)
        GridLayoutBase.update!(layout)
        return
    end
    rowgap!(layout, 0)
    colsize!(layout, 1, Relative(1.0))

    # THE BODY GETS ITS OWN SCENE, for the same reason `Subfigure` has one: the
    # blocks a caller puts in `card[i, j]` are separate blocks with separate
    # scenes, and a container that only hides ITS scene leaves them drawing.
    # Parenting them here makes the card's state win — `unhide!` returns early on
    # a block whose parent scene is invisible, so a `Subfigure` culling its
    # scrolled-out content cannot un-hide a card that is folded or filtered out.
    # (That bug looked like four cards' sliders painted on top of the one card
    #  the filter had left.)
    contentarea = lift(blockscene, c.layoutobservables.computedbbox, c.spacing) do bb, sp
        s = min(Float32(sp), bb.widths[2])
        return round_to_IRect2D(Rect2f(Point2f(bb.origin[1], bb.origin[2] + s),
                                       Vec2f(bb.widths[1], bb.widths[2] - s)))
    end
    c.scene = Scene(blockscene; camera = campixel!, viewport = contentarea,
                    visible = is_visible, clear = false)
    # A SECOND scene for the body, nested in the first: hiding the card hides
    # both, and FOLDING hides only this one. Without the nesting, folding had the
    # same defect hiding did — the body's widgets kept drawing over the card
    # below, because the cull walk found them under a visible parent.
    bodyarea = lift(blockscene, contentarea, c.headerheight) do ca, hh
        h = max(Float32(ca.widths[2]) - Float32(hh), 0.0f0)
        return round_to_IRect2D(Rect2f(Point2f(ca.origin), Vec2f(ca.widths[1], h)))
    end
    c.bodyscene = Scene(c.scene; camera = campixel!, viewport = bodyarea,
                        visible = lift(identity, blockscene, c.open), clear = false)
    c.body.parent = c.bodyscene

    # The header's own grid: [ arrow | title | accessory ]. The arrow and title
    # are drawn as text (they are decoration, and a Label here would fight the
    # header's fixed height), so the layout only has to hold the accessory cell
    # out of the title's way.
    headergl = GridLayout(layout[1, 1])
    Box(headergl[1, 1]; color = (:transparent, 0.0), strokewidth = 0, width = Auto(), height = 1, tellheight = false)
    # inset from the rounded corner, so an accessory button is not flush with it
    c.header = GridLayout(headergl[1, 2]; halign = :right, valign = :center,
                          alignmode = Outside(0.0f0, 6.0f0, 0.0f0, 0.0f0))
    c.header.parent = c.scene
    colsize!(headergl, 1, Auto(true, 1.0f0))
    colgap!(headergl, 0)

    # ---------------------------------------------------------------- geometry
    # The card's rect is its bbox minus the spacing row at the bottom: the
    # spacing is layout, not paint.
    cardrect = lift(blockscene, c.layoutobservables.computedbbox, c.spacing) do bb, sp
        s = min(Float32(sp), bb.widths[2])
        # y grows upward, so the spacing below the card is at the bottom of the
        # bbox and the paint starts above it.
        return Rect2f(Point2f(bb.origin[1], bb.origin[2] + s), Vec2f(bb.widths[1], bb.widths[2] - s))
    end
    headerrect = lift(blockscene, cardrect, c.headerheight) do r, hh
        h = min(Float32(hh), r.widths[2])
        return Rect2f(Point2f(r.origin[1], r.origin[2] + r.widths[2] - h), Vec2f(r.widths[1], h))
    end

    cardpoly = lift(blockscene, cardrect, c.cornerradius) do r, cr
        return roundedrectvertices(r, min(Float32(cr), min(r.widths...) / 2), 12)
    end
    # The header shares the card's top corners and is SQUARE at the bottom, so
    # it meets the body without a seam — which `roundedrectvertices` cannot do,
    # its corners being all or nothing.
    headerpoly = lift(blockscene, headerrect, c.cornerradius) do r, cr
        rr = min(Float32(cr), min(r.widths...) / 2)
        x0, y0 = Float32.(r.origin)
        x1, y1 = x0 + Float32(r.widths[1]), y0 + Float32(r.widths[2])
        pts = [Point2f(x0, y0)]
        for t in LinRange(Float32(pi), Float32(pi / 2), 12)     # top-left arc
            push!(pts, Point2f(x0 + rr + rr * cos(t), y1 - rr + rr * sin(t)))
        end
        for t in LinRange(Float32(pi / 2), 0.0f0, 12)           # top-right arc
            push!(pts, Point2f(x1 - rr + rr * cos(t), y1 - rr + rr * sin(t)))
        end
        push!(pts, Point2f(x1, y0))
        return pts
    end

    poly!(blockscene, cardpoly; color = c.backgroundcolor, strokecolor = c.strokecolor,
          strokewidth = c.strokewidth, visible = is_visible, inspectable = false)
    headerfill = lift(blockscene, c.selected, c.headercolor, c.headercolor_selected) do sel, plain, chosen
        return to_color(sel ? chosen : plain)
    end
    poly!(blockscene, headerpoly; color = headerfill, strokewidth = 0,
          visible = is_visible, inspectable = false)
    # The selection outline is drawn last so it sits over both fills.
    poly!(blockscene, cardpoly; color = (:transparent, 0.0), strokecolor = c.selectioncolor,
          strokewidth = lift((s, w) -> s ? Float32(w) : 0.0f0, blockscene, c.selected, c.selectionwidth),
          visible = is_visible, inspectable = false)

    arrowpos = lift(blockscene, headerrect, c.titleoffset) do r, off
        return Point2f(r.origin[1] + off, r.origin[2] + r.widths[2] / 2)
    end
    arrowtext = lift(o -> o ? "▾" : "▸", blockscene, c.open)
    arrowvis = lift(&, blockscene, is_visible, c.foldable)
    text!(blockscene, arrowpos; text = arrowtext, align = (:left, :center),
          color = c.arrowcolor, fontsize = c.titlesize, visible = arrowvis, inspectable = false)

    titlepos = lift(blockscene, headerrect, c.titleoffset, c.foldable) do r, off, fold
        return Point2f(r.origin[1] + off + (fold ? 15 : 0), r.origin[2] + r.widths[2] / 2)
    end
    text!(blockscene, titlepos; text = c.title, align = (:left, :center), color = c.titlecolor,
          font = c.titlefont, fontsize = c.titlesize, visible = is_visible, inspectable = false)

    # ---------------------------------------------------------------- folding
    on(blockscene, c.bodypadding; update = true) do pad
        sides = pad isa Number ? (pad, pad, pad, pad) : pad
        c.body.alignmode[] = Outside(to_rectsides(sides))
        GridLayoutBase.update!(c.body)
        return
    end

    function apply_open!(isopen::Bool)
        # A folded body is BOTH inert (its blocks stop drawing and stop taking
        # clicks) and zero-height, so the card shrinks to its header.
        set_content_visible!(c.body, isopen && c.visible[])
        c.body.height[] = isopen ? Auto(true, 1.0f0) : Fixed(0)
        return
    end
    on(blockscene, c.open) do isopen
        apply_open!(isopen)
        return
    end

    # ------------------------------------------------------------- collapsing
    # `visible = false` is not `hide!`: the card reports zero height, which is
    # what makes a filtered list close up instead of showing gaps. The user's
    # own `height` is remembered so restoring does not clobber it.
    function apply_visible!(vis::Bool)
        set_content_visible!(c.body, vis && c.open[])
        set_content_visible!(c.header, vis)
        if vis
            c.height = c.userheight[]
        else
            c.userheight[] = c.height[]
            c.height = 0
        end
        return
    end
    on(blockscene, c.visible) do vis
        apply_visible!(vis)
        return
    end

    # ------------------------------------------------------------ interaction
    on(blockscene, blockscene.events.mousebutton; priority = 55) do ev
        (ev.button === Mouse.left && ev.action === Mouse.press) || return Consume(false)
        c.visible[] || return Consume(false)
        receives_events(blockscene) || return Consume(false)
        pos = Point2f(blockscene.events.mouseposition[])
        pos in headerrect[] || return Consume(false)
        # The accessory cell belongs to whatever the user put there — a press
        # over it is that widget's, not the card's. An EMPTY layout reports the
        # default 0..100 box, which would swallow presses on the whole header.
        if !isempty(c.header.content)
            pos in c.header.layoutobservables.computedbbox[] && return Consume(false)
        end
        c.headerclicks[] = c.headerclicks[] + 1
        c.foldable[] && (c.open = !c.open[])
        return Consume(true)
    end

    apply_open!(c.open[])
    c.visible[] || apply_visible!(false)
    return
end

# `card[i, j]` is the BODY — the header has its own accessory cell, reached
# through `card_accessory`.
function Base.getindex(c::Card, i::Union{Integer, Colon, AbstractRange},
                       j::Union{Integer, Colon, AbstractRange}, side = GridLayoutBase.Inner())
    return c.body[i, j, side]
end
Base.firstindex(c::Card, dim) = firstindex(c.body, dim)
Base.lastindex(c::Card, dim) = lastindex(c.body, dim)

# `hide!` is the SCROLL-CULLING path (a Subfigure hides content that scrolled
# out of view) and it must not change the layout — a card that collapsed
# because it scrolled away would change the very content size that decides
# what is scrolled away. Collapsing is `visible`, and only `visible`.
function hide!(c::Card)
    c.blockscene.visible[] && (c.blockscene.visible[] = false)
    # `_block` hides every block once before `initialize_block!` runs, so the
    # sub-layouts are not there yet on that first call.
    isdefined(c, :body) || return
    set_content_visible!(c.body, false)
    set_content_visible!(c.header, false)
    return
end

function unhide!(c::Card)
    pv = parent(c.blockscene)
    pv === nothing || pv.visible[] || return
    c.blockscene.visible[] || (c.blockscene.visible[] = true)
    isdefined(c, :body) || return
    # Re-sync with the bound state rather than forcing `true`: a card that is
    # filtered out stays gone when it scrolls back into view.
    set_content_visible!(c.body, c.visible[] && c.open[])
    set_content_visible!(c.header, c.visible[])
    return
end

function update_state_before_display!(c::Card)
    return update_state_before_display!(c.layout)
end
