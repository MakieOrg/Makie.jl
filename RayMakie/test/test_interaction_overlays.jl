# What an INTERACTION draws, and where.
#
# Every bug here produced a picture rather than an error, and each was invisible
# to a test that only asked "did the pixels change".
#
#   1. RayMakie ignored Makie's `space` attribute entirely. Every recipe read
#      `scene.camera.projectionview` — the DATA-space matrix — so a plot with
#      `space = :pixel` got a matrix that maps data units and landed outside
#      clip. `Makie.space_to_clip(cam, space)` is the accessor and was used
#      nowhere. That is the whole reason the rectangle-zoom rubber band drew
#      nothing at all.
#
#   2. Axis tick labels went stale on zoom, twice over. `rebake!` skipped the
#      argument bake when the source tuple was `===` to the last one, and
#      `resize!` on an `MtlVector` keeps the Julia object while reallocating the
#      buffer under it — same objects, different device address, so the draw read
#      the previous frame's glyphs. And the glyph atlas was cached on
#      `length(atlas.data)`, which is a FIXED-SIZE image: the length never
#      changes, so it uploaded once and every glyph rendered afterwards stayed on
#      the CPU. Both show only if the labels are checked for being RIGHT.
#
# The band is a RING — eight vertices, eight triangles, an outer quad covering
# the whole axis and an inner quad that is the hole. Its bounding box is
# therefore the outer rectangle whatever the drag did, and a test that compares
# bounding boxes reports a correct band as "covers everything" and a band frozen
# at full extent as the same thing. Both of those readings were made here. What
# separates them is the HOLE: inside the dragged rectangle nothing may change,
# and everywhere else in the axis something must.
using Test, Makie, RayMakie, Hikari, GeometryBasics, Colors
using Makie: Mouse, MouseButtonEvent, Rect2f, Point2f

"""Per-pixel absolute RGB difference between two frames."""
framediff(a, b) = map((x, y) -> abs(Float64(red(x)) - Float64(red(y))) +
                                abs(Float64(green(x)) - Float64(green(y))) +
                                abs(Float64(blue(x)) - Float64(blue(y))), a, b)

@testset "a space = :pixel plot lands in pixel coordinates" begin
    # No axis, no data space: `campixel!` makes clip and pixel coordinates the
    # same thing, so a rectangle at (40, 30) of 60x50 has exactly one right
    # answer and `space` is the only thing that can get it wrong.
    scene = Scene(size = (200, 150), camera = Makie.campixel!)
    mesh!(scene, Rect2f(40, 30, 60, 50); space = :pixel, color = :red, shading = Makie.NoShading)
    screen = RayMakie.Screen(scene; visible = false)
    img = Makie.colorbuffer(screen)
    mask = map(c -> red(c) > 0.5 && green(c) < 0.3 && blue(c) < 0.3, img)
    @test any(mask)
    rows = [r for r in axes(mask, 1) if any(@view mask[r, :])]
    cols = [c for c in axes(mask, 2) if any(@view mask[:, c])]
    H = size(img, 1)
    @test extrema(cols) == (41, 100)                 # x 40..100, 1-based
    @test extrema(rows) == (H - 79, H - 30)          # y 30..80, measured from the bottom
    close(screen)
end

