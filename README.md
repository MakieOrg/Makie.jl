<div align="center">
<img src="https://raw.githubusercontent.com/JuliaPlots/Makie.jl/sd/abstract/docs/src/assets/logo.png" alt="Makie.jl" width="480">
</div>



From the japanese word [Maki-e](https://en.wikipedia.org/wiki/Maki-e), which is a technique to sprinkle lacquer with gold and silver powder.
Data is basically the gold and silver of our age, so lets spread it out beautifully on the screen!

**Documentation**: [![][docs-stable-img]][docs-stable-url] [![][docs-master-img]][docs-master-url]

Build status: [![][gitlab-img]][gitlab-url]

[gitlab-img]: https://gitlab.com/JuliaGPU/Makie.jl/badges/master/pipeline.svg
[gitlab-url]: https://gitlab.com/JuliaGPU/Makie.jl/pipelines
[docs-stable-img]: https://img.shields.io/badge/docs-stable-blue.svg
[docs-stable-url]: http://makie.juliaplots.org/stable/
[docs-master-img]: https://img.shields.io/badge/docs-master-blue.svg
[docs-master-url]: http://juliaplots.org/MakieGallery.jl/stable/


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
```
sudo apt-get install ffmpeg cmake xorg-dev
```


## Examples from the documentation: 

[![](http://makie.juliaplots.org/stable/media/thumb-3d_contour_with_2d_contour_slices.jpg)](http://makie.juliaplots.org/stable/examples-volume.html#3D-Contour-with-2D-contour-slices-1)
[![](http://makie.juliaplots.org/stable/media/thumb-animated_scatter.jpg)](http://makie.juliaplots.org/stable/examples-scatter.html#Animated-Scatter-1)
[![](http://makie.juliaplots.org/stable/media/thumb-animated_surface_and_wireframe.jpg)](http://makie.juliaplots.org/stable/examples-surface.html#Animated-surface-and-wireframe-1)
[![](http://makie.juliaplots.org/stable/media/thumb-arrows_3d.jpg)](http://makie.juliaplots.org/stable/examples-arrows.html#Arrows-3D-1)
[![](http://makie.juliaplots.org/stable/media/thumb-arrows_on_sphere.jpg)](http://makie.juliaplots.org/stable/examples-surface.html#Arrows-on-Sphere-1)
[![](http://makie.juliaplots.org/stable/media/thumb-axis___surface.jpg)](http://makie.juliaplots.org/stable/examples-surface.html#Axis-+-Surface-1)
[![](http://makie.juliaplots.org/stable/media/thumb-barplot_1.jpg)](http://makie.juliaplots.org/stable/examples-barplot.html#barplot-1)
[![](http://makie.juliaplots.org/stable/media/thumb-colored_mesh.jpg)](http://makie.juliaplots.org/stable/examples-mesh.html#Colored-Mesh-1)
[![](http://makie.juliaplots.org/stable/media/thumb-colored_triangle.jpg)](http://makie.juliaplots.org/stable/examples-mesh.html#colored-triangle-1)
[![](http://makie.juliaplots.org/stable/media/thumb-colormaps.jpg)](http://makie.juliaplots.org/stable/examples-image.html#colormaps-1)
[![](http://makie.juliaplots.org/stable/media/thumb-connected_sphere.jpg)](http://makie.juliaplots.org/stable/examples-scatter.html#Connected-Sphere-1)
[![](http://makie.juliaplots.org/stable/media/thumb-contour_1.jpg)](http://makie.juliaplots.org/stable/examples-contour.html#contour-1)
[![](http://makie.juliaplots.org/stable/media/thumb-contour_function.jpg)](http://makie.juliaplots.org/stable/examples-contour.html#Contour-Function-1)
[![](http://makie.juliaplots.org/stable/media/thumb-fem_mesh_3d.jpg)](http://makie.juliaplots.org/stable/examples-mesh.html#FEM-mesh-3D-1)
[![](http://makie.juliaplots.org/stable/media/thumb-fem_polygon_2d.jpg)](http://makie.juliaplots.org/stable/examples-poly.html#FEM-polygon-2D-1)
[![](http://makie.juliaplots.org/stable/media/thumb-fluctuation_3d.jpg)](http://makie.juliaplots.org/stable/examples-meshscatter.html#Fluctuation-3D-1)
[![](http://makie.juliaplots.org/stable/media/thumb-heatmap_1.jpg)](http://makie.juliaplots.org/stable/examples-heatmap.html#Heatmap-1)
[![](http://makie.juliaplots.org/stable/media/thumb-heatmap_interpolation.jpg)](http://makie.juliaplots.org/stable/examples-heatmap.html#heatmap-interpolation-1)
[![](http://makie.juliaplots.org/stable/media/thumb-image_1.jpg)](http://makie.juliaplots.org/stable/examples-image.html#image-1)
[![](http://makie.juliaplots.org/stable/media/thumb-image_on_surface_sphere.jpg)](http://makie.juliaplots.org/stable/examples-surface.html#Image-on-Surface-Sphere-1)
[![](http://makie.juliaplots.org/stable/media/thumb-image_scatter.jpg)](http://makie.juliaplots.org/stable/examples-scatter.html#image-scatter-1)
[![](http://makie.juliaplots.org/stable/media/thumb-interaction.jpg)](http://makie.juliaplots.org/stable/examples-scatter.html#Interaction-1)
[![](http://makie.juliaplots.org/stable/media/thumb-interaction_with_mouse.jpg)](http://makie.juliaplots.org/stable/examples-scatter.html#Interaction-with-Mouse-1)
[![](http://makie.juliaplots.org/stable/media/thumb-line_function.jpg)](http://makie.juliaplots.org/stable/examples-lines.html#Line-Function-1)
[![](http://makie.juliaplots.org/stable/media/thumb-line_gif.jpg)](http://makie.juliaplots.org/stable/examples-lines.html#Line-GIF-1)
[![](http://makie.juliaplots.org/stable/media/thumb-load_mesh.jpg)](http://makie.juliaplots.org/stable/examples-mesh.html#Load-Mesh-1)
[![](http://makie.juliaplots.org/stable/media/thumb-marker_offset.jpg)](http://makie.juliaplots.org/stable/examples-scatter.html#Marker-offset-1)
[![](http://makie.juliaplots.org/stable/media/thumb-marker_sizes.jpg)](http://makie.juliaplots.org/stable/examples-scatter.html#Marker-sizes-1)
[![](http://makie.juliaplots.org/stable/media/thumb-marker_sizes___marker_colors.jpg)](http://makie.juliaplots.org/stable/examples-scatter.html#Marker-sizes-+-Marker-colors-1)
[![](http://makie.juliaplots.org/stable/media/thumb-merged_color_mesh.jpg)](http://makie.juliaplots.org/stable/examples-mesh.html#Merged-color-Mesh-1)
[![](http://makie.juliaplots.org/stable/media/thumb-meshscatter_function.jpg)](http://makie.juliaplots.org/stable/examples-meshscatter.html#Meshscatter-Function-1)
[![](http://makie.juliaplots.org/stable/media/thumb-moire.jpg)](http://makie.juliaplots.org/stable/examples-linesegments.html#Moire-1)
[![](http://makie.juliaplots.org/stable/media/thumb-mouse_picking.jpg)](http://makie.juliaplots.org/stable/examples-scatter.html#Mouse-Picking-1)
[![](http://makie.juliaplots.org/stable/media/thumb-normals_of_a_cat.jpg)](http://makie.juliaplots.org/stable/examples-mesh.html#Normals-of-a-Cat-1)
[![](http://makie.juliaplots.org/stable/media/thumb-polygons.jpg)](http://makie.juliaplots.org/stable/examples-linesegments.html#Polygons-1)
[![](http://makie.juliaplots.org/stable/media/thumb-pong.jpg)](http://makie.juliaplots.org/stable/examples-scatter.html#pong-1)
[![](http://makie.juliaplots.org/stable/media/thumb-quiver_1.jpg)](http://makie.juliaplots.org/stable/examples-arrows.html#quiver-1)
[![](http://makie.juliaplots.org/stable/media/thumb-record_video.jpg)](http://makie.juliaplots.org/stable/examples-meshscatter.html#Record-Video-1)
[![](http://makie.juliaplots.org/stable/media/thumb-scatter_1.jpg)](http://makie.juliaplots.org/stable/examples-scatter.html#scatter-1)
[![](http://makie.juliaplots.org/stable/media/thumb-scatter_colormap.jpg)](http://makie.juliaplots.org/stable/examples-scatter.html#scatter-colormap-1)
[![](http://makie.juliaplots.org/stable/media/thumb-simple_meshscatter.jpg)](http://makie.juliaplots.org/stable/examples-meshscatter.html#Simple-meshscatter-1)
[![](http://makie.juliaplots.org/stable/media/thumb-sphere_mesh.jpg)](http://makie.juliaplots.org/stable/examples-mesh.html#Sphere-Mesh-1)
[![](http://makie.juliaplots.org/stable/media/thumb-subscenes.jpg)](http://makie.juliaplots.org/stable/examples-scatter.html#Subscenes-1)
[![](http://makie.juliaplots.org/stable/media/thumb-surface_1.jpg)](http://makie.juliaplots.org/stable/examples-surface.html#Surface-1)
[![](http://makie.juliaplots.org/stable/media/thumb-surface_with_image.jpg)](http://makie.juliaplots.org/stable/examples-surface.html#Surface-with-image-1)
[![](http://makie.juliaplots.org/stable/media/thumb-surface___contour3d.jpg)](http://makie.juliaplots.org/stable/examples-surface.html#surface-+-contour3d-1)
[![](http://makie.juliaplots.org/stable/media/thumb-test_heatmap___image_overlap.jpg)](http://makie.juliaplots.org/stable/examples-heatmap.html#Test-heatmap-+-image-overlap-1)
[![](http://makie.juliaplots.org/stable/media/thumb-textured_mesh.jpg)](http://makie.juliaplots.org/stable/examples-mesh.html#Textured-Mesh-1)
[![](http://makie.juliaplots.org/stable/media/thumb-text_annotation.jpg)](http://makie.juliaplots.org/stable/examples-text.html#Text-Annotation-1)
[![](http://makie.juliaplots.org/stable/media/thumb-text_rotation.jpg)](http://makie.juliaplots.org/stable/examples-text.html#Text-rotation-1)
[![](http://makie.juliaplots.org/stable/media/thumb-travelling_wave.jpg)](http://makie.juliaplots.org/stable/examples-lines.html#Travelling-wave-1)
[![](http://makie.juliaplots.org/stable/media/thumb-type_recipe_for_molecule_simulation.jpg)](http://makie.juliaplots.org/stable/examples-meshscatter.html#Type-recipe-for-molecule-simulation-1)
[![](http://makie.juliaplots.org/stable/media/thumb-unicode_marker.jpg)](http://makie.juliaplots.org/stable/examples-scatter.html#Unicode-Marker-1)
[![](http://makie.juliaplots.org/stable/media/thumb-viridis_meshscatter.jpg)](http://makie.juliaplots.org/stable/examples-scatter.html#Viridis-meshscatter-1)
[![](http://makie.juliaplots.org/stable/media/thumb-viridis_scatter.jpg)](http://makie.juliaplots.org/stable/examples-scatter.html#Viridis-scatter-1)
[![](http://makie.juliaplots.org/stable/media/thumb-volume_function.jpg)](http://makie.juliaplots.org/stable/examples-volume.html#Volume-Function-1)
[![](http://makie.juliaplots.org/stable/media/thumb-wireframe_of_a_mesh.jpg)](http://makie.juliaplots.org/stable/examples-mesh.html#Wireframe-of-a-Mesh-1)
[![](http://makie.juliaplots.org/stable/media/thumb-wireframe_of_a_surface.jpg)](http://makie.juliaplots.org/stable/examples-surface.html#Wireframe-of-a-Surface-1)


## Mouse interaction:

[<img src="https://user-images.githubusercontent.com/1010467/31519651-5992ca62-afa3-11e7-8b10-b66e6d6bee42.png" width="489">](https://vimeo.com/237204560 "Mouse Interaction")

## Animating a surface:

[<img src="https://user-images.githubusercontent.com/1010467/31519521-fd67907e-afa2-11e7-8c43-5f125780ae26.png" width="489">](https://vimeo.com/237284958 "Surface Plot")


## Complex examples
<a href="https://github.com/JuliaPlots/Makie.jl/blob/master/examples/bigdata.jl#L2"><img src="https://user-images.githubusercontent.com/1010467/48002153-fc15a680-e10a-11e8-812d-a5d717c47288.gif" width="480"/></a>

## IJulia examples:

[![](https://user-images.githubusercontent.com/1010467/32204865-33482ddc-bdec-11e7-9693-b94d999187dc.png)](https://gist.github.com/SimonDanisch/8f5489cffaf6b89c9a3712ba3eb12a84)


# Precompilation

You can compile binary for Makie and add it to your system image for fast plotting times with no JIT overhead.
To do that, you need to check out the additional packages for precompilation.
Then you can build a system image like this:

```julia
# add Makie dependencies
Pkg.add("AbstractPlotting")
Pkg.add("MakieGallery")
Pkg.add("GeometryTypes")
# add PackageCompiler
Pkg.add("PackageCompiler")
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
