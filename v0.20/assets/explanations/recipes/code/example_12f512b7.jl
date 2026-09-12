# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str                       # hide
__result = begin                                       # hide
    timestamps = 1:100

# we create some fake stock values in a way that looks pleasing later
startvalue = StockValue(0.0, 0.0, 0.0, 0.0)
stockvalues = foldl(timestamps[2:end], init = [startvalue]) do values, t
    open = last(values).close + 0.3 * randn()
    close = open + randn()
    high = max(open, close) + rand()
    low = min(open, close) - rand()
    push!(values, StockValue(
        open, close, high, low
    ))
end

# now we can use our new recipe
f = Figure()

stockchart(f[1, 1], timestamps, stockvalues)

# and let's try one where we change our default attributes
stockchart(f[2, 1], timestamps, stockvalues,
    downcolor = :purple, upcolor = :orange)
f
end                                                    # hide
sz = size(Makie.parent_scene(__result))                # hide
open(joinpath(@OUTPUT, "example_12f512b7_size.txt"), "w") do io # hide
    print(io, sz[1], " ", sz[2])                       # hide
end                                                    # hide
save(joinpath(@OUTPUT, "example_12f512b7.png"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
 # hide
nothing # hide