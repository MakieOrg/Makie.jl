# Tests for plots relying on Float32Convert
# - values outside -3.4e38 .. 3.4e38 (floatmax)
# - value ranges ⪅ 1e-7 * values
# - currently only applies to Axis
# - need to test primitives and everything using project

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
    text!(Point2(1, 1e9 + 6), text = "Test", fontsize = 20, align = (:left, :center))

    image!(ax, 0 .. 3, (1e9 + 7) .. (1e9 + 10), [1 2; 3 4])
    heatmap!(ax, 10 .. 11, (1e9 + 2) .. (1e9 + 3), [1 2; 3 4])
    surface!(ax, 10 .. 11, (1e9 + 4) .. (1e9 + 5), [1 2; 3 4]; shading=NoShading)

    mesh!(ax, Circle(Point2(5, 1e9 + 8.5), 1.0); color=:red, shading=NoShading)
    poly!(ax, [7, 9, 8], 1e9 .+ [2, 2, 3]; strokewidth=2)

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
