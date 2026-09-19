# Which space a number is in, for everything that lands in the output buffer.
#
# Two bugs, the same shape: a value measured in one frame of reference used as if
# it were in another. Both are invisible in the case the whole suite covers, and
# both showed up in one screenshot of `surface(rand(20, 20))`.
#
# ── units vs pixels ──────────────────────────────────────────────────────────
#
# A drawable is `px_per_unit` times bigger than the figure is in units, and
# everything that sizes a render target or indexes the output buffer has to know.
#
# `Makie.viewport(scene)` is in scene UNITS. Three consumers read it, and only
# one of them converted:
#
#   * `overlay_rendering.jl` scaled its viewport rectangles by `px_per_unit` —
#     so axis decorations were drawn at the right size.
#   * `compute_scene_resolution` sized a ray-traced sub-scene's FILM straight
#     from the viewport, and clipped it against a root size given in PIXELS.
#   * `composite_scene!` placed that film in the output buffer from the
#     viewport's origin, also straight.
#
# So on a Retina window `surface(rand(20, 20))` put a 568x418 traced image into a
# 1200x900 drawable at 1:1 — a quarter of the area, in the bottom-left corner —
# with the axis decorations drawn full size around it. `px_per_unit` is 1 for
# every offscreen render, which is why the whole suite passed.
#
# No window here: `px_per_unit` is a field and `resize!` is the entry point, so
# the HiDPI path is reachable on any machine, including one whose GLFW reports no
# monitor at all. `scene_viewport_px` is the single conversion both consumers go
# through now, so the film and its placement agree by construction.
# ── whose height is the y-flip against ──────────────────────────────────────
#
# `Makie.viewport(scene)` gives an origin measured in the ROOT, because a scene's
# viewport is placed in the figure and not in itself. `collect_overlay_robjs`
# flipped it with `size(state.makie_scene)`, which IS the root for an
# overlay-only state — every 2D figure, hence a green suite — and is the
# SUB-SCENE for a traced one. An `LScene` 368 units tall in a 400-unit figure was
# flipped against 368, so every decoration landed 32 units too high: the axis
# box, its ticks and its labels floated above the surface they belong to while
# the traced image itself was placed correctly. Asserted below by projecting
# known 3D points with Makie and checking the overlay marker actually lands
# there.
using Test, Makie, RayMakie, Hikari, GeometryBasics, Colors
using Makie: Point3f

"""Saturation, which picks the coloured plot out of a greyscale figure."""
sat(c) = maximum((red(c), green(c), blue(c))) - minimum((red(c), green(c), blue(c)))

"""Where the coloured content sits, as a fraction of the frame, and how much."""
function content_box(img; thresh = 0.15)
    m = map(c -> sat(c) > thresh, img)
    H, W = size(img)
    rs = [r for r in axes(m, 1) if any(@view m[r, :])]
    cs = [c for c in axes(m, 2) if any(@view m[:, c])]
    isempty(rs) && return nothing
    r0, r1 = extrema(rs)
    c0, c1 = extrema(cs)
    return (r0 / H, r1 / H, c0 / W, c1 / W, count(m) / length(m))
end

"""The same figure at 1x and at 2x, as normalised content boxes."""
function at_both_scales(buildfig, w, h)
    fig = buildfig()
    screen = RayMakie.Screen(fig.scene; visible = false)
    one = content_box(copy(Makie.colorbuffer(screen)))
    screen.px_per_unit = 2.0f0
    resize!(screen, 2w, 2h)
    two = content_box(copy(Makie.colorbuffer(screen)))
    return one, two, screen
end

