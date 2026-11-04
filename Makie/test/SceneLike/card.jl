using Makie: Card, card_accessory, filter_cards!
const GLB = Makie.GridLayoutBase

"Stack height as the parent layout sees it — the number a scroll panel is sized from."
stackheight(gl) = GLB.determinedirsize(gl, GLB.Row())

"A stack of `n` cards, each with a 30px body, spaced only by the cards themselves."
function cardstack(n; kwargs...)
    fig = Figure(size = (400, 900))
    # `default_rowgap`, not `rowgap!` afterwards: the latter only sets the gaps
    # that exist at the time, so a card added later would come back with the
    # default 18px gap above it. (`rowgap` is not a kwarg here — it lands in
    # `kwargs...` and does nothing at all.)
    stack = GridLayout(fig[1, 1]; valign = :top, default_rowgap = 0)
    cards = [Card(stack[i, 1]; title = "Card $i", kwargs...) for i in 1:n]
    for (i, c) in enumerate(cards)
        Label(c[1, 1], "body $i"; tellwidth = false, height = 30)
    end
    Makie.update_state_before_display!(fig)
    return fig, stack, cards
end

# 26 header + 30 body + 18 body padding (8 top, 10 bottom) + 8 spacing
const CARDHEIGHT = 82
const FOLDEDHEIGHT = 26 + 8

@testset "Card" begin
    @testset "sizes to its content" begin
        fig, stack, cards = cardstack(6)
        @test stackheight(stack) == 6 * CARDHEIGHT
        @test GLB.determinedirsize(cards[1].layout, GLB.Row()) == CARDHEIGHT
    end

    @testset "hiding COLLAPSES, and restores" begin
        fig, stack, cards = cardstack(6)
        for i in (2, 4, 6)
            cards[i].visible = false
        end
        Makie.update_state_before_display!(fig)
        # The whole point: no holes where the hidden cards were, and no leftover
        # gaps either — the spacing belongs to the card, not to the stack.
        @test stackheight(stack) == 3 * CARDHEIGHT
        for i in (2, 4, 6)
            cards[i].visible = true
        end
        Makie.update_state_before_display!(fig)
        @test stackheight(stack) == 6 * CARDHEIGHT
    end

    @testset "folding keeps the header" begin
        fig, stack, cards = cardstack(6)
        cards[1].open = false
        Makie.update_state_before_display!(fig)
        @test stackheight(stack) == 5 * CARDHEIGHT + FOLDEDHEIGHT
        cards[1].open = true
        Makie.update_state_before_display!(fig)
        @test stackheight(stack) == 6 * CARDHEIGHT
    end

    @testset "a hidden card's content is inert" begin
        fig, stack, cards = cardstack(3)
        label = contents(cards[2][1, 1])[1]
        @test label.blockscene.visible[]
        cards[2].visible = false
        @test !label.blockscene.visible[]
        cards[2].visible = true
        @test label.blockscene.visible[]
        # Folding hides the body too, without collapsing the card away.
        cards[2].open = false
        @test !label.blockscene.visible[]
    end

    @testset "hide! does NOT collapse" begin
        fig, stack, cards = cardstack(3)
        h = stackheight(stack)
        # `hide!` is the scroll-culling path: a card that collapsed because it
        # scrolled out of view would change the content size that decides what
        # is out of view.
        Makie.hide!(cards[2])
        Makie.update_state_before_display!(fig)
        @test stackheight(stack) == h
        Makie.unhide!(cards[2])
        @test stackheight(stack) == h
    end

    @testset "unhide! re-syncs with visible, it does not force" begin
        fig, stack, cards = cardstack(3)
        cards[2].visible = false
        label = contents(cards[2][1, 1])[1]
        Makie.unhide!(cards[2])            # e.g. scrolled back into view
        @test !label.blockscene.visible[]  # still filtered out
        @test stackheight(stack) == 2 * CARDHEIGHT
    end

    @testset "filter_cards! batches" begin
        fig, stack, cards = cardstack(8)
        filter_cards!(stack, cards) do c
            iseven(parse(Int, split(c.title[])[2]))
        end
        Makie.update_state_before_display!(fig)
        @test stackheight(stack) == 4 * CARDHEIGHT
        @test [c.visible[] for c in cards] == [false, true, false, true, false, true, false, true]
        filter_cards!(_ -> true, stack, cards)
        Makie.update_state_before_display!(fig)
        @test stackheight(stack) == 8 * CARDHEIGHT
    end

    @testset "header click folds; the accessory cell is not the card's" begin
        fig, stack, cards = cardstack(2)
        c = cards[1]
        Button(card_accessory(c); label = "×", width = 20, height = 18)
        Makie.update_state_before_display!(fig)
        @test c.open[]
        # A press on the header bar, away from the accessory. The BLOCK's
        # computedbbox is the laid-out one — `init_layout!` disconnects the
        # inner layout's, so reading that gives a stale default box.
        head = c.layoutobservables.computedbbox[]
        pos = Point2f(head.origin[1] + 30, head.origin[2] + head.widths[2] - 13)
        events = c.blockscene.events
        events.mouseposition[] = Tuple(pos)
        events.mousebutton[] = Makie.MouseButtonEvent(Mouse.left, Mouse.press)
        @test !c.open[]
        @test c.headerclicks[] == 1
    end

    @testset "a card that starts hidden takes no space" begin
        fig, stack, cards = cardstack(3)
        c = Card(stack[4, 1]; title = "Hidden", visible = false)
        Label(c[1, 1], "body"; tellwidth = false, height = 30)
        Makie.update_state_before_display!(fig)
        @test stackheight(stack) == 3 * CARDHEIGHT
    end
end

@testset "Card scenes" begin
    # The card owns a scene for itself and a nested one for its body. Both matter:
    # a container that only hides its OWN scene leaves the blocks a caller placed
    # in it drawing, because those are separate blocks with separate scenes — and
    # a Subfigure culling its scrolled-out content will happily `unhide!` them
    # again. Parenting makes the card's state win, because `unhide!` returns early
    # on a block whose parent scene is invisible.
    fig, stack, cards = cardstack(3)
    c = cards[2]
    label = contents(c[1, 1])[1]
    @test parent(label.blockscene) === c.bodyscene
    @test parent(c.bodyscene) === c.scene

    b = Button(card_accessory(c); label = "×", width = 20, height = 18)
    @test parent(b.blockscene) === c.scene   # the header lives in the card's scene…
    c.open = false
    @test !c.bodyscene.visible[]             # …so folding does not take it with it
    @test c.scene.visible[]
    c.open = true
    c.visible = false
    @test !c.scene.visible[]                 # hiding takes everything
end
