# CairoMakie

[CairoMakie](https://github.com/JuliaPlots/Makie.jl/tree/master/CairoMakie) uses Cairo.jl to draw vector graphics to SVG and PDF.
You should use it if you want to achieve the highest-quality plots for publications, as the rendering process of the GL backends works via bitmaps and is geared more towards speed than pixel-perfection.

### Special CairoMakie Properties

#### Inline Plot Type

You can choose the type of plot that is displayed inline in, e.g., VSCode, Pluto.jl, or any other environment, by setting it via the `activate!` function.

```julia
CairoMakie.activate!(type = "png")
CairoMakie.activate!(type = "svg")
```

#### Resolution Scaling

When you save a CairoMakie figure, you can change the mapping from figure resolution to pixels (when saving to png) or points (when saving to svg or pdf).
This way you can easily scale the resulting image up or down without having to change any plot element sizes.

Just specify `pt_per_unit` when saving vector formats and `px_per_unit` when saving pngs.
`px_per_unit` defaults to 1 and `pt_per_unit` defaults to 0.75.
When embedding svgs in websites, `1px` is equivalent to `0.75pt`.
This means that by default, saving a png or an svg results in an embedded image of the same apparent size.
If you require an exact size in `pt`, consider setting `pt_per_unit = 1`.

Here's an example:

```julia
fig = Figure(resolution = (800, 600))

save("normal.pdf", fig) # size = 600 x 450 pt
save("larger.pdf", fig, pt_per_unit = 2) # size = 1600 x 1200 pt
save("smaller.pdf", fig, pt_per_unit = 0.5) # size = 400 x 300 pt

save("normal.png", fig) # size = 800 x 600 px
save("larger.png", fig, px_per_unit = 2) # size = 1600 x 1200 px
save("smaller.png", fig, px_per_unit = 0.5) # size = 400 x 300 px
```

#### Z-Order

CairoMakie as a 2D engine has no concept of z-clipping, therefore its 3D capabilities are quite limited.
The z-values of 3D plots will have no effect and will be projected flat onto the canvas.
Z-layering is approximated by sorting all plot objects by their z translation value before drawing, after that by parent scene and then insertion order.
Therefore, if you want to draw something on top of something else, but it ends up below, try translating it forward via `translate!(obj, 0, 0, some_positive_z_value)`.

#### Selective Rasterization

By setting the `rasterize` attribute of a plot, you can tell CairoMakie that this plot needs to be rasterized when saving, even if saving to a vector backend.  This can be very useful for large meshes, surfaces or even heatmaps if on an irregular grid.

Assuming that you have a `Plot` object `plt`, you can set `plt.rasterize = true` for simple rasterization, or you can set `plt.rasterize = scale::Int`, where `scale` represents the scaling factor for the image surface.

For example, if your Scene's resolution is `(800, 600)`, by setting `scale=2`, the rasterized image will have a resolution of `(1600, 1200)`.

You can deactivate this rasterization by setting `plt.rasterize = false`.

Example: 
``` 
fig = Figure()
scatter(fig[1,1], v[:,1], v[:,2], rasterize = true, markersize = 1.0)
save("raster_test.pdf", fig)
```
