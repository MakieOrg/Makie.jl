@reference_test "Value range < eps(Float32)" begin
    fig = Figure()
    ax = Axis(fig[1, 1])
    xlims!(ax, 0, 12)
    # no ylims! to check autolimits as well
    ax.xticks[] = (0:12, string.(0:12))
    ax.yticks[] = (1e9 .+ (0:11), ["1e9 + $i" for i in 0:11])

    # scatter + lines
    scatterlines!(1:10, 1e9 .+ (1:10))
    linesegments!(2:11, 1e9 .+ (1:10))
    meshscatter!(3:12, 1e9 .+ (1:10))
    text!(Point2(1, 1e9 + 6), text = L"\frac{\sqrt{1+x}}{2}", fontsize = 20, align = (:left, :center))

    image!(ax, 0 .. 3, (1e9 + 7) .. (1e9 + 10), [1 2; 3 4])
    heatmap!(ax, 10 .. 11, (1e9 + 2) .. (1e9 + 3), [1 2; 3 4])
    surface!(ax, 10 .. 11, (1e9 + 4) .. (1e9 + 5), [1 2; 3 4]; shading=NoShading)

    mesh!(ax, Circle(Point2(5, 1e9 + 8.5), 1.0); color=:red, shading=NoShading)
    poly!(ax, [7, 9, 8], 1e9 .+ [2, 2, 3]; strokewidth=2)

    fig
end

# TODO: PlotUtils tick finding fails with these ranges (and still fails with
# e40/e-40), resulting in only 3 ticks for the x axis and lots of warnings.
@reference_test "Below floatmin, above floatmax" begin
    fig = Figure()
    ax = Axis(fig[1, 1])

    # scatter + lines
    scatterlines!(1e-100 .* (1:10), 1e100 .* (1:10))
    linesegments!(1e-100 .* (2:11), 1e100 .* (1:10))
    # meshscatter!( 1e-100 .* (3:12), 1e100 .* (1:10)) # markersize does not match scales
    text!(Point2(1e-100, 6e100), text = "Test", fontsize = 20, align = (:left, :center))

    image!(ax,    1e-100 .. 3e-100,  (7e100) .. (10e100), [1 2; 3 4])
    heatmap!(ax, 10e-100 .. 11e-100, (2e100) .. (3e100),  [1 2; 3 4])
    surface!(ax, 10e-100 .. 11e-100, (4e100) .. (5e100),  [1 2; 3 4]; shading=NoShading)

    mesh!(ax, Rect2d(Point2(5e-100, 8.5e100), Vec2d(1e-100, 1e100)); color=:red, shading=NoShading)
    poly!(ax, 1e-100 .* [7, 9, 8], 1e100 .* [2, 2, 3]; strokewidth=2)

    fig
end


@reference_test "Model application with Float32 scaling" begin
    fig = Figure()
    ax = Axis(fig[1, 1])
    xlims!(ax, 0, 14)
    ylims!(ax, 1e9, 1e9 + 12)
    ax.xticks[] = (0:12, string.(0:12))
    ax.yticks[] = (1e9 .+ (0:11), ["1e9 + $i" for i in 0:11])

    shift = Vec3(1, 1, 0)

    p1 = scatterlines!(1:10, 1e9 .+ (1:10))
    p2 = linesegments!(2:11, 1e9 .+ (1:10))
    p3 = meshscatter!(3:12, 1e9 .+ (1:10))
    p4 = text!(Point2(1, 1e9 + 6), text = "Test", fontsize = 20, align = (:left, :center))
    p5 = image!(ax, 0 .. 3, (1e9 + 7) .. (1e9 + 10), [1 2; 3 4])
    p6 = heatmap!(ax, 10 .. 11, (1e9 + 2) .. (1e9 + 3), [1 2; 3 4])
    p7 = surface!(ax, 10 .. 11, (1e9 + 4) .. (1e9 + 5), [1 2; 3 4]; shading=NoShading)
    p8 = mesh!(ax, Circle(Point2(5, 1e9 + 8.5), 1.0); color=:red, shading=NoShading)
    p9 = poly!(ax, [7, 9, 8], 1e9 .+ [2, 2, 3]; strokewidth=2)

    translate!.([p1, p2, p3, p4, p5, p6, p7, p8, p9], (shift,))

    fig
end

