# GLMakie

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

### Forcing Dedicated GPU Use In Linux

Normally the dedicated GPU is used for rendering.
If instead an integrated GPU is used, one can tell Julia to use the dedicated GPU while launching julia as `$ sudo DRI_PRIME=1 julia` in the bash terminal.
