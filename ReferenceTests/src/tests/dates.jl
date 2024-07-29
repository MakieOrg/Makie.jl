using Makie.Unitful, Makie.Dates, Test

some_time = Time("11:11:55.914")
date = Date("2021-10-27")
date_time = DateTime("2021-10-27T11:11:55.914")
time_range = some_time .+ range(Second(0); step=Second(5), length=10)
date_range = range(date, step=Day(5), length=10)
date_time_range = range(date_time, step=Week(5), length=10)

@reference_test "time_range" scatter(time_range, 1:10)
@reference_test "date_range" scatter(date_range, 1:10)
@reference_test "date_time_range" scatter(date_time_range, 1:10)

@reference_test "Don'some_time allow mixing units incorrectly" begin
    date_time_range = range(date_time, step=Second(5), length=10)
    f, ax, pl = scatter(date_time_range, 1:10)
    @test_throws ErrorException scatter!(time_range, 1:10)
    f
end

@reference_test "Force Unitful to be rendered as Time" begin
    yconversion = Makie.DateTimeConversion(Time)
    scatter(1:4, (1:4) .* u"s"; axis=(dim2_conversion=yconversion,))
end

@reference_test "Time Observable" begin
    obs = Observable(time_range)
    f, ax, pl = scatter(obs, 1:10)
    obs[] = some_time .+ range(Second(0); step=Second(1), length=10)
    autolimits!(ax)
    f
end

@reference_test "Date Observable" begin
    obs = Observable(date_range)
    f, ax, pl = scatter(obs, 1:10)
    obs[] = range(date, step=Day(1), length=10)
    autolimits!(ax)
    f
end

@reference_test "DateTime Observable" begin
    obs = Observable(date_time_range)
    f, ax, pl = scatter(obs, 1:10)
    obs[] = range(date_time, step=Week(3), length=10)
    autolimits!(ax)
    f
end
