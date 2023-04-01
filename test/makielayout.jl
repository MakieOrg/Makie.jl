# Minimal sanity checks for Makie Layout
@testset "Blocks constructors" begin
    fig = Figure()
    ax = Axis(fig[1, 1])
    cb = Colorbar(fig[1, 2])
    gl2 = fig[2, :] = Makie.GridLayout()
    bu = gl2[1, 1] = Button(fig)
    sl = gl2[1, 2] = Slider(fig)

    scat = scatter!(ax, rand(10))
    le = gl2[1, 3] = Legend(fig, [scat], ["scatter"])

    to = gl2[1, 4] = Toggle(fig)
    te = fig[0, :] = Label(fig, "A super title")
    me = fig[end + 1, :] = Menu(fig, options=["one", "two", "three"])
    tb = fig[end + 1, :] = Textbox(fig)
    is = fig[end + 1, :] = IntervalSlider(fig)
    @test true
end

@testset "deleting from axis" begin
    f = Figure()
    ax = Axis(f[1, 1])
    sc = scatter!(ax, randn(100, 2))
    li = lines!(ax, randn(100, 2))
    hm = heatmap!(ax, randn(20, 20))
    # axis contains 3 plots
    @test length(ax.scene.plots) == 3
    delete!(ax, sc)
    @test length(ax.scene.plots) == 2
    @test sc ∉ ax.scene.plots
    empty!(ax)
    @test isempty(ax.scene.plots)
end

@testset "zero heatmap" begin
    xs = LinRange(0, 20, 10)
    ys = LinRange(0, 15, 10)
    zs = zeros(length(xs), length(ys))

    fig = Figure()
    _, hm = heatmap(fig[1, 1], xs, ys, zs)
    cb = Colorbar(fig[1, 2], hm)

    @test hm.attributes[:colorrange][] == Vec(-.5, .5)
    @test cb.limits[] == Vec(-.5, .5)

    hm.attributes[:colorrange][] = Float32.((-1, 1))
    @test cb.limits[] == (-1, 1)

    # TODO: This doesn't work anymore because colorbar doesn't use the same observable
    # cb.limits[] = Float32.((-2, 2))
    # @test hm.attributes[:colorrange][] == (-2, 2)
end

@testset "Axis limits basics" begin
    f = Figure()
    ax = Axis(f[1, 1], limits = (nothing, nothing))
    ax.targetlimits[] = BBox(0, 10, 0, 20)
    @test ax.finallimits[] == BBox(0, 10, 0, 20)
    @test ax.limits[] == (nothing, nothing)
    xlims!(ax, -10, 10)
    @test ax.limits[] == ((-10, 10), nothing)
    @test ax.finallimits[] == BBox(-10, 10, 0, 20)
    ylims!(ax, -20, 30)
    @test ax.limits[] == ((-10, 10), (-20, 30))
    @test ax.finallimits[] == BBox(-10, 10, -20, 30)
    limits!(ax, -5, 5, -10, 10)
    @test ax.finallimits[] == BBox(-5, 5, -10, 10)
    @test ax.limits[] == ((-5, 5), (-10, 10))
    ax.limits[] = (nothing, nothing)
    ax.xautolimitmargin = (0, 0)
    ax.yautolimitmargin = (0, 0)
    scatter!(Point2f[(0, 0), (1, 2)])
    reset_limits!(ax)
    @test ax.limits[] == (nothing, nothing)
    @test ax.targetlimits[] == BBox(0, 1, 0, 2)
    @test ax.finallimits[] == BBox(0, 1, 0, 2)
    scatter!(Point2f(3, 4))
    reset_limits!(ax)
    @test ax.limits[] == (nothing, nothing)
    @test ax.targetlimits[] == BBox(0, 3, 0, 4)
    @test ax.finallimits[] == BBox(0, 3, 0, 4)
    limits!(ax, -1, 1, 0, 2)
    @test ax.limits[] == ((-1, 1), (0, 2))
    @test ax.targetlimits[] == BBox(-1, 1, 0, 2)
    @test ax.finallimits[] == BBox(-1, 1, 0, 2)
    scatter!(Point2f(5, 6))
    reset_limits!(ax)
    @test ax.limits[] == ((-1, 1), (0, 2))
    @test ax.targetlimits[] == BBox(-1, 1, 0, 2)
    @test ax.finallimits[] == BBox(-1, 1, 0, 2)
    autolimits!(ax)
    @test ax.limits[] == (nothing, nothing)
    @test ax.targetlimits[] == BBox(0, 5, 0, 6)
    @test ax.finallimits[] == BBox(0, 5, 0, 6)
    xlims!(ax, [-10, 10])
    @test ax.limits[] == ([-10, 10], nothing)
    @test ax.targetlimits[] == BBox(-10, 10, 0, 6)
    @test ax.finallimits[] == BBox(-10, 10, 0, 6)
    scatter!(Point2f(11, 12))
    reset_limits!(ax)
    @test ax.limits[] == ([-10, 10], nothing)
    @test ax.targetlimits[] == BBox(-10, 10, 0, 12)
    @test ax.finallimits[] == BBox(-10, 10, 0, 12)
    autolimits!(ax)
    ylims!(ax, [5, 7])
    @test ax.limits[] == (nothing, [5, 7])
    @test ax.targetlimits[] == BBox(0, 11, 5, 7)
    @test ax.finallimits[] == BBox(0, 11, 5, 7)
    scatter!(Point2f(-5, -7))
    reset_limits!(ax)
    @test ax.limits[] == (nothing, [5, 7])
    @test ax.targetlimits[] == BBox(-5, 11, 5, 7)
    @test ax.finallimits[] == BBox(-5, 11, 5, 7)
