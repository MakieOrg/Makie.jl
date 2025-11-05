# Generated plot_examples() implementations
# Extracted from docs/src/reference/plots/*.md files
# Each function shows the first example only

function Makie.plot_examples(::Type{<:ABLines})
    return """
## Examples

```julia
ablines(0, 1)
ablines!([1, 2, 3], [1, 1.5, 2], color = [:red, :orange, :pink], linestyle=:dash, linewidth=2)
current_figure()
```

See the [online documentation](https://docs.makie.org/stable/reference/plots/ablines) for more examples.
"""
end

function Makie.plot_examples(::Type{<:Annotation})
    return """
## Examples

```julia
f = Figure()

points = [(-2.15, -0.19), (-1.66, 0.78), (-1.56, 0.87), (-0.97, -1.91), (-0.96, -0.25), (-0.79, 2.6), (-0.74, 1.68), (-0.56, -0.44), (-0.36, -0.63), (-0.32, 0.67), (-0.15, -1.11), (-0.07, 1.23), (0.3, 0.73), (0.72, -1.48), (0.8, 1.12)]

fruit = ["Apple", "Banana", "Cherry", "Date", "Elderberry", "Fig", "Grape", "Honeydew",
          "Indian Fig", "Jackfruit", "Kiwi", "Lychee", "Mango", "Nectarine", "Orange"]

limits = (-3, 1.5, -3, 3)

ax1 = Axis(f[1, 1]; limits, title = "text")

scatter!(ax1, points)
text!(ax1, points, text = fruit)

ax2 = Axis(f[1, 2]; limits, title = "annotation")

scatter!(ax2, points)
annotation!(ax2, points, text = fruit)

hidedecorations!.([ax1, ax2])

f
```

See the [online documentation](https://docs.makie.org/stable/reference/plots/annotation) for more examples.
"""
end

function Makie.plot_examples(::Type{<:Arc})
    return """
## Examples

```julia
arc(Point2f(0), 1, -π, π)
```

See the [online documentation](https://docs.makie.org/stable/reference/plots/arc) for more examples.
"""
end

function Makie.plot_examples(::Type{<:Arrows})
    return """
## Examples

```julia
f = Figure(size = (800, 800))
Axis(f[1, 1], backgroundcolor = "black")

xs = LinRange(0, 2pi, 20)
ys = LinRange(0, 3pi, 20)
us = [sin(x) * cos(y) for x in xs, y in ys]
vs = [-cos(x) * sin(y) for x in xs, y in ys]
strength = vec(sqrt.(us .^ 2 .+ vs .^ 2))

arrows2d!(xs, ys, us, vs, lengthscale = 0.2, color = strength)

f
```

See the [online documentation](https://docs.makie.org/stable/reference/plots/arrows) for more examples.
"""
end

function Makie.plot_examples(::Type{<:Band})
    return """
## Examples

```julia
f = Figure()
Axis(f[1, 1])

xs = 1:0.2:10
ys_low = -0.2 .* sin.(xs) .- 0.25
ys_high = 0.2 .* sin.(xs) .+ 0.25

band!(xs, ys_low, ys_high)
band!(xs, ys_low .- 1, ys_high .-1, color = :red)

f
```

See the [online documentation](https://docs.makie.org/stable/reference/plots/band) for more examples.
"""
end

function Makie.plot_examples(::Type{<:BarPlot})
    return """
## Examples

```julia
f = Figure()
Axis(f[1, 1])

xs = 1:0.2:10
ys = 0.5 .* sin.(xs)

barplot!(xs, ys, color = :red, strokecolor = :black, strokewidth = 1)
barplot!(xs, ys .- 1, fillto = -1, color = xs, strokecolor = :black, strokewidth = 1)

f
```

See the [online documentation](https://docs.makie.org/stable/reference/plots/barplot) for more examples.
"""
end

