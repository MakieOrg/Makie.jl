# This file was generated, do not modify it. # hide
__result = begin # hide
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
end # hide
save(joinpath(@OUTPUT, "example_1366018641080456634.png"), __result; ) # hide

nothing # hide