# timeseries

## Examples

### Simple live data stream

```@example
fig, ax, pl = timeseries(0.5)

# Update with new values on each frame
on(events(fig).tick) do tick
    pl[1] = rand()  # Simulate sensor data
    autolimits!(ax)
end

Record(identity, fig, 1:150)
```

### Multiple synchronized timeseries

```@example
using Statistics

fig = Figure()
# use max_auto for ticks to be less jittery
ax = Axis(fig[1, 1], xlabel="Time", ylabel="Value", yticklabelspace=:max_auto)
ylims!(ax, -1, 3) # or just fixed limits
# Create three timeseries with different initial values
ts1 = timeseries!(ax, sin(0.0), label="Signal 1")
ts2 = timeseries!(ax, sin(0.5), label="Signal 2")
ts3 = timeseries!(ax, sin(1.0), label="Signal 3")

axislegend(ax, position=:lt)

# Simulate correlated sensor data
let t = 0.0
    on(events(fig).tick) do tick
        t += tick.delta_time
        # Update all three signals with correlated noise
        base = sin(t * 0.5)
        ts1[1] = base + 0.2 * randn()
        ts2[1] = base + 0.5 + 0.2 * randn()
        ts3[1] = base + 1.0 + 0.2 * randn()
        limits!(ax, (nothing, nothing), (-1, 3))
    end
end

Record(identity, fig, 1:150)
```
