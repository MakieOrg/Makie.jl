# Dodging

Dodging a visual element is the practice of offsetting its position relative to the other visual elements so that they do not overlap. For example, in a barplot, we can show three groups (color) at three distinct levels (x-axis), like so:

```@figure barplot
tbl = (cat = [1, 1, 1, 2, 2, 2, 3, 3, 3],
       height = 0.1:0.1:0.9,
       grp = [1, 2, 3, 1, 2, 3, 1, 2, 3],
       grp1 = [1, 2, 2, 1, 1, 2, 1, 1, 2],
       grp2 = [1, 1, 2, 1, 2, 1, 1, 2, 1]
       )

barplot(tbl.cat, tbl.height,
        dodge = tbl.grp,
        color = tbl.grp,
        axis = (xticks = (1:3, ["left", "middle", "right"]),
                title = "Dodged bars"),
        )
```

## Variable gap and width

When `dodge_gap` is a scalar, all dodged elements are spaced with the same gap. You can instead pass a vector of length N-1 (where N is the number of dodged elements) to vary the gap between each adjacent pair. This is useful for visually grouping related sub-groups closer together.

```@figure dodge_gap_vector
times = repeat(1:3, inner=6)
doses = repeat(1:2, inner=3, outer=3)
thirds = repeat(1:3, outer=6)
y = [0.4, 0.6, 0.5, 0.7, 0.3, 0.8, 0.5, 0.4, 0.7, 0.6, 0.8, 0.3, 0.3, 0.7, 0.6, 0.5, 0.4, 0.9]

# 6 dodged elements: gaps between elements 1-2, 2-3, 3-4, 4-5, 5-6
# Use a large gap between dose groups (positions 3-4) and small gaps within each dose group
dodge_gap = [0.05, 0.05, 0.3, 0.05, 0.05]
dodge = (doses .- 1) .* 3 .+ thirds

barplot(times, y;
        dodge = dodge,
        color = thirds,
        dodge_gap = dodge_gap,
        axis = (xticks = (1:3, ["Time 1", "Time 2", "Time 3"]),
                title = "Varying dodge gap"),
        )
```

Similarly, `width` can be a vector to give each dodged element a different width:

```@figure dodge_width_vector
times = repeat(1:3, inner=4)
doses = repeat(1:2, inner=2, outer=3)
halves = repeat(1:2, outer=6)
y = [0.6, 0.4, 0.7, 0.3, 0.5, 0.8, 0.4, 0.6, 0.7, 0.3, 0.5, 0.8]
dodge = (doses .- 1) .* 2 .+ halves

barplot(times, y;
        dodge = dodge,
        color = halves,
        width = [1.0, 0.4, 1.0, 0.4],
        dodge_gap = fill(0.1, 3),
        axis = (xticks = (1:3, ["Time 1", "Time 2", "Time 3"]),
                title = "Varying dodge width"),
        )
```

Both can be combined to give full control over the layout of each dodge group:

```@figure dodge_gap_and_width
times = repeat(1:3, inner=4)
doses = repeat(1:2, inner=2, outer=3)
halves = repeat(1:2, outer=6)
y = [0.6, 0.4, 0.7, 0.3, 0.5, 0.8, 0.4, 0.6, 0.7, 0.3, 0.5, 0.8]
dodge = (doses .- 1) .* 2 .+ halves

barplot(times, y;
        dodge = dodge,
        color = halves,
        width = [1.0, 0.4, 1.0, 0.4],
        dodge_gap = [0.05, 0.3, 0.05],
        axis = (xticks = (1:3, ["Time 1", "Time 2", "Time 3"]),
                title = "Varying gap and width"),
        )
```

## Compositing plot types

By using `n_dodge` you can align different plot types on the same axis so they share the same dodge layout. Each plot type occupies a specific slot within the shared dodge space. This enables rich composite visualizations, such as pairing a violin with a boxplot:

```@figure composite_dodge
using Random
rng = Xoshiro(2025_10_30)

values = [randn(rng, 100) .* 3 .+ 1; randn(rng, 100) .* 2 .+ 5; randn(rng, 100) .* -1;
          randn(rng, 100) .* 8 .+ 5; randn(rng, 100) .* 5 .+ 6; randn(rng, 100) .* 2 .+ 8]
types = repeat(1:6; inner=100)
x = (types .- 1) .÷ 3
colors = types .% 3
data = (; x, y=values, colors)

# Each color group occupies 2 slots: violin (slot *2+1), boxplot (slot *2+2)
n = length(unique(data.colors)) * 2
palette = Makie.current_default_theme()[:palette][:color][]

fig = Figure()
ax = Axis(fig[1, 1])

violin!(ax, data.x, data.y;
        side = :left,
        gap = 0.4,
        dodge = data.colors .* 2 .+ 1,
        n_dodge = n,
        width = repeat([2.0, 0.3], 3),
        color = palette[data.colors .+ 1],
        dodge_gap = [-0.2, 0.0, -0.2, 0.0, -0.2])

boxplot!(ax, data.x, data.y;
         gap = 0.4,
         dodge = data.colors .* 2 .+ 2,
         n_dodge = n,
         width = repeat([2.0, 0.3], 3),
         dodge_gap = [-0.2, 0.0, -0.2, 0.0, -0.2],
         color = palette[data.colors .+ 1])

fig
```

Negative gap values in `dodge_gap` cause adjacent elements to overlap, which is useful for nesting related plot types (e.g., overlapping a boxplot onto its corresponding violin).
