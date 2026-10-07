@testset "refresh_contentsize! is idempotent" begin
    f = Figure()
    sf = Subfigure(f.scene; bbox = Observable(Rect2f(0, 0, 300, 300)))
    Button(sf.layout[1, 1]; label = "x", width = 80, height = 20)
    Makie.update_state_before_display!(f)

    first = refresh_contentsize!(sf)
    @test refresh_contentsize!(sf) == first
    @test sf.contentsize[] == first
end

@testset "filtered nested cards stay inside the measured stack" begin
    f = Figure(size=(700,600))
    sf = Subfigure(f[1,1])
    root = Card(sf[1,1]; open=true)
    stack = GridLayout(root[1,1]; default_rowgap=0, valign=:top)
    cards = [Card(stack[i,1];open=true,spacing=2) for i in 1:20]
    for card in cards
        Button(card[1,1];label="last row",height=35)
    end
    for chosen in (last(cards),first(cards),last(cards))
        filter_cards!(c->c===chosen,stack,cards)
        Makie.update_state_before_display!(f)
        bb = stack.layoutobservables.computedbbox[]
        cb = chosen.layoutobservables.computedbbox[]
        @test cb.origin[2] >= bb.origin[2]-1
        @test cb.origin[2]+cb.widths[2] <= bb.origin[2]+bb.widths[2]+1
    end
end

@testset "Modal auto-sizes to content and honours min/max_size" begin
    f = Figure()
    m = Modal(f; min_size = (200, 60), max_size = (200, 200), title = "t")
    open!(m)

    add_rows!(n) = replace_content!(m) do sf
        for i in 1:n
            Button(sf.layout[i, 1]; label = "b$i", width = 100, height = 20)
        end
    end

    add_rows!(2)
    Makie.update_state_before_display!(f)
    small = m.subfigure.layoutobservables.computedbbox[].widths[2]

    add_rows!(5)
    Makie.update_state_before_display!(f)
    mid = m.subfigure.layoutobservables.computedbbox[].widths[2]
    @test mid > small

    # Back to the smaller list: no stale rows, so it shrinks back exactly.
    add_rows!(2)
    Makie.update_state_before_display!(f)
    @test m.subfigure.layoutobservables.computedbbox[].widths[2] ≈ small

    # Well past max_size: body is clamped and the content scrolls.
    add_rows!(40)
    Makie.update_state_before_display!(f)
    @test m.subfigure.layoutobservables.computedbbox[].widths[2] <= 200
end

@testset "replace_content! leaves no empty tracks behind" begin
    f = Figure()
    m = Modal(f; title = "t")
    open!(m)

    for n in (6, 2, 9, 1)
        replace_content!(m) do sf
            for i in 1:n
                Button(sf.layout[i, 1]; label = "b$i", width = 60, height = 18)
            end
        end
        Makie.update_state_before_display!(f)
        @test length(contents(m.layout)) == n
        @test size(m.layout) == (n, 1)
    end
end

@testset "replace_content! follows keys across positions" begin
    f = Figure()
    sf = Subfigure(f[1, 1])
    controls = Dict{Symbol, Any}()
    calls = Symbol[]
    function build(order)
        replace_content!(sf) do panel
            for (row, id) in enumerate(order)
                b = Button(panel.layout[row, 1]; key = (:button, id), label = string(id))
                controls[id] = b
                on(b.clicks; priority = 100) do _
                    push!(calls, id)
                end
            end
            offset = first(order) === :a ? 1 : first(order) === :b ? 2 : 3
            controls[:field] = Textbox(panel.layout[length(order) + offset, 2]; key = :field)
            controls[:slider] = Slider(panel.layout[length(order) + 4, offset]; key = :slider, range = 0:0.1:1)
        end
    end
    build([:a, :b, :c])
    old = copy(controls)
    Makie.focus!(old[:field])
    old[:field].editor.arg1 = "unfinished"
    set_close_to!(old[:slider], 0.7)
    for order in ([:c, :a, :b], [:b, :c, :a], [:a, :b, :c])
        build(order)
        @test all(controls[id] === old[id] for id in keys(old))
        @test old[:field].focused[]
        @test old[:field].editor.arg1[] == "unfinished"
        @test old[:slider].value[] ≈ 0.7
        for (row, id) in enumerate(order)
            @test only(contents(sf.layout[row, 1])) === old[id]
            empty!(calls)
            notify(old[id].clicks)
            @test calls == [id]
        end
    end
    build([:b, :c])
    @test !haskey(sf.buildkeys, old[:a])
    @test !haskey(sf.buildlisteners, old[:a])
    @test length(contents(sf.layout)) == 4
    @test_throws ArgumentError replace_content!(sf) do panel
        Button(panel.layout[1, 1]; key = :duplicate)
        Button(panel.layout[2, 1]; key = :duplicate)
    end
    @test !sf.layout.block_updates
    build([:a, :b, :c])
    @test length(contents(sf.layout)) == 5
end

@testset "unkeyed controls move and keyed type changes replace" begin
    f = Figure()
    sf = Subfigure(f[1, 1])
    button = Ref{Any}()
    for row in (1, 5, 2)
        before = isassigned(button) ? button[] : nothing
        replace_content!(sf) do panel
            button[] = Button(panel.layout[row, 2]; label = "move")
        end
        before === nothing || @test button[] === before
        @test length(contents(sf.layout)) == 1
    end
    replace_content!(sf) do panel
        button[] = Button(panel.layout[1, 1]; key = :changing, label = "button")
    end
    old = button[]
    replace_content!(sf) do panel
        button[] = Slider(panel.layout[2, 2]; key = :changing, range = 0:10)
    end
    @test button[] isa Slider
    @test button[] !== old
    @test !haskey(sf.buildkeys, old)