function Makie.plot_examples(::Type{<:BoxPlot})
    return """
## Examples

```julia
categories = rand(1:3, 1000)
values = randn(1000)

boxplot(categories, values)
```

See the [online documentation](https://docs.makie.org/stable/reference/plots/boxplot) for more examples.
"""
end

function Makie.plot_examples(::Type{<:Bracket})
    return """
## Examples

```julia
f, ax, l = lines(0..9, sin; axis = (; xgridvisible = false, ygridvisible = false))
ylims!(ax, -1.5, 1.5)

bracket!(pi/2, 1, 5pi/2, 1, offset = 5, text = "Period length", style = :square)

bracket!(pi/2, 1, pi/2, -1, text = "Amplitude", orientation = :down,
    linestyle = :dash, rotation = 0, align = (:right, :center), textoffset = 4, linewidth = 2, color = :red, textcolor = :red)

bracket!(2.3, sin(2.3), 4.0, sin(4.0),
    text = "Falling", offset = 10, orientation = :up, color = :purple, textcolor = :purple)

bracket!(Point(5.5, sin(5.5)), Point(7.0, sin(7.0)),
    text = "Rising", offset = 10, orientation = :down, color = :orange, textcolor = :orange, 
    fontsize = 30, textoffset = 30, width = 50)
f
```

See the [online documentation](https://docs.makie.org/stable/reference/plots/bracket) for more examples.
"""
end

function Makie.plot_examples(::Type{<:Contour})
    return """
## Examples

```julia
f = Figure()
Axis(f[1, 1])

xs = LinRange(0, 10, 100)
ys = LinRange(0, 15, 100)
zs = [cos(x) * sin(y) for x in xs, y in ys]

contour!(xs, ys, zs)

f
```

See the [online documentation](https://docs.makie.org/stable/reference/plots/contour) for more examples.
"""
end

function Makie.plot_examples(::Type{<:Contour3d})
    return """
## Examples

```julia
r = range(-pi, pi, length = 21)
data2d = [cos(x) + cos(y) for x in r, y in r]
data3d = [cos(x) + cos(y) + cos(z) for x in r, y in r, z in r]

f = Figure(size = (700, 400))
a1 = Axis3(f[1, 1], title = "3D contour()")
contour!(a1, -pi .. pi, -pi .. pi, -pi .. pi, data3d)

a2 = Axis3(f[1, 2], title = "contour3d()")
contour3d!(a2, r, r, data2d, linewidth = 3, levels = 10)
f
```

See the [online documentation](https://docs.makie.org/stable/reference/plots/contour3d) for more examples.
"""
end

function Makie.plot_examples(::Type{<:Contourf})
    return """
## Examples

```julia
using DelimitedFiles


volcano = readdlm(Makie.assetpath("volcano.csv"), ',', Float64)

f = Figure()
Axis(f[1, 1])

co = contourf!(volcano, levels = 10)

Colorbar(f[1, 2], co)

f
```

See the [online documentation](https://docs.makie.org/stable/reference/plots/contourf) for more examples.
"""
end

function Makie.plot_examples(::Type{<:CrossBar})
    return """
## Examples

```julia
xs = [1, 1, 2, 2, 3, 3]
ys = rand(6)
ymins = ys .- 1
ymaxs = ys .+ 1
dodge = [1, 2, 1, 2, 1, 2]

crossbar(xs, ys, ymins, ymaxs, dodge = dodge, show_notch = true)
```

See the [online documentation](https://docs.makie.org/stable/reference/plots/crossbar) for more examples.
"""
end

function Makie.plot_examples(::Type{<:DataShader})
    return """
## Examples

```julia
using DelimitedFiles

airports = Point2f.(eachrow(readdlm(assetpath("airportlocations.csv"))))
fig, ax, ds = datashader(airports,
    colormap=[:white, :black],
    # for documentation output we shouldn't calculate the image async,
    # since it won't wait for the render to finish and inline a blank image
    async = false,
    figure = (; figure_padding=0, size=(360*2, 160*2))
)
Colorbar(fig[1, 2], ds, label="Number of airports")
hidedecorations!(ax); hidespines!(ax)
fig
```

See the [online documentation](https://docs.makie.org/stable/reference/plots/datashader) for more examples.
"""
end