end

@testset "Colorbar plot object kwarg clash" begin
    for attr in (:colormap, :limits)
        f, ax, p = scatter(1:10, 1:10, color = 1:10, colorrange = (1, 10))
        Colorbar(f[2, 1], p)
        @test_throws ErrorException Colorbar(f[2, 1], p; Dict(attr => nothing)...)
    end

    for attr in (:colormap, :limits, :highclip, :lowclip)
        for F in (heatmap, contourf)
            f, ax, p = F(1:10, 1:10, randn(10, 10))
            Colorbar(f[1, 2], p)
            @test_throws ErrorException Colorbar(f[1, 3], p; Dict(attr => nothing)...)
        end
    end
end

@testset "Tick functions" begin
    automatic = Makie.automatic
    Automatic = Makie.Automatic

    get_ticks = Makie.get_ticks
    get_tickvalues = Makie.get_tickvalues
    get_ticklabels = Makie.get_ticklabels

    for func in [identity, log, log2, log10, Makie.logit]
        tup = ([1, 2, 3], ["a", "b", "c"])
        @test get_ticks(tup, func, automatic, 0, 5) == tup

        rng = 1:5
        @test get_ticks(rng, func, automatic, 0, 5) == ([1, 2, 3, 4, 5], ["1", "2", "3", "4", "5"])

        numbers = [1.0, 1.5, 2.0]
        @test get_ticks(numbers, func, automatic, 0, 5) == (numbers, ["1.0", "1.5", "2.0"])

        @test get_ticks(numbers, func, xs -> string.(xs) .* "kg", 0, 5) == (numbers, ["1.0kg", "1.5kg", "2.0kg"])

        @test get_ticks(WilkinsonTicks(5), identity, automatic, 1, 5) == ([1, 2, 3, 4, 5], ["1", "2", "3", "4", "5"])
    end
end

@testset "Colorbars" begin
    fig = Figure()
    hmap = heatmap!(Axis(fig[1, 1]), rand(4, 4))
    cb1 = Colorbar(fig[1,2], hmap; height = Relative(0.65))
    @test cb1.height[] == Relative(0.65)
    @testset "conversion" begin
        # https://github.com/MakieOrg/Makie.jl/issues/2278
        fig = Figure()
        cbar = Colorbar(fig[1,1], colormap=:viridis, colorrange=Vec2f(0, 1))
        ticklabel_strings = first.(cbar.axis.elements[:ticklabels][1][])
        @test ticklabel_strings[1] == "0.0"
        @test ticklabel_strings[end] == "1.0"
    end
