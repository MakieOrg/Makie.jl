import Makie.SpecApi as S
using Makie.ComputePipeline

function resolve_all!(plot)
    for (k, v) in plot.attributes.outputs
        v[]
    end
    return
end
# Track the changes from the backends view (we prune updates that don't actually change anything)
function all_changes!(plot)
    all_outputs = collect(keys(plot.attributes.outputs))
    return register_computation!(plot.attributes, all_outputs, [:changed]) do attr, changeset, _
        res = Dict{Symbol, Any}()
        for k in keys(attr)
            changeset[k] && (res[k] = attr[k])
        end
        return (res,)
    end
end
# This is a simpler version of the above, but isdirty(x) is conservative
# And is true for any computed value depending on a dirty input.
function check_changed(plot, changed)
    for (k, v) in plot.attributes.outputs
        @testset "changed $k" begin
            if haskey(changed, k)
                @test ComputePipeline.isdirty(v)
                @test changed[k] == v[]
            else
                @test !ComputePipeline.isdirty(v)
            end
        end
    end
    return
end

@testset "diffing" begin
    @testset "update_plot!" begin
        oldspec = S.Scatter(1:4; cycle = [])
        newspec = S.Scatter(1:4; cycle = [])

        p = Makie.to_plot_object(newspec)
        s = Scene()
        plot!(s, p)
        resolve_all!(s.plots[1])
        updated = Makie.update_plot!(p, oldspec, newspec)


        oldspec = S.Scatter(1:4; cycle = [])
        newspec = S.Scatter(1:4; cycle = [])
        p = Makie.to_plot_object(newspec)
        s = Scene()
        plot!(s, p)
        all_changes!(s.plots[1])
        s.plots[1].changed[] |> empty! # fetch one time, to initialize
        updated = Makie.update_plot!(p, oldspec, newspec)
        @test isempty(updated)
        @test isempty(s.plots[1].changed[])
        newspec = S.Scatter(1:4; color = :red, cycle = [])
        updated = Makie.update_plot!(p, oldspec, newspec)
        oldspec = newspec
        @test updated == [:color => to_color(:red)]
        @test s.plots[1].changed[] == Dict(:color => to_color(:red), :raw_color => to_color(:red), :scaled_color => to_color(:red))
        newspec = S.Scatter(1:4; color = :green, cycle = [])
        updated = Makie.update_plot!(p, oldspec, newspec)
        oldspec = newspec
        @test updated == [:color => to_color(:green)]
        @test s.plots[1].changed[] == Dict(:color => to_color(:green), :raw_color => to_color(:green), :scaled_color => to_color(:green))
        newspec = S.Scatter(1:5; color = :green, cycle = [])
        updates = Makie.update_plot!(p, oldspec, newspec)
        oldspec = newspec
        @test s.plots[1].args[][1] == Dict(updates)[:arg1]
        oldspec = S.Scatter(1:5; color = :green, marker = :rect, cycle = [])
        newspec = S.Scatter(1:4; color = :red, marker = :circle, cycle = [])
        p = Makie.to_plot_object(oldspec)
        s = Scene()
        plot!(s, p)
        updates = Dict(Makie.update_plot!(p, oldspec, newspec))
        @test updates[:arg1] == p.arg1[]
        @test updates[:color] == p.color[]
        @test Makie.to_spritemarker(updates[:marker]) == p.marker[]
    end

    @testset "diff_plotlist!" begin
        scene = Scene()
        plotspecs = [S.Scatter(1:4; color = :red), S.Scatter(1:4; color = :red)]
        reusable_plots = IdDict{PlotSpec, Plot}()
        obs_to_notify = Observable[]
        new_plots = Makie.diff_plotlist!(scene, plotspecs, nothing, reusable_plots)
        @test length(new_plots) == 2
        @test Set(scene.plots) == Set(values(new_plots))

        foreach(plot -> resolve_all!(plot), scene.plots)
        new_plots2 = Makie.diff_plotlist!(scene, plotspecs, nothing, new_plots)

        @test isempty(new_plots) # they got all used up
        @test Set(scene.plots) == Set(values(new_plots2))
        check_changed(scene.plots[1], (;)) # changed without updating anything
        check_changed(scene.plots[2], (;)) # changed without updating anything

        plotspecs = [S.Scatter(1:4; color = :yellow), S.Scatter(1:4; color = :green)]
        plot1 = scene.plots[1]
        plot2 = scene.plots[2]
        all_changes!(plot1)
        all_changes!(plot2)
        plot1.changed[] # resolve once, all attributes will be changed on first resolve
        plot2.changed[]
        new_plots3 = Makie.diff_plotlist!(scene, plotspecs, nothing, new_plots2)

        @test isempty(new_plots) # they got all used up
        @test Set(scene.plots) == Set(values(new_plots3))
        yellow = to_color(:yellow)
        green = to_color(:green)
        plot1.changed[] == Dict(:color => yellow, :raw_color => yellow, :scaled_color => yellow)
        plot2.changed[] == Dict(:color => green, :raw_color => green, :scaled_color => green)
    end