end

@testset "fixed-width typing does not relayout the form" begin
    f = Figure()
    tb = Textbox(f[1, 1]; width = 90)
    updates = Ref(0)
    listener = on(tb.layoutobservables.autosize) do _
        updates[] += 1
    end
    tb.editor.arg1 = "1"
    tb.editor.arg1 = "12345"
    tb.editor.arg1 = "12"
    @test updates[] == 0
    # Content-dependent dimensions must still update, including line count.
    tb.editor.arg1 = "12\n34"
    @test updates[] == 1
    tb.width = Auto()
    previous = tb.layoutobservables.autosize[][1]
    tb.editor.arg1 = "a much wider line"
    @test tb.layoutobservables.autosize[][1] > previous
    off(listener)
end

@testset "compact filters retain controls without accumulating empty rows" begin
    f = Figure()
    stack = GridLayout(f[1, 1]; default_rowgap=0)
    cards = [Card(stack[i, 1]; open=true) for i in 1:20]
    fields = [Textbox(c[1, 1]; stored_string="value $i") for (i,c) in enumerate(cards)]
    for chosen in (20, 1, 10, 20)
        filter_cards!(c -> c === cards[chosen], stack, cards; compact=true)
        @test size(stack)[1] == 2
        @test only(contents(stack[1, 1])) === cards[chosen]
        @test length(contents(stack)) == 20
        @test all(fields[i].stored_string[] == "value $i" for i in 1:20)
    end
    filter_cards!(_ -> true, stack, cards; compact=true)
    @test all(only(contents(stack[i, 1])) === cards[i] for i in 1:20)
    filter_cards!(_ -> false, stack, cards; compact=true)
    @test size(stack)[1] == 1
    foreach(delete!, cards)
    @test all(field.parent === nothing for field in fields)
end

@testset "text changes only report dimensions the layout uses" begin
    f = Figure(size=(600,400))
    status = Label(f[1,1], "1"; width=Relative(1), tellwidth=false)
    button = Button(f[2,1]; label="1", width=90)
    Makie.update_state_before_display!(f)
    updates = Ref(0)
    listener = on(button.layoutobservables.computedbbox) do _
        updates[] += 1
    end
    status.text = "111111111"
    @test updates[] == 0
    @test status.layoutobservables.computedbbox[].widths[1] == 90
    before = status.layoutobservables.autosize[][2]
    status.text = "11\n11"
    @test status.layoutobservables.autosize[][2] > before
    @test updates[] > 0
    status.text = "111111111"
    status.width = Auto()
    wide = status.layoutobservables.autosize[][1]
    status.text = "1"
    @test status.layoutobservables.autosize[][1] < wide
    off(listener)
    updates[] = 0
    listener = on(status.layoutobservables.computedbbox) do _
        updates[] += 1
    end
    button.label = "111111"
    @test updates[] == 0
    button.width = Auto()
    @test button.layoutobservables.autosize[][1] > 0
    off(listener)
end

@testset "forwarded containers update unchanged extents and restored geometry" begin
    f = Figure(size=(600,400))
    card = Card(f[1,1]; width=300, height=200, open=true)
    first = Button(card[1,1]; label="first", width=80, height=30)
    Makie.update_state_before_display!(f)
    second = Button(card[1,2]; label="second", width=80, height=30)
    @test second.layoutobservables.computedbbox[].origin[1] > first.layoutobservables.computedbbox[].origin[1]
    card.body[2,1] = first
    @test first.layoutobservables.computedbbox[].origin[2] < second.layoutobservables.computedbbox[].origin[2]
    card.visible = false
    card.width = 450
    card.visible = true
    @test card.layoutobservables.computedbbox[].widths[1] == 450
    @test first.blockscene.visible[] && second.blockscene.visible[]
    bb = card.layoutobservables.computedbbox[]
    @test all(b.layoutobservables.computedbbox[].origin in bb for b in (first,second))
    # Intrinsic changes must still reach ancestors when dimensions are automatic.
    card.height = Auto()
    before = card.layoutobservables.reporteddimensions[].inner[2]
    first.height = 90
    @test card.layoutobservables.reporteddimensions[].inner[2] > before
end
@testset "hidden containers retain their own visibility when restored" begin
    f = Figure(size=(400,400))
    sf = Subfigure(f[1,1]; visible=false)
    b = Button(sf[1,1]; label="hidden")
    @test !sf.scene.visible[]
    @test !Makie.scene_visible(b.blockscene)
    Makie.unhide!(sf)
    @test !sf.scene.visible[]
    sf.visible = true
    @test sf.scene.visible[]
    @test Makie.scene_visible(b.blockscene)
    sf.visible = false
    Makie.unhide!(sf)
    @test !sf.scene.visible[]
    @test !Makie.scene_visible(b.blockscene)
    card = Card(f[2,1]; title="hidden", visible=false)
    child = Button(card[1,1]; label="hidden card child")
    Makie.unhide!(card)
    @test !Makie.scene_visible(card.scene)
    @test !Makie.scene_visible(child.blockscene)
    # Plot visibility is separate from layout culling. Initially hidden labels
    # must still become visible when their own attribute changes later.
    label = Label(f[3,1], "toggle"; visible=false)
    Makie.unhide!(label)
    @test Makie.scene_visible(label.blockscene)
    @test !first(label.blockscene.plots).visible[]
    label.visible = true
    @test Makie.scene_visible(label.blockscene)
    @test first(label.blockscene.plots).visible[]
end
