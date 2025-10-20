using Makie.Unitful
import DynamicQuantities as DQ
using Makie.Dates

@testset "1 arg expansion" begin
    f, ax, pl = scatter(u"m" .* (1:10))
    @test pl isa Scatter{Tuple{Vector{Point2{Float64}}}}
    f, ax, pl = scatter(DQ.u"m" .* (1:10))
    @test pl isa Scatter{Tuple{Vector{Point2{Float64}}}}
    f, ax, pl = scatter(Categorical(["a", "b", "c"]))
    @test pl isa Scatter{Tuple{Vector{Point2{Float64}}}}
    f, ax, pl = scatter(now() .+ range(Second(0); step = Second(5), length = 10))
    @test pl isa Scatter{Tuple{Vector{Point2{Float64}}}}
end

@recipe(UnitfulPlot, x) do scene
    return Attributes()
end

function Makie.plot!(plot::UnitfulPlot)
    return scatter!(plot, plot.x, map(x -> x .* u"s", plot.x))
end

@recipe DQPlot (x,) begin
end

function Makie.plot!(plot::DQPlot)
    return scatter!(plot, plot.x, map(x -> x .* DQ.u"s", plot.x))
end

@testset "dates in recipe" begin
    f, ax, pl = unitfulplot(1:5)
    pl_conversion = Makie.get_conversions(pl)
    ax_conversion = Makie.get_conversions(ax)
    @test pl_conversion[2] isa Makie.UnitfulConversion
    @test ax_conversion[2] isa Makie.UnitfulConversion
    @test pl.plots[1][1][] == Point{2, Float32}.(1:5, 1:5)

    f, ax, pl = dqplot(1:5)
    pl_conversion = Makie.get_conversions(pl)
    ax_conversion = Makie.get_conversions(ax)
    @test pl_conversion[2] isa Makie.DQConversion
    @test ax_conversion[2] isa Makie.DQConversion
    @test pl.plots[1][1][] == Point{2, Float32}.(1:5, 1:5)
end

struct DateStruct end

function Makie.convert_arguments(::PointBased, ::DateStruct)
    return (1:5, DateTime.(1:5))
end

# TODO recursive dim converts

@testset "dates in convert_arguments" begin
    f, ax, pl = scatter(DateStruct())
    pl_conversion = Makie.get_conversions(pl)
    ax_conversion = Makie.get_conversions(ax)
    @test pl_conversion[2] isa Makie.DateTimeConversion

    @test pl[1][] == Point.(1:5, Float64.(Makie.date_to_number.(DateTime, DateTime.(1:5))))
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
    conversion = Makie.CategoricalConversion(; sortby = identity)
    f, ax, pl = barplot([:a, :b, :c], 1:3; axis = (dim1_conversion = conversion,))
    @test ax.dim1_conversion[] == Makie.get_conversions(pl)[1]
    @test conversion == Makie.get_conversions(pl)[1]
    @test ax.scene.conversions[1] == Makie.get_conversions(pl)[1]
    @test pl[1][] == Point.(1:3, 1:3)
end


@testset "unit switching" begin
    f, ax, pl = scatter(rand(Hour(1):Hour(1):Hour(20), 10))
    # Unitful works as well
    scatter!(ax, LinRange(0u"yr", 0.1u"yr", 5))
    # TODO, how to check for this case?
    @test_throws ResolveException scatter!(ax, 1:4) # happens inside graph in dim_convert
    @test_throws ArgumentError scatter!(ax, Hour(1):Hour(1):Hour(4), 1:4)

    # TODO, DynamicQuantities does not work with Dates. Is this by design?
    f, ax, pl = scatter(rand(Hour(1):Hour(1):Hour(20), 10))
    @test_throws ResolveException{Makie.Unitful.DimensionError} scatter!(ax, LinRange(0 * DQ.u"yr", 0.1 * DQ.u"yr", 5))
end

function test_cleanup(arg)
    obs = Observable(arg)
    f, ax, pl = scatter(obs)
    @test length(obs.listeners) == 1
    delete!(ax, pl)
    return @test length(obs.listeners) == 0
end

