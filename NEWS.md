# News

## v0.17

- **Breaking** Added `space` as a generic attribute to switch between data, pixel, relative and clip space for positions. `space` in text has been renamed to `markerspace` because of this. `Pixel` and `SceneSpace` are no longer valid inputs for `space` or `markerspace` [#1596](https://github.com/JuliaPlots/Makie.jl/pull/1596).
- **Breaking** Deprecated `mouse_selection(scene)` for `pick(scene)`.
- **Breaking** Bumped `GridLayoutBase` version to `v0.7`, which introduced offset layouts. Now, indexing into row 0 doesn't create a new row 1, but a new row 0, so that all previous content positions stay the same. This makes building complex layouts order-independent [#1704](https://github.com/JuliaPlots/Makie.jl/pull/1704).
- **Breaking** deprecate `to_colormap(cmap, ncolors)` in favor of `categorical_colors(cmap, ncolors)` and `resample_cmap(cmap, ncolors)` [#1901](https://github.com/JuliaPlots/Makie.jl/pull/1901)
- Added `empty!(fig)` and changed `empty!(scene)` to remove all child plots without detaching windows [#1818](https://github.com/JuliaPlots/Makie.jl/pull/1818).
- Switched to erroring instead of warning for deprecated events `mousebuttons`, `keyboardbuttons` and `mousedrag`.
- `Layoutable` was renamed to `Block` and the infrastructure changed such that attributes are fixed fields and each block has its own `Scene` for better encapsulation [#1796](https://github.com/JuliaPlots/Makie.jl/pull/1796).
- Added `SliderGrid` block which replaces the deprecated `labelslider!` and `labelslidergrid!` functions [#1796](https://github.com/JuliaPlots/Makie.jl/pull/1796).
- The default anti-aliasing method can now be set in `CairoMakie.activate!` using the `antialias` keyword.  Available options are `CairoMakie.Cairo.ANTIALIAS_*` [#1875](https://github.com/JuliaPlots/Makie.jl/pull/1875).
- Added ability to rasterize a plots in CairoMakie vector graphics if `plt.rasterize = true` or `plt.rasterize = scale::Int` [#1872](https://github.com/JuliaPlots/Makie.jl/pull/1872).
- Fixed segfaults in `streamplot_impl` on Mac M1 [#1830](https://github.com/JuliaPlots/Makie.jl/pull/1830).
- Set the [Cairo miter limit](https://www.cairographics.org/manual/cairo-cairo-t.html#cairo-set-miter-limit) to mimic GLMakie behaviour [#1844](https://github.com/JuliaPlots/Makie.jl/pull/1844).
- Fixed a method ambiguity in `rotatedrect` [#1846](https://github.com/JuliaPlots/Makie.jl/pull/1846).
- Allow weights in statistical recipes [#1816](https://github.com/JuliaPlots/Makie.jl/pull/1816).
- Fixed manual cycling of plot attributes [#1873](https://github.com/JuliaPlots/Makie.jl/pull/1873).
- Fixed type constraints in ticklabelalign attributes [#1882](https://github.com/JuliaPlots/Makie.jl/pull/1882).

##  v0.16.4

- Fixed WGLMakie performance bug and added option to set fps via `WGLMakie.activate!(fps=30)`.
- Implemented `nan_color`, `lowclip`, `highclip` for `image(::Matrix{Float})` in shader.
- Cleaned up mesh shader and implemented `nan_color`, `lowclip`, `highclip` for `mesh(m; color::Matrix{Float})` on the shader.
- Allowed `GLMakie.Buffer` `GLMakie.Sampler` to be used in `GeometryBasics.Mesh` to partially update parts of a mesh/texture and different interpolation and clamping modes for the texture.

## v0.16

- **Breaking** Removed `Node` alias [#1307](https://github.com/JuliaPlots/Makie.jl/pull/1307), [#1393](https://github.com/JuliaPlots/Makie.jl/pull/1393). To upgrade, simply replace all occurrences of `Node` with `Observable`.
- **Breaking** Cleaned up `Scene` type [#1192](https://github.com/JuliaPlots/Makie.jl/pull/1192), [#1393](https://github.com/JuliaPlots/Makie.jl/pull/1393). The `Scene()` constructor doesn't create any axes or limits anymore. All keywords like `raw`, `show_axis` have been removed. A scene now always works like it did when using the deprecated `raw=true`. All the high level functionality like showing an axis and adding a 3d camera has been moved to `LScene`. See the new `Scene` tutorial for more info: https://makie.juliaplots.org/dev/tutorials/scenes/.
- **Breaking** Lights got moved to `Scene`, see the [lighting docs](https://makie.juliaplots.org/stable/documentation/lighting) and [RPRMakie examples](https://makie.juliaplots.org/stable/documentation/backends/rprmakie/).
- Added ECDF plot [#1310](https://github.com/JuliaPlots/Makie.jl/pull/1310).
- Added Order Independent Transparency to GLMakie [#1418](https://github.com/JuliaPlots/Makie.jl/pull/1418), [#1506](https://github.com/JuliaPlots/Makie.jl/pull/1506). This type of transparency is now used with `transpareny = true`. The old transparency handling is available with `transparency = false`.
- Fixed blurry text in GLMakie and WGLMakie [#1494](https://github.com/JuliaPlots/Makie.jl/pull/1494).
- Introduced a new experimental backend for ray tracing: [RPRMakie](https://makie.juliaplots.org/stable/documentation/backends/rprmakie/).
- Added the `Cycled` type, which can be used to select the i-th value from the current cycler for a specific attribute [#1248](https://github.com/JuliaPlots/Makie.jl/pull/1248).
- The plot function `scatterlines` now uses `color` as `markercolor` if `markercolor` is `automatic`. Also, cycling of the `color` attribute is enabled [#1463](https://github.com/JuliaPlots/Makie.jl/pull/1463).
- Added the function `resize_to_layout!`, which allows to resize a `Figure` so that it contains its top `GridLayout` without additional whitespace or clipping [#1438](https://github.com/JuliaPlots/Makie.jl/pull/1438).
- Cleaned up lighting in 3D contours and isosurfaces [#1434](https://github.com/JuliaPlots/Makie.jl/pull/1434).
- Adjusted attributes of volumeslices to follow the normal structure [#1404](https://github.com/JuliaPlots/Makie.jl/pull/1404). This allows you to adjust attributes like `colormap` without going through nested attributes.
- Added depth to 3D contours and isosurfaces [#1395](https://github.com/JuliaPlots/Makie.jl/pull/1395), [#1393](https://github.com/JuliaPlots/Makie.jl/pull/1393). This allows them to intersect correctly with other 3D objects.
- Restricted 3D scene camera to one scene [#1394](https://github.com/JuliaPlots/Makie.jl/pull/1394), [#1393](https://github.com/JuliaPlots/Makie.jl/pull/1393). This fixes issues with multiple scenes fighting over events consumed by the camera. You can select a scene by cleaning on it.
- Added depth shift attribute for GLMakie and WGLMakie [#1382](https://github.com/JuliaPlots/Makie.jl/pull/1382), [#1393](https://github.com/JuliaPlots/Makie.jl/pull/1393). This can be used to adjust render order similar to `overdraw`.
- Simplified automatic width computation in barplots [#1223](https://github.com/JuliaPlots/Makie.jl/pull/1223), [#1393](https://github.com/JuliaPlots/Makie.jl/pull/1393). If no `width` attribute is passed, the default width is computed as the minimum difference between consecutive `x` positions. Gap between bars are given by the (multiplicative) `gap` attribute. The actual bar width equals `width * (1 - gap)`.
- Added logical expressions for `ispressed` [#1222](https://github.com/JuliaPlots/Makie.jl/pull/1222), [#1393](https://github.com/JuliaPlots/Makie.jl/pull/1393). This moves a lot of control over hotkeys towards the user. With these changes one can now set a hotkey to trigger on any or no key, collections of keys and logical combinations of keys (i.e. "A is pressed and B is not pressed").
- Fixed issues with `Menu` render order [#1411](https://github.com/JuliaPlots/Makie.jl/pull/1411).
- Added `label_rotation` to barplot [#1401](https://github.com/JuliaPlots/Makie.jl/pull/1401).
- Fixed issue where `pixelcam!` does not remove controls from other cameras [#1504](https://github.com/JuliaPlots/Makie.jl/pull/1504).
- Added conversion for OffsetArrays [#1260](https://github.com/JuliaPlots/Makie.jl/pull/1260).
- The `qqplot` `qqline` options were changed to `:identity`, `:fit`, `:fitrobust` and `:none` (the default) [#1563](https://github.com/JuliaPlots/Makie.jl/pull/1563). Fixed numeric error due to double computation of quantiles when fitting `qqline`. Deprecated `plot(q::QQPair)` method as it does not have enough information for correct `qqline` fit.

All other changes are collected [in this PR](https://github.com/JuliaPlots/Makie.jl/pull/1521) and in the [release notes](https://github.com/JuliaPlots/Makie.jl/releases/tag/v0.16.0).

## v0.15.3
- The functions `labelslidergrid!` and `labelslider!` now set fixed widths for the value column with a heuristic. It is possible now to pass `Formatting.format` format strings as format specifiers in addition to the previous functions.
- Fixed 2D arrow rotations in `streamplot` [#1352](https://github.com/JuliaPlots/Makie.jl/pull/1352).

## v0.15.2
- Reenabled Julia 1.3 support.
- Use [MathTexEngine v0.2](https://github.com/Kolaru/MathTeXEngine.jl/releases/tag/v0.2.0).
- Depend on new GeometryBasics, which changes all the Vec/Point/Quaternion/RGB/RGBA - f0 aliases to just f. For example, `Vec2f0` is changed to `Vec2f`. Old aliases are still exported, but deprecated and will be removed in the next breaking release. For more details and an upgrade script, visit [GeometryBasics#97](https://github.com/JuliaGeometry/GeometryBasics.jl/pull/97).
- Added `hspan!` and `vspan!` functions [#1264](https://github.com/JuliaPlots/Makie.jl/pull/1264).

## v0.15.1
- Switched documentation framework to Franklin.jl.
- Added a specialization for `volumeslices` to DataInspector.
- Fixed 1 element `hist` [#1238](https://github.com/JuliaPlots/Makie.jl/pull/1238) and make it easier to move `hist` [#1150](https://github.com/JuliaPlots/Makie.jl/pull/1150).

## v0.15.0

- `LaTeXString`s can now be used as input to `text` and therefore as labels for `Axis`, `Legend`, or other comparable objects. Mathematical expressions are typeset using [MathTeXEngine.jl](https://github.com/Kolaru/MathTeXEngine.jl) which offers a fast approximation of LaTeX typesetting [#1022](https://github.com/JuliaPlots/Makie.jl/pull/1022).
- Added `Symlog10` and `pseudolog10` axis scales for log scale approximations that work with zero and negative values [#1109](https://github.com/JuliaPlots/Makie.jl/pull/1109).
- Colorbar limits can now be passed as the attribute `colorrange` similar to plots [#1066](https://github.com/JuliaPlots/Makie.jl/pull/1066).
- Added the option to pass three vectors to heatmaps and other plots using `SurfaceLike` conversion [#1101](https://github.com/JuliaPlots/Makie.jl/pull/1101).
- Added `stairs` plot recipe [#1086](https://github.com/JuliaPlots/Makie.jl/pull/1086).
- **Breaking** Removed `FigurePosition` and `FigureSubposition` types. Indexing into a `Figure` like `fig[1, 1]` now returns `GridPosition` and `GridSubposition` structs, which can be used in the same way as the types they replace. Because of an underlying change in `GridLayoutBase.jl`, it is now possible to do `Axis(gl[1, 1])` where `gl` is a `GridLayout` that is a sublayout of a `Figure`'s top layout [#1075](https://github.com/JuliaPlots/Makie.jl/pull/1075).
- Bar plots and histograms have a new option for adding text labels [#1069](https://github.com/JuliaPlots/Makie.jl/pull/1069).
- It is now possible to specify one `linewidth` value per segment in `linesegments` [#992](https://github.com/JuliaPlots/Makie.jl/pull/992).
- Added a new 3d camera that allows for better camera movements using keyboard and mouse [#1024](https://github.com/JuliaPlots/Makie.jl/pull/1024).
- Fixed the application of scale transformations to `surface` [#1070](https://github.com/JuliaPlots/Makie.jl/pull/1070).
- Added an option to set a custom callback function for the `RectangleZoom` axis interaction to enable other use cases than zooming [#1104](https://github.com/JuliaPlots/Makie.jl/pull/1104).
- Fixed rendering of `heatmap`s with one or more reversed ranges in CairoMakie, as in `heatmap(1:10, 10:-1:1, rand(10, 10))` [#1100](https://github.com/JuliaPlots/Makie.jl/pull/1100).
- Fixed volume slice recipe and added docs for it [#1123](https://github.com/JuliaPlots/Makie.jl/pull/1123).
