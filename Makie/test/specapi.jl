import Makie.SpecApi as S

@testset "diffing" begin
    @testset "update_plot!" begin
        obs = Observable[]
        oldspec = S.Scatter(1:4; cycle=[])
        newspec = S.Scatter(1:4; cycle=[])
        p = Makie.to_plot_object(newspec)
        s = Scene()
        plot!(s, p)
        Makie.update_plot!(obs, p, oldspec, newspec)
        @test isempty(obs)

        newspec = S.Scatter(1:4; color=:red)
        Makie.update_plot!(obs, p, oldspec, newspec)
        oldspec = newspec
        @test length(obs) == 1
        @test obs[1] === p.color

        newspec = S.Scatter(1:4; color=:green, cycle=[])
        empty!(obs)
        Makie.update_plot!(obs, p, oldspec, newspec)
        oldspec = newspec
        @test length(obs) == 1
        @test obs[1] === p.color
        @test obs[1].val == to_color(:green)

        newspec = S.Scatter(1:5; color=:green, cycle=[])
        empty!(obs)
        Makie.update_plot!(obs, p, oldspec, newspec)
        oldspec = newspec
        @test length(obs) == 1
        @test obs[1] === p.args[1]

        oldspec = S.Scatter(1:5; color=:green, marker=:rect, cycle=[])
        newspec = S.Scatter(1:4; color=:red, marker=:circle, cycle=[])
        empty!(obs)
        p = Makie.to_plot_object(oldspec)
        s = Scene()
        plot!(s, p)
        Makie.update_plot!(obs, p, oldspec, newspec)
        @test length(obs) == 3
        @test obs[1] === p.args[1]
        @test obs[2] === p.color
        @test obs[3] === p.marker
    end

    @testset "diff_plotlist!" begin
        scene = Scene();
        plotspecs = [S.Scatter(1:4; color=:red), S.Scatter(1:4; color=:red)]
        reusable_plots = IdDict{PlotSpec,Plot}()
        obs_to_notify = Observable[]
        new_plots = Makie.diff_plotlist!(scene, plotspecs, obs_to_notify, reusable_plots)
        @test length(new_plots) == 2
        @test Set(scene.plots) == Set(values(new_plots))
        @test isempty(obs_to_notify)

        new_plots2 = Makie.diff_plotlist!(scene, plotspecs, obs_to_notify, new_plots)

        @test isempty(new_plots) # they got all used up
        @test Set(scene.plots) == Set(values(new_plots2))
        @test isempty(obs_to_notify)

        plotspecs = [S.Scatter(1:4; color=:yellow), S.Scatter(1:4; color=:green)]
        new_plots3 = Makie.diff_plotlist!(scene, plotspecs, obs_to_notify, new_plots2)

        @test isempty(new_plots) # they got all used up
        @test Set(scene.plots) == Set(values(new_plots3))
        # TODO, and some point we should try to find the matching plot and just
        # switch them, so we don't need an update!
        @test Set(obs_to_notify) == Set([scene.plots[1].color, scene.plots[2].color])
    end
end

struct TestPlot
end
function Makie.convert_arguments(P::Type{<:Plot}, ::TestPlot)
    return PlotSpec(P, Point2f.(1:5, 1:5); color=1:5, cycle=[])
end

@testset "PlotSpec with attributes in convert_arguments" begin
    f, ax, pl = scatter(TestPlot())
    @test pl.color[] == 1:5
    pl.color = [0, 1, 2, 3, 4]
    @test pl.color[] == [0, 1, 2, 3, 4]
    f, ax, pl = lines(TestPlot())
    @test pl.color[] == 1:5
    pl.color = [0, 1, 2, 3, 4]
    @test pl.color[] == [0, 1, 2, 3, 4]
end


@testset "Specapi and Dim conversions" begin
    f, ax, pl = plot(S.GridLayout([S.Axis(; plots=[S.Scatter(1:4, Categorical(["a", "b", "c", "d"]); markersize=20)])]))
    # make sure ticks change correctly
    p = scatter!(1:2, Categorical(["x", "y"]); markersize=20)
    ax = current_axis()
    conversion = Makie.get_conversions(ax)
    pconversion = Makie.get_conversions(p)

    @test conversion == pconversion
    @test conversion[2] isa Makie.CategoricalConversion
    @test ax.dim2_conversion[] isa Makie.CategoricalConversion
    f
end

struct ForwardAllAttributes end
function Makie.convert_arguments(::Type{Lines}, ::ForwardAllAttributes; kwargs...)
    return S.Lines([1, 2, 3], [1, 2, 3]; kwargs...)
end
Makie.used_attributes(T::Type{<:Plot}, ::ForwardAllAttributes) = (Makie.attribute_names(T)...,)
@testset "Forward all attribute without error" begin
    f, ax, pl = lines(ForwardAllAttributes(); color=:red)
    @test pl.color[] == to_color(:red)
end

struct UsedAttributesStairs
    a::Vector{Int}
    b::Vector{Int}
end

Makie.used_attributes(::Type{<:Stairs}, h::UsedAttributesStairs) = (:clamp_bincounts,)
function Makie.convert_arguments(P::Type{<:Stairs}, h::UsedAttributesStairs; clamp_bincounts=false)
    return convert_arguments(P, h.a, h.b)
end

@testset "Used attributes with stair plot" begin
    f, ax, pl = stairs(UsedAttributesStairs([1, 2, 3], [1, 2, 3]))
    @test !haskey(pl, :clamp_bincounts)
    @test !haskey(pl.plots[1], :clamp_bincounts)
end