function Makie.plot_examples(::Type{<:Dendrogram})
    return """
## Examples

```julia
using CairoMakie

# Relative positions of leaf nodes
# These positions will be translated to place the root node at `origin`
leaves = Point2f[
    (1,0),
    (2,0.5),
    (3,1),
    (4,2),
    (5,0)
]

# connections between nodes which merge into a new node
merges = [
    (1, 2), # creates node 6
    (6, 3), # 7
    (4, 5), # 8
    (7, 8), # 9
]

dendrogram(leaves, merges)
```

See the [online documentation](https://docs.makie.org/stable/reference/plots/dendrogram) for more examples.
"""
end

function Makie.plot_examples(::Type{<:Density})
    return """
## Examples

```julia
f = Figure()
Axis(f[1, 1])

density!(randn(200))
density!(randn(200) .+ 2, alpha = 0.8)

f
```

See the [online documentation](https://docs.makie.org/stable/reference/plots/density) for more examples.
"""
end

function Makie.plot_examples(::Type{<:ECDFPlot})
    return """
## Examples

```julia
f = Figure()
Axis(f[1, 1])

ecdfplot!(randn(200))

f
```

See the [online documentation](https://docs.makie.org/stable/reference/plots/ecdf) for more examples.
"""
end

function Makie.plot_examples(::Type{<:Errorbars})
    return """
## Examples

```julia
f = Figure()
Axis(f[1, 1])

xs = 0:0.5:10
ys = 0.5 .* sin.(xs)

lowerrors = fill(0.1, length(xs))
higherrors = LinRange(0.1, 0.4, length(xs))

errorbars!(xs, ys, higherrors; color = :red, label="data") # same low and high error

# plot position scatters so low and high errors can be discriminated
scatter!(xs, ys; markersize = 3, color = :black, label="data")

# the `label=` must be the same for merge to work
# without merge, two separate legend items will appear
axislegend(merge=true)

f
```

See the [online documentation](https://docs.makie.org/stable/reference/plots/errorbars) for more examples.
"""
end

function Makie.plot_examples(::Type{<:Heatmap})
    return """
## Examples

```julia
f = Figure()
ax = Axis(f[1, 1])

centers_x = 1:5
centers_y = 6:10
data = reshape(1:25, 5, 5)

heatmap!(ax, centers_x, centers_y, data)

scatter!(ax, [(x, y) for x in centers_x for y in centers_y], color=:white, strokecolor=:black, strokewidth=1)

f
```

See the [online documentation](https://docs.makie.org/stable/reference/plots/heatmap) for more examples.
"""
end

function Makie.plot_examples(::Type{<:Hexbin})
    return """
## Examples

```julia
using Random
Random.seed!(1234)

f = Figure(size = (800, 800))

x = rand(300)
y = rand(300)

for i in 2:5
    ax = Axis(f[fldmod1(i-1, 2)...], title = "bins = \$i", aspect = DataAspect())
    hexbin!(ax, x, y, bins = i)
    wireframe!(ax, Rect2f(Point2f.(x, y)), color = :red)
    scatter!(ax, x, y, color = :red, markersize = 5)
end

f
```

See the [online documentation](https://docs.makie.org/stable/reference/plots/hexbin) for more examples.
"""
end

function Makie.plot_examples(::Type{<:Hist})
    return """
## Examples

```julia
data = randn(1000)

f = Figure()
hist(f[1, 1], data, bins = 10)
hist(f[1, 2], data, bins = 20, color = :red, strokewidth = 1, strokecolor = :black)
hist(f[2, 1], data, bins = [-5, -2, -1, 0, 1, 2, 5], color = :gray)
hist(f[2, 2], data, normalization = :pdf)
f
```

See the [online documentation](https://docs.makie.org/stable/reference/plots/hist) for more examples.
"""
end

