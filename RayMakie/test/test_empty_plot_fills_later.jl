# A plot created EMPTY and filled later has to draw when the data arrives.
#
# It did not, and the failure was permanent for the life of the graph.
# `draw_atomic` for `lines` and `text` answers `(nothing,)` while there is
# nothing to draw, `nothing` is ComputePipeline's word for "this output did not
# CHANGE", and on the FIRST resolve there is no old value to keep — so the
# output slot was created as a `RefValue{Nothing}` and the next resolve, the one
# with real points, died on `convert(Nothing, ::RenderObject)`. Every frame
# after that logged "an overlay render object failed to resolve" and drew
# nothing. Fixed in `ComputePipeline.slotfor`.
#
# A GUI is where this bites: the video editor's crop rectangle and its size
# label exist from the moment the tool is built and get their data on the first
# drag. A figure that plots data it already has resolves to a `RenderObject`
# first and types the slot correctly, which is why nothing else here saw it.

using Test
using RayMakie, Makie, Colors

@testset "a plot created empty draws once it has data" begin
    f = Figure(size = (200, 200), backgroundcolor = :white)
    ax = Axis(f[1, 1])
    Makie.limits!(ax, 0, 10, 0, 10)

    pts = Observable(Point2f[])                      # EMPTY at creation
    lines!(ax, pts; color = :red, linewidth = 6)
    txt = Observable("")
    text!(ax, Point2f(5, 8); text = txt, color = :red, fontsize = 30)

    screen = RayMakie.Screen(f.scene; visible = false)
    blank = Makie.colorbuffer(screen)

    isred(c) = red(c) > 0.6 && green(c) < 0.35 && blue(c) < 0.35
    @test count(isred, blank) == 0                   # nothing to draw yet, and no error

    pts[] = Point2f[(1, 1), (9, 9)]
    txt[] = "hi"
    drawn = Makie.colorbuffer(screen)

    # The whole point: the render objects resolve NOW, having answered
    # `nothing` first. Before the fix this count stayed at 0 for ever.
    @test count(isred, drawn) > 50

    # …and emptying it again is not an error either — that is the `nothing`
    # path on a slot that now holds a value, which always worked and has to keep
    # working.
    pts[] = Point2f[]
    txt[] = ""
    @test Makie.colorbuffer(screen) !== nothing

    close(screen)
end
