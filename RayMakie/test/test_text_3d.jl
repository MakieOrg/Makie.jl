# Text whose glyph size lives in DATA space, which is what a 3D axis's labels are.
#
# Makie's text carries two spaces: `space`, where the anchor lives, and
# `markerspace`, where the glyph quad's size lives. The sprite shader builds the
# quad with `projection` for a billboard and with `projection * view` otherwise,
# because a camera-facing quad's offsets are in VIEW space while an oriented
# one's are in the marker's own space.
#
# RayMakie hardcoded `billboard = true` for every text plot. That is right for
# exactly the case the whole suite covered — a 2D axis's tick labels, where
# `markerspace` is `:pixel`, the rotation is the identity, and pixel space has an
# identity `view` so both branches agree — and wrong for `LScene`'s `axis3d!`,
# whose labels are per-character rotations onto the axis planes with
# `markerspace = :data`. Dropping `view` there built every glyph quad in the
# wrong basis and smeared it into a band across the whole figure: `surface(rand(20, 20))`
# came out with three grey stripes over the plot. It is derived from the rotation
# now, the way GLMakie's default is.
#
# Measured as the DIFFERENCE the text plot makes to the frame, because the thing
# under test is how much of the figure the glyphs cover: 0.2 % when they are
# glyphs, 39 % when they are bands. Three orders of magnitude, so the threshold
# needs no tuning.
using Test, Makie, RayMakie, Hikari, GeometryBasics, Colors
using Makie: Point3f, Vec3f

"""The fraction of the frame that `plot` changes, by hiding it and rendering twice."""
function ink_fraction(fig, plot)
    plot.visible[] = false
    without = copy(Makie.colorbuffer(fig; backend = RayMakie))
    plot.visible[] = true
    with = copy(Makie.colorbuffer(fig; backend = RayMakie))
    d = map(without, with) do a, b
        abs(Float64(red(a)) - Float64(red(b))) +
        abs(Float64(green(a)) - Float64(green(b))) +
        abs(Float64(blue(a)) - Float64(blue(b)))
    end
    return count(>(0.02), d) / length(d)
end

@testset "a 3D axis's labels are glyphs, not bands" begin
    zs = [Float32(abs(sin(i) * cos(j))) for i in 1:6, j in 1:6]
    fig = Figure(size = (200, 150))
    ls = LScene(fig[1, 1])
    surface!(ls, zs)
    Makie.colorbuffer(fig; backend = RayMakie)   # resolve, so the axis3d exists

    # `LScene` adds `axis3d!`, whose first child is the label text and whose
    # second is the frame/grid/ticks.
    axis3d = ls.scene.plots[1]
    labels = axis3d.plots[1]
    @test Makie.plotkey(axis3d) === :axis3d
    @test Makie.plotkey(labels) === :text

    # The case that broke: a per-character rotation in data markerspace.
    @test to_value(labels[:markerspace]) === :data
    @test to_value(labels[:text_rotation]) isa AbstractVector

    # …so it must NOT be billboarded.
    @test to_value(labels[:billboard]) === false

    # And the glyphs cover a sliver of the figure rather than banding it.
    # 0.16 % here against 38.65 % with the bug.
    @test ink_fraction(fig, labels) < 0.02
end

@testset "billboard follows the rotation" begin
    @test RayMakie.identity_rotation(Makie.Quaternionf(0, 0, 0, 1))
    @test !RayMakie.identity_rotation(Makie.qrotation(Vec3f(1, 0, 0), 0.6f0))
    # A VECTOR of rotations is never the identity, even when every entry is:
    # a plot that gives one rotation per character is asking for oriented
    # glyphs, and that is the case billboarding has to yield to.
    @test !RayMakie.identity_rotation([Makie.Quaternionf(0, 0, 0, 1)])
end
