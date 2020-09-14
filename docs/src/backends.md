# Backends

There are three main backends for AbstractPlotting:

- `GLMakie` (Desktop, high performance, 100% features) **default**
- `WGLMakie` (Web, fast drawing, 80% features) **web**
- `CairoMakie` (Print, SVG/PDF, 70% features) **2D-only** (for now)

You can activate any backend by `using` the appropriate package and calling it's `activate!` function; to activate WGLMakie, you would do s`using WGLMakie; WGLMakie.activate!()`.

## [GLMakie](https://github.com/JuliaPlots/GLMakie.jl)

GLMakie is the native, desktop-based backend, and is the most feature-complete.  
It requires an OpenGL enabled graphics card with OpenGL version 3.3 or higher.

## [WGLMakie](https://github.com/JuliaPlots/WGLMakie.jl)

WGLMakie is the Web-based backend, and is still experimental (though relatively feature-complete). Only serving it on a webpage or in Pluto.jl / Ijulia are currently supported. VSCode integration should come soon.

## [CairoMakie](https://github.com/JuliaPlots/CairoMakie.jl)

CairoMakie uses Cairo to draw vector graphics to SVG and PDF.  
It needs Cairo.jl to build properly, which may be difficult on MacOS.

!!! tip "using GPU for rendering scenes in Linux" Normally the dedicated GPU is used for rendering scenes, but in case of mobile GPU's in Linux, one can tell Julia to use the dedicated GPU while launching julia as :` $ sudo DRI_PRIME=1 julia` in bash terminal.
