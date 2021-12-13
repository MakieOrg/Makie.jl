# Backends

Makie is the frontend package that defines all plotting functions.
It is reexported by every backend, so you don't have to specifically install or import it.

There are four backends which concretely implement all abstract rendering capabilities defined in Makie:

| Package                                                        | Description                                                                           |
| :------------------------------------------------------------- | :------------------------------------------------------------------------------------ |
| [`GLMakie.jl`](/documentation/backends/glmakie/)       | GPU-powered, interactive 2D and 3D plotting in standalone `GLFW.jl` windows.          |
| [`CairoMakie.jl`](/documentation/backends/cairomakie/) | `Cairo.jl` based, non-interactive 2D backend for publication-quality vector graphics. |
| [`WGLMakie.jl`](/documentation/backends/wglmakie/)     | WebGL-based interactive 2D and 3D plotting that runs within browsers.                 |
| [`RPRMakie.jl`](/documentation/backends/rprmakie/)     | An experimental Ray tracing backend.                 |

### Activating Backends

You can activate any backend by `using` the appropriate package and calling its `activate!` function.

Example with WGLMakie:

```julia
using WGLMakie
WGLMakie.activate!()
```
