using Dates, Unitful, Test

@cell "combining units, error for numbers" begin
    f, ax, pl = scatter(rand(Second(1):Second(60):Second(20*60), 10), 1:10)
    scatter!(ax, rand(Hour(1):Hour(1):Hour(20), 10), 1:10)
    @test_throws Unitful.DimensionError scatter!(ax, rand(10), 1:10) # should error!
    f
end

@cell "different units for x + y" begin
    scatter(u"ns" .* (1:10), u"d" .* rand(10) .* 10)
end

@cell "Nanoseconds on y" begin
    linesegments(1:10, Nanosecond.(round.(LinRange(0, 4599800000000, 10))))
end

@cell "Meter & time on x, y" begin
    scatter(u"cm" .* (1:10), u"d" .* (1:10))
end

@cell "Auto units for observables" begin
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
