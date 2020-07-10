<div align="center">
    <img src="https://raw.githubusercontent.com/JuliaPlots/Makie.jl/master/assets/logo.png" alt="Makie.jl" width="480">
</div>

From the japanese word [_Maki-e_](https://en.wikipedia.org/wiki/Maki-e), which is a technique to sprinkle lacquer with gold and silver powder.
Data is basically the gold and silver of our age, so let's spread it out beautifully on the screen!

**Documentation**: [![][docs-stable-img]][docs-stable-url] [![][docs-master-img]][docs-master-url]

Build status: [![][gitlab-img]][gitlab-url]

[![DOI](https://zenodo.org/badge/104806923.svg)](https://zenodo.org/badge/latestdoi/104806923)

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
On Linux, you also need to add the following to get GLFW to build (if you don't have those already):

### Debian/Ubuntu
```bash
sudo apt-get install cmake xorg-dev
```

### RedHat/Fedora
```bash
sudo dnf install cmake libXrandr-devel libXinerama-devel libXcursor-devel
```

# Ecosystem

Makie is the metapackage for a rich ecosystem, which consists of [GLMakie.jl](https://github.com/JuliaPlots/GLMakie.jl), [CairoMakie.jl](https://github.com/JuliaPlots/CairoMakie.jl) and [WGLMakie.jl](https://github.com/JuliaPlots/WGLMakie.jl) (the backends); [AbstractPlotting.jl](https://github.com/JuliaPlots/AbstractPlotting.jl) (the bulk of the package); and [StatsMakie.jl](https://github.com/JuliaPlots/StatsMakie.jl) (statistical plotting support, as in [StatsPlots.jl](https://github.com/JuliaPlots/StatsPlots.jl)).

[MakieLayout.jl](https://github.com/jkrumbiegel/MakieLayout.jl) is a layout manager for Makie.  It brings grid layouts, a new 2D axis, and widgets like sliders and buttons that behave well in a layout to Makie.

There is experimental support for using Plots.jl and RecipesBase.jl recipes in [MakieRecipes.jl](https://github.com/JuliaPlots/MakieRecipes.jl), and a prototype TeX plotting implementation with vector support in [MakieTeX.jl](https://github.com/JuliaPlots/MakieTeX.jl).

Examples, and test infrastructure, are in [MakieGallery.jl](https://github.com/JuliaPlots/MakieGallery.jl).

You can also follow Makie on [twitter](https://twitter.com/MakiePlots) to get the latest, outstanding examples:
[![image](https://user-images.githubusercontent.com/1010467/81500210-e7523a00-92d0-11ea-9849-1240f165e0f8.png)](https://twitter.com/MakiePlots)

### MakieLayout
Interactive MakieLayout example by [AlexisRenchon](https://github.com/AlexisRenchon):

[![out](https://user-images.githubusercontent.com/1010467/81500379-2e8cfa80-92d2-11ea-884a-7069d401e5d0.gif)](https://github.com/jkrumbiegel/MakieLayout.jl)


### InteractiveChaos
[![](https://user-images.githubusercontent.com/1010467/81500069-ea005f80-92cf-11ea-81db-2b7bcbfea297.gif)
](https://github.com/JuliaDynamics/InteractiveChaos.jl)

### GeoMakie
[![](https://user-images.githubusercontent.com/32143268/74341805-5bcf1880-4d76-11ea-86ee-d0822ba70ab4.png)](https://github.com/JuliaPlots/GeoMakie.jl)

### MakieTeX
[![](https://user-images.githubusercontent.com/32143268/79641464-5696ab80-81b5-11ea-902d-d65da76dfa69.png)](https://github.com/JuliaPlots/MakieTeX.jl)

### StatsMakie
[![](https://user-images.githubusercontent.com/6333339/49150576-38e94d80-f305-11e8-99e7-fedf0a2f114d.png)](https://github.com/JuliaPlots/StatsMakie.jl)


## Using Juno with Makie

The default OpenGL backend for Makie is not interactive in the Juno plotpane - it just shows a PNG instead.  To get full interactivity, you can run `AbstractPlotting.inline!(false)`.

If that fails, you can disable the plotpane in Atom's settings by going to `Juno` - `Settings` - `UI Options` - Then, make sure `Enable Plot Plane` is __not__ checked.


## Using IJulia / Jupyter Notebook with Makie

Currently, only non-interactive plots are supported. (See the issues [#15](https://github.com/JuliaPlots/Makie.jl/issues/15) and [#266](https://github.com/JuliaPlots/Makie.jl/issues/266).)

You may need to run `AbstractPlotting.inline!(true)` in order for plots to appear.

## Precompilation

You can compile a binary for Makie and add it to your system image for fast plotting times with no JIT overhead.
To do that, you need to check out the additional packages for precompilation.
Then you can build a system image like this:

```julia
using Pkg
# add PackageCompiler and other dependencies
pkg"add PackageCompiler"
# Make sure you have v1.0 or higher of PackageCompiler!

using PackageCompiler

# This will create a system image in the current directory, which you can
# use by launching Julia with `julia -J ./MakieSys.so`.
PackageCompiler.create_sysimage(
    :Makie;
    sysimage_path="MakieSys.so",
    precompile_execution_file=joinpath(pkgdir(Makie), "test", "test_for_precompile.jl")
)
```

Should the display not work after compilation, call `AbstractPlotting.__init__()` immediately after `using Makie`.


## Examples from the documentation:

[![](http://juliaplots.org/MakieReferenceImages/gallery//3d_contour_with_2d_contour_slices/media/thumb.png)](http://juliaplots.org/MakieReferenceImages/gallery/3d_contour_with_2d_contour_slices/index.html)
[![](http://juliaplots.org/MakieReferenceImages/gallery/animated_scatter/media/thumb.png)](http://juliaplots.org/MakieReferenceImages/gallery/animated_scatter/index.html)
[![](http://juliaplots.org/MakieReferenceImages/gallery/animated_surface_and_wireframe/media/thumb.png)](http://juliaplots.org/MakieReferenceImages/gallery/animated_surface_and_wireframe/index.html)
[![](http://juliaplots.org/MakieReferenceImages/gallery/arrows_3d/media/thumb.png)](http://juliaplots.org/MakieReferenceImages/gallery/arrows_3d/index.html)
[![](http://juliaplots.org/MakieReferenceImages/gallery/arrows_on_sphere/media/thumb.png)](http://juliaplots.org/MakieReferenceImages/gallery/arrows_on_sphere/index.html)
[![](http://juliaplots.org/MakieReferenceImages/gallery/axis___surface/media/thumb.png)](http://juliaplots.org/MakieReferenceImages/gallery/axis___surface/index.html)
[![](http://juliaplots.org/MakieReferenceImages/gallery/barplot_1/media/thumb.png)](http://juliaplots.org/MakieReferenceImages/gallery/barplot_1/index.html)
[![](http://juliaplots.org/MakieReferenceImages/gallery/colored_mesh/media/thumb.png)](http://juliaplots.org/MakieReferenceImages/gallery/colored_mesh/index.html)
[![](http://juliaplots.org/MakieReferenceImages/gallery/colored_triangle/media/thumb.png)](http://juliaplots.org/MakieReferenceImages/gallery/colored_triangle/index.html)
[![](http://juliaplots.org/MakieReferenceImages/gallery/colormaps/media/thumb.png)](http://juliaplots.org/MakieReferenceImages/gallery/colormaps/index.html)
[![](http://juliaplots.org/MakieReferenceImages/gallery/connected_sphere/media/thumb.png)](http://juliaplots.org/MakieReferenceImages/gallery/connected_sphere/index.html)
[![](http://juliaplots.org/MakieReferenceImages/gallery/contour_1/media/thumb.png)](http://juliaplots.org/MakieReferenceImages/gallery/contour_1/index.html)
[![](http://juliaplots.org/MakieReferenceImages/gallery/contour_function/media/thumb.png)](http://juliaplots.org/MakieReferenceImages/gallery/contour_function/index.html)
[![](http://juliaplots.org/MakieReferenceImages/gallery/fem_mesh_3d/media/thumb.png)](http://juliaplots.org/MakieReferenceImages/gallery/fem_mesh_3d/index.html)
[![](http://juliaplots.org/MakieReferenceImages/gallery/fem_polygon_2d/media/thumb.png)](http://juliaplots.org/MakieReferenceImages/gallery/fem_polygon_2d/index.html)
[![](http://juliaplots.org/MakieReferenceImages/gallery/fluctuation_3d/media/thumb.png)](http://juliaplots.org/MakieReferenceImages/gallery/fluctuation_3d/index.html)
[![](http://juliaplots.org/MakieReferenceImages/gallery/heatmap_1/media/thumb.png)](http://juliaplots.org/MakieReferenceImages/gallery/heatmap_1/index.html)
[![](http://juliaplots.org/MakieReferenceImages/gallery/heatmap_interpolation/media/thumb.jpg)](http://juliaplots.org/MakieReferenceImages/gallery/heatmap_interpolation/index.html)
[![](http://juliaplots.org/MakieReferenceImages/gallery/image_1/media/thumb.jpg)](http://juliaplots.org/MakieReferenceImages/gallery/image_1/index.html)
[![](http://juliaplots.org/MakieReferenceImages/gallery/image_on_surface_sphere/media/thumb.png)](http://juliaplots.org/MakieReferenceImages/gallery/image_on_surface_sphere/index.html)
[![](http://juliaplots.org/MakieReferenceImages/gallery/image_scatter/media/thumb.png)](http://juliaplots.org/MakieReferenceImages/gallery/image_scatter/index.html)
[![](http://juliaplots.org/MakieReferenceImages/gallery/interaction/media/thumb.png)](http://juliaplots.org/MakieReferenceImages/gallery/interaction/index.html)
[![](http://juliaplots.org/MakieReferenceImages/gallery/interaction_with_mouse/media/thumb.png)](http://juliaplots.org/MakieReferenceImages/gallery/interaction_with_mouse/index.html)
[![](http://juliaplots.org/MakieReferenceImages/gallery/line_function/media/thumb.png)](http://juliaplots.org/MakieReferenceImages/gallery/line_function/index.html)
[![](http://juliaplots.org/MakieReferenceImages/gallery/line_gif/media/thumb.png)](http://juliaplots.org/MakieReferenceImages/gallery/line_gif/index.html)
[![](http://juliaplots.org/MakieReferenceImages/gallery/load_mesh/media/thumb.png)](http://juliaplots.org/MakieReferenceImages/gallery/load_mesh/index.html)
[![](http://juliaplots.org/MakieReferenceImages/gallery/marker_offset/media/thumb.png)](http://juliaplots.org/MakieReferenceImages/gallery/marker_offset/index.html)
[![](http://juliaplots.org/MakieReferenceImages/gallery/marker_sizes/media/thumb.png)](http://juliaplots.org/MakieReferenceImages/gallery/marker_sizes/index.html)
[![](http://juliaplots.org/MakieReferenceImages/gallery/marker_sizes___marker_colors/media/thumb.png)](http://juliaplots.org/MakieReferenceImages/gallery/marker_sizes___marker_colors/index.html)
[![](http://juliaplots.org/MakieReferenceImages/gallery/merged_color_mesh/media/thumb.png)](http://juliaplots.org/MakieReferenceImages/gallery/merged_color_mesh/index.html)
[![](http://juliaplots.org/MakieReferenceImages/gallery/meshscatter_function/media/thumb.png)](http://juliaplots.org/MakieReferenceImages/gallery/meshscatter_function/index.html)
[![](http://juliaplots.org/MakieReferenceImages/gallery/moire/media/thumb.png)](http://juliaplots.org/MakieReferenceImages/gallery/moire/index.html)
[![](http://juliaplots.org/MakieReferenceImages/gallery/mouse_picking/media/thumb.png)](http://juliaplots.org/MakieReferenceImages/gallery/mouse_picking/index.html)
[![](http://juliaplots.org/MakieReferenceImages/gallery/normals_of_a_cat/media/thumb.png)](http://juliaplots.org/MakieReferenceImages/gallery/normals_of_a_cat/index.html)
[![](http://juliaplots.org/MakieReferenceImages/gallery/polygons/media/thumb.png)](http://juliaplots.org/MakieReferenceImages/gallery/polygons/index.html)
[![](http://juliaplots.org/MakieReferenceImages/gallery/pong/media/thumb.png)](http://juliaplots.org/MakieReferenceImages/gallery/pong/index.html)
[![](http://juliaplots.org/MakieReferenceImages/gallery/quiver_1/media/thumb.png)](http://juliaplots.org/MakieReferenceImages/gallery/quiver_1/index.html)
[![](http://juliaplots.org/MakieReferenceImages/gallery/record_video/media/thumb.png)](http://juliaplots.org/MakieReferenceImages/gallery/record_video/index.html)
[![](http://juliaplots.org/MakieReferenceImages/gallery/scatter_1/media/thumb.png)](http://juliaplots.org/MakieReferenceImages/gallery/scatter_1/index.html)
[![](http://juliaplots.org/MakieReferenceImages/gallery/scatter_colormap/media/thumb.png)](http://juliaplots.org/MakieReferenceImages/gallery/scatter_colormap/index.html)
[![](http://juliaplots.org/MakieReferenceImages/gallery/simple_meshscatter/media/thumb.png)](http://juliaplots.org/MakieReferenceImages/gallery/simple_meshscatter/index.html)
[![](http://juliaplots.org/MakieReferenceImages/gallery/sphere_mesh/media/thumb.png)](http://juliaplots.org/MakieReferenceImages/gallery/sphere_mesh/index.html)
[![](http://juliaplots.org/MakieReferenceImages/gallery/subscenes/media/thumb.png)](http://juliaplots.org/MakieReferenceImages/gallery/subscenes/index.html)
[![](http://juliaplots.org/MakieReferenceImages/gallery/surface_1/media/thumb.png)](http://juliaplots.org/MakieReferenceImages/gallery/surface_1/index.html)
[![](http://juliaplots.org/MakieReferenceImages/gallery/surface_with_image/media/thumb.png)](http://juliaplots.org/MakieReferenceImages/gallery/surface_with_image/index.html)
[![](http://juliaplots.org/MakieReferenceImages/gallery/surface___contour3d/media/thumb.png)](http://juliaplots.org/MakieReferenceImages/gallery/surface___contour3d/index.html)
[![](http://juliaplots.org/MakieReferenceImages/gallery/test_heatmap___image_overlap/media/thumb.png)](http://juliaplots.org/MakieReferenceImages/gallery/test_heatmap___image_overlap/index.html)
[![](http://juliaplots.org/MakieReferenceImages/gallery/textured_mesh/media/thumb.png)](http://juliaplots.org/MakieReferenceImages/gallery/textured_mesh/index.html)
[![](http://juliaplots.org/MakieReferenceImages/gallery/text_annotation/media/thumb.png)](http://juliaplots.org/MakieReferenceImages/gallery/text_annotation/index.html)
[![](http://juliaplots.org/MakieReferenceImages/gallery/text_rotation/media/thumb.png)](http://juliaplots.org/MakieReferenceImages/gallery/text_rotation/index.html)
[![](http://juliaplots.org/MakieReferenceImages/gallery/travelling_wave/media/thumb.png)](http://juliaplots.org/MakieReferenceImages/gallery/travelling_wave/index.html)
[![](http://juliaplots.org/MakieReferenceImages/gallery/type_recipe_for_molecule_simulation/media/thumb.png)](http://juliaplots.org/MakieReferenceImages/gallery/type_recipe_for_molecule_simulation/index.html)
[![](http://juliaplots.org/MakieReferenceImages/gallery/unicode_marker/media/thumb.png)](http://juliaplots.org/MakieReferenceImages/gallery/unicode_marker/index.html)
[![](http://juliaplots.org/MakieReferenceImages/gallery/viridis_meshscatter/media/thumb.png)](http://juliaplots.org/MakieReferenceImages/gallery/viridis_meshscatter/index.html)
[![](http://juliaplots.org/MakieReferenceImages/gallery/viridis_scatter/media/thumb.png)](http://juliaplots.org/MakieReferenceImages/gallery/viridis_scatter/index.html)
[![](http://juliaplots.org/MakieReferenceImages/gallery/volume_function/media/thumb.png)](http://juliaplots.org/MakieReferenceImages/gallery/volume_function/index.html)
[![](http://juliaplots.org/MakieReferenceImages/gallery/wireframe_of_a_mesh/media/thumb.png)](http://juliaplots.org/MakieReferenceImages/gallery/wireframe_of_a_mesh/index.html)
[![](http://juliaplots.org/MakieReferenceImages/gallery/wireframe_of_a_surface/media/thumb.png)](http://juliaplots.org/MakieReferenceImages/gallery/wireframe_of_a_surface/index.html)


## Mouse interaction:

<img src="https://user-images.githubusercontent.com/1010467/31519651-5992ca62-afa3-11e7-8b10-b66e6d6bee42.png" width="489">

## Animating a surface:

<img src="https://user-images.githubusercontent.com/1010467/31519521-fd67907e-afa2-11e7-8c43-5f125780ae26.png" width="489">


## Complex examples
<a href="https://github.com/JuliaPlots/MakieGallery.jl/blob/master/examples/bigdata.jl#L2"><img src="https://user-images.githubusercontent.com/1010467/48002153-fc15a680-e10a-11e8-812d-a5d717c47288.gif" width="480"/></a>