end

struct TestPlot
end
function Makie.convert_arguments(P::Type{<:Plot}, ::TestPlot)
    return PlotSpec(P, Point2f.(1:5, 1:5); color = 1:5, cycle = [])
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
    f, ax, pl = plot(S.GridLayout([S.Axis(; plots = [S.Scatter(1:4, Categorical(["a", "b", "c", "d"]); markersize = 20)])]))
    # make sure ticks change correctly
    p = scatter!(1:2, Categorical(["x", "y"]); markersize = 20)
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

function Makie.used_attributes(T::Type{<:Plot}, ::ForwardAllAttributes)
    return (Makie.flattened_keys(Makie.documented_attributes(T))...,)
end

@testset "Forward all attribute without error" begin
    f, ax, pl = lines(ForwardAllAttributes(); color = :red)
    @test pl.color[] == :red
end

struct UsedAttributesStairs
    a::Vector{Int}
    b::Vector{Int}
end

Makie.used_attributes(::Type{<:Stairs}, h::UsedAttributesStairs) = (:clamp_bincounts,)
function Makie.convert_arguments(P::Type{<:Stairs}, h::UsedAttributesStairs; clamp_bincounts = false)
    return convert_arguments(P, h.a, h.b)
end

@testset "Used attributes with stair plot" begin
    f, ax, pl = stairs(UsedAttributesStairs([1, 2, 3], [1, 2, 3]))
    @test haskey(pl, :clamp_bincounts)
    @test !haskey(pl.plots[1], :clamp_bincounts)
end

@testset "then observer clean up" begin
    ax = S.Axis(title = "interaction")
    ax.then(axis -> on(println, events(axis).mouseposition))
    gl = S.GridLayout(ax)
    @test gl.content[1][2] === ax
    f, _, pl = plot(gl)
    real_ax = f.content[1]
    mpos = events(real_ax).mouseposition
    @test length(mpos.listeners) == 2
    @test mpos.listeners[end][2] === println
    @test length(ax.then_observers) == 1
    @test first(ax.then_observers).f === println

    pl[1] = S.GridLayout(S.Axis(title = "interaction"))
    @test real_ax === f.content[1] # reuse axis
    @test length(mpos.listeners) == 1
    @test mpos.listeners[1][2] !== println
end

@testset "Blockspec reuse" begin
    ax1 = S.Axis(; title = "Title 1")
    ax2 = S.Axis(; title = "Title 2")
    ax3 = S.Axis(; title = "Title 3")
    axes = [ax1, ax2, ax3]
    gl = S.GridLayout(axes)
    f, _, pl = plot(gl)
    real_axes = copy(f.content[1:3])
    @test map(x -> x.title[], real_axes) == ["Title $i" for i in 1:3]
    pl[1] = S.GridLayout(reverse(axes))
    rev_axes = copy(f.content[1:3])
    c_axes = map(x -> x.content, f.layout.content)
    # Axis don't get reversed, we only update the titles
    @test rev_axes == c_axes
    @test map(x -> x.title[], rev_axes) == reverse(["Title $i" for i in 1:3])
    @test all(((a, b),) -> a === b, zip(rev_axes, real_axes))
    @test all(((a, b),) -> a.title[] == b.title[], zip(rev_axes, real_axes))
    pl[1] = S.GridLayout()
    @test isempty(f.content)
    @test isempty(f.layout.content)