function Makie.plot_examples(::Type{<:HLines})
    return """
## Examples

```julia
hlines([1, 2, 3])
```

See the [online documentation](https://docs.makie.org/stable/reference/plots/hlines) for more examples.
"""
end

function Makie.plot_examples(::Type{<:HSpan})
    return """
## Examples

```julia
hspan([0, 1, 2], [0.5, 1.2, 2.1])
```

See the [online documentation](https://docs.makie.org/stable/reference/plots/hspan) for more examples.
"""
end

function Makie.plot_examples(::Type{<:Image})
    return """
## Examples

```julia
using FileIO

img = load(assetpath("cow.png"))

f = Figure()

image(f[1, 1], img,
    axis = (title = "Default",))

image(f[1, 2], img,
    axis = (aspect = DataAspect(), title = "DataAspect()",))

image(f[2, 1], rotr90(img),
    axis = (aspect = DataAspect(), title = "rotr90",))

image(f[2, 2], img',
    axis = (aspect = DataAspect(), yreversed = true,
        title = "img' and reverse y-axis",))

f
```

See the [online documentation](https://docs.makie.org/stable/reference/plots/image) for more examples.
"""
end

function Makie.plot_examples(::Type{<:Lines})
    return """
## Examples

```julia
ps = rand(Point3f, 500)
cs = rand(500)
f = Figure(size = (600, 650))
Label(f[1, 1], "base", tellwidth = false)
lines(f[2, 1], ps, color = cs, fxaa = false)
Label(f[1, 2], "fxaa = true", tellwidth = false)
lines(f[2, 2], ps, color = cs, fxaa = true)
Label(f[3, 1], "transparency = true", tellwidth = false)
lines(f[4, 1], ps, color = cs, transparency = true)
Label(f[3, 2], "overdraw = true", tellwidth = false)
lines(f[4, 2], ps, color = cs, overdraw = true)
f
```

See the [online documentation](https://docs.makie.org/stable/reference/plots/lines) for more examples.
"""
end

function Makie.plot_examples(::Type{<:LineSegments})
    return """
## Examples

```julia
f = Figure()
Axis(f[1, 1])

xs = 1:0.2:10
ys = sin.(xs)

linesegments!(xs, ys)
linesegments!(xs, ys .- 1, linewidth = 5)
linesegments!(xs, ys .- 2, linewidth = 5, color = LinRange(1, 5, length(xs)))

f
```

See the [online documentation](https://docs.makie.org/stable/reference/plots/linesegments) for more examples.
"""
end

function Makie.plot_examples(::Type{<:Mesh})
    return """
## Examples

```julia
vertices = [
    0.0 0.0;
    1.0 0.0;
    1.0 1.0;
    0.0 1.0;
]

faces = [
    1 2 3;
    3 4 1;
]

colors = [:red, :green, :blue, :orange]

mesh(vertices, faces, color = colors, shading = NoShading)
```

See the [online documentation](https://docs.makie.org/stable/reference/plots/mesh) for more examples.
"""
end

function Makie.plot_examples(::Type{<:MeshScatter})
    return """
## Examples

```julia
xs = cos.(1:0.5:20)
ys = sin.(1:0.5:20)
zs = LinRange(0, 3, length(xs))

meshscatter(xs, ys, zs, markersize = 0.1, color = zs)
```

See the [online documentation](https://docs.makie.org/stable/reference/plots/meshscatter) for more examples.
"""
end

function Makie.plot_examples(::Type{<:Pie})
    return """
## Examples

```julia
data   = [36, 12, 68, 5, 42, 27]
colors = [:yellow, :orange, :red, :blue, :purple, :green]

f, ax, plt = pie(data,
                 color = colors,
                 radius = 4,
                 inner_radius = 2,
                 strokecolor = :white,
                 strokewidth = 5,
                 axis = (autolimitaspect = 1, )
                )

f
```

See the [online documentation](https://docs.makie.org/stable/reference/plots/pie) for more examples.
"""
end

