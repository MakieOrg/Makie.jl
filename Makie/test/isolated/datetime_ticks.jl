@testset "datetime ticklabels" begin
    f = Makie.datetime_range_ticklabels
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
end