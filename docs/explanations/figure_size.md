# Exporting a Figure with physical dimensions

Makie currently uses a unitless approach for specifying Figure resolution, font sizes, line widths, etc. The dimensions of the final result depend on which export format you use, and what settings you specify when saving. Unitless means that `resolution = (800, 600)` doesn't mean pixels, or mm, or cm. Before saving or displaying, these are just numbers.

GLMakie and WGLMakie can only export bitmaps (png files). CairoMakie can export both bitmaps and vector graphics (svg and pdf). These two file types have fundamentally different concepts of size.

## Bitmaps

Bitmaps always have a fixed resolution in pixels. Pixels are not a physical dimension. Monitor pixels have a physical size, and printer dots have one as well, but not the actual image. An image only has a physical size if you decide for a mapping from pixels to physical dimensions. That is usually the `dpi` value (dots per inch).

This value comes from printing and tells you how many printer dots fit into one inch. If we say that one printer dot corresponds to one pixel, then we can use `dpi` to convert from pixels to inch. (Pixels are not actually dots, but this interpretation is widely used. The actual metric to go from pixels to inches is `ppi` or pixels per inch.)

So if you need a plot at 4 x 3 inches and 400 dpi, you could set the figure size like this:

```!
size_in_inches = (4, 3)
dpi = 400
size_in_pixels = size_in_inches .* dpi
```

This means, if you export a bitmap, it doesn't have a physical size per se, but you can choose one later by deciding at what dpi you want to print the image. If you place a bitmap into a LaTeX document, for example, you can choose the size yourself, but just have to take care that the resulting dpi are high enough for your purposes, and that the document doesn't look blurry when printed.

When you save a `Figure` as a bitmap with GLMakie or WGLMakie, the unitless resolution can be interpreted as pixel size. If you save a bitmap with CairoMakie, you additionally have the option to use a scaling factor that decides the mapping from unitless dimensions to pixels. This is done with the `px_per_unit` keyword argument.

```julia
f = Figure(resolution = (800, 600))
# in GLMakie or WGLMakie
save("figure.png", f) # output size = 800 x 600 pixels
# in CairoMakie
save("figure.png", f) # output size = 800 x 600 pixels
save("figure.png", f, px_per_unit = 2) # output size = 1600 x 1200 pixels
```

## Vector graphics

Vector graphics don't have a resolution like bitmap images. They are collections of mathematical descriptions of lines and curves, and these can be arbitrarily scaled up and down. Vector graphics do have physical dimensions in that their content size is usually specified in `pt` which has a direct mapping to inch by convention, as 1 inch is equivalent to 72 pt.

When you export vector graphics with CairoMakie, you can control the mapping from unitless size to size in pt with the `pt_per_unit` keyword argument. This is by default set to `0.75`. The reason for this is that in web contexts, by convention 1 px is equivalent to 0.75 pt. So if you use Pluto or Jupyter notebooks and display a figure once as a bitmap and once as a vector graphic, they will have the same apparent size.

If you want to save a figure for a publication, you usually want to fit font sizes to the rest of the document, and adjust the size to what the journal expects.

Font sizes are usually given in pt, figure sizes in inches.

So if you need a 4 x 3 inches figure and your font size is 12 pt, you should set up and save your figure like this:

```julia
size_inches = (4, 3)
size_pt = 72 .* size_inches
f = Figure(resolution = size_pt, fontsize = 12)
save("figure.pdf", f, pt_per_unit = 1)
```