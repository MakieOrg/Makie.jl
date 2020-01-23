<div align="center">
<img src="https://raw.githubusercontent.com/JuliaPlots/Makie.jl/sd/abstract/docs/src/assets/logo.png" alt="Makie.jl" width="480">
</div>



From the japanese word [_Maki-e_](https://en.wikipedia.org/wiki/Maki-e), which is a technique to sprinkle lacquer with gold and silver powder.
Data is basically the gold and silver of our age, so let's spread it out beautifully on the screen!

**Documentation**: [![][docs-stable-img]][docs-stable-url] [![][docs-master-img]][docs-master-url]

Build status: [![][gitlab-img]][gitlab-url]

[gitlab-img]: https://gitlab.com/JuliaGPU/Makie.jl/badges/master/pipeline.svg
[gitlab-url]: https://gitlab.com/JuliaGPU/Makie.jl/pipelines
[docs-stable-img]: https://img.shields.io/badge/docs-stable-lightgrey.svg
[docs-stable-url]: http://makie.juliaplots.org/stable/
[docs-master-img]: https://img.shields.io/badge/docs-master-blue.svg
[docs-master-url]: http://makie.juliaplots.org/dev/


# Installation

```julia
julia>]
pkg> add Makie
pkg> test Makie
```

If you plan to use `Makie#master`, you likely also need to check out `AbstractPlotting#master` and `GLMakie#master`.

## Dependencies
You will need to have ffmpeg in the path to run the video recording examples.
On linux you also need to add the following to get GLFW to build (if you don't have those already):

### Debian/Ubuntu
```
sudo apt-get install ffmpeg cmake xorg-dev
```

### RedHat/Fedora
```
sudo dnf install ffmpeg cmake libXrandr-devel libXinerama-devel libXcursor-devel
```
Note that the [RPM Fusion repo](https://rpmfusion.org/) is needed for `ffmpeg`.

# Ecosystem

`Makie.jl` is the metapackage for a rich ecosystem, which consists of [`GLMakie.jl`](https://github.com/JuliaPlots/GLMakie.jl), [`CairoMakie.jl`](https://github.com/JuliaPlots/CairoMakie.jl) and [`WGLMakie.jl`](https://github.com/JuliaPlots/WGLMakie.jl) (the backends); [`AbstractPlotting.jl`](https://github.com/JuliaPlots/AbstractPlotting.jl) (the bulk of the package); and [`StatsMakie.jl`](https://github.com/JuliaPlots/StatsMakie.jl) (statistical plotting support, as in [`StatsPlots.jl`](https://github.com/JuliaPlots/StatsPlots.jl)).

Examples, and test infrastructure, are hosted at [`MakieGallery.jl`](https://github.com/JuliaPlots/MakieGallery.jl)

## Using Juno with Makie

The default OpenGL backend for Makie is not interactive in the Juno plotpane - it just shows a PNG instead.  To get full interactivity, you can run `AbstractPlotting.inline!(false).

If that fails, you can disable the plotpane in Atom's settings by going to `Juno` - `Settings` - `UI Options` - Then, make sure `Enable Plot Plane` is __not__ checked. 

## Mouse interaction:

[<img src="https://user-images.githubusercontent.com/1010467/31519651-5992ca62-afa3-11e7-8b10-b66e6d6bee42.png" width="489">](https://vimeo.com/237204560 "Mouse Interaction")

## Animating a surface:

[<img src="https://user-images.githubusercontent.com/1010467/31519521-fd67907e-afa2-11e7-8c43-5f125780ae26.png" width="489">](https://vimeo.com/237284958 "Surface Plot")


## Complex examples
<a href="https://github.com/JuliaPlots/Makie.jl/blob/master/examples/bigdata.jl#L2"><img src="https://user-images.githubusercontent.com/1010467/48002153-fc15a680-e10a-11e8-812d-a5d717c47288.gif" width="480"/></a>

## IJulia examples:

[![](https://user-images.githubusercontent.com/1010467/32204865-33482ddc-bdec-11e7-9693-b94d999187dc.png)](https://gist.github.com/SimonDanisch/8f5489cffaf6b89c9a3712ba3eb12a84)


# Precompilation

You can compile a binary for Makie and add it to your system image for fast plotting times with no JIT overhead.
To do that, you need to check out the additional packages for precompilation.
Then you can build a system image like this:

```julia
import Pkg
# add PackageCompiler and other dependencies
Pkg.add.(["PackageCompiler", "AbstractPlotting", "GDAL", "GeometryTypes", "MakieGallery", "RDatasets"])
using PackageCompiler
# This is not well tested, so please be careful - I don't take any responsibilities for a messed up Julia install.

# The safe option:
PackageCompiler.compile_incremental(:Makie, :AbstractPlotting, force = false) # can take around ~20 minutes
# After this, to use the system image, you will have to invoke Julia with the sysimg that PackageCompiler provides.

# Replaces Julia's system image
# please be very careful with the option below, since this can make your Julia stop working.
# If Julia doesn't start for you anymore, consider doing:
# using PackageCompiler; PackageCompiler.revert() # <- not well tested

PackageCompiler.compile_incremental(:Makie, :AbstractPlotting, force = true)
```
Should the display not work after compilation, use `AbstractPlotting.__init__()`, or force display by calling `display(AbstractPlotting.PlotDisplay(), scene);` on your `Scene`. 