end

@testset "Legend construction" begin
    f, ax, pl = plotlist([S.Scatter(1:4, 1:4; marker = :circle, label = "A"), S.Scatter(1:6, 1:6; marker = :rect, label = "B")])
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
    @test first.(pl.converted[][1]) == vals[sortperm(xvals)] # sorted by ENUM value
    # test y values and expand_dimensions too
    f, ax, pl = barplot(xvals)
    vals = Makie.convert_dim_value.((ax.dim2_conversion[],), xvals)
    @test last.(pl.converted[][1]) == vals[sortperm(xvals)] # sorted by ENUM value
end

@testset "axis links" begin
    axisspecs = [S.Axis(title = "$i,$j", plots = [S.Scatter((i .+ j) .+ (1:3), (i .+ j) .+ (1:3))]) for i in 1:2, j in 1:2]

    x_eachrow = Observable(true)
    gridspec = lift(x_eachrow) do x_eachrow
        S.GridLayout(axisspecs, xaxislinks = (x_eachrow ? eachrow : eachcol)(axisspecs), yaxislinks = (x_eachrow ? eachcol : eachrow)(axisspecs))
    end

    fig, _ = plot(gridspec)

    axes = [content(fig[i, j]) for i in 1:2, j in 1:2]
    for v in eachrow(axes)
        @test all(v) do ax
            Set(ax.xaxislinks) == Set(v)
        end
    end
    for v in eachcol(axes)
        @test all(v) do ax
            Set(ax.yaxislinks) == Set(v)
        end
    end

    x_eachrow[] = false

    # now the links are flipped

    for v in eachcol(axes)
        @test all(v) do ax
            Set(ax.xaxislinks) == Set(v)
        end
    end
    for v in eachrow(axes)
        @test all(v) do ax
            Set(ax.yaxislinks) == Set(v)
        end
    end

    # test single vector as well

    axisspecs2 = [S.Axis(title = "$i,$j", plots = [S.Scatter((i .+ j) .+ (1:3), (i .+ j) .+ (1:3))]) for i in 1:2, j in 1:2]
    gridspec2 = S.GridLayout(axisspecs2, xaxislinks = first(eachrow(axisspecs2)), yaxislinks = first(eachcol(axisspecs2)))
    fig, _ = plot(gridspec2)
    axes2 = [content(fig[i, j]) for i in 1:2, j in 1:2]

    for (i, v) in enumerate(eachrow(axes2))
        @test all(v) do ax
            Set(ax.xaxislinks) == (i == 1 ? Set(v) : Set([]))
        end
    end
    for (i, v) in enumerate(eachcol(axes2))
        @test all(v) do ax
            Set(ax.yaxislinks) == (i == 1 ? Set(v) : Set([]))
        end
    end
end

@testset "GridLayout deletion" begin
    # this should not error
    @test begin
        obs = Observable(
            S.GridLayout(
                [
                S.Box(color = :red) S.GridLayout([S.Box(color = :blue)])
                ]
            )
        )
        f, a, p = plot(obs)
        obs[] = S.GridLayout([S.Box(color = :lightgray)])
        true
    end
end

@testset "SpecApi in Blocks" begin
    obs = Observable{Any}(S.Box())
    fig, block = Block(obs)
    @test !isnothing(block.layout)
    @test length(block.layout.content) == 1
    box = block.layout.content[1].content
    @test box isa Box
    @test block.blocks == [box]

    obs[] = S.GridLayout([S.Label(text = "a") S.Label(text = "b")])
    @test length(block.layout.content) == 2
    lbl1, lbl2 = map(x -> x.content, block.layout.content)
    @test lbl1 isa Label
    @test lbl2 isa Label
    @test block.blocks == [lbl1, lbl2]
end

