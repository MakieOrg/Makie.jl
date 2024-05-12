````@raw html
---
# https://vitepress.dev/reference/default-theme-home-page
layout: home

hero:
  name: Makie.jl
  text: 
  tagline: Interactive data visualizations and plotting in Julia 
  image:
    src: logo.svg
    alt: Makie
  actions:
    - theme: brand
      text: Introduction
      link: /introduction
    - theme: alt
      text: View on Github
      link: https://github.com/MakieOrg/Makie.jl
    - theme: alt
      text: API Reference
      link: /api
---
````

# Welcome to Makie!

Makie is a data visualization ecosystem for the [Julia](https://julialang.org/) programming language, with high performance and extensibility.
It is available for Windows, Mac and Linux.

## Example

```@example
using GLMakie # All functionality is defined in Makie and every backend re-exports Makie
GLMakie.activate!() # hide

Base.@kwdef mutable struct Lorenz
    dt::Float64 = 0.01
    σ::Float64 = 10
    ρ::Float64 = 28
    β::Float64 = 8/3
    x::Float64 = 1
    y::Float64 = 1
    z::Float64 = 1
end

function step!(l::Lorenz)
    dx = l.σ * (l.y - l.x)
    dy = l.x * (l.ρ - l.z) - l.y
    dz = l.x * l.y - l.β * l.z
    l.x += l.dt * dx
    l.y += l.dt * dy
    l.z += l.dt * dz
    Point3f(l.x, l.y, l.z)
end

attractor = Lorenz()

points = Observable(Point3f[]) # Signal that can be used to update plots efficiently
colors = Observable(Int[])

set_theme!(theme_black())

fig, ax, l = lines(points, color = colors,
    colormap = :inferno, transparency = true, 
    axis = (; type = Axis3, protrusions = (0, 0, 0, 0), 
              viewmode = :fit, limits = (-30, 30, -30, 30, 0, 50)))

record(fig, "lorenz.mp4", 1:120) do frame
    for i in 1:50
        # update arrays inplace
        push!(points[], step!(attractor))
        push!(colors[], frame)
    end
    ax.azimuth[] = 1.7pi + 0.3 * sin(2pi * frame / 120) # set the view angle of the axis
    notify(points); notify(colors) # tell points and colors that their value has been updated
    l.colorrange = (0, frame) # update plot attribute directly
end
set_theme!() # hide
```

```@raw html
<video autoplay loop muted playsinline controls src="./lorenz.mp4" />
```

## Installation and Import

Add one or more of the Makie backend packages [`GLMakie.jl`](/explanations/backends/glmakie/) (OpenGL), [`CairoMakie.jl`](/explanations/backends/cairomakie/) (Cairo), or [`WGLMakie.jl`](/explanations/backends/wglmakie/) (WebGL), [`RPRMakie`](/explanations/backends/rprmakie/) (RadeonProRender) using Julia's inbuilt package manager. Each backend re-exports `Makie` so there's no need to install it separately.

Makie is the core package, and the backends have no user facing functionality.  They only render the final result.  See the [Backends](@ref) page for more information!

```julia
]add GLMakie
using GLMakie
```

To switch to a different backend, for example `CairoMakie`, call `CairoMakie.activate!()`.

## First Steps

### Basic Tutorial
Learn the basics of plotting with Makie.

![Basic Tutorial](/assets/basic_tutorial_example.png)

### Layout Tutorial
Check out how to make complex plots and layouts.

![Layout Tutorial](/assets/layout_tutorial.png)

### Plot Reference
A visual reference of all available plotting functions and their attributes.

![Plot Reference](/assets/mandelbrot_heatmap.png)


## Makie Ecosystem

There are four backends, each of which has particular strengths. You can switch between backends at any time.

### GLMakie.jl
GPU-powered, interactive 2D and 3D plotting in standalone `GLFW.jl` windows.

![GLMakie.jl](/assets/surface_example.png)

### CairoMakie.jl
`Cairo.jl` based, non-interactive 2D backend for publication-quality vector graphics.

![CairoMakie.jl](/assets/density_example.png)

### WGLMakie.jl
WebGL-based interactive 2D and 3D plotting that runs within browsers.

![WGLMakie.jl](/assets/wireframe_example.png)

### RPRMakie.jl
Backend using RadeonProRender for raytracing Makie scenes.

![RPRMakie.jl](/assets/topographie.png)

The differences between backends are explained in more details under [Backends](@ref).

### Extensions and Resources

These packages and sites are maintained by third parties. If you install packages, keep an eye on version conflicts or downgrades as the Makie ecosystem is developing quickly so things break occasionally.

### AlgebraOfGraphics.jl
Grammar-of-graphics style plotting, inspired by ggplot2.

![AlgebraOfGraphics.jl](/assets/aog_example.png)

### Beautiful Makie
This third-party gallery contains many advanced examples.

![Beautiful Makie](/assets/beautifulmakie_example.png)

### GraphMakie.jl
Graphs with two- and three-dimensional layout algorithms.

![GraphMakie.jl](/assets/graphmakie.png)

### GeoMakie.jl
Geographic plotting utilities including projections.

![GeoMakie.jl](/assets/geomakie_example.png)


## Citing Makie

If you use Makie for a scientific publication, please cite [our JOSS paper](https://joss.theoj.org/papers/10.21105/joss.03349) the following way:

> Danisch & Krumbiegel, (2021). Makie.jl: Flexible high-performance data visualization for Julia. Journal of Open Source Software, 6(65), 3349, https://doi.org/10.21105/joss.03349

You can use the following BibTeX entry:

```
@article{DanischKrumbiegel2021,
  doi = {10.21105/joss.03349},
  url = {https://doi.org/10.21105/joss.03349},
  year = {2021},
  publisher = {The Open Journal},
  volume = {6},
  number = {65},
  pages = {3349},
  author = {Simon Danisch and Julius Krumbiegel},
  title = {{Makie.jl}: Flexible high-performance data visualization for {Julia}},
  journal = {Journal of Open Source Software}
}
```

## Getting Help

1. Use the REPL `?` help mode.
1. Click this link to open a preformatted topic on the [Julia Discourse Page](https://discourse.julialang.org/new-topic?title=Makie%20-%20Your%20question%20here&category=domain/viz&tags=Makie&body=You%20can%20write%20your%20question%20in%20this%20space.%0A%0ABefore%20asking%2C%20please%20take%20a%20minute%20to%20make%20sure%20that%20you%20have%20installed%20the%20latest%20available%20versions%20and%20have%20looked%20at%20%5Bthe%20most%20recent%20documentation%5D(http%3A%2Fmakie.juliaplots.org%2Fstable%2F)%20%3Ainnocent%3A). If you do this manually, please use the category Domain/Visualization and tag questions with `Makie` to increase their visibility.
1. For casual conversation about Makie and its development, have a look at the  [Makie Discord Server](https://discord.gg/6mpFXPCvks). Please direct your usage questions to [Discourse](https://discourse.julialang.org/new-topic?title=Makie%20-%20Your%20question%20here&category=domain/viz&tags=Makie&body=You%20can%20write%20your%20question%20in%20this%20space.%0A%0ABefore%20asking%2C%20please%20take%20a%20minute%20to%20make%20sure%20that%20you%20have%20installed%20the%20latest%20available%20versions%20and%20have%20looked%20at%20%5Bthe%20most%20recent%20documentation%5D(http%3A%2Fmakie.juliaplots.org%2Fstable%2F)%20%3Ainnocent%3A) and not to Slack, to make questions and answers accessible to everybody.
1. For technical issues and bug reports, open an [issue](https://github.com/MakieOrg/Makie.jl/issues/new) in the [Makie.jl](https://github.com/MakieOrg/Makie.jl) repository which serves as the central hub for Makie and backend issues.
