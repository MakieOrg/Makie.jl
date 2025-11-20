# vlines

## Examples

### Basic vertical lines with styling

```@figure
f = Figure()
ax = Axis(f[1, 1], xlabel = "x", ylabel = "y")

# Plot some data
x = range(0, 4π, length = 100)
lines!(ax, x, sin.(x), label = "sin(x)")

# Add vertical lines at key positions
vlines!(ax, [π/2, 3π/2, 5π/2, 7π/2],
    color = :red, linewidth = 2, linestyle = :dash,
    label = "Peaks")

axislegend(ax)
f
```

### Highlighting data ranges

```@figure
using Random
Random.seed!(123)

f = Figure()
ax = Axis(f[1, 1], xlabel = "Time", ylabel = "Value")

# Generate time series data
t = 1:100
data = cumsum(randn(100))
lines!(ax, t, data, color = :black, linewidth = 2)

# Highlight specific time ranges with colored vertical lines
vlines!(ax, [25, 75], color = [:blue, :orange], linewidth = 3, alpha = 0.6)
text!(ax, [25, 75], [maximum(data) * 0.9, maximum(data) * 0.9],
    text = ["Event A", "Event B"],
    align = (:center, :center))

f
```
