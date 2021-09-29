## using_cairomakie
using CairoMakie

## cairomakie_lineplot
f, ax, l = lines(1:10, 1:10)
mktempdir() do path
    save(joinpath(path, "test_cairomakie.png"), f)
end
