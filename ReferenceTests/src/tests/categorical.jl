using Test
using Makie.ComputePipeline: ResolveException
using Makie: Categorical

@reference_test "multi plot, error with non categorical" begin
    f, ax, p = scatter(1:4, Categorical(["a", "b", "c", "a"]), color = 1:4, colormap = :viridis, markersize = 20)
    scatter!(ax, 1:4, Categorical(["b", "x", "a", "c"]), color = 1:4, colormap = :reds, markersize = 20)
    # TODO, throw better error (not that easy since we need to check for sortability)
    @test_throws ResolveException scatter!(ax, 1:4, 1:4) # error
    f
end

@reference_test "different types without sorting function" begin
    # If we set the ticks explicitly, with sortby defaulting to nothing,
    # we can combine all objects:
    f = Figure()
    ax = Axis(
        f[1, 1];
        dim1_conversion = Makie.CategoricalConversion(; sortby = nothing),
        dim2_conversion = Makie.CategoricalConversion(; sortby = nothing)
    )

    p = scatter!(ax, 1:4, Categorical(["a", "b", "c", "a"]); color = 1:4, colormap = :viridis, markersize = 20)
    sp = scatter!(ax, 1:4, 1:4; color = 1:4, colormap = :reds, markersize = 20)
    scatter!(ax, [1im, 2im], 1:2, color = [:red, :black], markersize = 20)
    f
end

@reference_test "new random categories, interactive" begin
    obs = Observable(Categorical(["o", "m", "d", "p", "p"]))
    obs2 = Observable(Categorical(["q", "f", "y", "e", "n"]))
    f, ax, pl = scatter(1:5, obs, markersize = 20, color = 1:5, colormap = :viridis)
    scatter!(1:5, obs2, markersize = 20, color = 1:5, colormap = :reds)
    obs[] = Categorical(["f", "z", "a", "u", "z"])
    obs2[] = Categorical(["i", "s", "n", "i", "o"])
    autolimits!(ax)
    f
end

@reference_test "changing order of categorical values" begin
    obs = Observable(Categorical(["a", "a", "b", "b"]))
    f, ax, p = scatter(1:4, obs; markersize = 20, color = 1:4, colormap = :viridis)
    obs[] = Categorical(["a", "b", "a", "b"])
    f
end

@reference_test "new categories, in between old values" begin
    obs = Observable(Categorical(["a", "c", "e", "g"]))
    f, ax, p = scatter(1:4, obs, markersize = 20, color = 1:4, colormap = :viridis)
    obs[] = Categorical(["b", "d", "f", "h"])
    f
end

struct SomeStruct
    value
end

@reference_test "custom struct, with custom sorting function" begin
    f = Figure()
    conversion = Makie.CategoricalConversion(sortby = x -> x.value)
    xtickformat = x -> string.(getfield.(x, :value)) .* " val"
    ax = Axis(f[1, 1]; dim1_conversion = conversion, xtickformat = xtickformat)
    barplot!(ax, SomeStruct.([:a, :b, :c]), 1:3)
    f
end

@reference_test "Categorical xticks yticks" begin
    f, ax, p = scatter(Categorical(["a", "b", "c", "d"]), Categorical(["a", "a", "c", "x"]), markersize = 20)
    ax.xticks = ["a", "d"]
    ax.yticks = ["a", "b", "d", "x"]
    f
end
