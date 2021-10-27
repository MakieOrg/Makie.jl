using GLMakie

begin
    f, ax, p = scatter(1:4, ["a", "b", "c", "a"])
    scatter!(ax, 1:4, ["b", "x", "a", "c"])
    # scatter!(ax, 1:4, 1:4) # error
end

begin
    obs = Observable(string.(rand('a':'z', 5)))
    obs2 = Observable(string.(rand('a':'z', 5)))
    f, ax, pl = scatter(1:5, obs)
    scatter!(1:5, obs2)
    obs[] = string.(rand('a':'z', 5))
    obs2[] = string.(rand('a':'z', 5))
    autolimits!(ax)
    f
end

begin
    obs = Observable(["a", "a", "b", "b"])
    f, ax, p = scatter(1:4, obs)
    obs[] = ["a", "b", "a", "b"]
    f
end

begin
    obs = Observable(["a", "c", "e", "g"])
    f, ax, p = scatter(1:4, obs)
    obs[] = ["b", "d", "f", "h"]
    f
end

struct Test
    value
end
begin
    f = Figure()
    xticks = MakieLayout.CategoricalTicks(sortby=x->x.value)
    xtickformat = x-> string.(getfield.(x, :value)) .* " val"
    ax = Axis(f[1,1]; xticks=xticks, xtickformat=xtickformat)
    barplot!(ax, Test.([:a, :b, :c]), rand(3))
    f
end
