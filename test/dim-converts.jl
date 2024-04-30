using Makie.Unitful
using Makie.Dates

@testset "1 arg expansion" begin
    f, ax, pl = scatter(u"m" .* (1:10))
    @test pl isa Scatter{Tuple{Vector{Point2{Float64}}}}
    f, ax, pl = scatter(Categorical(["a", "b", "c"]))
    @test pl isa Scatter{Tuple{Vector{Point2{Float64}}}}
    f, ax, pl = scatter(now() .+ range(Second(0); step=Second(5), length=10))
    @test pl isa Scatter{Tuple{Vector{Point2{Float64}}}}
end

@recipe(UnitfulPlot, x) do scene
    return Attributes()
end

function Makie.plot!(plot::UnitfulPlot)
    return scatter!(plot, plot.x, map(x -> x .* u"s", plot.x))
end

@testset "dates in recipe" begin
    f, ax, pl = unitfulplot(1:5)
    pl_conversion = Makie.get_conversions(pl)
    ax_conversion = Makie.get_conversions(ax)
    @test pl_conversion[2] isa Makie.UnitfulConversion
    @test ax_conversion[2] isa Makie.UnitfulConversion
    @test pl.plots[1][1][] == Point{2,Float32}.(1:5, 1:5)
end


struct DateStruct end

function Makie.convert_arguments(::PointBased, ::DateStruct)
    return (1:5, DateTime.(1:5))
end

@testset "dates in convert_arguments" begin
    f, ax, pl = scatter(DateStruct())
    pl_conversion = Makie.get_conversions(pl)
    ax_conversion = Makie.get_conversions(ax)
    @test pl_conversion[2] isa Makie.DateTimeConversion
    @test pl_conversion[2] isa Makie.DateTimeConversion

    @test pl[1][] == Point.(1:5, Float64.(Makie.date_to_number.(DateTime.(1:5))))
end

@testset "Categorical ylims!" begin
    f, ax, p = scatter(1:4, Categorical(["a", "b", "c", "a"]))
    scatter!(ax, 1:4, Categorical(["b", "d", "a", "c"]))
    ylims!(ax, "0", "x")
    Makie.update_state_before_display!(ax)
    lims = Makie.convert_dim_value.(Ref(ax), 2, ["0", "x"])
    (xmin, ymin), (xmax, ymax) = extrema(ax.finallimits[])
    @test [ymin, ymax] == lims
end

@testset "Conversion with implicit axis" begin
    conversion = Makie.CategoricalConversion(; sortby=identity)
    f, ax, pl = barplot([:a, :b, :c], 1:3; axis=(dim1_conversion=conversion,))
    @test ax.dim1_conversion[] == Makie.get_conversions(pl)[1]
    @test conversion == Makie.get_conversions(pl)[1]
    @test ax.scene.conversions[1] == Makie.get_conversions(pl)[1]
    @test pl[1][] == Point.(1:3, 1:3)
end

@testset "unit switching" begin
    f, ax, pl = scatter(rand(Hour(1):Hour(1):Hour(20), 10))
    # Unitful works as well
    scatter!(ax, LinRange(0u"yr", 0.1u"yr", 5))
    @test_throws Unitful.DimensionError scatter!(ax, 1:4)
    @test_throws ArgumentError scatter!(ax, Hour(1):Hour(1):Hour(4), 1:4)
end

function test_cleanup(arg)
    obs = Observable(arg)
    f, ax, pl = scatter(obs)
    @test length(obs.listeners) == 1
    delete!(ax, pl)
    @test length(obs.listeners) == 0
end

@testset "clean up observables" begin
    @testset "UnitfulConversion" begin
        test_cleanup([0.01u"km", 0.02u"km", 0.03u"km", 0.04u"km"])
    end
    @testset "CategoricalConversion" begin
        test_cleanup(Categorical(["a", "b", "c"]))
    end
    @testset "DateTimeConversion" begin
        dates = now() .+ range(Second(0); step=Second(5), length=10)
        test_cleanup(dates)
    end
end
