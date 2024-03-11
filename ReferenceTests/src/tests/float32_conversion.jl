# Tests for plots relying on Float32Convert
# - values outside -3.4e38 .. 3.4e38 (floatmax)
# - value ranges ⪅ 1e-7 * values
# - currently only applies to Axis
# - need to test primitives and everything using project

@reference_test "Sub-Float32 eps" begin
    fig = Figure()
    ax = Axis(fig[1, 1])
    xlims!(ax, 0, 12)
    ax.xticks[] = (0:12, string.(0:12))
    ax.yticks[] = (1e9 .+ (0:11), ["1e9 + $i" for i in 0:11])

    # scatter + lines
    scatterlines!(1:10, 1e9 .+ (1:10))
    linesegments!(2:11, 1e9 .+ (1:10))
    meshscatter!(3:12, 1e9 .+ (1:10))

    image!(ax, 0 .. 3, (1e9 + 7) .. (1e9 + 10), [1 2; 3 4])
    heatmap!(ax, 10 .. 11, (1e9 + 2) .. (1e9 + 3), [1 2; 3 4])
    surface!(ax, 10 .. 11, (1e9 + 4) .. (1e9 + 5), [1 2; 3 4]; shading=NoShading)

    mesh!(ax, Circle(Point2(5, 1e9 + 8.5), 1.0); color=:red, shading=NoShading)
    poly!(ax, [7, 9, 8], 1e9 .+ [2, 2, 3]; strokewidth=2)

    fig
end
