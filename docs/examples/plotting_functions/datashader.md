
```julia
using Parquet2
using LinearAlgebra, Interpolations, Downloads
bucket = "https://ursa-labs-taxi-data.s3.us-east-2.amazonaws.com"
year=2009
month="01"
filename = join([year, month, "data.parquet"], "/")
out = joinpath("$year-$month-data.parquet")
url = bucket * "/" * filename
Downloads.download(url, out)
ds = Parquet2.Dataset(out)

dlat = Parquet2.load(ds, "dropoff_latitude")
dlon = Parquet2.load(ds, "dropoff_longitude")

points = Point2f.(dlat, dlon)

function eq_hist(matrix; nbins=256 * 256)
    h_eq = fit(Histogram, vec(matrix), nbins=nbins)
    h_eq = normalize(h_eq, mode=:density)
    cdf = cumsum(h_eq.weights)
    cdf = cdf / cdf[end]
    edg = h_eq.edges[1]
    interp_linear = LinearInterpolation(edg, [cdf..., cdf[end]])
    out = reshape(interp_linear(vec(matrix)), size(matrix))
    return out
end
f, ax, pl = datashader(pointies;
    binfactor=1, axis=(; type=Axis), post=eq_hist, colormap=:fire)
```


```julia

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

points = trajectory(Clifford, cargs[1]...; n=4 * (10^7))

datashader(points; colormap=[:black; Makie.to_colormap(:batlow)],
    binfactor=2,
    post=mat -> log10.(mat .+ 1.0f0), axis=(; type=Axis))
```
