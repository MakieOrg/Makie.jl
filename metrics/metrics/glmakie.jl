## using_glmakie
using GLMakie

## glmakie_lineplot
f, ax, l = lines(1:10, 1:10)
mktempdir() do path
    save(joinpath(path, "test.png"), f)
end
