# This file was generated, do not modify it. # hide
timestamps = Observable(collect(1:100))
stocknode = Observable(stockvalues)

fig, ax, sc = stockchart(timestamps, stocknode)

record(fig, "stockchart_animation.mp4", 101:200,
        framerate = 30) do t
    # push a new timestamp without triggering the observable
    push!(timestamps[], t)

    # push a new StockValue without triggering the observable
    old = last(stocknode[])
    open = old.close + 0.3 * randn()
    close = open + randn()
    high = max(open, close) + rand()
    low = min(open, close) - rand()
    new = StockValue(open, close, high, low)
    push!(stocknode[], new)

    # now both timestamps and stocknode are synchronized
    # again and we can trigger one of them by assigning it to itself
    # to update the whole stockcharts plot for the new frame
    stocknode[] = stocknode[]
    # let's also update the axis limits because the plot will grow
    # to the right
    autolimits!(ax)
end
nothing # hide

using GLMakie # hide
GLMakie.activate!() # hide