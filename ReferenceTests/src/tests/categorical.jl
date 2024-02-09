using Test

@reference_test "multi plot, error with non categorical" begin
    f, ax, p = scatter(1:4, ["a", "b", "c", "a"])
    scatter!(ax, 1:4, ["b", "x", "a", "c"])
    # TODO, throw better error (not that easy since we need to check for sortability)
    # @test_throws MethodError scatter!(ax, 1:4, 1:4) # error
    f
end

@reference_test "different types without sorting function" begin
    # If we set the ticks explicitely, with sortby defaulting to nothing,
    # we can combine all objects:
    f = Figure()
    # Not sure how this worked previously, since sortby was set to identity,
    #
    ax = Axis(f[1, 1];
        x_dim_convert=Makie.CategoricalConversion(),
        y_dim_convert=Makie.CategoricalConversion())

    p = scatter!(ax, 1:4, ["a", "b", "c", "a"])
    scatter!(ax, 1:4, 1:4)
    scatter!(ax, [1im, 2im], 1:2)
    f
end

@reference_test "new random categories, interactive" begin
    obs = Observable(["o", "m", "d", "p", "p"])
    obs2 = Observable(["q", "f", "y", "e", "n"])
    f, ax, pl = scatter(1:5, obs)
    scatter!(1:5, obs2)
    obs[] = ["f", "z", "a", "u", "z"]
    obs2[] = ["f", "s", "n", "i", "o"]
    autolimits!(ax)
    f
end

@reference_test "changing order of categorical values" begin
    obs = Observable(["a", "a", "b", "b"])
    f, ax, p = scatter(1:4, obs)
    obs[] = ["a", "b", "a", "b"]
    f
end

@reference_test "new categories, inbetween old values" begin
    obs = Observable(["a", "c", "e", "g"])
    f, ax, p = scatter(1:4, obs)
    obs[] = ["b", "d", "f", "h"]
    f
end

struct SomeStruct
    value
end

@reference_test "custom struct, with custom sorting function" begin
    f = Figure()
    conversion = Makie.CategoricalConversion(sortby=x->x.value)
    xtickformat = x-> string.(getfield.(x, :value)) .* " val"
    ax = Axis(f[1, 1]; x_dim_convert=conversion, xtickformat=xtickformat)
    barplot!(ax, SomeStruct.([:a, :b, :c]), rand(3))
    f
end
