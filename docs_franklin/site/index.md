## Welcome to Makie!

Makie is a high-performance, extendable, and multi-platform plotting ecosystem for the [Julia](https://julialang.org/) programming language.

## Installation and Import

Add one or more of the Makie backend packages [`GLMakie.jl`](https://github.com/JuliaPlots/Makie.jl/tree/master/GLMakie) (OpenGL), [`CairoMakie.jl`](https://github.com/JuliaPlots/Makie.jl/tree/master/CairoMakie) (Cairo), or [`WGLMakie.jl`](https://github.com/JuliaPlots/Makie.jl/tree/master/WGLMakie) (WebGL).

```julia
]add GLMakie
using GLMakie
```

To switch to a different backend, for example `CairoMakie`, call `CairoMakie.activate!()`.

## First Steps

@@box-container
  @@box
    @@title \myreflink{Basic Tutorial} @@
    @@box-content
      @@description
      Learn the basics of plotting with Makie.
      @@
      ~~~
      <img src="/assets/basic_tutorial_example.png">
      ~~~
    @@
  @@

  @@box
    @@title \myreflink{Layout Tutorial} @@
    @@box-content
      @@description
      Check out how to make complex plots and layouts.
      @@
      ~~~
      <img src="/assets/tutorials/layout-tutorial/code/output/final_result.png">
      ~~~
    @@
  @@

  @@box
    @@title [Beautiful Makie](https://lazarusa.github.io/BeautifulMakie/) @@
    @@box-content
      @@description
      A gallery that is maintained in a separate repository.
      @@
      ~~~
      <img src="/assets/beautifulmakie_example.png">
      ~~~
    @@
  @@
@@

## Makie Backends

@@box-container
  @@box
    @@title [GLMakie.jl](https://github.com/JuliaPlots/Makie.jl/tree/master/GLMakie) @@
    @@box-content
      @@description
      GPU-powered, interactive 2D and 3D plotting in standalone `GLFW.jl` windows.
      @@
      ~~~
      <img src="/assets/surface_example.png">
      ~~~
    @@
  @@

  @@box
    @@title [CairoMakie.jl](https://github.com/JuliaPlots/Makie.jl/tree/master/CairoMakie) @@
    @@box-content
      @@description
      `Cairo.jl` based, non-interactive 2D backend for publication-quality vector graphics.
      @@
      ~~~
      <img src="/assets/density_example.png">
      ~~~
    @@
  @@

  @@box
    @@title [WGLMakie.jl](https://github.com/JuliaPlots/Makie.jl/tree/master/WGLMakie) @@
    @@box-content
      @@description
      WebGL-based interactive 2D and 3D plotting that runs within browsers.
      @@
      ~~~
      <img src="/assets/wireframe_example.png">
      ~~~
    @@
  @@
@@

The differences between backends are explained in more details under [Backends & Output](@ref).

### Extension Packages

These packages are maintained by third parties. If you install them, keep an eye on version conflicts or downgrades as the Makie ecosystem is developing quickly so things break occasionally.

@@box-container
  @@box
    @@title [AlgebraOfGraphics.jl](https://github.com/JuliaPlots/AlgebraOfGraphics.jl/) @@
    @@description
    Grammar-of-graphics style plotting, inspired by ggplot2.
    @@
    ~~~
    <img src="/assets/algebraofgraphics_example.svg">
    ~~~
  @@

  @@box
    @@title [GeoMakie.jl](https://github.com/JuliaPlots/GeoMakie.jl) @@
    @@description
    Geographic plotting utilities. Currently not maintained.
    @@
    ~~~
    <img src="/assets/geomakie_example.png">
    ~~~
  @@
@@


## Getting Help

1. Use the REPL `?` help mode.
1. Click this link to open a preformatted topic on the [Julia Discourse Page](https://discourse.julialang.org/new-topic?title=Makie%20-%20Your%20question%20here&category=domain/viz&tags=Makie&body=You%20can%20write%20your%20question%20in%20this%20space.%0A%0ABefore%20asking%2C%20please%20take%20a%20minute%20to%20make%20sure%20that%20you%20have%20installed%20the%20latest%20available%20versions%20and%20have%20looked%20at%20%5Bthe%20most%20recent%20documentation%5D(http%3A%2Fmakie.juliaplots.org%2Fstable%2F)%20%3Ainnocent%3A). If you do this manually, please use the category Domain/Visualization and tag questions with `Makie` to increase their visibility.
1. For casual conversation about Makie and its development, have a look at the `#makie` channel in the [Julia Slack group](https://julialang.org/slack/). Please direct your usage questions to [Discourse](https://discourse.julialang.org/new-topic?title=Makie%20-%20Your%20question%20here&category=domain/viz&tags=Makie&body=You%20can%20write%20your%20question%20in%20this%20space.%0A%0ABefore%20asking%2C%20please%20take%20a%20minute%20to%20make%20sure%20that%20you%20have%20installed%20the%20latest%20available%20versions%20and%20have%20looked%20at%20%5Bthe%20most%20recent%20documentation%5D(http%3A%2Fmakie.juliaplots.org%2Fstable%2F)%20%3Ainnocent%3A) and not to Slack, to make questions and answers accessible to everybody.
1. For technical issues and bug reports, open an issue in the [Makie.jl](https://github.com/JuliaPlots/Makie.jl) repository which serves as the central hub for Makie and backend issues.
