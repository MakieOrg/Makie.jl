
![CI](https://github.com/JuliaPlots/WGLMakie.jl/workflows/CI/badge.svg)
[![Codecov](https://codecov.io/gh/JuliaPlots/WGLMakie.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/JuliaPlots/WGLMakie.jl)

WGLMakie is a WebGL backend for the [Makie.jl](https://www.github.com/JuliaPlots/Makie.jl) plotting package, implemented using Three.js.


Backend specific docs, for creating interactive and static html pages:

[![](https://img.shields.io/badge/docs-stable-blue.svg)](http://juliaplots.org/WGLMakie.jl/stable/)
[![](https://img.shields.io/badge/docs-master-blue.svg)](http://juliaplots.org/WGLMakie.jl/dev/)

# Installation

```julia
using Pkg
pkg"add WGLMakie AbstractPlotting"
```

## Teardown (if you want to uninstall)

```julia
using Pkg
pkg"rm WGLMakie"
```


# Usage

Now, it should just work like Makie:

```julia
using AbstractPlotting, WGLMakie

scatter(rand(4))
```
In the REPL, this will open a browser tab, that will refresh on a new display.
In VSCode, this should open in the plotpane.
You can also embed plots in a JSServe webpage:
```julia
function dom_handler(session, request)
    return DOM.div(
        DOM.h1("Some Makie Plots:"),
        meshscatter(1:4, color=1:4),
        meshscatter(1:4, color=rand(RGBAf0, 4)),
        meshscatter(1:4, color=rand(RGBf0, 4)),
        meshscatter(1:4, color=:red),
        meshscatter(rand(Point3f0, 10), color=rand(RGBf0, 10)),
        meshscatter(rand(Point3f0, 10), marker=Pyramid(Point3f0(0), 1f0, 1f0)),
    )
end
isdefined(Main, :app) && close(app)
app = JSServe.Server(dom_handler, "127.0.0.1", 8082)
```

## Sponsors

<img src="https://github.com/JuliaPlots/Makie.jl/blob/master/assets/BMBF_gefoerdert_2017_en.jpg?raw=true" width="300"/>
Förderkennzeichen: 01IS10S27, 2020
