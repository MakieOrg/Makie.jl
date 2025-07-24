using Makie.Dates
@testset "tick finding" begin
    dtt = Makie.DateTimeTicks()
    for tstart in [DateTime(0), DateTime(2000, 1, 1), DateTime(2025, 7, 2), DateTime(2025, 7, 2, 5), DateTime(2025, 7, 2, 5, 17, 32), DateTime(2025, 7, 2, 5, 17, 32, 241)]
        for dist in [1, 2, 17, 103, 1076]
            for type in [Millisecond, Second, Minute, Hour, Month, Year]
                tend = tstart + type(dist)
                ticks, _ = Makie.locate_datetime_ticks(dtt, tstart, tend)
                nticks = length(ticks)
                @test allunique(ticks)
                @test length(ticks) >= 2
                @test all(tick -> tstart <= tick <= tend, ticks)
            end
        end
    end
end
@testset "datetime ticklabels" begin
    sym(::Year) = :year
    sym(::Month) = :month
    sym(::Day) = :day
    sym(::Hour) = :hour
    sym(::Minute) = :minute
    sym(::Second) = :second
    sym(::Millisecond) = :millisecond
    f(range::AbstractRange) = Makie.datetime_range_ticklabels(Makie.DateTimeTicks(), collect(range), sym(range.step))
    DT = DateTime

    # shortening for first days of years or months
    @test f(DT(2025, 1, 1):Year(1):DT(2028, 1, 1)) == ["2025", "2026", "2027", "2028"]
    @test f(DT(2025, 1, 1):Year(2):DT(2028, 1, 1)) == ["2025", "2027"]
    @test f(DT(2025, 1, 1):Month(1):DT(2025, 4, 1)) == ["2025-01", "2025-02", "2025-03", "2025-04"]
    @test f(DT(2025, 1, 1):Month(2):DT(2025, 4, 1)) == ["2025-01", "2025-03"]
    @test f(DT(2025, 1, 1):Month(2):DT(2025, 4, 1)) == ["2025-01", "2025-03"]

    # for years, non-first month needs longer labels
    @test f(DT(2025, 2, 1):Year(1):DT(2028, 2, 1)) == ["2025-02", "2026-02", "2027-02", "2028-02"]
    # same for non-first day
    @test f(DT(2025, 1, 2):Year(1):DT(2028, 1, 2)) == ["2025-01-02", "2026-01-02", "2027-01-02", "2028-01-02"]
    # for months, non-first day
    @test f(DT(2025, 1, 2):Month(1):DT(2025, 4, 2)) == ["2025-01-02", "2025-02-02", "2025-03-02", "2025-04-02"]

    # Day intervals - all midnight times
    @test f(DT(2025, 1, 1):Day(1):DT(2025, 1, 5)) == ["2025-01-01", "2025-01-02", "2025-01-03", "2025-01-04", "2025-01-05"]
    @test f(DT(2025, 1, 1):Day(2):DT(2025, 1, 7)) == ["2025-01-01", "2025-01-03", "2025-01-05", "2025-01-07"]

    # Hour intervals - same day
    @test f(DT(2025, 1, 1, 9):Hour(1):DT(2025, 1, 1, 12)) == ["9:00\n2025-01-01", "10:00", "11:00", "12:00"]
    @test f(DT(2025, 1, 1, 9):Hour(2):DT(2025, 1, 1, 15)) == ["9:00\n2025-01-01", "11:00", "13:00", "15:00"]

    # Hour intervals - crossing days
    @test f(DT(2025, 1, 1, 22):Hour(1):DT(2025, 1, 2, 2)) == ["22:00\n2025-01-01", "23:00", "0:00\n2025-01-02", "1:00", "2:00"]
    @test f(DT(2025, 1, 1, 23):Hour(3):DT(2025, 1, 2, 5)) == ["23:00\n2025-01-01", "2:00\n2025-01-02", "5:00"]

    # Minute intervals - same hour (shows shortened format within same hour)
    @test f(DT(2025, 1, 1, 9, 0):Minute(15):DT(2025, 1, 1, 9, 45)) == ["9:00\n2025-01-01", ":15", ":30", ":45"]
    @test f(DT(2025, 1, 1, 9, 30):Minute(10):DT(2025, 1, 1, 10, 0)) == ["9:30\n2025-01-01", ":40", ":50", "10:00"]

    # Minute intervals - crossing hours
    @test f(DT(2025, 1, 1, 9, 50):Minute(10):DT(2025, 1, 1, 10, 20)) == ["9:50\n2025-01-01", "10:00", ":10", ":20"]

    # Minute intervals - crossing days
    @test f(DT(2025, 1, 1, 23, 45):Minute(15):DT(2025, 1, 2, 0, 30)) == ["23:45\n2025-01-01", "0:00\n2025-01-02", ":15", ":30"]

    # Second intervals - same minute
    @test f(DT(2025, 1, 1, 9, 0, 0):Second(15):DT(2025, 1, 1, 9, 0, 45)) == ["9:00:00\n2025-01-01", ":15", ":30", ":45"]
    @test f(DT(2025, 1, 1, 9, 0, 30):Second(10):DT(2025, 1, 1, 9, 1, 0)) == ["9:00:30\n2025-01-01", ":40", ":50", ":1:00"]

    # Second intervals - crossing minutes (shows shortened format within same hour)
    @test f(DT(2025, 1, 1, 9, 0, 50):Second(10):DT(2025, 1, 1, 9, 1, 20)) == ["9:00:50\n2025-01-01", ":1:00", ":10", ":20"]

    # Second intervals - crossing hours
    @test f(DT(2025, 1, 1, 9, 59, 50):Second(10):DT(2025, 1, 1, 10, 0, 20)) == ["9:59:50\n2025-01-01", "10:00:00", ":10", ":20"]

    # Second intervals - crossing days
    @test f(DT(2025, 1, 1, 23, 59, 50):Second(10):DT(2025, 1, 2, 0, 0, 20)) == ["23:59:50\n2025-01-01", "0:00:00\n2025-01-02", ":10", ":20"]

    # Millisecond intervals - same second
    @test f(DT(2025, 1, 1, 9, 0, 0, 0):Millisecond(250):DT(2025, 1, 1, 9, 0, 0, 750)) == ["9:00:00.000\n2025-01-01", ".250", ".500", ".750"]

    # Millisecond intervals - crossing seconds
    @test f(DT(2025, 1, 1, 9, 0, 0, 800):Millisecond(200):DT(2025, 1, 1, 9, 0, 1, 400)) == ["9:00:00.800\n2025-01-01", ":01.000", ".200", ".400"]

    # Millisecond intervals - crossing minutes
    @test f(DT(2025, 1, 1, 9, 0, 59, 800):Millisecond(200):DT(2025, 1, 1, 9, 1, 0, 400)) == ["9:00:59.800\n2025-01-01", ":1:00.000", ".200", ".400"]

    # Edge cases - single element ranges (return full string representation)
    @test f(DT(2025, 1, 1):Year(1):DT(2025, 1, 1)) == ["2025-01-01T00:00:00"]
    @test f(DT(2025, 1, 1, 12, 30, 45):Second(1):DT(2025, 1, 1, 12, 30, 45)) == ["2025-01-01T12:30:45"]

    # Edge cases - empty ranges
    @test f(DT(2025, 1, 2):Day(1):DT(2025, 1, 1)) == []

    # Mixed date and time (non-midnight) with day/month intervals
    @test f(DT(2025, 1, 1, 12, 30):Day(1):DT(2025, 1, 3, 12, 30)) == ["12:30:00\n2025-01-01", "12:30:00\n2025-01-02", "12:30:00\n2025-01-03"]
    @test f(DT(2025, 1, 15, 14, 22):Month(1):DT(2025, 4, 15, 14, 22)) == ["14:22:00\n2025-01-15", "14:22:00\n2025-02-15", "14:22:00\n2025-03-15", "14:22:00\n2025-04-15"]

    # Large step sizes
    @test f(DT(2020, 1, 1):Year(5):DT(2035, 1, 1)) == ["2020", "2025", "2030", "2035"]
    @test f(DT(2025, 1, 1):Month(6):DT(2026, 7, 1)) == ["2025-01", "2025-07", "2026-01", "2026-07"]
    @test f(DT(2025, 1, 1):Day(10):DT(2025, 2, 1)) == ["2025-01-01", "2025-01-11", "2025-01-21", "2025-01-31"]

    # Crossing year boundaries
    @test f(DT(2024, 12, 1):Month(1):DT(2025, 3, 1)) == ["2024-12", "2025-01", "2025-02", "2025-03"]
    @test f(DT(2024, 12, 31, 22):Hour(2):DT(2025, 1, 1, 4)) == ["22:00\n2024-12-31", "0:00\n2025-01-01", "2:00", "4:00"]
    @test f(DT(2024, 12, 31, 23, 59):Minute(1):DT(2025, 1, 1, 0, 2)) == ["23:59\n2024-12-31", "0:00\n2025-01-01", ":01", ":02"]
end

@testset "time ticks close to edges" begin
    f(vmin, vmax) = Makie.get_ticks(Makie.DateTimeConversion(Time), Makie.automatic, identity, Makie.automatic, vmin, vmax)
    tmin = Time(0)
    tmax = Time(0) - Nanosecond(1)
    num_tmin = Makie.date_to_number(Time, tmin)
    num_tmax = Makie.date_to_number(Time, tmax)
    num_lower_tmin = num_tmin - 1
    num_higher_tmax = num_tmax + 1
    @test Makie.number_to_date(Time, num_lower_tmin) > tmin
    @test Makie.number_to_date(Time, num_higher_tmax) < tmax
    @test f(num_tmin, num_tmax) == f(num_lower_tmin, num_higher_tmax)
    @test !isempty(f(num_lower_tmin, num_higher_tmax)[1])
end
