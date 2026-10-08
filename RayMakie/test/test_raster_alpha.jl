# `alpha` fades a plot in RASTER mode as it does in GLMakie.
#
# Lines, line segments (so `vlines`/`hlines`), images and heatmaps read their
# raw `color`/`image` and drew at full strength whatever `alpha` was, while
# scatter, text and poly read Makie's `scaled_color`, which has it. A film keys
# `alpha` to fade a curve, a grid or a picture in and out, and in RASTER mode
# none of those moved. They read `scaled_color` now, on a live screen too.
#
# An image or heatmap with `interpolate = false` (a heatmap's default) shows each
# value as a square; it was sampled linearly whatever the attribute said.

using Test, RayMakie, Makie, Mantle, Colors

brightest(img) = maximum(c -> Float32(red(c) + green(c) + blue(c)), img)

function alphaframe(draw!, a)
    fig = Figure(; size = (160, 160), backgroundcolor = :black)
    ax = Axis(fig[1, 1]; backgroundcolor = :black)
    hidedecorations!(ax); hidespines!(ax)
    draw!(ax, a)
    limits!(ax, 0, 1, 0, 1)
    screen = RayMakie.Screen(fig.scene; device = Mantle.defaultbackend(), visible = false, rasterize = true,
                             samples = 1)
    try
        return brightest(colorbuffer(screen))
    finally
        close(screen)
    end
end

@testset "alpha fades every plot kind" begin
    kinds = ["lines" => (ax, a) -> lines!(ax, [0.1, 0.9], [0.5, 0.5]; color = :white, linewidth = 6, alpha = a),
             "linesegments" => (ax, a) -> linesegments!(ax, [Point2f(0.1, 0.5), Point2f(0.9, 0.5)]; color = :white,
                                                        linewidth = 6, alpha = a),
             "vlines" => (ax, a) -> vlines!(ax, [0.5]; color = :white, linewidth = 6, alpha = a),
             "numeric lines" => (ax, a) -> lines!(ax, [0.1, 0.9], [0.5, 0.5]; color = [1.0, 1.0],
                                                  colormap = [:white, :white], linewidth = 6, alpha = a),
             "image" => (ax, a) -> image!(ax, 0.2 .. 0.7, 0.2 .. 0.7, fill(RGBf(1, 1, 1), 4, 4); alpha = a),
             "heatmap" => (ax, a) -> heatmap!(ax, 0.2 .. 0.7, 0.2 .. 0.7, ones(4, 4); colormap = [:white, :white],
                                              alpha = a),
             "scatter" => (ax, a) -> scatter!(ax, [0.5], [0.5]; color = :white, markersize = 30, alpha = a)]
    for (name, draw!) in kinds
        full, faint, gone = (alphaframe(draw!, a) for a in (1.0, 0.3, 0.0))
        @testset "$name" begin
            @test full > 2.5f0
            @test faint < 0.5f0 * full
            @test gone < 0.05f0
        end
    end
end

@testset "a changed alpha and interpolate reach a live screen" begin
    fig = Figure(; size = (160, 160), backgroundcolor = :black)
    ax = Axis(fig[1, 1]; backgroundcolor = :black)
    hidedecorations!(ax); hidespines!(ax)
    line = lines!(ax, [0.1, 0.9], [0.2, 0.2]; color = :white, linewidth = 6)
    checker = [RGBf(1, 1, 1) RGBf(0, 0, 0); RGBf(0, 0, 0) RGBf(1, 1, 1)]
    picture = image!(ax, 0.2 .. 0.8, 0.4 .. 1.0, checker; interpolate = false)
    limits!(ax, 0, 1, 0, 1)
    screen = RayMakie.Screen(fig.scene; device = Mantle.defaultbackend(), visible = false, rasterize = true,
                             samples = 1)
    try
        img = colorbuffer(screen)
        h = size(img, 1)
        rows = round(Int, 0.75h):round(Int, 0.82h)       # the line, near the bottom
        @test brightest(img[rows, :]) > 2.5f0
        line.alpha = 0.2
        @test brightest(colorbuffer(screen)[rows, :]) < 1f0
        # nearest sampling: only black and white inside the checker, no greys
        inner = colorbuffer(screen)[round(Int, 0.1h):round(Int, 0.5h), round(Int, 0.25h):round(Int, 0.75h)]
        @test all(c -> (v = Float32(red(c) + green(c) + blue(c)); v < 0.1f0 || v > 2.9f0), inner)
        picture.interpolate = true
        inner = colorbuffer(screen)[round(Int, 0.1h):round(Int, 0.5h), round(Int, 0.25h):round(Int, 0.75h)]
        @test any(c -> 0.3f0 < Float32(red(c) + green(c) + blue(c)) < 2.7f0, inner)
    finally
        close(screen)
    end
end

# A label faded to nothing must not claim depth. Its glyphs kept the 0.001 the
# fill is raised to, were never discarded, and a label drawn later at the same
# place (a caption replacing a faded one) had holes in the shape of the
# invisible letters.
@testset "a faded label leaves no holes in one drawn over it" begin
    function frame(draw!)
        fig = Figure(; size = (300, 80), backgroundcolor = RGBf(0.7, 0.66, 0.6))
        ov = Scene(fig.scene; camera = campixel!, clear = false)
        draw!(ov)
        screen = RayMakie.Screen(fig.scene; device = Mantle.defaultbackend(), visible = false, rasterize = true,
                                 samples = 1)
        try
            return Float32.(red.(colorbuffer(screen)))
        finally
            close(screen)
        end
    end
    box!(ov) = poly!(ov, Rect2f(20, 10, 260, 60); color = RGBAf(0.06, 0.06, 0.07, 1))
    faded!(ov) = textlabel!(ov, Point2f(150, 40); text = "zzzz zzzz", fontsize = 40, text_color = RGBAf(1, 1, 1, 0),
                            background_color = RGBAf(0, 0, 0, 0), strokecolor = RGBAf(1, 1, 1, 0))
    @test maximum(abs.(frame(ov -> (faded!(ov); box!(ov))) .- frame(box!))) < 0.02f0
end
