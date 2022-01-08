# News

## v0.16

#### Big Changes

- add ECDF plot [#1310](https://github.com/JuliaPlots/Makie.jl/pull/1310)
- add Order Independent Transparency to GLMakie [#1418](https://github.com/JuliaPlots/Makie.jl/pull/1418), [#1506](https://github.com/JuliaPlots/Makie.jl/pull/1506). This type of transparency is now used with `transpareny = true`. The old transparency handling is available with `transparency = false`.
- fix blurry text in GLMakie and WGLMakie [#1494](https://github.com/JuliaPlots/Makie.jl/pull/1494)
- A new experimental Backend for ray tracing got introduced: [RPRMakie](https://makie.juliaplots.org/stable/documentation/backends/rprmakie/)
- **Breaking** Remove `Node` alias [#1307](https://github.com/JuliaPlots/Makie.jl/pull/1307), [#1393](https://github.com/JuliaPlots/Makie.jl/pull/1393). To upgrade, simply replace all occurrences of `Node` with `Observable`
- **Breaking** clean up Scene type [#1192](https://github.com/JuliaPlots/Makie.jl/pull/1192), [#1393](https://github.com/JuliaPlots/Makie.jl/pull/1393). Long story short, Scene() doesn't create any axes or limits anymore. All keywords like `raw`, `show_axis` have been removed. A scene now always works like when using the deprecated `raw=true`. All the high level functionality like showing an axis and adding a 3d camera has been moved to `LScene`. See the new `Scene` tutorial for more info: https://makie.juliaplots.org/dev/tutorials/scenes/
- **lights got moved to scene** [lighting docs](https://makie.juliaplots.org/stable/documentation/lighting) and [RPRMakie examples](https://makie.juliaplots.org/stable/documentation/backends/rprmakie/)


#### Small Changes

- Added the `Cycled` type, which can be used to select the i-th value from the current cycler for a specific attribute. [#1248](https://github.com/JuliaPlots/Makie.jl/pull/1248)
- The plot function `scatterlines` now uses `color` as `markercolor` if `markercolor` is `automatic`. Also, cycling of the `color` attribute is enabled. [#1463](https://github.com/JuliaPlots/Makie.jl/pull/1463)
- Added the function `resize_to_layout!`, which allows to resize a `Figure` so that it contains its top `GridLayout` without additional whitespace or clipping. [#1438](https://github.com/JuliaPlots/Makie.jl/pull/1438)
- Cleanup lighting in 3D contours and isosurfaces [#1434](https://github.com/JuliaPlots/Makie.jl/pull/1434)
- Adjust attributes of volumeslices to follow the normal structure [#1404](https://github.com/JuliaPlots/Makie.jl/pull/1404). This allows you to adjust attributes like `colormap` without going through nested attributes.
- Add depth to 3D contours and isosurfaces [#1395](https://github.com/JuliaPlots/Makie.jl/pull/1395), [#1393](https://github.com/JuliaPlots/Makie.jl/pull/1393). This allows them to intersect correctly with other 3D objects.
- Restrict 3D scene camera to one scene [#1394](https://github.com/JuliaPlots/Makie.jl/pull/1394), [#1393](https://github.com/JuliaPlots/Makie.jl/pull/1393). This fixes issues with multiple scenes fighting over events consumed by the camera. You can select a scene by cleaning on it.
- add depth shift attribute for GLMakie and WGLMakie [#1382](https://github.com/JuliaPlots/Makie.jl/pull/1382), [#1393](https://github.com/JuliaPlots/Makie.jl/pull/1393). This can used to adjust render order similar to `overdraw`
- simplify plotting barplot by group [#1223](https://github.com/JuliaPlots/Makie.jl/pull/1223), [#1393](https://github.com/JuliaPlots/Makie.jl/pull/1393). This allows specifying x_distance in a bar plot. It corresponds to the bar width + the x_gap. The rationale is that we compute this from the data, assuming that bar width plus x_gap should equal minimum(diffs(x)), but in categorical data we just want that to be 1 (otherwise things get problematic if in some group not all categories are present).
- add logical expressions for `ispressed` [#1222](https://github.com/JuliaPlots/Makie.jl/pull/1222), [#1393](https://github.com/JuliaPlots/Makie.jl/pull/1393). This moves a lot of control over hotkeys towards the user. With these changes one can now set an hotkey to trigger on any or no key, collections of keys and logical combinations of keys (i.e. "A is pressed and B is not pressed").
- fix issues with Menu render order [#1411](https://github.com/JuliaPlots/Makie.jl/pull/1411)
- add label_rotation to barplot [#1401](https://github.com/JuliaPlots/Makie.jl/pull/1401)
- fix issue where `pixelcam!` does not remove controls from other cameras [#1504](https://github.com/JuliaPlots/Makie.jl/pull/1504)
- add conversion for offsetarrays [#1260](https://github.com/JuliaPlots/Makie.jl/pull/1260)

#### All other changes
Are collected [in this PR](https://github.com/JuliaPlots/Makie.jl/pull/1521) and in the [release notes](https://github.com/JuliaPlots/Makie.jl/releases/tag/v0.16.0).

## v0.15.3
- The functions `labelslidergrid!` and `labelslider!` now set fixed widths for the value column with a heuristic. It is possible now to pass `Formatting.format` format strings as format specifiers in addition to the previous functions.
- fix 2D arrow rotations in `streamplot` [#1352](https://github.com/JuliaPlots/Makie.jl/pull/1352)

## v0.15.2
- Reenabled Julia 1.3 support.
- Use [MathTexEngine v0.2](https://github.com/Kolaru/MathTeXEngine.jl/releases/tag/v0.2.0).
- Depend on new GeometryBasics, which changes all the Vec/Point/Quaternion/RGB/RGBA - f0 aliases to just f. For example, `Vec2f0` is changed to `Vec2f`. Old aliases are still exported, but deprecated and will be removed in the next breaking release. For more details and an upgrade script, visit [GeometryBasics#97](https://github.com/JuliaGeometry/GeometryBasics.jl/pull/97).
- Added `hspan!` and `vspan!` functions [#1264](https://github.com/JuliaPlots/Makie.jl/pull/1264).

## v0.15.1
- Switched documentation framework to Franklin.jl.
- Added a specialization for `volumeslices` to DataInspector.
- Fix [1 element `hist`](https://github.com/JuliaPlots/Makie.jl/pull/1238) and make it [easier to move `hist`](https://github.com/JuliaPlots/Makie.jl/pull/1150).

## v0.15.0

- `LaTeXString`s can now be used as input to `text` and therefore as labels for `Axis`, `Legend`, or other comparable objects. Mathematical expressions are typeset using [MathTeXEngine.jl](https://github.com/Kolaru/MathTeXEngine.jl) which offers a fast approximation of LaTeX typesetting. [#1022](https://github.com/JuliaPlots/Makie.jl/pull/1022)
- Added `Symlog10` and `pseudolog10` axis scales for log scale approximations that work with zero and negative values. [#1109](https://github.com/JuliaPlots/Makie.jl/pull/1109)
- Colorbar limits can now be passed as the attribute `colorrange` similar to plots. [#1066](https://github.com/JuliaPlots/Makie.jl/pull/1066)
- Added the option to pass three vectors to heatmaps and other plots using `SurfaceLike` conversion. [#1101](https://github.com/JuliaPlots/Makie.jl/pull/1101)
- Added `stairs` plot recipe. [#1086](https://github.com/JuliaPlots/Makie.jl/pull/1086)
- Removed `FigurePosition` and `FigureSubposition` types. Indexing into a `Figure` like `fig[1, 1]` now returns `GridPosition` and `GridSubposition` structs, which can be used in the same way as the types they replace. Because of an underlying change in `GridLayoutBase.jl`, it is now possible to do `Axis(gl[1, 1])` where `gl` is a `GridLayout` that is a sublayout of a `Figure`'s top layout. [#1075](https://github.com/JuliaPlots/Makie.jl/pull/1075)
- Bar plots and histograms have a new option for adding text labels. [#1069](https://github.com/JuliaPlots/Makie.jl/pull/1069)
- It is possible to specify one linewidth value per segment in `linesegments`. [#992](https://github.com/JuliaPlots/Makie.jl/pull/992)
- Added a new 3d camera that allows for better camera movements using keyboard and mouse. [#1024](https://github.com/JuliaPlots/Makie.jl/pull/1024)
- Fixed the application of scale transformations to `surface`. [#1070](https://github.com/JuliaPlots/Makie.jl/pull/1070)
- Added an option to set a custom callback function for the `RectangleZoom` axis interaction to enable other use cases than zooming. [#1104](https://github.com/JuliaPlots/Makie.jl/pull/1104)
- Fixed rendering of `heatmap`s with one or more reversed ranges in CairoMakie, as in `heatmap(1:10, 10:-1:1, rand(10, 10))`. [#1100](https://github.com/JuliaPlots/Makie.jl/pull/1100)
- fixed volume slice recipe and add docs for it [#1123](https://github.com/JuliaPlots/Makie.jl/pull/1123)
