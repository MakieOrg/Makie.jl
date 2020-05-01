# CairoMakie

The Cairo Backend for Makie

[![Build Status](https://travis-ci.org/JuliaPlots/CairoMakie.jl.svg?branch=master)](https://travis-ci.org/JuliaPlots/CairoMakie.jl) ![](https://github.com/JuliaPlots/CairoMakie.jl/workflows/CI/badge.svg)

[![codecov](https://codecov.io/gh/JuliaPlots/CairoMakie.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/JuliaPlots/CairoMakie.jl)

## Usage

To add CairoMakie to your environment, simply run the following in the REPL:
```julia
]add CairoMakie
```

If you are using CairoMakie and GLMakie together, you can use each backend's `activate!` function to switch between them.

## Issues
Please file all issues in the [Makie.jl](https://github.com/JuliaPlots/Makie.jl/issues/new), and mention CairoMakie in the issue text!

## Limitations

As of now, CairoMakie only supports 2D scenes.  It is also noticeably slower than GLMakie.

## Saving

Makie overloads the FileIO interface, so you can save a Scene `scene` as `save("filename.extension", scene)`.  CairoMakie supports saving to PNG, PDF, SVG and EPS.

Additionally, when using CairoMakie, you can scale the resolution or size which you save a figure at, without changing its appearance.  This scaling factor is configured by passing keyword arguments to `save`.  PNGs can be scaled by `px_per_unit` (default 1) and vector graphics (SVG, PDF, EPS) can be scaled by `pt_per_unit`.

## Using CairoMakie with Gtk.jl

You can render onto a GtkCanvas using Gtk, and use that as a display for your scenes.

```julia
using Gtk, CairoMakie, AbstractPlotting

canvas = @GtkCanvas()
window = GtkWindow(canvas, "Makie", 500, 500)

function drawonto(canvas, scene)
    @guarded draw(canvas) do _
       resize!(scene, Gtk.width(canvas), Gtk.height(canvas))
       screen = CairoMakie.CairoScreen(scene, Gtk.cairo_surface(canvas), getgc(canvas), nothing)
       CairoMakie.cairo_draw(screen, scene)
    end
end

scene = heatmap(rand(50, 50)) # or something

drawonto(canvas, scene)
show(canvas); # trigger rendering
```