function Makie.plot_examples(::Type{<:Poly})
    return """
## Examples

```julia
using Makie.GeometryBasics


f = Figure()
Axis(f[1, 1])

poly!(Point2f[(0, 0), (2, 0), (3, 1), (1, 1)], color = :red, strokecolor = :black, strokewidth = 1)

f
```

See the [online documentation](https://docs.makie.org/stable/reference/plots/poly) for more examples.
"""
end

function Makie.plot_examples(::Type{<:QQNorm})
    return """
## Examples

```julia
xs = 2 .* randn(100) .+ 3

qqnorm(xs, qqline = :fitrobust)
```

See the [online documentation](https://docs.makie.org/stable/reference/plots/qqnorm) for more examples.
"""
end

function Makie.plot_examples(::Type{<:QQPlot})
    return """
## Examples

```julia
xs = randn(100)
ys = randn(100)

qqplot(xs, ys, qqline = :identity)
```

See the [online documentation](https://docs.makie.org/stable/reference/plots/qqplot) for more examples.
"""
end

function Makie.plot_examples(::Type{<:RainClouds})
    return """
## Examples

```julia
using Random
using Makie: rand_localized

####
#### Below is used for testing the plotting functionality.
####

function mockup_distribution(N)
    all_possible_labels = ["Single Mode", "Double Mode", "Random Exp", "Uniform"]
    category_type = rand(all_possible_labels)

    if category_type == "Single Mode"
        random_mean = rand_localized(0, 8)
        random_spread_coef = rand_localized(0.3, 1)
        data_points = random_spread_coef*randn(N) .+ random_mean

    elseif category_type == "Double Mode"
        random_mean = rand_localized(0, 8)
        random_spread_coef = rand_localized(0.3, 1)
        data_points = random_spread_coef*randn(Int(round(N/2.0))) .+ random_mean

        random_mean = rand_localized(0, 8)
        random_spread_coef = rand_localized(0.3, 1)
        data_points = vcat(data_points, random_spread_coef*randn(Int(round(N/2.0))) .+ random_mean)

    elseif category_type == "Random Exp"
        data_points = randexp(N)

    elseif category_type == "Uniform"
        min = rand_localized(0, 4)
        max = min + rand_localized(0.5, 4)
        data_points = [rand_localized(min, max) for _ in 1:N]

    else
        error("Unidentified category.")
    end

    return data_points
end

function mockup_categories_and_data_array(num_categories; N = 500)
    category_labels = String[]
    data_array = Float64[]

    for category_label in string.(('A':'Z')[1:min(num_categories, end)])
        data_points = mockup_distribution(N)

        append!(category_labels, fill(category_label, N))
        append!(data_array, data_points)
    end
    return category_labels, data_array
end

category_labels, data_array = mockup_categories_and_data_array(3)

colors = Makie.wong_colors()
rainclouds(category_labels, data_array;
    axis = (; xlabel = "Categories of Distributions", ylabel = "Samples", title = "My Title"),
    plot_boxplots = false, cloud_width=0.5, clouds=hist, hist_bins=50,
    color = colors[indexin(category_labels, unique(category_labels))])
```

See the [online documentation](https://docs.makie.org/stable/reference/plots/rainclouds) for more examples.
"""
end

function Makie.plot_examples(::Type{<:Rangebars})
    return """
## Examples

```julia
f = Figure()
Axis(f[1, 1])

vals = -1:0.1:1
lows = zeros(length(vals))
highs = LinRange(0.1, 0.4, length(vals))

rangebars!(vals, lows, highs, color = :red)

f
```

See the [online documentation](https://docs.makie.org/stable/reference/plots/rangebars) for more examples.
"""
end

function Makie.plot_examples(::Type{<:Scatter})
    return """
## Examples

```julia
xs = range(0, 10, length = 30)
ys = 0.5 .* sin.(xs)

scatter(xs, ys)
```

See the [online documentation](https://docs.makie.org/stable/reference/plots/scatter) for more examples.
"""
end