end

@testset "cycling" begin
    fig = Figure()
    ax = Axis(fig[1, 1], palette = (patchcolor = [:blue, :green],))
    pl = density!(rand(10); color = Cycled(2))
    @test pl.color[] === :green
    pl = density!(rand(10); color = Cycled(1))
    @test pl.color[] === :blue
end

@testset "briefly empty ticklabels" begin
    # issue 2079, for some reason at Axis initialization briefly there would be a zero-element
    # ticklabel/position array and this would be split into a Vector{Any} for the positions,
    # triggering a conversion error
    # So we just check that the same scenario doesn't error again
    f = Figure()
    ax = Axis(f[1,1], xticks = 20:10:80)
    scatter!(ax, 30:10:100, rand(Float64, 8), color = :red)
end

# issues 1958 and 2006
@testset "axislegend number align" begin
    f = Figure()
    ax = Axis(f[1,1], xticks = 20:10:80)
    lines!(ax, 1:10, label = "A line")
    leg = axislegend(ax, position = (0.4, 0.8))
    @test leg.halign[] == 0.4
    @test leg.valign[] == 0.8
end

# issue 2005
@testset "invalid plotting function keyword arguments" begin
    for T in [Axis, Axis3, LScene]
        f = Figure()
        kw = (; backgroundcolor = :red)
        @test_throws ArgumentError lines(f[1, 1], 1:10, figure = kw)
        @test_nowarn               lines(f[1, 2], 1:10, axis = kw)
        @test_throws ArgumentError lines(f[1, 3][1, 1], 1:10, figure = kw)
        @test_nowarn               lines(f[1, 4][1, 2], 1:10, axis = kw)
        ax = T(f[1, 5])
        @test_throws ArgumentError lines!(ax, 1:10, axis = kw)
        @test_throws ArgumentError lines!(ax, 1:10, axis = kw)
        @test_throws ArgumentError lines!(1:10, axis = kw)
        @test_throws ArgumentError lines!(1:10, figure = kw)
        @test_nowarn               lines!(1:10)
        @test_throws ArgumentError lines!(f[1, 5], 1:10, figure = kw)
        @test_throws ArgumentError lines!(f[1, 5], 1:10, axis = kw)
        @test_nowarn               lines!(f[1, 5], 1:10)
    end
end

@testset "Linked axes" begin
    # this tests a bug in 0.17.4 where the first axis targetlimits
    # don't change because the second axis has limits contained inside those
    # of the first, so the axis linking didn't proliferate
    f = Figure()
    ax1 = Axis(f[1, 1], xautolimitmargin = (0, 0), yautolimitmargin = (0, 0))
    ax2 = Axis(f[2, 1], xautolimitmargin = (0, 0), yautolimitmargin = (0, 0))
    scatter!(ax1, 1:5, 2:6)
    scatter!(ax2, 2:3, 3:4)
    reset_limits!(ax1)
    reset_limits!(ax2)
    @test first.(extrema(ax1.finallimits[])) == (1, 5)
    @test last.(extrema(ax1.finallimits[])) == (2, 6)
    @test first.(extrema(ax2.finallimits[])) == (2, 3)
    @test last.(extrema(ax2.finallimits[])) == (3, 4)
    linkxaxes!(ax1, ax2)
    @test first.(extrema(ax1.finallimits[])) == (1, 5)
    @test last.(extrema(ax1.finallimits[])) == (2, 6)
    @test first.(extrema(ax2.finallimits[])) == (1, 5)
    @test last.(extrema(ax2.finallimits[])) == (3, 4)
    linkyaxes!(ax1, ax2)
    @test first.(extrema(ax1.finallimits[])) == (1, 5)
    @test last.(extrema(ax1.finallimits[])) == (2, 6)
    @test first.(extrema(ax2.finallimits[])) == (1, 5)
    @test last.(extrema(ax2.finallimits[])) == (2, 6)
