# WGLMakie

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://JuliaPlots.github.io/WGLMakie.jl/stable)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://JuliaPlots.github.io/WGLMakie.jl/dev)
[![Build Status](https://travis-ci.com/JuliaPlots/WGLMakie.jl.svg?branch=master)](https://travis-ci.com/JuliaPlots/WGLMakie.jl)
[![Codecov](https://codecov.io/gh/JuliaPlots/WGLMakie.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/JuliaPlots/WGLMakie.jl)

WGLMakie is a WebGL backend for the [Makie.jl](https://www.github.com/JuliaPlots/Makie.jl) plotting package, implemented using Three.js.

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

## Sponsors

<img src="https://github.com/JuliaPlots/Makie.jl/blob/master/assets/BMBF_gefoerdert_2017_en.jpg?raw=true" width="300"/>
Förderkennzeichen: 01IS10S27, 2020