@testset "a traced sub-scene's film is sized in drawable pixels" begin
    w, h = 300, 240
    one, two, screen = at_both_scales(w, h) do
        f = Figure(size = (w, h))
        ax = Axis3(f[1, 1])
        surface!(ax, [Float32(sin(i / 3) * cos(j / 3)) for i in 1:12, j in 1:12])
        f
    end

    @test size(screen.output_buffer) == (2h, 2w)

    # The film of the RAY-TRACED state, which is the one that was wrong. Its
    # viewport in units times two, and not the viewport: at 1x this film was
    # 208x268 and it has to be 416x536 here.
    traced = only(filter(s -> !s.overlay_only, screen.scene_states))
    vp = Makie.viewport(traced.makie_scene)[]
    fh, fw = size(traced.film.framebuffer)
    @test fw ≈ 2 * Makie.widths(vp)[1] rtol = 0.02
    @test fh ≈ 2 * Makie.widths(vp)[2] rtol = 0.02

    # …and it lands in the same place. A film sized right but placed from a
    # viewport in units would still sit low and left of where it belongs.
    @test one !== nothing && two !== nothing
    for i in 1:4
        @test one[i] ≈ two[i] atol = 0.02
    end
    @test one[5] ≈ two[5] rtol = 0.1
    close(screen)
end

@testset "an overlay-only figure draws the same picture at 2x" begin
    # The path that already converted. Here so that the conversion cannot be
    # removed from one consumer and left in the other.
    w, h = 300, 240
    one, two, screen = at_both_scales(w, h) do
        f = Figure(size = (w, h))
        ax = Axis(f[1, 1])
        lines!(ax, 1:10, [sin(i) for i in 1:10]; color = :red)
        f
    end
    @test size(screen.output_buffer) == (2h, 2w)
    @test one !== nothing && two !== nothing
    for i in 1:4
        @test one[i] ≈ two[i] atol = 0.02
    end
    close(screen)
end


"""Centres of the connected clusters of `mask`, as (col, row), left to right."""
function dot_centres(mask; gap = 12)
    clusters = Vector{Vector{CartesianIndex{2}}}()
    for i in findall(mask)
        placed = false
        for c in clusters
            if any(j -> abs(j[1] - i[1]) <= gap && abs(j[2] - i[2]) <= gap, c)
                push!(c, i); placed = true; break
            end
        end
        placed || push!(clusters, [i])
    end
    return [(sum(x -> x[2], c) / length(c), sum(x -> x[1], c) / length(c))
            for c in clusters]
end

@testset "a 3D scene's overlays land where Makie projects them" begin
    zs = [Float32(abs(sin(i * 0.7) * cos(j * 0.9))) for i in 1:20, j in 1:20]
    fig = Figure(size = (500, 400))
    ls = LScene(fig[1, 1])
    surface!(ls, zs)

    # The four corners of the surface's own data box, as OVERLAY markers. They
    # have exactly one right place: on the corners of the traced surface.
    corners = [Point3f(1, 1, zs[1, 1]), Point3f(20, 1, zs[20, 1]),
               Point3f(1, 20, zs[1, 20]), Point3f(20, 20, zs[20, 20])]
    scatter!(ls, corners; color = :red, markersize = 14, overdraw = true)
    img = Makie.colorbuffer(fig; backend = RayMakie)

    H = size(img, 1)
    ox, oy = minimum(ls.scene.viewport[])
    want = [let q = Makie.project(ls.scene, p)
                (ox + q[1], H - (oy + q[2]))
            end for p in corners]
    got = dot_centres(map(c -> red(c) > 0.7 && green(c) < 0.35 && blue(c) < 0.35, img))
    @test length(got) == 4

    # Matched by PROXIMITY, not by sorting: two of these corners project to the
    # same column, so any ordering on (col, row) can pair them up crosswise on a
    # half-pixel difference and report a 165 px error for a correct picture.
    matched = Int[]
    for w in want
        d, i = findmin(g -> hypot(g[1] - w[1], g[2] - w[2]), got)
        # Within a marker's own antialiased centroid. The bug put these 32 px out.
        @test d < 2
        push!(matched, i)
    end
    @test length(unique(matched)) == 4     # a bijection, not four hits on one dot
end
