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
        new_plots = Makie.diff_plotlist!(scene, plotspecs, obs_to_notify, nothing, reusable_plots)
        @test length(new_plots) == 2
        @test Set(scene.plots) == Set(values(new_plots))
        @test isempty(obs_to_notify)

        new_plots2 = Makie.diff_plotlist!(scene, plotspecs, obs_to_notify, nothing, new_plots)

        @test isempty(new_plots) # they got all used up
        @test Set(scene.plots) == Set(values(new_plots2))
        @test isempty(obs_to_notify)

        plotspecs = [S.Scatter(1:4; color=:yellow), S.Scatter(1:4; color=:green)]
        new_plots3 = Makie.diff_plotlist!(scene, plotspecs, obs_to_notify, nothing, new_plots2)

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

@testset "then observer clean up" begin
    ax = S.Axis(title="interaction")
    ax.then(axis-> on(println, events(axis).mouseposition))
    gl = S.GridLayout(ax)

    f, _, pl = plot(gl)
    real_ax = f.content[1]
    mpos = events(real_ax).mouseposition
    @test length(mpos.listeners) == 2
    @test mpos.listeners[end][2] === println
    @test length(ax.then_observers) == 1
    @test first(ax.then_observers).f === println

    pl[1] = S.GridLayout(S.Axis(title="interaction"))
    @test real_ax === f.content[1] # re-use axis
    @test length(mpos.listeners) == 1
    @test mpos.listeners[1][2] !== println
end

@testset "Blockspec re-use" begin
    ax1 = S.Axis(; title="Title 1")
    ax2 = S.Axis(; title="Title 2")
    ax3 = S.Axis(; title="Title 3")
    axes = [ax1, ax2, ax3]
    gl = S.GridLayout(axes)
    f, _, pl = plot(gl)
    real_axes = copy(f.content[1:3])
    @test map(x-> x.title[], real_axes) == ["Title $i" for i in 1:3]
    pl[1] = S.GridLayout(reverse(axes))
    rev_axes = copy(f.content[1:3])
    c_axes = map(x-> x.content, f.layout.content)
    # Axis don't get reversed, we only update the titles
    @test rev_axes == c_axes
    @test map(x-> x.title[], rev_axes) == reverse(["Title $i" for i in 1:3])
    @test all(((a, b),) -> a === b, zip(rev_axes, real_axes))
    @test all(((a, b),) -> a.title[] == b.title[], zip(rev_axes, real_axes))
    pl[1] =  S.GridLayout()
    @test isempty(f.content)
    @test isempty(f.layout.content)
end

@testset "Legend construction" begin
    f, ax, pl = plotlist([S.Scatter(1:4, 1:4; marker = :circle, label="A"), S.Scatter(1:6, 1:6; marker = :rect, label="B")])
    leg = axislegend(ax)
    # Test that the legend has two scatter plots
    @test count(x -> x isa Makie.Scatter, leg.scene.plots) == 2

    # Test that the scatter plots have the correct markers
    # This is too internal and fragile, so we won't actually test this
    # @test leg.scene.plots[2].marker[] == :circle
    # @test leg.scene.plots[3].marker[] == :rect

    # Test that the legend has the correct labels.
    # Again, I consider this too fragile to work with!
    # @test contents(contents(leg.grid)[1])[2].text[] == "A"
    # @test contents(contents(leg.grid)[2])[4].text[] == "B"
end

@recipe(TestRecipeForSpecApi) do scene
    return Attributes()
end

@testset "External Recipe compatibility (#4295)" begin
    @test_nowarn S.TestRecipeForSpecApi
    @test_nowarn S.TestRecipeForSpecApi(1, 2, 3; a = 4, b = 5)
end

@enum Directions North East South West

@testset "Enums" begin
    xvals = [North, East, South, West]
    f, ax, pl = barplot(xvals, [1, 2, 3, 4])
    # The value a categorical conversion maps to is somewhat arbitrary, so to make the test robust we
    # best use the actual look up
    vals = Makie.convert_dim_value.((ax.dim1_conversion[],), xvals)
    @test first.(pl.converted[1][]) == vals[sortperm(xvals)] # sorted by ENUM value
    # test y values and expand_dimensions too
    f, ax, pl = barplot(xvals)
    vals = Makie.convert_dim_value.((ax.dim2_conversion[],), xvals)
    @test last.(pl.converted[1][]) == vals[sortperm(xvals)] # sorted by ENUM value
end
