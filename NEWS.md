# News

## master

- Add `loop` option for GIF outputs when recording videos with `record` [#2891](https://github.com/MakieOrg/Makie.jl/pull/2891)

## v0.19.4

- Added export of `hidezdecorations!` from MakieLayout [#2821](https://github.com/MakieOrg/Makie.jl/pull/2821).
- Fix line shader [#2828](https://github.com/MakieOrg/Makie.jl/pull/2828).

## v0.19.3

- Added the `stephist` plotting function [#2408](https://github.com/JuliaPlots/Makie.jl/pull/2408).
- Added the `brackets` plotting function [#2356](https://github.com/MakieOrg/Makie.jl/pull/2356).
- Fixed an issue where `poly` plots with `Vector{<: MultiPolygon}` inputs with per-polygon color were mistakenly rendered as meshes using CairoMakie [#2590](https://github.com/MakieOrg/Makie.jl/pulls/2478).
- Fixed a small typo which caused an error in the `Stepper` constructor [#2600](https://github.com/MakieOrg/Makie.jl/pulls/2478).
- Improve cleanup on block deletion [#2614](https://github.com/MakieOrg/Makie.jl/pull/2614)
- Add `menu.scroll_speed` and increase default speed for non-apple [#2616](https://github.com/MakieOrg/Makie.jl/pull/2616).
- Fixed rectangle zoom for nonlinear axes [#2674](https://github.com/MakieOrg/Makie.jl/pull/2674)
- Cleaned up linestyles in GLMakie (Fixing artifacting, spacing/size, anti-aliasing) [#2666](https://github.com/MakieOrg/Makie.jl/pull/2666).
- Fixed issue with scatterlines only accepting concrete color types as `markercolor` [#2691](https://github.com/MakieOrg/Makie.jl/pull/2691).
- Fixed an accidental issue where `LaTeXStrings` were not typeset correctly in `Axis3` [#2558](https://github.com/MakieOrg/Makie.jl/pull/2588).
- Fixed a bug where line segments in `text(lstr::LaTeXString)` were ignoring offsets [#2668](https://github.com/MakieOrg/Makie.jl/pull/2668).
- Fixed a bug where the `arrows` recipe accidentally called a `Bool` when `normalize = true` [#2740](https://github.com/MakieOrg/Makie.jl/pull/2740).
- Re-exported the `@colorant_str` (`colorant"..."`) macro from Colors.jl [#2726](https://github.com/MakieOrg/Makie.jl/pull/2726).
- Speedup heatmaps in WGLMakie. [#2647](https://github.com/MakieOrg/Makie.jl/pull/2647)
- Fix slow `data_limits` for recipes, which made plotting lots of data with recipes much slower [#2770](https://github.com/MakieOrg/Makie.jl/pull/2770).

## v0.19.1

- Add `show_data` method for `band` which shows the min and max values of the band at the x position of the cursor [#2497](https://github.com/MakieOrg/Makie.jl/pull/2497).
- Added `xlabelrotation`, `ylabelrotation` (`Axis`) and `labelrotation` (`Colorbar`) [#2478](https://github.com/MakieOrg/Makie.jl/pull/2478).
- Fixed forced rasterization in CairoMakie svg files when polygons with colors specified as (color, alpha) tuples were used [#2535](https://github.com/MakieOrg/Makie.jl/pull/2535).
- Do less copies of Observables in Attributes + plot pipeline [#2443](https://github.com/MakieOrg/Makie.jl/pull/2443). 
- Add Search Page and tweak Result Ordering [#2474](https://github.com/MakieOrg/Makie.jl/pull/2474).
- Remove all global attributes from TextureAtlas implementation and fix julia#master [#2498](https://github.com/MakieOrg/Makie.jl/pull/2498). 
- Use new JSServe, implement WGLMakie picking, improve performance and fix lots of WGLMakie bugs [#2428](https://github.com/MakieOrg/Makie.jl/pull/2428).

## v0.19.0

- **Breaking** The attribute `textsize` has been removed everywhere in favor of the attribute `fontsize` which had also been in use.
  To migrate, search and replace all uses of `textsize` to `fontsize` [#2387](https://github.com/MakieOrg/Makie.jl/pull/2387).
- Added rich text which allows to more easily use superscripts and subscripts as well as differing colors, fonts, fontsizes, etc. for parts of a given text [#2321](https://github.com/MakieOrg/Makie.jl/pull/2321).

## v0.18.4

- Added the `waterfall` plotting function [#2416](https://github.com/JuliaPlots/Makie.jl/pull/2416).
- Add support for `AbstractPattern` in `WGLMakie` [#2432](https://github.com/MakieOrg/Makie.jl/pull/2432).
- Broadcast replaces deprecated method for quantile [#2430](https://github.com/MakieOrg/Makie.jl/pull/2430).
- Fix CairoMakie's screen re-using [#2440](https://github.com/MakieOrg/Makie.jl/pull/2440).
- Fix repeated rendering with invisible objects [#2437](https://github.com/MakieOrg/Makie.jl/pull/2437).
- Fix hvlines for GLMakie [#2446](https://github.com/MakieOrg/Makie.jl/pull/2446).

## v0.18.3

- Add `render_on_demand` flag for `GLMakie.Screen`. Setting this to `true` will skip rendering until plots get updated. This is the new default [#2336](https://github.com/MakieOrg/Makie.jl/pull/2336), [#2397](https://github.com/MakieOrg/Makie.jl/pull/2397).
- Clean up OpenGL state handling in GLMakie [#2397](https://github.com/MakieOrg/Makie.jl/pull/2397).
- Fix salting [#2407](https://github.com/MakieOrg/Makie.jl/pull/2407).
- Fixes for [GtkMakie](https://github.com/jwahlstrand/GtkMakie.jl) [#2418](https://github.com/MakieOrg/Makie.jl/pull/2418).

## v0.18.2

- Fix Axis3 tick flipping with negative azimuth [#2364](https://github.com/MakieOrg/Makie.jl/pull/2364).
- Fix empty!(fig) and empty!(ax) [#2374](https://github.com/MakieOrg/Makie.jl/pull/2374), [#2375](https://github.com/MakieOrg/Makie.jl/pull/2375).
- Remove stencil buffer [#2389](https://github.com/MakieOrg/Makie.jl/pull/2389).
- Move Arrows and Wireframe to MakieCore [#2384](https://github.com/MakieOrg/Makie.jl/pull/2384).
- Skip legend entry if label is nothing [#2350](https://github.com/MakieOrg/Makie.jl/pull/2350).

## v0.18.1

- fix heatmap interpolation [#2343](https://github.com/MakieOrg/Makie.jl/pull/2343).
- move poly to MakieCore [#2334](https://github.com/MakieOrg/Makie.jl/pull/2334)
- Fix picking warning and update_axis_camera [#2352](https://github.com/MakieOrg/Makie.jl/pull/2352).
- bring back inline!, to not open a window in VSCode repl [#2353](https://github.com/MakieOrg/Makie.jl/pull/2353).

## v0.18

- **Breaking** Added `BezierPath` which can be constructed from SVG like command list, SVG string or from a `Polygon`.
  Added ability to use `BezierPath` and `Polgyon` as scatter markers.
  Replaced default symbol markers like `:cross` which converted to characters before with more precise `BezierPaths` and adjusted default markersize to 12.
  **Deprecated** using `String` to specify multiple char markers (`scatter(1:4, marker="abcd")`).
  **Deprecated** concrete geometries as markers like `Circle(Point2f(0), 1.5)` in favor of using the type like `Circle` for dispatch to special backend methods.
  Added single image marker support to WGLMakie [#979](https://github.com/MakieOrg/Makie.jl/pull/979).
- **Breaking** Refactored `display`, `record`, `colorbuffer` and `screens` to be faster and more consistent [#2306](https://github.com/MakieOrg/Makie.jl/pull/2306#issuecomment-1275918061).
- **Breaking** Refactored `DataInspector` to use `tooltip`. This results in changes in the attributes of DataInspector. Added `inspector_label`, `inspector_hover` and `inspector_clear` as optional attributes [#2095](https://github.com/JuliaPlots/Makie.jl/pull/2095).
- Added the `hexbin` plotting function [#2201](https://github.com/JuliaPlots/Makie.jl/pull/2201).
- Added the `tricontourf` plotting function [#2226](https://github.com/JuliaPlots/Makie.jl/pull/2226).
- Fixed per character attributes in text [#2244](https://github.com/JuliaPlots/Makie.jl/pull/2244).
- Allowed `CairoMakie` to render `scatter` with images as markers [#2080](https://github.com/MakieOrg/Makie.jl/pull/2080).
- Reworked text drawing and added ability to draw special characters via glyph indices in order to draw more LaTeX math characters with MathTeXEngine v0.5 [#2139](https://github.com/MakieOrg/Makie.jl/pull/2139).
- Allowed text to be copy/pasted into `Textbox` [#2281](https://github.com/MakieOrg/Makie.jl/pull/2281)
- Fixed updates for multiple meshes [#2277](https://github.com/MakieOrg/Makie.jl/pull/2277).
- Fixed broadcasting for linewidth, lengthscale & arrowsize in `arrow` recipe [#2273](https://github.com/MakieOrg/Makie.jl/pull/2273).
- Made GLMakie relocatable [#2282](https://github.com/MakieOrg/Makie.jl/pull/2282).
- Fixed changing input types in plot arguments [#2297](https://github.com/MakieOrg/Makie.jl/pull/2297).
- Better performance for Menus and fix clicks on items [#2299](https://github.com/MakieOrg/Makie.jl/pull/2299).
- Fixed CairoMakie bitmaps with transparency by using premultiplied ARGB surfaces [#2304](https://github.com/MakieOrg/Makie.jl/pull/2304).
- Fixed hiding of `Scene`s by setting `scene.visible[] = false` [#2317](https://github.com/MakieOrg/Makie.jl/pull/2317).
- `Axis` now accepts a `Tuple{Bool, Bool}` for `xtrimspine` and `ytrimspine` to trim only one end of the spine [#2171](https://github.com/JuliaPlots/Makie.jl/pull/2171).

## v0.17.13

- Fixed boundingboxes [#2184](https://github.com/MakieOrg/Makie.jl/pull/2184).
- Fixed highclip/lowclip in meshscatter, poly, contourf, barplot [#2183](https://github.com/MakieOrg/Makie.jl/pull/2183).
- Fixed gridline updates [#2196](https://github.com/MakieOrg/Makie.jl/pull/2196).
- Fixed glDisablei argument order, which crashed some Intel drivers.

## v0.17.12

- Fixed stackoverflow in show [#2167](https://github.com/MakieOrg/Makie.jl/pull/2167).

## v0.17.11

- `rainclouds`(!) now supports `violin_limits` keyword argument, serving the same.
role as `datalimits` in `violin` [#2137](https://github.com/MakieOrg/Makie.jl/pull/2137).
- Fixed an issue where nonzero `strokewidth` results in a thin outline of the wrong color if `color` and `strokecolor` didn't match and weren't transparent. [#2096](https://github.com/MakieOrg/Makie.jl/pull/2096).
- Improved performance around Axis(3) limits [#2115](https://github.com/MakieOrg/Makie.jl/pull/2115).
- Cleaned up stroke artifacts in scatter and text [#2096](https://github.com/MakieOrg/Makie.jl/pull/2096).
- Compile time improvements [#2153](https://github.com/MakieOrg/Makie.jl/pull/2153).
- Mesh and Surface now interpolate between values instead of interpolating between colors for WGLMakie + GLMakie [#2097](https://github.com/MakieOrg/Makie.jl/pull/2097).

## v0.17.10

- Bumped compatibility bound of `GridLayoutBase.jl` to `v0.9.0` which fixed a regression with `Mixed` and `Outside` alignmodes in nested `GridLayout`s [#2135](https://github.com/MakieOrg/Makie.jl/pull/2135).

## v0.17.9

- Patterns (`Makie.AbstractPattern`) are now supported by `CairoMakie` in `poly` plots that don't involve `mesh`, such as `bar` and `poly` [#2106](https://github.com/MakieOrg/Makie.jl/pull/2106/).
- Fixed regression where `Block` alignments could not be specified as numbers anymore [#2108](https://github.com/MakieOrg/Makie.jl/pull/2108).
- Added the option to show mirrored ticks on the other side of an Axis using the attributes `xticksmirrored` and `yticksmirrored` [#2105](https://github.com/MakieOrg/Makie.jl/pull/2105).
- Fixed a bug where a set of `Axis` wouldn't be correctly linked together if they were only linked in pairs instead of all at the same time [#2116](https://github.com/MakieOrg/Makie.jl/pull/2116).

## v0.17.7

- Improved `Menu` performance, now it should me much harder to reach the boundary of 255 scenes in GLMakie. `Menu` also takes a `default` keyword argument now and can be scrolled if there is too little space available.

## v0.17.6

- **EXPERIMENTAL**: Added support for multiple windows in GLMakie through `display(GLMakie.Screen(), figure_or_scene)` [#1771](https://github.com/MakieOrg/Makie.jl/pull/1771).
- Added support for RGB matrices in `heatmap` with GLMakie [#2036](https://github.com/MakieOrg/Makie.jl/pull/2036)
- `Textbox` doesn't defocus anymore on trying to submit invalid input [#2041](https://github.com/MakieOrg/Makie.jl/pull/2041).
- `text` now takes the position as the first argument(s) like `scatter` and most other plotting functions, it is invoked `text(x, y, [z], text = "text")`. Because it is now of conversion type `PointBased`, the positions can be given in all the usual different ways which are implemented as conversion methods. All old invocation styles such as `text("text", position = Point(x, y))` still work to maintain backwards compatibility [#2020](https://github.com/MakieOrg/Makie.jl/pull/2020).

## v0.17.5

- Fixed a regression with `linkaxes!` [#2039](https://github.com/MakieOrg/Makie.jl/pull/2039).

## v0.17.4

- The functions `hlines!`, `vlines!`, `hspan!`, `vspan!` and `abline!` were reimplemented as recipes. This allows using them without an `Axis` argument in first position and also as visuals in AlgebraOfGraphics.jl. Also, `abline!` is now called `ablines!` for consistency, `abline!` is still exported but deprecated and will be removed in the future. [#2023](https://github.com/MakieOrg/Makie.jl/pulls/2023).
- Added `rainclouds` and `rainclouds!` [#1725](https://github.com/MakieOrg/Makie.jl/pull/1725).
- Improve CairoMakie performance [#1964](https://github.com/MakieOrg/Makie.jl/pull/1964) [#1981](https://github.com/MakieOrg/Makie.jl/pull/1981).
- Interpolate colormap correctly [#1973](https://github.com/MakieOrg/Makie.jl/pull/1973).
- Fix picking [#1993](https://github.com/MakieOrg/Makie.jl/pull/1993).
- Improve compile time latency [#1968](https://github.com/MakieOrg/Makie.jl/pull/1968) [#2000](https://github.com/MakieOrg/Makie.jl/pull/2000).
- Fix multi poly with rects [#1999](https://github.com/MakieOrg/Makie.jl/pull/1999).
- Respect scale and nonlinear values in PlotUtils cgrads [#1979](https://github.com/MakieOrg/Makie.jl/pull/1979).
- Fix CairoMakie heatmap filtering [#1828](https://github.com/MakieOrg/Makie.jl/pull/1828).
- Remove GLVisualize and MakieLayout module [#2007](https://github.com/MakieOrg/Makie.jl/pull/2007) [#2008](https://github.com/MakieOrg/Makie.jl/pull/2008).
- Add linestyle and default to extrema(z) for contour, remove bitrotten fillrange [#2008](https://github.com/MakieOrg/Makie.jl/pull/2008).

## v0.17.3

- Switched to `MathTeXEngine v0.4`, which improves the look of LaTeXStrings [#1952](https://github.com/MakieOrg/Makie.jl/pull/1952).
- Added subtitle capability to `Axis` [#1859](https://github.com/MakieOrg/Makie.jl/pull/1859).
- Fixed a bug where scaled colormaps constructed using `Makie.cgrad` were not interpreted correctly.

## v0.17.2

- Changed the default font from `Dejavu Sans` to `TeX Gyre Heros Makie` which is the same as `TeX Gyre Heros` with slightly decreased descenders and ascenders. Decreasing those metrics reduced unnecessary whitespace and alignment issues. Four fonts in total were added, the styles Regular, Bold, Italic and Bold Italic. Also changed `Axis`, `Axis3` and `Legend` attributes `titlefont` to `TeX Gyre Heros Makie Bold` in order to separate it better from axis labels in multifacet arrangements [#1897](https://github.com/MakieOrg/Makie.jl/pull/1897).

## v0.17.1

- Added word wrapping. In `Label`, `word_wrap = true` causes it to use the suggested width and wrap text to fit. In `text`, `word_wrap_width > 0` can be used to set a pixel unit line width. Any word (anything between two spaces without a newline) that goes beyond this width gets a newline inserted before it [#1819](https://github.com/MakieOrg/Makie.jl/pull/1819).
- Improved `Axis3`'s interactive performance [#1835](https://github.com/MakieOrg/Makie.jl/pull/1835).
- Fixed errors in GLMakie's `scatter` implementation when markers are given as images. [#1917](https://github.com/MakieOrg/Makie.jl/pull/1917).
- Removed some method ambiguities introduced in v0.17 [#1922](https://github.com/MakieOrg/Makie.jl/pull/1922).
- Add an empty default label, `""`, to each slider that doesn't have a label in `SliderGrid` [#1888](https://github.com/MakieOrg/Makie.jl/pull/1888).

## v0.17

- **Breaking** Added `space` as a generic attribute to switch between data, pixel, relative and clip space for positions. `space` in text has been renamed to `markerspace` because of this. `Pixel` and `SceneSpace` are no longer valid inputs for `space` or `markerspace` [#1596](https://github.com/MakieOrg/Makie.jl/pull/1596).
- **Breaking** Deprecated `mouse_selection(scene)` for `pick(scene)`.
- **Breaking** Bumped `GridLayoutBase` version to `v0.7`, which introduced offset layouts. Now, indexing into row 0 doesn't create a new row 1, but a new row 0, so that all previous content positions stay the same. This makes building complex layouts order-independent [#1704](https://github.com/MakieOrg/Makie.jl/pull/1704).
- **Breaking** deprecate `to_colormap(cmap, ncolors)` in favor of `categorical_colors(cmap, ncolors)` and `resample_cmap(cmap, ncolors)` [#1901](https://github.com/MakieOrg/Makie.jl/pull/1901) [#1723](https://github.com/MakieOrg/Makie.jl/pull/1723).
- Added `empty!(fig)` and changed `empty!(scene)` to remove all child plots without detaching windows [#1818](https://github.com/MakieOrg/Makie.jl/pull/1818).
- Switched to erroring instead of warning for deprecated events `mousebuttons`, `keyboardbuttons` and `mousedrag`.
- `Layoutable` was renamed to `Block` and the infrastructure changed such that attributes are fixed fields and each block has its own `Scene` for better encapsulation [#1796](https://github.com/MakieOrg/Makie.jl/pull/1796).
- Added `SliderGrid` block which replaces the deprecated `labelslider!` and `labelslidergrid!` functions [#1796](https://github.com/MakieOrg/Makie.jl/pull/1796).
- The default anti-aliasing method can now be set in `CairoMakie.activate!` using the `antialias` keyword.  Available options are `CairoMakie.Cairo.ANTIALIAS_*` [#1875](https://github.com/MakieOrg/Makie.jl/pull/1875).
- Added ability to rasterize a plots in CairoMakie vector graphics if `plt.rasterize = true` or `plt.rasterize = scale::Int` [#1872](https://github.com/MakieOrg/Makie.jl/pull/1872).
- Fixed segfaults in `streamplot_impl` on Mac M1 [#1830](https://github.com/MakieOrg/Makie.jl/pull/1830).
- Set the [Cairo miter limit](https://www.cairographics.org/manual/cairo-cairo-t.html#cairo-set-miter-limit) to mimic GLMakie behaviour [#1844](https://github.com/MakieOrg/Makie.jl/pull/1844).
- Fixed a method ambiguity in `rotatedrect` [#1846](https://github.com/MakieOrg/Makie.jl/pull/1846).
- Allow weights in statistical recipes [#1816](https://github.com/MakieOrg/Makie.jl/pull/1816).
- Fixed manual cycling of plot attributes [#1873](https://github.com/MakieOrg/Makie.jl/pull/1873).
- Fixed type constraints in ticklabelalign attributes [#1882](https://github.com/MakieOrg/Makie.jl/pull/1882).

## v0.16.4

- Fixed WGLMakie performance bug and added option to set fps via `WGLMakie.activate!(fps=30)`.
- Implemented `nan_color`, `lowclip`, `highclip` for `image(::Matrix{Float})` in shader.
- Cleaned up mesh shader and implemented `nan_color`, `lowclip`, `highclip` for `mesh(m; color::Matrix{Float})` on the shader.
- Allowed `GLMakie.Buffer` `GLMakie.Sampler` to be used in `GeometryBasics.Mesh` to partially update parts of a mesh/texture and different interpolation and clamping modes for the texture.

## v0.16

- **Breaking** Removed `Node` alias [#1307](https://github.com/MakieOrg/Makie.jl/pull/1307), [#1393](https://github.com/MakieOrg/Makie.jl/pull/1393). To upgrade, simply replace all occurrences of `Node` with `Observable`.
- **Breaking** Cleaned up `Scene` type [#1192](https://github.com/MakieOrg/Makie.jl/pull/1192), [#1393](https://github.com/MakieOrg/Makie.jl/pull/1393). The `Scene()` constructor doesn't create any axes or limits anymore. All keywords like `raw`, `show_axis` have been removed. A scene now always works like it did when using the deprecated `raw=true`. All the high level functionality like showing an axis and adding a 3d camera has been moved to `LScene`. See the new `Scene` tutorial for more info: https://docs.makie.org/dev/tutorials/scenes/.
- **Breaking** Lights got moved to `Scene`, see the [lighting docs](https://docs.makie.org/stable/documentation/lighting) and [RPRMakie examples](https://docs.makie.org/stable/documentation/backends/rprmakie/).
- Added ECDF plot [#1310](https://github.com/MakieOrg/Makie.jl/pull/1310).
- Added Order Independent Transparency to GLMakie [#1418](https://github.com/MakieOrg/Makie.jl/pull/1418), [#1506](https://github.com/MakieOrg/Makie.jl/pull/1506). This type of transparency is now used with `transpareny = true`. The old transparency handling is available with `transparency = false`.
- Fixed blurry text in GLMakie and WGLMakie [#1494](https://github.com/MakieOrg/Makie.jl/pull/1494).
- Introduced a new experimental backend for ray tracing: [RPRMakie](https://docs.makie.org/stable/documentation/backends/rprmakie/).
- Added the `Cycled` type, which can be used to select the i-th value from the current cycler for a specific attribute [#1248](https://github.com/MakieOrg/Makie.jl/pull/1248).
- The plot function `scatterlines` now uses `color` as `markercolor` if `markercolor` is `automatic`. Also, cycling of the `color` attribute is enabled [#1463](https://github.com/MakieOrg/Makie.jl/pull/1463).
- Added the function `resize_to_layout!`, which allows to resize a `Figure` so that it contains its top `GridLayout` without additional whitespace or clipping [#1438](https://github.com/MakieOrg/Makie.jl/pull/1438).
- Cleaned up lighting in 3D contours and isosurfaces [#1434](https://github.com/MakieOrg/Makie.jl/pull/1434).
- Adjusted attributes of volumeslices to follow the normal structure [#1404](https://github.com/MakieOrg/Makie.jl/pull/1404). This allows you to adjust attributes like `colormap` without going through nested attributes.
- Added depth to 3D contours and isosurfaces [#1395](https://github.com/MakieOrg/Makie.jl/pull/1395), [#1393](https://github.com/MakieOrg/Makie.jl/pull/1393). This allows them to intersect correctly with other 3D objects.
- Restricted 3D scene camera to one scene [#1394](https://github.com/MakieOrg/Makie.jl/pull/1394), [#1393](https://github.com/MakieOrg/Makie.jl/pull/1393). This fixes issues with multiple scenes fighting over events consumed by the camera. You can select a scene by cleaning on it.
- Added depth shift attribute for GLMakie and WGLMakie [#1382](https://github.com/MakieOrg/Makie.jl/pull/1382), [#1393](https://github.com/MakieOrg/Makie.jl/pull/1393). This can be used to adjust render order similar to `overdraw`.
- Simplified automatic width computation in barplots [#1223](https://github.com/MakieOrg/Makie.jl/pull/1223), [#1393](https://github.com/MakieOrg/Makie.jl/pull/1393). If no `width` attribute is passed, the default width is computed as the minimum difference between consecutive `x` positions. Gap between bars are given by the (multiplicative) `gap` attribute. The actual bar width equals `width * (1 - gap)`.
- Added logical expressions for `ispressed` [#1222](https://github.com/MakieOrg/Makie.jl/pull/1222), [#1393](https://github.com/MakieOrg/Makie.jl/pull/1393). This moves a lot of control over hotkeys towards the user. With these changes one can now set a hotkey to trigger on any or no key, collections of keys and logical combinations of keys (i.e. "A is pressed and B is not pressed").
- Fixed issues with `Menu` render order [#1411](https://github.com/MakieOrg/Makie.jl/pull/1411).
- Added `label_rotation` to barplot [#1401](https://github.com/MakieOrg/Makie.jl/pull/1401).
- Fixed issue where `pixelcam!` does not remove controls from other cameras [#1504](https://github.com/MakieOrg/Makie.jl/pull/1504).
- Added conversion for OffsetArrays [#1260](https://github.com/MakieOrg/Makie.jl/pull/1260).
- The `qqplot` `qqline` options were changed to `:identity`, `:fit`, `:fitrobust` and `:none` (the default) [#1563](https://github.com/MakieOrg/Makie.jl/pull/1563). Fixed numeric error due to double computation of quantiles when fitting `qqline`. Deprecated `plot(q::QQPair)` method as it does not have enough information for correct `qqline` fit.

All other changes are collected [in this PR](https://github.com/MakieOrg/Makie.jl/pull/1521) and in the [release notes](https://github.com/MakieOrg/Makie.jl/releases/tag/v0.16.0).

## v0.15.3
- The functions `labelslidergrid!` and `labelslider!` now set fixed widths for the value column with a heuristic. It is possible now to pass `Formatting.format` format strings as format specifiers in addition to the previous functions.
- Fixed 2D arrow rotations in `streamplot` [#1352](https://github.com/MakieOrg/Makie.jl/pull/1352).

## v0.15.2
- Reenabled Julia 1.3 support.
- Use [MathTexEngine v0.2](https://github.com/Kolaru/MathTeXEngine.jl/releases/tag/v0.2.0).
- Depend on new GeometryBasics, which changes all the Vec/Point/Quaternion/RGB/RGBA - f0 aliases to just f. For example, `Vec2f0` is changed to `Vec2f`. Old aliases are still exported, but deprecated and will be removed in the next breaking release. For more details and an upgrade script, visit [GeometryBasics#97](https://github.com/JuliaGeometry/GeometryBasics.jl/pull/97).
- Added `hspan!` and `vspan!` functions [#1264](https://github.com/MakieOrg/Makie.jl/pull/1264).

## v0.15.1
- Switched documentation framework to Franklin.jl.
- Added a specialization for `volumeslices` to DataInspector.
- Fixed 1 element `hist` [#1238](https://github.com/MakieOrg/Makie.jl/pull/1238) and make it easier to move `hist` [#1150](https://github.com/MakieOrg/Makie.jl/pull/1150).

## v0.15.0

- `LaTeXString`s can now be used as input to `text` and therefore as labels for `Axis`, `Legend`, or other comparable objects. Mathematical expressions are typeset using [MathTeXEngine.jl](https://github.com/Kolaru/MathTeXEngine.jl) which offers a fast approximation of LaTeX typesetting [#1022](https://github.com/MakieOrg/Makie.jl/pull/1022).
- Added `Symlog10` and `pseudolog10` axis scales for log scale approximations that work with zero and negative values [#1109](https://github.com/MakieOrg/Makie.jl/pull/1109).
- Colorbar limits can now be passed as the attribute `colorrange` similar to plots [#1066](https://github.com/MakieOrg/Makie.jl/pull/1066).
- Added the option to pass three vectors to heatmaps and other plots using `SurfaceLike` conversion [#1101](https://github.com/MakieOrg/Makie.jl/pull/1101).
- Added `stairs` plot recipe [#1086](https://github.com/MakieOrg/Makie.jl/pull/1086).
- **Breaking** Removed `FigurePosition` and `FigureSubposition` types. Indexing into a `Figure` like `fig[1, 1]` now returns `GridPosition` and `GridSubposition` structs, which can be used in the same way as the types they replace. Because of an underlying change in `GridLayoutBase.jl`, it is now possible to do `Axis(gl[1, 1])` where `gl` is a `GridLayout` that is a sublayout of a `Figure`'s top layout [#1075](https://github.com/MakieOrg/Makie.jl/pull/1075).
- Bar plots and histograms have a new option for adding text labels [#1069](https://github.com/MakieOrg/Makie.jl/pull/1069).
- It is now possible to specify one `linewidth` value per segment in `linesegments` [#992](https://github.com/MakieOrg/Makie.jl/pull/992).
- Added a new 3d camera that allows for better camera movements using keyboard and mouse [#1024](https://github.com/MakieOrg/Makie.jl/pull/1024).
- Fixed the application of scale transformations to `surface` [#1070](https://github.com/MakieOrg/Makie.jl/pull/1070).
- Added an option to set a custom callback function for the `RectangleZoom` axis interaction to enable other use cases than zooming [#1104](https://github.com/MakieOrg/Makie.jl/pull/1104).
- Fixed rendering of `heatmap`s with one or more reversed ranges in CairoMakie, as in `heatmap(1:10, 10:-1:1, rand(10, 10))` [#1100](https://github.com/MakieOrg/Makie.jl/pull/1100).
- Fixed volume slice recipe and added docs for it [#1123](https://github.com/MakieOrg/Makie.jl/pull/1123).
