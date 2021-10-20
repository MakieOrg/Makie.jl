@def title = "Home"
@def order = 0
@def frontpage = true

# Welcome to Makie!

Makie is a data visualization ecosystem for the [Julia](https://julialang.org/) programming language, with high performance and extensibility.
It is available for Windows, Mac and Linux.

## Example

~~~
<input id="hidecode" class="hidecode" type="checkbox">
~~~
```julia:lorenz
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

points = Node(Point3f[])
colors = Node(Int[])

set_theme!(theme_black())

fig, ax, l = lines(points, color = colors,
    colormap = :inferno, transparency = true,
    axis = (; type = Axis3, protrusions = (0, 0, 0, 0),
        viewmode = :fit, limits = (-30, 30, -30, 30, 0, 50)))

record(fig, "lorenz.mp4", 1:120) do frame
    for i in 1:50
        push!(points[], step!(attractor))
        push!(colors[], frame)
    end
    ax.azimuth[] = 1.7pi + 0.3 * sin(2pi * frame / 120)
    notify.((points, colors))
    l.colorrange = (0, frame)
end
set_theme!() # hide
```
~~~
<label for="hidecode" class="hidecode"></label>
~~~

\video{lorenz, autoplay = true}

## Installation and Import

Add one or more of the Makie backend packages [`GLMakie.jl`](https://github.com/JuliaPlots/Makie.jl/tree/master/GLMakie) (OpenGL), [`CairoMakie.jl`](https://github.com/JuliaPlots/Makie.jl/tree/master/CairoMakie) (Cairo), or [`WGLMakie.jl`](https://github.com/JuliaPlots/Makie.jl/tree/master/WGLMakie) (WebGL) using Julia's inbuilt package manager. Each backend re-exports `Makie` so there's no need to install it separately.

```julia
]add GLMakie
using GLMakie
```

To switch to a different backend, for example `CairoMakie`, call `CairoMakie.activate!()`.

## First Steps

@@box-container
  @@box
    ~~~<a class="boxlink" href="tutorials/basic-tutorial/">~~~
    @@title Basic Tutorial @@
    @@box-content
      @@description
      Learn the basics of plotting with Makie.
      @@
      ~~~
      <img src="/assets/basic_tutorial_example.png">
      ~~~
    @@
    ~~~</a>~~~
  @@

  @@box
    ~~~<a class="boxlink" href="tutorials/layout-tutorial/">~~~
    @@title Layout Tutorial @@
    @@box-content
      @@description
      Check out how to make complex plots and layouts.
      @@
      ~~~
      <img src="/assets/tutorials/layout-tutorial/code/output/final_result.png">
      ~~~
    @@
    ~~~</a>~~~
  @@

  @@box
    ~~~<a class="boxlink" href="examples/plotting_functions/">~~~
    @@title Plot Examples @@
    @@box-content
      @@description
      Have a look at this list of examples for the available plotting functions.
      @@
      ~~~
      <img src="/assets/examples/plotting_functions/heatmap/code/output/mandelbrot_heatmap.png">
      ~~~
    @@
    ~~~</a>~~~
  @@

@@

## Makie Ecosystem

There are three backends, each of which has particular strengths. You can switch between backends at any time.

@@box-container
  @@box
    ~~~<a class="boxlink" href="https://github.com/JuliaPlots/Makie.jl/tree/master/GLMakie">~~~
    @@title GLMakie.jl@@
    @@box-content
      @@description
      GPU-powered, interactive 2D and 3D plotting in standalone `GLFW.jl` windows.
      @@
      ~~~
      <img src="/assets/surface_example.png">
      ~~~
    @@
    ~~~</a>~~~
  @@

  @@box
    ~~~<a class="boxlink" href="https://github.com/JuliaPlots/Makie.jl/tree/master/CairoMakie">~~~
    @@title CairoMakie.jl @@
    @@box-content
      @@description
      `Cairo.jl` based, non-interactive 2D backend for publication-quality vector graphics.
      @@
      ~~~
      <img src="/assets/density_example.png">
      ~~~
    @@
    ~~~</a>~~~
  @@

  @@box
    ~~~<a class="boxlink" href="https://github.com/JuliaPlots/Makie.jl/tree/master/WGLMakie">~~~
    @@title WGLMakie.jl @@
    @@box-content
      @@description
      WebGL-based interactive 2D and 3D plotting that runs within browsers.
      @@
      ~~~
      <img src="/assets/wireframe_example.png">
      ~~~
    @@
    ~~~</a>~~~
  @@
@@

The differences between backends are explained in more details under \myreflink{Backends & Output}.

### Extensions and Resources

These packages and sites are maintained by third parties. If you install packages, keep an eye on version conflicts or downgrades as the Makie ecosystem is developing quickly so things break occasionally.

@@box-container
  @@box
    ~~~<a class="boxlink" href="https://github.com/JuliaPlots/AlgebraOfGraphics.jl/">~~~
    @@title AlgebraOfGraphics.jl @@
    @@box-content
      @@description
      Grammar-of-graphics style plotting, inspired by ggplot2.
      @@
      ~~~
      <img src="/assets/aog_example.png">
      ~~~
    @@
    ~~~</a>~~~
  @@

  @@box
    ~~~<a class="boxlink" href="https://lazarusa.github.io/BeautifulMakie/">~~~
    @@title Beautiful Makie @@
    @@box-content
      @@description
      This third-party gallery contains many advanced examples.
      @@
      ~~~
      <img src="/assets/beautifulmakie_example.png">
      ~~~
    @@
    ~~~</a>~~~
  @@

  @@box
    ~~~<a class="boxlink" href="https://github.com/JuliaPlots/GraphMakie.jl">~~~
    @@title GraphMakie.jl @@
    @@box-content
      @@description
      Graphs with two- and three-dimensional layout algorithms.
      @@
      ~~~
      <img src="/assets/graphmakie.png">
      ~~~
    @@
    ~~~</a>~~~
  @@

  @@box
    ~~~<a class="boxlink" href="https://github.com/JuliaPlots/GeoMakie.jl">~~~
    @@title GeoMakie.jl @@
    @@box-content
      @@description
      Geographic plotting utilities including projections.
      @@
      ~~~
      <img src="/assets/geomakie_example.png">
      ~~~
    @@
    ~~~</a>~~~
  @@
@@


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
  title = {Makie.jl: Flexible high-performance data visualization for Julia},
  journal = {Journal of Open Source Software}
}
```

## Getting Help

1. Use the REPL `?` help mode.
1. Click this link to open a preformatted topic on the [Julia Discourse Page](https://discourse.julialang.org/new-topic?title=Makie%20-%20Your%20question%20here&category=domain/viz&tags=Makie&body=You%20can%20write%20your%20question%20in%20this%20space.%0A%0ABefore%20asking%2C%20please%20take%20a%20minute%20to%20make%20sure%20that%20you%20have%20installed%20the%20latest%20available%20versions%20and%20have%20looked%20at%20%5Bthe%20most%20recent%20documentation%5D(http%3A%2Fmakie.juliaplots.org%2Fstable%2F)%20%3Ainnocent%3A). If you do this manually, please use the category Domain/Visualization and tag questions with `Makie` to increase their visibility.
1. For casual conversation about Makie and its development, have a look at the `#makie` channel in the [Julia Slack group](https://julialang.org/slack/). Please direct your usage questions to [Discourse](https://discourse.julialang.org/new-topic?title=Makie%20-%20Your%20question%20here&category=domain/viz&tags=Makie&body=You%20can%20write%20your%20question%20in%20this%20space.%0A%0ABefore%20asking%2C%20please%20take%20a%20minute%20to%20make%20sure%20that%20you%20have%20installed%20the%20latest%20available%20versions%20and%20have%20looked%20at%20%5Bthe%20most%20recent%20documentation%5D(http%3A%2Fmakie.juliaplots.org%2Fstable%2F)%20%3Ainnocent%3A) and not to Slack, to make questions and answers accessible to everybody.
1. For technical issues and bug reports, open an issue in the [Makie.jl](https://github.com/JuliaPlots/Makie.jl) repository which serves as the central hub for Makie and backend issues.
