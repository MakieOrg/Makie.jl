using Unitful, Dates, Test

time = Time("11:11:55.914")
date = Date("2021-10-27")
date_time = DateTime("2021-10-27T11:11:55.914")
time_range = range(time, step=Second(5), length=10)
date_range = range(date, step=Day(5), length=10)
date_time_range = range(date_time, step=Week(5), length=10)

@cell "time_range" scatter(time_range, 1:10)
@cell "date_range" scatter(date_range, 1:10)
@cell "date_time_range" scatter(date_time_range, 1:10)

@cell "Don't allow mixing units incorrectly" begin
    date_time_range = range(date_time, step=Second(5), length=10)
    f, ax, pl = scatter(date_time_range, 1:10)
    @test_throws ErrorException scatter!(time_range, 1:10)
    f
end

@cell "Force Unitful to be rendered as Time" begin
    yticks = MakieLayout.DateTimeTicks(Time)
    scatter(1:4, (1:4) .* u"s", axis=(yticks=yticks,))
end

@cell "Time Observable" begin
    obs = Observable(time_range)
    f, ax, pl = scatter(obs, 1:10)
    obs[] = range(time, step=Second(1), length=10)
    autolimits!(ax)
    f
end

@cell "Date Observable" begin
    obs = Observable(date_range)
    f, ax, pl = scatter(obs, 1:10)
    obs[] = range(date, step=Day(1), length=10)
    autolimits!(ax)
    f
end

@cell "DateTime Observable" begin
    obs = Observable(date_time_range)
    f, ax, pl = scatter(obs, 1:10)
    obs[] = range(date_time, step=Week(3), length=10)
    autolimits!(ax)
    f
end
