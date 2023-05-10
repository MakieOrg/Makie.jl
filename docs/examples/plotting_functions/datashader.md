# datashader

{{doc datashader}}

## Examples

### Airports

\begin{examplefigure}{}
```julia
using DelimitedFiles, GLMakie
GLMakie.activate!() # hide
# For saving/showing/inlining into documentation we need to disable async calculation.
Makie.set_theme!(DataShader = (; async_latest=false))
airports = Point2f.(eachrow(readdlm(assetpath("airportlocations.csv"))))
fig, ax, ds = datashader(airports,
    colormap=[:white, :black],
    # use type=Axis, so that Makie doesn't need to infer
    # the axis type, which can be expensive for a large amount of points
    axis = (; type=Axis),
    figure = (; figurepadding=0, resolution=(360*3, 160*3))
)
hidedecorations!(ax); hidespines!(ax)
fig
```
\end{examplefigure}

### Strange Attractors

\begin{examplefigure}{}
```julia
# Taken from Lazaro Alonso in Beautiful Makie:
# https://beautiful.makie.org/dev/examples/generated/2d/datavis/strange_attractors/?h=cliffo#trajectory
Clifford((x, y), a, b, c, d) = Point2f(sin(a * y) + c * cos(a * x), sin(b * x) + d * cos(b * y))

function trajectory(fn, x0, y0, kargs...; n=1000) #  kargs = a, b, c, d
    xy = zeros(Point2f, n + 1)
    xy[1] = Point2f(x0, y0)
    @inbounds for i in 1:n
        xy[i+1] = fn(xy[i], kargs...)
    end
    return xy
end

cargs = [[0, 0, -1.3, -1.3, -1.8, -1.9],
    [0, 0, -1.4, 1.6, 1.0, 0.7],
    [0, 0, 1.7, 1.7, 0.6, 1.2],
    [0, 0, 1.7, 0.7, 1.4, 2.0],
    [0, 0, -1.7, 1.8, -1.9, -0.4],
    [0, 0, 1.1, -1.32, -1.03, 1.54],
    [0, 0, 0.77, 1.99, -1.31, -1.45],
    [0, 0, -1.9, -1.9, -1.9, -1.0],
    [0, 0, 0.75, 1.34, -1.93, 1.0],
    [0, 0, -1.32, -1.65, 0.74, 1.81],
    [0, 0, -1.6, 1.6, 0.7, -1.0],
    [0, 0, -1.7, 1.5, -0.5, 0.7]
]

fig = Figure(resolution=(1000, 1000))
fig_grid = CartesianIndices((3, 4))
cmap = to_colormap(:BuPu_9)
cmap[1] = RGBAf(1, 1, 1, 1) # make sure background is white
for (i, arg) in enumerate(cargs)
    # localy, one can go pretty crazy with n,
    # e.g. 4*(10^7), but we don't want the docbuild to become too slow.
    points = trajectory(Clifford, arg...; n=10^6)
    r, c = Tuple(fig_grid[i])
    ax, plot = datashader(fig[r, c], points;
        colormap=cmap,
        axis=(; type=Axis, title=join(string.(arg), ", ")))
    hidedecorations!(ax)
    hidespines!(ax)
end
rowgap!(fig.layout,5)
colgap!(fig.layout,1)
fig
```
\end{examplefigure}

### Bigger examples

Timings in the comments are from running this on a 32gb Ryzen 5800H laptop.
Both examples aren't fully optimized yet, and just use raw, unsorted, memory mapped Point2f arrays.
In the future, we'll want to add acceleration structures to optimize access to sub-regions.

#### 14 million point NYC taxi dataset

```julia
using GLMakie, Downloads, Parquet2
bucket = "https://ursa-labs-taxi-data.s3.us-east-2.amazonaws.com"
year = 2009
month = "01"
filename = join([year, month, "data.parquet"], "/")
out = joinpath("$year-$month-data.parquet")
url = bucket * "/" * filename
Downloads.download(url, out)
# Loading ~1.5s
@time begin
    ds = Parquet2.Dataset(out)
    dlat = Parquet2.load(ds, "dropoff_latitude")
    dlon = Parquet2.load(ds, "dropoff_longitude")
    # One could use struct array here, but dlon/dlat are
    # a custom array type from Parquet2 supporting missing and some other things, which slows the whole thing down.
    # points = StructArray{Point2f}((dlon, dlat))
    points = Point2f.(dlon, dlat)
end

# ~0.06s
@time begin
    f, ax, ds = datashader(points;
        colormap=:fire,
        axis=(; type=Axis, autolimitaspect = 1),
        figure=(;figure_padding=0, resolution=(1200, 600))
    )
    # make image fill the whole screen
    hidedecorations!(ax)
    hidespines!(ax)
    display(f)
end
```
![](/assets/datashader-14million.gif)

### 2.7 billion OSM GPS points

Download the data from [OSM GPS points](https://planet.osm.org/gps)
and use the script from [drawing-2-7-billion-points-in-10s](https://medium.com/hackernoon/drawing-2-7-billion-points-in-10s-ecc8c85ca8fa) to convert the CSV to a binary blob that we can memory map.

The script needed some updates for the current Julia version
that you can find [here](https://gist.github.com/SimonDanisch/c5a92afe63476343e5b6b45be84774b7#file-fast-csv-parse-jl).

```julia
using GLMakie, Mmap
path = "gpspoints.bin"

points = Mmap.mmap(open(path, "r"), Vector{Point2f});
# ~ 26s
@time begin
    f, ax, pl = datashader(
        points;
        # For a big dataset its interesting to see how long each aggregation takes
        show_timings = true,
        # Use a local operation which is faster to calculate and looks good!
        local_post=x-> log10(x + 1),
        #=
            in the code we used to save the binary, we had the points in the wrong order.
            A good chance to demonstrate the `point_func` argument,
            Which gets applied to every point before aggregating it
        =#
        point_func=reverse,
        axis=(; type=Axis, autolimitaspect = 1),
        figure=(;figure_padding=0, resolution=(1200, 600))
    )
    hidedecorations!(ax)
    hidespines!(ax)
    display(f)
end
```
```
aggregation took 1.395s
aggregation took 1.176s
aggregation took 0.81s
aggregation took 0.791s
aggregation took 0.729s
aggregation took 1.272s
aggregation took 1.117s
aggregation took 0.866s
aggregation took 0.724s
```
![](/assets/datashader_2-7_billion.gif)