function collect_cycle_indices(plots, indices = Int[])
    for p in plots
        if p isa PlotList
            collect_cycle_indices(p.plots, indices)
        else
            # Pulling plot.cycle_index is what initializes cycling and increments
            # the scenes cycle counter(s). If we do it here we will not catch
            # incorrect intiialization.
            cycle = p.cycle[]
            for key in Makie.attrsyms(cycle)
                p.attributes[key][]
            end
            if Makie.ComputePipeline.isdirty(p.cycle_index)
                push!(indices, -1)
            else
                push!(indices, p.cycle_index[])
            end
        end
    end
    return indices
end

@testset "plotlist cycling" begin
    inputs = [
        [S.Scatter(fill(i + 1, 5), 1:5) for i in 1:3],
        [S.Scatter(fill(i + 1, 5), 1:5) for i in 1:7],
        [S.Scatter(fill(i + 1, 5), 1:5) for i in 1:3],
        [S.Scatter(fill(i + 1, 5), 1:5) for i in 1:2],
        [S.Scatter(fill(i + 1, 5), 1:5) for i in 1:3],
    ]

    f = Figure(size = (500, 1000))

    pls = []
    for j in 1:5
        # later update
        scatter(f[j, 1], fill(1, 5), (1:5), marker = Rect)
        p = plotlist!(inputs[1])
        push!(pls, p)
        scatter!(fill(9, 5), (1:5), marker = Rect)

        # direct init
        scatter(f[j, 2], fill(1, 5), (1:5), marker = Rect)
        plotlist!(inputs[j])
        scatter!(fill(9, 5), (1:5), marker = Rect)
    end

    # update column
    for i in 1:5
        indices = collect_cycle_indices(f.content[2i - 1].scene.plots)
        @test indices == [1, 2, 3, 4, 5]
    end

    # init column
    # indices will collect from: [scatter, plotlist.plots..., scatter]
    indices = collect_cycle_indices(f.content[2].scene.plots)
    @test indices == [1, 2, 3, 4, 5]
    indices = collect_cycle_indices(f.content[4].scene.plots)
    @test indices == collect(1:9)
    indices = collect_cycle_indices(f.content[6].scene.plots)
    @test indices == [1, 2, 3, 4, 5]
    indices = collect_cycle_indices(f.content[8].scene.plots)
    @test indices == [1, 2, 3, 4]
    indices = collect_cycle_indices(f.content[10].scene.plots)
    @test indices == [1, 2, 3, 4, 5]

    # successively update plotlists to check how they affect cycle indices
    for i in 1:5
        for j in i:5
            pls[j].arg1 = inputs[i]
        end
    end

    # update column
    indices = collect_cycle_indices(f.content[1].scene.plots)
    @test indices == [1, 2, 3, 4, 5]
    indices = collect_cycle_indices(f.content[3].scene.plots)
    @test indices == [1, 2, 3, 4, 6, 7, 8, 9, 5]
    # ^ 5 existed before and we currently don't update other cycle indices as
    # side effects, so we get a jump from 4 -> 6 in the plotlist plots
    indices = collect_cycle_indices(f.content[5].scene.plots)
    @test indices == [1, 2, 3, 4, 5]
    indices = collect_cycle_indices(f.content[7].scene.plots)
    @test indices == [1, 2, 3, 5]
    indices = collect_cycle_indices(f.content[9].scene.plots)
    @test indices == [1, 2, 3, 6, 5]
    # ^ would be nice if this was 1:5 again, but the plotlist currently doesn't
    # know that 4 is available

    # init column - should be unaffected
    indices = collect_cycle_indices(f.content[2].scene.plots)
    @test indices == [1, 2, 3, 4, 5]
    indices = collect_cycle_indices(f.content[4].scene.plots)
    @test indices == collect(1:9)
    indices = collect_cycle_indices(f.content[6].scene.plots)
    @test indices == [1, 2, 3, 4, 5]
    indices = collect_cycle_indices(f.content[8].scene.plots)
    @test indices == [1, 2, 3, 4]
    indices = collect_cycle_indices(f.content[10].scene.plots)
    @test indices == [1, 2, 3, 4, 5]

    f
end
