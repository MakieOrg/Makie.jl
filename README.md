# WGLMakie

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://SimonDanisch.github.io/WGLMakie.jl/stable)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://SimonDanisch.github.io/WGLMakie.jl/dev)
[![Build Status](https://travis-ci.com/SimonDanisch/WGLMakie.jl.svg?branch=master)](https://travis-ci.com/SimonDanisch/WGLMakie.jl)
[![Build Status](https://ci.appveyor.com/api/projects/status/github/SimonDanisch/WGLMakie.jl?svg=true)](https://ci.appveyor.com/project/SimonDanisch/WGLMakie-jl)
[![Codecov](https://codecov.io/gh/SimonDanisch/WGLMakie.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/SimonDanisch/WGLMakie.jl)

WGLMakie is a WebGL backend for the [Makie.jl](https://www.github.com/JuliaPlots/Makie.jl) plotting package, implemented using Three.js.

# Installation

```julia
using Pkg
pkg"up; add https://github.com/SimonDanisch/ShaderAbstractions.jl https://github.com/JuliaPlots/WGLMakie.jl GeometryBasics#master Tables Observables AbstractPlotting#sd-webgl GeometryTypes JSCall#master StaticArrays WebIO#sd-httpheader RDatasets DataFrames StatsMakie MakieGallery#master"
```

## Teardown (if you want to uninstall)

```julia
using Pkg
pkg"rm ShaderAbstractions WGLMakie; free GeometryBasics AbstractPlotting WebIO JSCall MakieGallery"
```

Warning - this package is **in development** and **may break often**. 

# Usage

Still to come, but it will use the `AbstractPlotting` standard interface:

```julia
using AbstractPlotting, WGLMakie

AbstractPlotting.current_backend[] = WGLMakie.WGLBackend()
```