@reference_test "Float64 h/vspan + h/vlines + error/rangebars + ablines" begin
    fig = Figure()
    ax = Axis(fig[1, 1])

    hspan!(ax, [1e9 + 4.5], [1e9 + 5.5], color = :yellow)
    vspan!(ax, [1e9 + 4.5], [1e9 + 5.5], color = :yellow)

    hlines!(ax, [1e9 + 4.5, 1e9 + 5.5], color = :red, linewidth = 4)
    vlines!(ax, [1e9 + 4.5, 1e9 + 5.5], color = :red, linewidth = 4)

    errorbars!(ax, 1e9 .+ (1:9), 1e9 .+ (1:9), 0.3, whiskerwidth = 10, direction = :x)
    rangebars!(ax, 1e9 .+ (1:9), 1e9 .+ (0.7:8.7), 1e9 .+ (1.3:9.3), whiskerwidth = 10)

    ablines!(ax, 2 * (1e9 + 5), -1.0)

    fig
end

@reference_test "Float64 hist" begin
    fig = Figure()
    ax = Axis(fig[1, 1])
    ylims!(ax, -1, 23)
    p = hist!(
        ax, 1e9 .+ cos.(range(0, pi, length = 100)),
        strokewidth = 2, bins = 10, bar_labels = :y
    )
    fig
end

@reference_test "Float64 model" begin
    fig = Figure()
    ax = Axis(fig[1, 1])

    p = heatmap!(ax, -0.75 .. -0.25, -0.75 .. -0.25, [1 2; 3 4], colormap = [:lightblue, :yellow])
    translate!(p, 1e9, 1e8, 0)
    p = image!(ax, 0..1, 0..1, [1 2; 3 4], colormap = [:lightblue, :yellow])
    translate!(p, 1e9, 1e8, 0)


    ps = 0.5 .* Makie.Point2d[(-1, -1), (-1, 1), (1, 1), (1, -1)]
    p = scatter!(ax, ps, marker = '+', markersize = 30)
    translate!(p, 1e9, 1e8, 0)
    p = text!(ax, ps, text = string.(1:4), fontsize = 20)
    translate!(p, 1e9, 1e8, 0)

    p = lines!(ax, [Point2f(cos(x), sin(x)) for x in range(0, 2pi, length=101)])
    translate!(p, 1e9, 1e8, 0)
    p = linesegments!(ax, [0.9 * Point2f(cos(x), sin(x)) for x in range(0, 2pi, length=101)])
    translate!(p, 1e9, 1e8, 0)
    p = lines!(ax, [0.8 * Point2f(cos(x), sin(x)) for x in range(0, 2pi, length=101)], linestyle = :dash)
    translate!(p, 1e9, 1e8, 0)

    fig
end

@reference_test "Float64 model with rotation" begin
    fig = Figure()
    ax = Axis(fig[1, 1])

    # TODO: broken in GLMakie (bad placement), CairoMakie (not supported)
    # p = heatmap!(ax, -0.75 .. -0.25, -0.75 .. -0.25, [1 2; 3 4], colormap = [:lightblue, :yellow])
    # translate!(p, 1e9, 1e8, 0)
    # rotate!(p, Vec3f(0,0,1), pi/4)
    p = image!(ax, 0..1, 0..1, [1 2; 3 4], colormap = [:lightblue, :yellow])
    translate!(p, 1e9, 1e8, 0)
    rotate!(p, Vec3f(0,0,1), pi/4)

    ps = 0.5 .* Makie.Point2d[(-1, -1), (-1, 1), (1, 1), (1, -1)]
    p = scatter!(ax, ps, marker = '+', markersize = 30)
    translate!(p, 1e9, 1e8, 0)
    rotate!(p, Vec3f(0,0,1), pi/4)
    p = text!(ax, ps, text = string.(1:4), fontsize = 20)
    translate!(p, 1e9, 1e8, 0)
    rotate!(p, Vec3f(0,0,1), pi/4)

    p = lines!(ax, [Point2f(cos(x), sin(x)) for x in range(0, 2pi, length=101)])
    translate!(p, 1e9, 1e8, 0)
    rotate!(p, Vec3f(0,0,1), pi/4)
    p = linesegments!(ax, [0.9 * Point2f(cos(x), sin(x)) for x in range(0, 2pi, length=101)])
    translate!(p, 1e9, 1e8, 0)
    rotate!(p, Vec3f(0,0,1), pi/4)
    p = lines!(ax, [0.8 * Point2f(cos(x), sin(x)) for x in range(0, 2pi, length=101)], linestyle = :dash)
    translate!(p, 1e9, 1e8, 0)
    rotate!(p, Vec3f(0,0,1), pi/4)

    fig
end