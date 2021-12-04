# Backends & Output

Makie is the frontend package that defines all plotting functions.
It is reexported by every backend, so you don't have to specifically install or import it.

There are three main backends which concretely implement all abstract rendering capabilities defined in Makie:

| Package                                                        | Description                                                                           |
| :------------------------------------------------------------- | :------------------------------------------------------------------------------------ |
| [`GLMakie.jl`](https://github.com/JuliaPlots/Makie.jl/tree/master/GLMakie)       | GPU-powered, interactive 2D and 3D plotting in standalone `GLFW.jl` windows.          |
| [`CairoMakie.jl`](https://github.com/JuliaPlots/Makie.jl/tree/master/CairoMakie) | `Cairo.jl` based, non-interactive 2D backend for publication-quality vector graphics. |
| [`WGLMakie.jl`](https://github.com/JuliaPlots/Makie.jl/tree/master/WGLMakie)     | WebGL-based interactive 2D and 3D plotting that runs within browsers.                 |
| [`RPRMakie.jl`](https://github.com/JuliaPlots/Makie.jl/tree/master/RPRMakie)     | An experimental Ray tracing backend.                 |

### Activating Backends

You can activate any backend by `using` the appropriate package and calling its `activate!` function.

Example with WGLMakie:

```julia
using WGLMakie
WGLMakie.activate!()
```

## GLMakie

[GLMakie](https://github.com/JuliaPlots/Makie.jl/tree/master/GLMakie) is the native, desktop-based backend, and is the most feature-complete.
It requires an OpenGL enabled graphics card with OpenGL version 3.3 or higher.

### Special GLMakie Properties

#### Window Parameters

You can set parameters of the window with the function `set_window_config!` which only takes effect when opening a new window.

```julia
set_window_config!(;
    renderloop = renderloop,
    vsync = false,
    framerate = 30.0,
    float = false,
    pause_rendering = false,
    focus_on_show = false,
    decorated = true,
    title = "Makie"
)
```

## CairoMakie

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

## WGLMakie

[WGLMakie](https://github.com/JuliaPlots/Makie.jl/tree/master/WGLMakie) is the Web-based backend, and is still experimental (though relatively feature-complete). Serving it on a webpage or in Pluto.jl / Ijulia / VSCode are currently supported.

## Miscellaneous Tips

### Forcing Dedicated GPU Use In Linux

Normally the dedicated GPU is used for rendering.
If instead an integrated GPU is used, one can tell Julia to use the dedicated GPU while launching julia as `$ sudo DRI_PRIME=1 julia` in the bash terminal.