@testset "clean up observables" begin
    @testset "UnitfulConversion" begin
        test_cleanup([0.01u"km", 0.02u"km", 0.03u"km", 0.04u"km"])
    end
    @testset "DQConversion" begin
        test_cleanup([0.01 * DQ.u"km", 0.02 * DQ.u"km", 0.03 * DQ.u"km", 0.04 * DQ.u"km"])
    end
    @testset "CategoricalConversion" begin
        test_cleanup(Categorical(["a", "b", "c"]))
    end
    @testset "DateTimeConversion" begin
        dates = now() .+ range(Second(0); step = Second(5), length = 10)
        test_cleanup(dates)
    end
end

@testset "Type constraints (#3938)" begin
    # Integers cannot be converted to Irrationals,
    # so if the type of the observable is tightened
    # somewhere within the pipeline, there should be a
    # conversion error!
    obs = Observable{Vector}([π, π])
    f, a, p = plot(obs)
    obs.val = [1, 1] # Integers are not convertible to Irrational, so if the type was "solidified" here, there should be a conversion error
    @test_nowarn notify(obs)
end

@testset "Recipe dim converts" begin
    # These tests mainly test that one set of arguments can correctly generate
    # dim_converts

    UC = Makie.UnitfulConversion
    CC = Makie.CategoricalConversion
    NC = Makie.NoDimConversion

    function test_plot(func, args...; dims = (1, 2), kwargs...)
        get_value(x) = first(x)
        get_value(x::Makie.ClosedInterval) = minimum(x)

        simplify(t::Tuple) = simplify.(t)
        simplify(r::AbstractRange) = ntuple(i -> r[i], length(r))
        simplify(::Nothing) = nothing
        simplify(i::Integer) = i

        @testset "$func" begin
            f, a, p = func(args...; kwargs...)

            args = convert_arguments(typeof(p), args...)

            @test simplify(p.arg_dims[]) == dims

            dc_args = Any[nothing, nothing, nothing]
            # UnitfulConversion only sees the first arg, so overwrite back to front
            for i in reverse(eachindex(dims))
                dims[i] == 0 && continue
                if dims[i] isa Integer
                    dc_args[dims[i]] = args[i]
                else
                    for (j, d) in enumerate(dims[i])
                        dc_args[d] = getindex.(args[i], j)
                    end
                end
            end

            dim_converts = p.dim_conversions[]
            for i in 1:3
                dc = dim_converts[i]

                if dc isa Makie.CategoricalConversion
                    @test dc_args[i] isa Categorical
                    @test keys(dc.category_to_int[]) == Set(dc_args[i].values)
                elseif dc isa Makie.UnitfulConversion
                    @test !(dc_args[i] isa Categorical)
                    @test dc.unit[] == Unitful.unit(get_value(dc_args[i]))
                elseif dc isa Makie.NoDimConversion
                    @test !(dc_args[i] isa Categorical)
                    # @test !(dc_args[i] isa UnitfulThing)
                    @test eltype(dc_args[i]) <: Real
                    @test !isnothing(dc_args[i])
                elseif dc isa Nothing
                    @test nothing === dc_args[i]
                else
                    error("Did not implement $(typeof(dc))")
                end
            end
        end
    end

    # Skipped:
    # - ablines
    # - arc
    # - axis
    # - LineSegmentBuffer, TextBuffer
    # - datashader
    # - pie
    # - rainclouds

    # dims are always on the next line so they are easier to see

    # TODO: Primitives
    @testset "Primitives" begin
        test_plot(heatmap, (1:5) .* u"s", Categorical(["A", "B"]), rand(5, 2))
        test_plot(image, 0u"m" .. 1u"m", 0 .. 1, rand(10, 10))
        test_plot(
            surface, (1:5) .* u"m", (1:5) .* u"cm", rand(5, 5) .* u"W",
            dims = (1, 2, 3)
        )
        test_plot(scatter, Categorical(["A", "C", "D"]), (1:3) .* u"N")
        test_plot(meshscatter, (1:3) .* u"m", (1:3) .* u"cm")
        test_plot(lines, (1:3) .* u"s", Categorical(["A", "C", "D"]))
        test_plot(linesegments, (4:-1:1) .* u"s", (1:4) .* u"N")
        test_plot(text, 1u"m", 1u"s", text = "here")
        test_plot(
            volume, 0u"m" .. 1u"m", 0u"g" .. 1u"g", 0u"s" .. 1u"s", rand(10, 10, 10),
            dims = (1, 2, 3)
        )
        test_plot(
            mesh, rand(5) .* u"m", rand(5) .* u"s", rand(5) .* u"g",
            dims = (1, 2, 3)
        )
        test_plot(
            voxels, 0u"m" .. 1u"m", 0u"g" .. 1u"g", 0u"s" .. 1u"s", rand(10, 10, 10),
            dims = (1, 2, 3)
        )
    end

    # Recipes (basic_recipes)
    @testset "Basic Recipes" begin
        test_plot(annotation, Categorical(["A", "B", "E"]), (1:3) .* u"m", text = ["one", "two", "three"])
        test_plot(
            arrows2d, (1:5) .* u"m", 1:5, (0.1:0.1:0.5) .* u"m", zeros(5),
            dims = (1, 2, 1, 2)
        )
        # test_plot(band, 1:4, Categorical(["A", "A", "B", "B"]), Categorical(["D", "D", "C", "C"])) # Broken
        test_plot(
            band, Categorical(["A", "B", "C", "D"]), rand(4) .* u"cm", rand(4) .* u"m",
            dims = (1, 2, 2)
        )
        test_plot(
            band, Categorical(["A", "B", "C", "D"]), rand(4) .* u"cm", rand(4) .* u"m", direction = :y,
            dims = (2, 1, 1)
        )
        test_plot(
            barplot,
            Categorical(["A", "B"][mod1.(1:20, 2)]), rand(20) .* u"m",
            stack = fld1.(1:20, 2), color = fld1.(1:20, 2)
        )
        test_plot(
            bracket, 1u"m", 0, 1u"m", 2,
            dims = (1, 2, 1, 2)
        )
        test_plot(
            bracket, 1u"m", 0u"s", 1u"m", 2u"s",
            dims = (1, 2, 1, 2)
        )
        test_plot(contourf, (1:10) .* u"m", (1:10) .* u"s", rand(10, 10))
        test_plot(contour, (1:10) .* u"m", (1:10) .* u"s", rand(10, 10))
        test_plot(
            contour, 0u"m" .. 1u"m", 0u"s" .. 1u"s", 0 .. 1, rand(10, 10, 10),
            dims = (1, 2, 3)
        )

        test_plot(
            errorbars, 1:3, (1:3) .* u"m", (1:3) .* u"dm",
            dims = (1, 2, 2)
        )
        test_plot(
            rangebars, 1:3, (1:3) .* u"cm", (1:3) .* u"dm",
            dims = (1, 2, 2)
        )
        test_plot(
            errorbars, (1:3) .* u"m", (1:3), (1:3) .* u"dm", direction = :x,
            dims = (1, 2, 1)
        )
        test_plot(
            rangebars, 1:3, (1:3) .* u"cm", (1:3) .* u"dm", direction = :x,
            dims = (2, 1, 1)
        )

        test_plot(
            hlines, rand(3) .* u"m",
            dims = (2,)
        )
        test_plot(
            vlines, Categorical(["A", "C", "D"]),
            dims = (1,)
        )
        test_plot(
            vspan, 1u"m", 2u"m",
            dims = (1, 1)
        )
        test_plot(
            hspan, 1u"m", 2u"m",
            dims = (2, 2)
        )

        test_plot(poly, rand(10) .* u"m", rand(10) .* u"s")
        test_plot(scatterlines, rand(10) .* u"m", rand(10) .* u"s")
        test_plot(series, rand(10) .* u"m", rand(3, 10) .* u"s")
        test_plot(spy, 1u"m" .. 10u"m", 1u"s" .. 10u"s", rand(10, 10))
        test_plot(stairs, rand(10) .* u"m", rand(10) .* u"s")
        test_plot(stem, rand(10) .* u"m", rand(10) .* u"s")
        test_plot(
            streamplot, p -> p, 0u"m" .. 1u"m", (1:10) .* u"s",
            dims = (0, 1, 2)
        )
        test_plot(textlabel, rand(10), rand(10) .* u"m", text = string.(1:10))
        test_plot(
            timeseries, 1.0 * u"µm",
            dims = (2,)
        )
        test_plot(tooltip, 1, 2u"m", text = "woo")
        test_plot(tricontourf, rand(10), rand(10) .* u"m", rand(10))
        test_plot(voronoiplot, rand(10), rand(10) .* u"m")
        test_plot(voronoiplot, rand(10), rand(10) .* u"m", rand(10))
        test_plot(waterfall, 1:10, rand(10) .* u"m")
        # test_plot(waterfall, rand(10) .* u"m") # test doesn't handle expand_arguments()
    end

    @testset "stats plots" begin
        test_plot(
            boxplot, Categorical(rand(["A", "B"], 10)), rand(10) .* u"m",
            dims = (1, 2)
        )

        test_plot(
            crossbar, Categorical(["A", "B", "C", "D"]), rand(4) .* u"m",
            (rand(4) .- 1) .* u"m", (rand(4) .+ 1) .* u"m",
            orientation = :vertical,
            dims = (1, 2, 2, 2)
        )
        test_plot(
            crossbar, Categorical(["A", "B", "C", "D"]), rand(4) .* u"m",
            (rand(4) .- 1) .* u"m", (rand(4) .+ 1) .* u"m",
            orientation = :horizontal,
            dims = (2, 1, 1, 1)
        )

        # probably doesn't make sense but it works...
        test_plot(dendrogram, (1:16) .* u"m", rand(16) .* u"s", [(2i - 1, 2i) for i in 1:15])

        test_plot(
            density, rand(100) .* u"s",
            dims = (1,)
        )
        test_plot(
            density, rand(100) .* u"s", direction = :y,
            dims = (2,)
        )

        test_plot(qqplot, rand(100) .* u"m", rand(100) .* u"cm")
        # qqplot(rand(100) .* u"cm", rand(100)) # doesn't work, shouldn't work?
        test_plot(
            qqnorm, rand(100) .* u"cm",
            dims = (2,)
        )
        test_plot(
            ecdfplot, 10 .* rand(100) .* u"m",
            dims = (1,)
        )

        test_plot(hexbin, rand(10) .* u"m", rand(10) .* u"s")
        test_plot(
            stephist, rand(100) .* u"g",
            dims = (1,)
        )
        test_plot(
            hist, rand(100) .* u"g",
            dims = (1,)
        )
        test_plot(
            hist, rand(100) .* u"g", direction = :x,
            dims = (2,)
        )
        test_plot(violin, Categorical(rand(["A", "B"], 100)), rand(100) .* u"s")
        test_plot(
            violin, Categorical(rand(["A", "B"], 100)), rand(100) .* u"s", orientation = :horizontal,
            dims = (2, 1)
        )
    end

    # Sample plots that allow unique Point[] args
    @testset "point-like conversions" begin
        # PointBased() with different input types
        x = rand(10) * u"s"
        y = rand(10) * u"m"
        test_plot(scatter, collect(zip(x, y)), dims = ((1, 2),))
        test_plot(barplot, Vec.(x, y), direction = :x, dims = ((2, 1),))
        test_plot(scatterlines, Point.(x, y, y), dims = ((1, 2, 3),))

        # Other independent cases
        ps = Point.(x, y)
        test_plot(annotation, ps, text = string.(1:10), dims = ((1, 2),))
        test_plot(annotation, ps, ps, text = string.(1:10), dims = ((1, 2, 1, 2),))
        test_plot(arrows2d, ps, ps, dims = ((1, 2), (1, 2),))
        test_plot(bracket, ps, ps, dims = ((1, 2), (1, 2),))
        test_plot(errorbars, ps, y, dims = ((1, 2), 2,))
        test_plot(errorbars, ps, Vec.(y, y), dims = ((1, 2), (2, 2),))
        test_plot(errorbars, Point.(x, y, x), direction = :x, dims = ((1, 2, 1),))
        test_plot(errorbars, Point.(x, y, x, x), direction = :x, dims = ((1, 2, 1, 1),))
        test_plot(rangebars, x, tuple.(y, y), dims = (1, (2, 2),))
        test_plot(rangebars, tuple.(x, y, y), dims = ((1, 2, 2),))
        test_plot(poly, ps, 1:9, dims = ((1, 2),))
        test_plot(dendrogram, ps, [(i, i+1) for i in 1:2:13], dims = ((1, 2),))
    end
end
