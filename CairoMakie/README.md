# CairoMakie

The Cairo Backend for Makie

Read the docs for Makie and it's backends [here](http://makie.juliaplots.org/.dev)


## Issues

Please file all issues in [Makie.jl](https://github.com/JuliaPlots/Makie.jl/issues/new), and mention CairoMakie in the issue text.

## Limitations

CairoMakie is intended as a backend for static vector graphics at publication quality. Therefore, it does not support the interactive features of GLMakie and is slower when visualizing large amounts data. 3D plots are currently not available because of the inherent limitations of 2D vector graphics.

## Saving

Makie overloads the FileIO interface, so you can save a Scene `scene` as `save("filename.extension", scene)`. CairoMakie supports saving to PNG, PDF, SVG and EPS.

You can scale the size of the output figure, without changing its appearance by passing keyword arguments to `save`. PNGs can be scaled by `px_per_unit` (default 1) and vector graphics (SVG, PDF, EPS) can be scaled by `pt_per_unit`.

```julia
save("plot.svg", scene, pt_per_unit = 0.5) # halve the dimensions of the resulting SVG
save("plot.png", scene, px_per_unit = 2) # double the resolution of the resulting PNG
```

## Using CairoMakie with Gtk.jl

You can render onto a GtkCanvas using Gtk, and use that as a display for your scenes.

```julia
using Gtk, CairoMakie

canvas = @GtkCanvas()
window = GtkWindow(canvas, "Makie", 500, 500)

function drawonto(canvas, figure)
    @guarded draw(canvas) do _
        scene = figure.scene
        resize!(scene, Gtk.width(canvas), Gtk.height(canvas))
        screen = CairoMakie.CairoScreen(scene, Gtk.cairo_surface(canvas), getgc(canvas), nothing)
        CairoMakie.cairo_draw(screen, scene)
    end
end

fig, ax, pl = heatmap(rand(50, 50)) # or something

drawonto(canvas, fig)
show(canvas); # trigger rendering
```
