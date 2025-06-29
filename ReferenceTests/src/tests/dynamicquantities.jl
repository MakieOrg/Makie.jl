using DynamicQuantities, Test

@reference_test "combining units, error for numbers" begin
    f, ax, pl = scatter(((1:600:(100 * 60))u"s" .|> us"min"), 1:10, markersize = 20, color = 1:10)
    scatter!(ax, (1:10)u"hr", 1:10; markersize = 20, color = 1:10, colormap = :reds)
    @test_throws ResolveException scatter!(ax, rand(10), 1:10) # should error!
    f
end

@reference_test "Basic units" begin
   f = Figure()
   scatter(f[1, 1], us"ns" * (1:10), us"d" * (1:10), markersize = 20, color = 1:10)
   linesegments(f[1, 2], 1:10, round.(LinRange(0, 4599800000000, 10))u"ns" .|> us"minute")
   scatter(f[2, 1], us"cm" * (1:10), us"d" * (1:10))
   # TODO, implement log units, e.g., dB, mag?
   scatter(f[2, 2], (60:10:100) * us"Hz")
   f
end

# TODO: Do we really want to support this? Currently uses the units specified in the initial plot
# call as intended in the original PR: https://github.com/SymbolicML/DynamicQuantities.jl/pull/165
#@reference_test "Auto units for observables" begin
#    obs = Observable{Any}(u"s" * (1:10))
#    f, ax, pl = scatter(1:10, obs)
#    st = Stepper(f)
#
#    obs[] = u"yr" * (1:10)
#    autolimits!(ax)
#    Makie.step!(st)
#
#    obs[] = u"ns" * (1:10)
#    autolimits!(ax)
#    Makie.step!(st)
#
#    st
#end

@reference_test "Unit reflection" begin
    # Don't swallow units past the first
    f, a, p = scatter((1:10) * us"J/s")
    # Don't simplify (assume the user knows better)
    scatter(f[1, 2], (1:10) * u"K", exp.(1:10) * us"mm/m^2")
    # Do not change prefixes of simple or compound units
    scatter(f[2, 1], 10 .^ (1:6) * us"W/m^2", (1:6) .* 1000 * u"nm"; axis=(; dim2_conversion=Makie.DQConversion(us"μm")))
    # Do not change units/prefixes for simple units when adding more plots
    scatter(f[2, 2], (0:10) * u"W/m^2", (0:10) * u"g"; axis=(; dim1_conversion=Makie.DQConversion(us"W/m^2")))
    scatter!((0:10) * u"kW/m^2", (0:10) * us"kg")
    f
end

@reference_test "Unitful Axis3" begin
    fig = Figure(size = (700, 300))
    ax = Axis3(fig[1, 1], dim1_conversion = Makie.DQConversion(us"m"))
    xs, ys = -2:0.2:2, -2:0.2:2
    x, y, z = [xi for xi in xs for yi in ys], [yi for xi in xs for yi in ys], [sin(xi) * cos(yi) for xi in xs for yi in ys]
    scatter!(ax, u"m" * x, y, z; markersize = 10, color = x, alpha = 0.8, transparency = true)
    t = 0:0.1:6π; x, y = cos.(t), sin.(t)
    scatter(fig[1, 2], x, y, t * u"s", markersize = 15, color = t, alpha = 0.8, transparency = true, axis = (; type = Axis3))
    fig
end
