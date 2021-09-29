<div align="center">
    <img src="https://raw.githubusercontent.com/JuliaPlots/Makie.jl/master/assets/makie_logo_canvas.svg" alt="Makie.jl">
</div>

From the japanese word [_Maki-e_](https://en.wikipedia.org/wiki/Maki-e), which is a technique to sprinkle lacquer with gold and silver powder.
Data is the gold and silver of our age, so let's spread it out beautifully on the screen!

[Check out the documentation here!](http://makie.juliaplots.org/stable/)

[![][docs-stable-img]][docs-stable-url] [![][docs-master-img]][docs-master-url]

[gitlab-img]: https://gitlab.com/JuliaGPU/Makie.jl/badges/master/pipeline.svg
[gitlab-url]: https://gitlab.com/JuliaGPU/Makie.jl/pipelines
[docs-stable-img]: https://img.shields.io/badge/docs-stable-lightgrey.svg
[docs-stable-url]: http://makie.juliaplots.org/stable/
[docs-master-img]: https://img.shields.io/badge/docs-master-blue.svg
[docs-master-url]: http://makie.juliaplots.org/dev/

# Citing Makie

If you use Makie for a scientific publication, please cite [our JOSS paper](https://joss.theoj.org/papers/10.21105/joss.03349) the following way:

> Danisch & Krumbiegel, (2021). Makie.jl: Flexible high-performance data visualization for Julia. Journal of Open Source Software, 6(65), 3349, https://doi.org/10.21105/joss.03349

BibTeX entry:

```bib
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

# Installation

Please consider using the backends directly. As explained in the documentation, they re-export all of Makie's functionality.
So, instead of installing Makie, just install e.g. GLMakie directly:
```julia
julia>]
pkg> add GLMakie
pkg> test GLMakie
```


Interactive example by [AlexisRenchon](https://github.com/AlexisRenchon):

![out](https://user-images.githubusercontent.com/1010467/81500379-2e8cfa80-92d2-11ea-884a-7069d401e5d0.gif)

Example from [InteractiveChaos.jl](https://github.com/JuliaDynamics/InteractiveChaos.jl)

[![interactive chaos](https://user-images.githubusercontent.com/1010467/81500069-ea005f80-92cf-11ea-81db-2b7bcbfea297.gif)
](https://github.com/JuliaDynamics/InteractiveChaos.jl)


You can follow Makie on [twitter](https://twitter.com/MakiePlots) to get the latest, outstanding examples:
[![image](https://user-images.githubusercontent.com/1010467/81500210-e7523a00-92d0-11ea-9849-1240f165e0f8.png)](https://twitter.com/MakiePlots)


## Sponsors

<img src="https://github.com/JuliaPlots/Makie.jl/blob/master/assets/BMBF_gefoerdert_2017_en.jpg?raw=true" width="300"/>
Förderkennzeichen: 01IS10S27, 2020
