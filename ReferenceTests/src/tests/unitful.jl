using Makie.Dates, Makie.Unitful, Test

@reference_test "combining units, error for numbers" begin
    f, ax, pl = scatter(Second(1):Second(600):Second(100*60), 1:10, markersize=20, color=1:10)
    scatter!(ax, Hour(1):Hour(1):Hour(10), 1:10; markersize=20, color=1:10, colormap=:reds)
    @test_throws Unitful.DimensionError scatter!(ax, rand(10), 1:10) # should error!
    f
end

@reference_test "different units for x + y" begin
    scatter(u"ns" .* (1:10), u"d" .* (1:10), markersize=20, color=1:10)
end

@reference_test "Nanoseconds on y" begin
    linesegments(1:10, Nanosecond.(round.(LinRange(0, 4599800000000, 10))))
end

@reference_test "Meter & time on x, y" begin
    scatter(u"cm" .* (1:10), u"d" .* (1:10))
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
