````@raw html
---
# https://vitepress.dev/reference/default-theme-home-page
layout: home

hero:
  name: Makie
  text:
  tagline: Interactive data visualizations and plotting in Julia
  image:
    src: logo.svg
    alt: Makie
  actions:
    - theme: brand
      text: Getting started
      link: /tutorials/getting-started
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

Makie turns your data into beautiful images or animations, such as this one:

::: details Show me the code

```@example
using GLMakie
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

points = Point3f[]
colors = Int[]

set_theme!(theme_black())

fig, ax, l = lines(points, color = colors,
    colormap = :inferno, transparency = true,
    axis = (; type = Axis3, protrusions = (0, 0, 0, 0),
              viewmode = :fit, limits = (-30, 30, -30, 30, 0, 50)))

record(fig, "lorenz.mp4", 1:120) do frame
    for i in 1:50
        push!(points, step!(attractor))
        push!(colors, frame)
    end
    ax.azimuth[] = 1.7pi + 0.3 * sin(2pi * frame / 120)
    Makie.update!(l, arg1 = points, color = colors) # Makie 0.24+
    l.colorrange = (0, frame)
end
set_theme!() # hide
```
:::

```@raw html
<video autoplay loop muted playsinline controls src="./lorenz.mp4" style="max-height: 40vh;"/>
```

## Installation

Makie offers four different backends (more info under [What is a backend](@ref)).
We suggest GLMakie for GPU-accelerated, interactive plots, and CairoMakie for static vector graphics.

- [GLMakie](@ref) (OpenGL based, interactive)
- [CairoMakie](@ref) (Cairo based, static vector graphics)
- [WGLMakie](@ref) (WebGL based, displays plots in the browser)
- [RPRMakie](@ref) (Experimental ray-tracing using RadeonProRender)

Then install it using Julia's package manager `Pkg`:

```julia
using Pkg
Pkg.add("GLMakie")
```

There's no need to install `Makie.jl` separately, it is re-exported by each backend package.

## First Steps

If you are new to Makie, have a look at [Getting started](@ref).

For inspiration, visit [Beautiful Makie](https://beautiful.makie.org/) for a collection of interesting plots.

An overview of third-party packages that expand Makie's capabilities is at [Ecosystem](@ref).

## Citing Makie

If you use Makie for a scientific publication, please cite [our JOSS paper](https://joss.theoj.org/papers/10.21105/joss.03349) the following way:

> Danisch & Krumbiegel, (2021). Makie.jl: Flexible high-performance data visualization for Julia. Journal of Open Source Software, 6(65), 3349, https://doi.org/10.21105/joss.03349

::: details Show BibTeX

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

:::

## Getting Help

1. Use the REPL `?` help mode.
1. Click this link to open a preformatted topic on the [Julia Discourse Page](https://discourse.julialang.org/new-topic?title=Makie%20-%20Your%20question%20here&category=domain/viz&tags=Makie&body=You%20can%20write%20your%20question%20in%20this%20space.%0A%0ABefore%20asking%2C%20please%20take%20a%20minute%20to%20make%20sure%20that%20you%20have%20installed%20the%20latest%20available%20versions%20and%20have%20looked%20at%20%5Bthe%20most%20recent%20documentation%5D(http%3A%2Fmakie.juliaplots.org%2Fstable%2F)%20%3Ainnocent%3A). If you do this manually, please use the category Domain/Visualization and tag questions with `Makie` to increase their visibility.
1. For casual conversation about Makie and its development, have a look at the  [Makie Discord Server](https://discord.gg/6mpFXPCvks). Please direct your usage questions to [Discourse](https://discourse.julialang.org/new-topic?title=Makie%20-%20Your%20question%20here&category=domain/viz&tags=Makie&body=You%20can%20write%20your%20question%20in%20this%20space.%0A%0ABefore%20asking%2C%20please%20take%20a%20minute%20to%20make%20sure%20that%20you%20have%20installed%20the%20latest%20available%20versions%20and%20have%20looked%20at%20%5Bthe%20most%20recent%20documentation%5D(http%3A%2Fmakie.juliaplots.org%2Fstable%2F)%20%3Ainnocent%3A) and not to Slack, to make questions and answers accessible to everybody.
1. For technical issues and bug reports, open an [issue](https://github.com/MakieOrg/Makie.jl/issues/new) in the [Makie.jl](https://github.com/MakieOrg/Makie.jl) repository which serves as the central hub for Makie and backend issues.