function Makie.plot_examples(::Type{<:ScatterLines})
    return """
## Examples

```julia
f = Figure()
Axis(f[1, 1])

xs = LinRange(0, 10, 20)
ys = 0.5 .* sin.(xs)

scatterlines!(xs, ys, color = :red)
scatterlines!(xs, ys .- 1, color = xs, markercolor = :red)
scatterlines!(xs, ys .- 2, markersize = LinRange(5, 30, 20))
scatterlines!(xs, ys .- 3, marker = :cross, strokewidth = 1,
    markersize = 20, color = :orange, strokecolor = :black)

f
```

See the [online documentation](https://docs.makie.org/stable/reference/plots/scatterlines) for more examples.
"""
end

function Makie.plot_examples(::Type{<:Series})
    return """
## Examples

```julia
data = cumsum(randn(4, 101), dims = 2)

fig, ax, sp = series(data, labels=["label \$i" for i in 1:4])
axislegend(ax)
fig
```

See the [online documentation](https://docs.makie.org/stable/reference/plots/series) for more examples.
"""
end

function Makie.plot_examples(::Type{<:Spy})
    return """
## Examples

```julia
using SparseArrays

N = 10 # dimension of the sparse matrix
p = 0.1 # independent probability that an entry is zero

A = sprand(N, N, p)
f, ax, plt = spy(A, framecolor = :lightgrey, axis=(;
    aspect=1,
    title = "Visualization of a random sparse matrix")
)

hidedecorations!(ax) # remove axis labeling

f
```

See the [online documentation](https://docs.makie.org/stable/reference/plots/spy) for more examples.
"""
end

function Makie.plot_examples(::Type{<:Stairs})
    return """
## Examples

```julia
f = Figure()

xs = LinRange(0, 4pi, 21)
ys = sin.(xs)

stairs(f[1, 1], xs, ys)
stairs(f[2, 1], xs, ys; step=:post, color=:blue, linestyle=:dash)
stairs(f[3, 1], xs, ys; step=:center, color=:red, linestyle=:dot)

f
```

See the [online documentation](https://docs.makie.org/stable/reference/plots/stairs) for more examples.
"""
end

function Makie.plot_examples(::Type{<:Stem})
    return """
## Examples

```julia
f = Figure()
Axis(f[1, 1])

xs = LinRange(0, 4pi, 30)

stem!(xs, sin.(xs))

f
```

See the [online documentation](https://docs.makie.org/stable/reference/plots/stem) for more examples.
"""
end

function Makie.plot_examples(::Type{<:StepHist})
    return """
## Examples

```julia
data = randn(1000)

f = Figure()
stephist(f[1, 1], data, bins = 10)
stephist(f[1, 2], data, bins = 20, color = :red, linewidth = 3)
stephist(f[2, 1], data, bins = [-5, -2, -1, 0, 1, 2, 5], color = :gray)
stephist(f[2, 2], data, normalization = :pdf)
f
```

See the [online documentation](https://docs.makie.org/stable/reference/plots/stephist) for more examples.
"""
end

function Makie.plot_examples(::Type{<:StreamPlot})
    return """
## Examples

```julia
struct FitzhughNagumo{T}
    ϵ::T
    s::T
    γ::T
    β::T
end

P = FitzhughNagumo(0.1, 0.0, 1.5, 0.8)

f(x, P::FitzhughNagumo) = Point2f(
    (x[1]-x[2]-x[1]^3+P.s)/P.ϵ,
    P.γ*x[1]-x[2] + P.β
)

f(x) = f(x, P)

fig, ax, pl = streamplot(f, -1.5..1.5, -1.5..1.5, colormap = :magma)
# you can also pass a function to `color`, to either return a number or color value
streamplot(fig[1,2], f, -1.5 .. 1.5, -1.5 .. 1.5, color=(p)-> RGBAf(p..., 0.0, 1))
fig
```

See the [online documentation](https://docs.makie.org/stable/reference/plots/streamplot) for more examples.
"""
end