end

# issue 1718
@testset "Linked axes of linked axes" begin
    # check that if linking axis A and B, where B has already been linked to C, A and C are also linked
    f = Figure()
    ax1 = Axis(f[1, 1])
    ax2 = Axis(f[1, 2])
    ax3 = Axis(f[1, 3])

    linkaxes!(ax2, ax3)
    @test Set(ax1.xaxislinks) == Set([])
    @test Set(ax2.xaxislinks) == Set([ax3])
    @test Set(ax3.xaxislinks) == Set([ax2])
    @test Set(ax1.yaxislinks) == Set([])
    @test Set(ax2.yaxislinks) == Set([ax3])
    @test Set(ax3.yaxislinks) == Set([ax2])

    linkaxes!(ax1, ax2)
    @test Set(ax1.xaxislinks) == Set([ax2, ax3])
    @test Set(ax2.xaxislinks) == Set([ax1, ax3])
    @test Set(ax3.xaxislinks) == Set([ax1, ax2])
    @test Set(ax1.yaxislinks) == Set([ax2, ax3])
    @test Set(ax2.yaxislinks) == Set([ax1, ax3])
    @test Set(ax3.yaxislinks) == Set([ax1, ax2])
end

copy_listeners(obs::Observable) = copy(obs.listeners)
function iterate_observable_fields(f, x::T) where T
    for (fieldname, fieldtype) in zip(fieldnames(T), fieldtypes(T))
        fieldtype <: Observable || continue
        f(fieldname, getfield(x, fieldname))
    end
    return
end

function iterate_attributes(f, a::Attributes, prefix = "")
    for (key, value) in a
        if value isa Attributes
            iterate_attributes(f, value, "$prefix:$key")
        else
            f("$prefix:$key", value)
        end
    end
end

function listener_dict(s::Scene)
    d = Dict{String,Vector}()
    iterate_observable_fields(s) do fieldname, field
        d["$fieldname"] = copy_listeners(field)
    end
    iterate_observable_fields(s.events) do fieldname, field
        d["events:$fieldname"] = copy_listeners(field)
    end
    iterate_observable_fields(s.camera) do fieldname, field
        d["camera:$fieldname"] = copy_listeners(field)
    end
    iterate_attributes(s.theme) do prefix, obs
        d["theme:$prefix"] = copy_listeners(obs)
    end
    return d
end

function dictdiff(before, after)
    kd = setdiff(keys(before), keys(after))
    isempty(kd) || error("Mismatching keys: $kd")
    d = Dict{String,Vector}()
    for key in keys(after)
        befset = Set(last.(before[key]))
        v = filter(after[key]) do (prio,func)
            func ∉ befset
        end
        isempty(v) || (d[key] = v)
    end
    return d
end

function get_difference_dict(blockfunc)
    s = Scene(camera = campixel!);
    before = listener_dict(s)
    block = blockfunc(s)
    delete!(block)
    after = listener_dict(s)
    return dictdiff(before, after)
end

@testset "Deletion of Blocks" begin
    blocks = [Axis, Axis3, Slider, Toggle, Label, Button, Menu, Textbox, Box]
    @testset "$block" for block in blocks
        d = get_difference_dict(block)
        @test isempty(d)
    end
    @testset "Slidergrid" begin
        d = get_difference_dict() do scene
            SliderGrid(scene,
                (label = "Amplitude", range = 0:0.1:10, startvalue = 5),
                (label = "Frequency", range = 0:0.5:50, format = "{:.1f}Hz", startvalue = 10),
                (label = "Phase", range = 0:0.01:2pi,
                    format = x -> string(round(x/pi, digits = 2), "π"))
            ) 
        end
        @test isempty(d)
    end
    @testset "Legend" begin
        d = get_difference_dict() do scene
            Legend(scene, [
                MarkerElement(marker = :cross),
                LineElement(),
                PolyElement(),
            ], ["Label 1", "Label 2", "Label 3"])
        end
        @test isempty(d)
    end
end