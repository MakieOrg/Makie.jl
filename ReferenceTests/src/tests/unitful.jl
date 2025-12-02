using Makie.Dates, Makie.Unitful, Test

@reference_test "combining units, error for numbers" begin
    f, ax, pl = scatter(Second(1):Second(600):Second(100 * 60), 1:10, markersize = 20, color = 1:10)
    scatter!(ax, Hour(1):Hour(1):Hour(10), 1:10; markersize = 20, color = 1:10, colormap = :reds)
    @test_throws ResolveException scatter!(ax, rand(10), 1:10) # should error!
    f
end

@reference_test "Basic units" begin
    f = Figure()
    scatter(f[1, 1], u"ns" .* (1:10), u"d" .* (1:10), markersize = 20, color = 1:10)
    linesegments(f[1, 2], 1:10, Nanosecond.(round.(LinRange(0, 4599800000000, 10))))
    scatter(f[2, 1], u"cm" .* (1:10), u"d" .* (1:10))
    scatter(f[2, 2], (60:10:100) * u"dB")
    f
end

@reference_test "Auto units for observables" begin
    obs = Observable{Any}(u"s" .* (1:10))
    f, ax, pl = scatter(1:10, obs)
    st = Stepper(f)

    obs[] = u"yr" .* (1:10)
    autolimits!(ax)
    Makie.step!(st)

    obs[] = u"ns" .* (1:10)
    autolimits!(ax)
    Makie.step!(st)

    st
end

@reference_test "Unit reflection" begin
    # Don't swallow units past the first
    f, a, p = scatter((1:10) .* u"J/s")
    # Don't simplify (assume the user knows better)
    scatter(f[1, 2], (1:10) .* u"K", exp.(1:10) .* u"mm/m^2")
    # Only change prefixes of simple units, not compound units
    scatter(f[2, 1], 10 .^ (1:6) .* u"W/m^2", (1:6) .* 1000 .* u"nm")
    # Only change units/prefixes for simple units when adding more plots
    scatter(f[2, 2], (0:10) .* u"W/m^2", (0:10) .* u"g")
    scatter!((0:10) .* u"kW/m^2", (0:10) .* u"kg")
    f
end

@reference_test "Unitful Axis3" begin
    fig = Figure(size = (700, 300))
    ax = Axis3(fig[1, 1], dim1_conversion = Makie.UnitfulConversion(u"m"))
    xs, ys = -2:0.2:2, -2:0.2:2
    x, y, z = [xi for xi in xs for yi in ys], [yi for xi in xs for yi in ys], [sin(xi) * cos(yi) for xi in xs for yi in ys]
    scatter!(ax, u"m" .* x, y, z; markersize = 10, color = x, alpha = 0.8, transparency = true)
    t = 0:0.1:6π; x, y = cos.(t), sin.(t)
    scatter(fig[1, 2], x, y, t .* u"s", markersize = 15, color = t, alpha = 0.8, transparency = true, axis = (; type = Axis3))
    fig
end
