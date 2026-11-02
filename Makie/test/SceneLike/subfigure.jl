@testset "refresh_contentsize! is idempotent" begin
    f = Figure()
    sf = Subfigure(f.scene; bbox = Observable(Rect2f(0, 0, 300, 300)))
    Button(sf.layout[1, 1]; label = "x", width = 80, height = 20)
    Makie.update_state_before_display!(f)

    first = refresh_contentsize!(sf)
    @test refresh_contentsize!(sf) == first
    @test sf.contentsize[] == first
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

@testset "replace_content! deletes blocks inside nested grids" begin
    f = Figure()
    m = Modal(f; title = "t")
    open!(m)

    # A nested GridLayout is ordinary content. `delete_layoutable!` only
    # detaches the grid, so without a recursive delete its blocks keep their
    # scenes and every rebuild stacks another copy on top of the last.
    build!(labels) = replace_content!(m) do sf
        Label(sf.layout[1, 1], "header")
        inner = GridLayout(sf.layout[2, 1])
        for (i, l) in enumerate(labels)
            Checkbox(inner[1, 2i - 1]; checked = false)
            Label(inner[1, 2i], l)
        end
    end

    # Each block owns a scene under the content scene; an orphaned block keeps
    # its scene and goes on rendering, so this counts what is actually drawn.
    nblocks() = length(Makie.content_scene(m).children)

    build!(["a", "b"])
    Makie.update_state_before_display!(f)
    first_count = nblocks()
    @test first_count == 5          # header + 2 * (checkbox + label)

    build!(["a", "b"])
    Makie.update_state_before_display!(f)
    @test nblocks() == first_count  # rebuilt, not accumulated

    build!(["x"])
    Makie.update_state_before_display!(f)
    @test nblocks() == 3
end