function Makie.plot_examples(::Type{<:Surface})
    return """
## Examples

```julia
xs = LinRange(0, 10, 100)
ys = LinRange(0, 15, 100)
zs = [cos(x) * sin(y) for x in xs, y in ys]

surface(xs, ys, zs, axis=(type=Axis3,))
```

See the [online documentation](https://docs.makie.org/stable/reference/plots/surface) for more examples.
"""
end

function Makie.plot_examples(::Type{<:Text})
    return """
## Examples

```julia
f = Figure()

Axis(f[1, 1], aspect = DataAspect(), backgroundcolor = :gray50)

scatter!(Point2f(0, 0))
text!(0, 0, text = "center", align = (:center, :center))

circlepoints = [(cos(a), sin(a)) for a in LinRange(0, 2pi, 16)[1:end-1]]
scatter!(circlepoints)
text!(
    circlepoints,
    text = "this is point " .* string.(1:15),
    rotation = LinRange(0, 2pi, 16)[1:end-1],
    align = (:right, :baseline),
    color = cgrad(:Spectral)[LinRange(0, 1, 15)]
)

f
```

See the [online documentation](https://docs.makie.org/stable/reference/plots/text) for more examples.
"""
end

function Makie.plot_examples(::Type{<:TextLabel})
    return """
## Examples

```julia
using CairoMakie
using FileIO

f, a, p = image(rotr90(load(assetpath("cow.png"))))
textlabel!(a, Point2f(200, 150), text = "Cow", fontsize = 20)
f
```

See the [online documentation](https://docs.makie.org/stable/reference/plots/textlabel) for more examples.
"""
end

function Makie.plot_examples(::Type{<:Tooltip})
    return """
## Examples

```julia
fig, ax, p = scatter(Point2f(0), marker = 'x', markersize = 20)
tooltip!(Point2f(0), "This is a tooltip pointing at x")
fig
```

See the [online documentation](https://docs.makie.org/stable/reference/plots/tooltip) for more examples.
"""
end

function Makie.plot_examples(::Type{<:Tricontourf})
    return """
## Examples

```julia
using Random
Random.seed!(1234)

x = randn(50)
y = randn(50)
z = -sqrt.(x .^ 2 .+ y .^ 2) .+ 0.1 .* randn.()

f, ax, tr = tricontourf(x, y, z)
scatter!(x, y, color = z, strokewidth = 1, strokecolor = :black)
Colorbar(f[1, 2], tr)
f
```

See the [online documentation](https://docs.makie.org/stable/reference/plots/tricontourf) for more examples.
"""
end

function Makie.plot_examples(::Type{<:Triplot})
    return """
## Examples

```julia
using DelaunayTriangulation

using Random
Random.seed!(1234)

points = randn(Point2f, 50)
f, ax, tr = triplot(points, show_points = true, triangle_color = :lightblue)

tri = triangulate(points)
ax, tr = triplot(f[1, 2], tri, show_points = true)
f
```

See the [online documentation](https://docs.makie.org/stable/reference/plots/triplot) for more examples.
"""
end

function Makie.plot_examples(::Type{<:Violin})
    return """
## Examples

```julia
categories = rand(1:3, 1000)
values = randn(1000)

violin(categories, values)
```

See the [online documentation](https://docs.makie.org/stable/reference/plots/violin) for more examples.
"""
end

function Makie.plot_examples(::Type{<:VLines})
    return """
## Examples

```julia
vlines([1, 2, 3])
```

See the [online documentation](https://docs.makie.org/stable/reference/plots/vlines) for more examples.
"""
end

function Makie.plot_examples(::Type{<:Volume})
    return """
## Examples

```julia
r = LinRange(-1, 1, 100)
cube = [(x.^2 + y.^2 + z.^2) for x = r, y = r, z = r]
contour(cube, alpha=0.5)
```

See the [online documentation](https://docs.makie.org/stable/reference/plots/volume) for more examples.
"""
end