@testset "the rectangle-zoom band is a ring with the hole at the dragged rect" begin
    fig = Figure(size = (600, 450))
    ax = Axis(fig[1, 1])
    lines!(ax, 1:10, [sin(i) for i in 1:10])
    screen = RayMakie.Screen(fig.scene; visible = false)
    Makie.colorbuffer(screen)          # lay the figure out before reading limits
    Makie.reset_limits!(ax)

    rz = ax.interactions[:rectanglezoom][2]
    rz.active[] = false
    before = copy(Makie.colorbuffer(screen))

    # A real drag, through the event system: `rectnode` is what the interaction
    # writes, so setting it by hand would skip the half of this that can break.
    vp = ax.scene.viewport[]
    ox, oy = minimum(vp)
    topoint(p) = Point2f(Makie.project(ax.scene, Point2f(p))) .+ Point2f(ox, oy)
    from, to = (3.0, -0.5), (7.0, 0.5)
    ev = Makie.events(fig.scene)
    ev.mouseposition[] = Tuple(topoint(from))
    ev.mousebutton[] = MouseButtonEvent(Mouse.left, Mouse.press)
    for t in (0.25, 0.5, 0.75, 1.0)
        ev.mouseposition[] = Tuple(topoint(from) .+ Float32(t) .* (topoint(to) .- topoint(from)))
    end
    @test rz.active[]
    during = copy(Makie.colorbuffer(screen))

    # Ground truth for where the hole belongs, from the same function the plot's
    # positions come from.
    verts = Makie._selection_vertices(ax.scene, ax.finallimits[], rz.rectnode[])
    H = size(during, 1)
    topix(x, y) = (H - round(Int, oy + y), round(Int, ox + x))
    r0, c0 = topix(verts[5][1], verts[7][2])
    r1, c1 = topix(verts[7][1], verts[5][2])

    d = framediff(before, during)
    # Inset by a few pixels so the band's own antialiased edge counts as neither.
    hole = d[(r0 + 4):(r1 - 4), (c0 + 4):(c1 - 4)]
    ring = copy(d[(H - (oy + widths(vp)[2]) + 4):(H - oy - 4), (ox + 4):(ox + widths(vp)[1] - 4)])
    rr0 = r0 - (H - (oy + widths(vp)[2]) + 4) + 1
    cc0 = c0 - (ox + 4) + 1
    ring[max(1, rr0 - 4):min(end, rr0 + (r1 - r0) + 4),
         max(1, cc0 - 4):min(end, cc0 + (c1 - c0) + 4)] .= -1.0
    ringvals = filter(>=(0.0), vec(ring))

    @test count(>(0.01), hole) == 0                        # the hole is untouched
    @test count(>(0.01), ringvals) == length(ringvals)     # and everything else is not
    @test !isempty(hole) && !isempty(ringvals)

    # Releasing zooms to exactly what was dragged, and takes the band away.
    ev.mousebutton[] = MouseButtonEvent(Mouse.left, Mouse.release)
    @test !rz.active[]
    lims = ax.finallimits[]
    @test all(isapprox.(Tuple(minimum(lims)), from; atol = 1e-4))
    @test all(isapprox.(Tuple(widths(lims)), to .- from; atol = 1e-4))
    close(screen)
end

@testset "axis tick labels are redrawn at the new ticks after a zoom" begin
    # The stale-glyph bugs: the labels have to match the ticks Makie computed
    # FOR THIS FRAME, not merely differ from the previous frame's. Checked by
    # matching ink columns in the label strip against the tick positions.
    fig = Figure(size = (600, 450))
    ax = Axis(fig[1, 1])
    lines!(ax, 1:10, [sin(i) for i in 1:10])
    screen = RayMakie.Screen(fig.scene; visible = false)
    Makie.colorbuffer(screen)
    Makie.reset_limits!(ax)

    """Columns holding dark ink in the strip just below the x spine."""
    function label_ink_columns(img, ax)
        vp = ax.scene.viewport[]
        ox, oy = minimum(vp)
        H = size(img, 1)
        # The strip between the spine and the bottom of the axis area, which is
        # where the tick labels are and the plot never is.
        r0 = H - oy + 6
        r1 = min(H, r0 + 18)
        strip = view(img, r0:r1, :)
        return [c for c in axes(strip, 2)
                if any(p -> red(p) < 0.5 && green(p) < 0.5 && blue(p) < 0.5, @view strip[:, c])]
    end

    """
    The pixel x of every x tick Makie placed, in image columns.

    `xaxis.tickpositions` is already in the block scene's absolute pixels — the
    same space the image is in — so this is what Makie decided, not a
    reprojection of it that could agree with a wrong label for the same reason.
    """
    tick_columns(ax) = [p[1] for p in getfield(ax.xaxis, :graph)[:tickpositions][]]

    for lims in (Rect2f(1, -1.2, 9, 2.4), Rect2f(3, -0.5, 4, 1.0), Rect2f(6.5, 0.0, 3, 0.9))
        Makie.limits!(ax, lims)
        img = Makie.colorbuffer(screen)
        ink = label_ink_columns(img, ax)
        ticks = tick_columns(ax)
        @test !isempty(ink)
        @test !isempty(ticks)
        # Every tick inside the axis has ink near it, and no ink sits far from
        # every tick. The second half is what catches labels left over from the
        # previous limits: those land where the OLD ticks were.
        vp = ax.scene.viewport[]
        inside = filter(t -> minimum(vp)[1] + 4 <= t <= minimum(vp)[1] + widths(vp)[1] - 4, ticks)
        @test all(t -> any(c -> abs(c - t) <= 22, ink), inside)
        @test all(c -> any(t -> abs(c - t) <= 22, ticks), ink)
    end
    close(screen)
end
