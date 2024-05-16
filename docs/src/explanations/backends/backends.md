# What is a backend

Makie is the frontend package that defines all plotting functions.
It is reexported by every backend, so you don't have to specifically install or import it.

There are four backends which concretely implement all abstract rendering capabilities defined in Makie:

| Package                                                        | Description                                                                           |
| :------------------------------------------------------------- | :------------------------------------------------------------------------------------ |
| [GLMakie](@ref)       | GPU-powered, interactive 2D and 3D plotting in standalone `GLFW.jl` windows.          |
| [CairoMakie](@ref) | `Cairo.jl` based, non-interactive 2D (and some 3D) backend  for publication-quality vector graphics. |
| [WGLMakie](@ref)     | WebGL-based interactive 2D and 3D plotting that runs within browsers.                 |
| [RPRMakie](@ref)     | An experimental ray tracing backend.                 |

### Activating Backends

You can activate any backend by `using` the appropriate package and calling its `activate!` function.

Example with WGLMakie:

```julia
using WGLMakie
WGLMakie.activate!()
```

Each backend's `activate!` function optionally takes keyword arguments (referred to as `screen_config...`) that control various aspects of the backend.
For example, to activate the GLMakie backend and set it up to produce windows with a custom title and no anti-aliasing:

```julia
using GLMakie
GLMakie.activate!(title = "Custom title", fxaa = false)
```

The keyword arguments accepted by each backend are listed in the backend-specific documentation pages linked in the table above.