function Makie.plot_examples(::Type{<:VolumeSlices})
    return """
## Examples

```julia
fig = Figure()
ax = LScene(fig[1, 1], show_axis=false)

x = LinRange(0, π, 50)
y = LinRange(0, 2π, 100)
z = LinRange(0, 3π, 150)

sgrid = SliderGrid(
    fig[2, 1],
    (label = "yz plane - x axis", range = 1:length(x)),
    (label = "xz plane - y axis", range = 1:length(y)),
    (label = "xy plane - z axis", range = 1:length(z)),
)

lo = sgrid.layout
nc = ncols(lo)

vol = [cos(X)*sin(Y)*sin(Z) for X ∈ x, Y ∈ y, Z ∈ z]
plt = volumeslices!(ax, x, y, z, vol)

# connect sliders to `volumeslices` update methods
sl_yz, sl_xz, sl_xy = sgrid.sliders

on(sl_yz.value) do v; plt[:update_yz][](v) end
on(sl_xz.value) do v; plt[:update_xz][](v) end
on(sl_xy.value) do v; plt[:update_xy][](v) end

set_close_to!(sl_yz, .5length(x))
set_close_to!(sl_xz, .5length(y))
set_close_to!(sl_xy, .5length(z))

# add toggles to show/hide heatmaps
hmaps = [plt[Symbol(:heatmap_, s)][] for s ∈ (:yz, :xz, :xy)]
toggles = [Toggle(lo[i, nc + 1], active = true) for i ∈ 1:length(hmaps)]

map(zip(hmaps, toggles)) do (h, t)
    on(t.active) do active
        h.visible = active
    end
end

# cam3d!(ax.scene, projectiontype=Makie.Orthographic)

fig
```

See the [online documentation](https://docs.makie.org/stable/reference/plots/volumeslices) for more examples.
"""
end

function Makie.plot_examples(::Type{<:Voronoiplot})
    return """
## Examples

```julia
using Random
Random.seed!(1234)


f = Figure(size=(1200, 450))
ax = Axis(f[1, 1])
voronoiplot!(ax, rand(Point2f, 50))

ax = Axis(f[1, 2])
voronoiplot!(ax, rand(10, 10), rand(10, 10), rand(10, 10))
f
```

See the [online documentation](https://docs.makie.org/stable/reference/plots/voronoiplot) for more examples.
"""
end

function Makie.plot_examples(::Type{<:Voxels})
    return """
## Examples

```julia
# Same as volume example
r = LinRange(-1, 1, 100)
cube = [(x.^2 + y.^2 + z.^2) for x = r, y = r, z = r]
cube_with_holes = cube .* (cube .> 1.4)

# To match the volume example with isovalue=1.7 and isorange=0.05 we map all
# values outside the range (1.65..1.75) to invisible air blocks with is_air
f, a, p = voxels(-1..1, -1..1, -1..1, cube_with_holes, is_air = x -> !(1.65 <= x <= 1.75))
```

See the [online documentation](https://docs.makie.org/stable/reference/plots/voxels) for more examples.
"""
end

function Makie.plot_examples(::Type{<:VSpan})
    return """
## Examples

```julia
vspan([0, 1, 2], [0.5, 1.2, 2.1])
```

See the [online documentation](https://docs.makie.org/stable/reference/plots/vspan) for more examples.
"""
end

function Makie.plot_examples(::Type{<:Waterfall})
    return """
## Examples

```julia
y = [6, 4, 2, -8, 3, 5, 1, -2, -3, 7]

waterfall(y)
```

See the [online documentation](https://docs.makie.org/stable/reference/plots/waterfall) for more examples.
"""
end

function Makie.plot_examples(::Type{<:Wireframe})
    return """
## Examples

```julia
x, y = collect(-8:0.5:8), collect(-8:0.5:8)
z = [sinc(√(X^2 + Y^2) / π) for X ∈ x, Y ∈ y]

wireframe(x, y, z, axis=(type=Axis3,), color=:black)
```

See the [online documentation](https://docs.makie.org/stable/reference/plots/wireframe) for more examples.
"""
end

