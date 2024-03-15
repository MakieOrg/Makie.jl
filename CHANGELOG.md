# Changelog

## [Unreleased]
- Added supported markers hint to unsupported marker warn message.

- Remove StableHashTraits in favor of calculating hashes directly with CRC32c [#3667](https://github.com/MakieOrg/Makie.jl/pull/3667).

## [0.20.8] - 2024-02-22

- Fixed excessive use of space with HTML image outputs [#3642](https://github.com/MakieOrg/Makie.jl/pull/3642).
- Fixed bugs with format strings and add new features by switching to Format.jl [#3633](https://github.com/MakieOrg/Makie.jl/pull/3633).
- Fixed an issue where CairoMakie would unnecessarily rasterize polygons [#3605](https://github.com/MakieOrg/Makie.jl/pull/3605).
- Added `PointBased` conversion trait to `scatterlines` recipe [#3603](https://github.com/MakieOrg/Makie.jl/pull/3603).
- Multiple small fixes for `map_latest`, `WGLMakie` picking and `PlotSpec` [#3637](https://github.com/MakieOrg/Makie.jl/pull/3637).
- Fixed PolarAxis `rticks` being incompatible with rich text. [#3615](https://github.com/MakieOrg/Makie.jl/pull/3615)
- Fixed an issue causing lines, scatter and text to not scale with resolution after deleting plots in GLMakie. [#3649](https://github.com/MakieOrg/Makie.jl/pull/3649)

## [0.20.7] - 2024-02-04

- Equalized alignment point of mirrored ticks to that of normal ticks [#3598](https://github.com/MakieOrg/Makie.jl/pull/3598).
- Fixed stack overflow error on conversion of gridlike data with missings [#3597](https://github.com/MakieOrg/Makie.jl/pull/3597).
- Fixed mutation of CairoMakie src dir when displaying png files [#3588](https://github.com/MakieOrg/Makie.jl/pull/3588).
- Added better error messages for plotting into `FigureAxisPlot` and `AxisPlot` as Plots.jl users are likely to do [#3596](https://github.com/MakieOrg/Makie.jl/pull/3596).
- Added compat bounds for IntervalArithmetic.jl due to bug with DelaunayTriangulation.jl [#3595](https://github.com/MakieOrg/Makie.jl/pull/3595).
- Removed possibility of three-argument `barplot` [#3574](https://github.com/MakieOrg/Makie.jl/pull/3574).

## [0.20.6] - 2024-02-02

- Fix issues with Camera3D not centering [#3582](https://github.com/MakieOrg/Makie.jl/pull/3582)
- Allowed creating legend entries from plot objects with scalar numbers as colors [#3587](https://github.com/MakieOrg/Makie.jl/pull/3587).

## [0.20.5] - 2024-01-25

- Use plot plot instead of scene transform functions in CairoMakie, fixing missplaced h/vspan. [#3552](https://github.com/MakieOrg/Makie.jl/pull/3552)
- Fix error printing on shader error [#3530](https://github.com/MakieOrg/Makie.jl/pull/3530).
- Update pagefind to 1.0.4 for better headline search [#3534](https://github.com/MakieOrg/Makie.jl/pull/3534).
- Remove unecessary deps, e.g. Setfield [3546](https://github.com/MakieOrg/Makie.jl/pull/3546).
- Don't clear args, rely on delete deregister_callbacks [#3543](https://github.com/MakieOrg/Makie.jl/pull/3543).
- Add interpolate keyword for Surface [#3541](https://github.com/MakieOrg/Makie.jl/pull/3541).
- Fix a DataInspector bug if inspector_label is used with RGB images [#3468](https://github.com/MakieOrg/Makie.jl/pull/3468).

## [0.20.4] - 2024-01-04

- Changes for Bonito rename and WGLMakie docs improvements [#3477](https://github.com/MakieOrg/Makie.jl/pull/3477).
- Add stroke and glow support to scatter and text in WGLMakie [#3518](https://github.com/MakieOrg/Makie.jl/pull/3518).
- Fix clipping issues with Camera3D when zooming in [#3529](https://github.com/MakieOrg/Makie.jl/pull/3529)

## [0.20.3] - 2023-12-21

- Add `depthsorting` as a hidden attribute for scatter plots in GLMakie as an alternative fix for outline artifacts. [#3432](https://github.com/MakieOrg/Makie.jl/pull/3432)
- Disable SDF based anti-aliasing in scatter, text and lines plots when `fxaa = true` in GLMakie. This allows removing outline artifacts at the cost of quality. [#3408](https://github.com/MakieOrg/Makie.jl/pull/3408)
- DataInspector Fixes: Fixed depth order, positional labels being in transformed space and `:inspector_clear` not getting called when moving from one plot to another. [#3454](https://github.com/MakieOrg/Makie.jl/pull/3454)
- Fixed bug in GLMakie where the update from a (i, j) sized GPU buffer to a (j, i) sized buffer would fail [#3456](https://github.com/MakieOrg/Makie.jl/pull/3456).
- Add `interpolate=true` to `volume(...)`, allowing to disable interpolation [#3485](https://github.com/MakieOrg/Makie.jl/pull/3485).

## [0.20.2] - 2023-12-01

- Switched from SHA512 to CRC32c salting in CairoMakie svgs, drastically improving svg rendering speed [#3435](https://github.com/MakieOrg/Makie.jl/pull/3435).
- Fixed a bug with h/vlines and h/vspan not correctly resolving transformations [#3418](https://github.com/MakieOrg/Makie.jl/pull/3418).
- Fixed a bug with h/vlines and h/vspan returning the wrong limits, causing an error in Axis [#3427](https://github.com/MakieOrg/Makie.jl/pull/3427).
- Fixed clipping when zooming out of a 3D (L)Scene [#3433](https://github.com/MakieOrg/Makie.jl/pull/3433).
- Moved the texture atlas cache to `.julia/scratchspaces` instead of a dedicated `.julia/makie` [#3437](https://github.com/MakieOrg/Makie.jl/pull/3437)

## [0.20.1] - 2023-11-23

- Fixed bad rendering of `poly` in GLMakie by triangulating points after transformations [#3402](https://github.com/MakieOrg/Makie.jl/pull/3402).
- Fixed bug regarding inline display in VSCode Jupyter notebooks and other similar environments [#3403](https://github.com/MakieOrg/Makie.jl/pull/3403).
- Fixed issue with `plottype`, allowed `onany(...; update = true)` and fixed `Block` macro use outside Makie [#3401](https://github.com/MakieOrg/Makie.jl/pull/3401).

## [0.20.0] - 2023-11-21

- GLMakie has gained support for HiDPI (aka Retina) screens. This also enables saving images with higher resolution than screen pixel dimensions [#2544](https://github.com/MakieOrg/Makie.jl/pull/2544).
- Fixed an issue where NaN was interpreted as zero when rendering `surface` through CairoMakie [#2598](https://github.com/MakieOrg/Makie.jl/pull/2598).
- Improved 3D camera handling, hotkeys and functionality [#2746](https://github.com/MakieOrg/Makie.jl/pull/2746).
- Added `shading = :verbose` in GLMakie to allow for multiple light sources. Also added more light types, fixed light directions for the previous lighting model (now `shading = :fast`) and adjusted `backlight` to affect normals[#3246](https://github.com/MakieOrg/Makie.jl/pull/3246).
- Changed the glyph used for negative numbers in tick labels from hyphen to minus [#3379](https://github.com/MakieOrg/Makie.jl/pull/3379).
- Added new declarative API for AlgebraOfGraphics, Pluto and easier dashboards [#3281](https://github.com/MakieOrg/Makie.jl/pull/3281).
- WGLMakie got faster line rendering with less updating bugs [#3062](https://github.com/MakieOrg/Makie.jl/pull/3062).
- **Breaking** Replaced `PolarAxis.radial_distortion_threshold` with `PolarAxis.radius_at_origin`. [#3381](https://github.com/MakieOrg/Makie.jl/pull/3381)
- **Breaking** Deprecated the `resolution` keyword in favor of `size` to reflect that this value is not a pixel resolution anymore [#3343](https://github.com/MakieOrg/Makie.jl/pull/3343).
- **Breaking** Refactored the `SurfaceLike` family of traits into `VertexGrid`, `CellGrid` and `ImageLike` [#3106](https://github.com/MakieOrg/Makie.jl/pull/3106).
- **Breaking** Deprecated `pixelarea(scene)` and `scene.px_area` in favor of viewport.
- **Breaking** Refactored the `Combined` Plot object and renamed it to `Plot`, improving compile times ~2x [#3082](https://github.com/MakieOrg/Makie.jl/pull/3082).
- **Breaking** Removed old depreactions in [#3113](https://github.com/MakieOrg/Makie.jl/pull/3113/commits/3a39210ef87a0032d78cb27c0c1019faa604effd).
- **Breaking** Deprecated using AbstractVector as sides of `image` [#3395](https://github.com/MakieOrg/Makie.jl/pull/3395).
- **Breaking** `errorbars` and `rangebars` now use color cycling [#3230](https://github.com/MakieOrg/Makie.jl/pull/3230).

## [0.19.12] - 2023-10-31

- Added `cornerradius` attribute to `Box` for rounded corners [#3346](https://github.com/MakieOrg/Makie.jl/pull/3346).
- Fix grouping of a zero-height bar in `barplot`. Now a zero-height bar shares the same properties of the previous bar, and if the bar is the first one, its height is treated as positive if and only if there exists a bar of positive height or all bars are zero-height [#3058](https://github.com/MakieOrg/Makie.jl/pull/3058).
- Fixed a bug where Axis still consumes scroll events when interactions are disabled [#3272](https://github.com/MakieOrg/Makie.jl/pull/3272).
- Added `cornerradius` attribute to `Box` for rounded corners [#3308](https://github.com/MakieOrg/Makie.jl/pull/3308).
- Upgraded `StableHashTraits` from 1.0 to 1.1 [#3309](https://github.com/MakieOrg/Makie.jl/pull/3309).

## [0.19.11] - 2023-10-05

- Setup automatic colorbars for volumeslices [#3253](https://github.com/MakieOrg/Makie.jl/pull/3253).
- Colorbar for arrows [#3275](https://github.com/MakieOrg/Makie.jl/pull/3275).
- Small bugfixes [#3275](https://github.com/MakieOrg/Makie.jl/pull/3275).

## [0.19.10] - 2023-09-21

- Fixed bugs with Colorbar in recipes, add new API for creating a recipe colorbar and introduce experimental support for Categorical colormaps [#3090](https://github.com/MakieOrg/Makie.jl/pull/3090).
- Added experimental Datashader implementation [#2883](https://github.com/MakieOrg/Makie.jl/pull/2883).
- **Breaking** Changed the default order Polar arguments to (theta, r). [#3154](https://github.com/MakieOrg/Makie.jl/pull/3154)
- General improvements to `PolarAxis`: full rlimtis & thetalimits, more controls and visual tweaks. See pr for more details.[#3154](https://github.com/MakieOrg/Makie.jl/pull/3154)

## [0.19.9] - 2023-09-11

- Allow arbitrary reversible scale functions through `ReversibleScale`.
- Deprecated `linestyle=vector_of_gaps` in favor of `linestyle=Linestyle(vector_of_gaps)` [3135](https://github.com/MakieOrg/Makie.jl/pull/3135), [3193](https://github.com/MakieOrg/Makie.jl/pull/3193).
- Fixed some errors around dynamic changes of `ax.xscale` or `ax.yscale` [#3084](https://github.com/MakieOrg/Makie.jl/pull/3084)
- Improved Barplot Label Alignment [#3160](https://github.com/MakieOrg/Makie.jl/issues/3160).
- Fixed regression in determining axis limits [#3179](https://github.com/MakieOrg/Makie.jl/pull/3179)
- Added a theme `theme_latexfonts` that uses the latex font family as default fonts [#3147](https://github.com/MakieOrg/Makie.jl/pull/3147).
- Upgrades `StableHashTraits` from 0.3 to 1.0

## [0.19.8] - 2023-08-15

- Improved CairoMakie rendering of `lines` with repeating colors in an array [#3141](https://github.com/MakieOrg/Makie.jl/pull/3141).
- Added `strokecolormap` to poly. [#3145](https://github.com/MakieOrg/Makie.jl/pull/3145)
- Added `xreversed`, `yreversed` and `zreversed` attributes to `Axis3` [#3138](https://github.com/MakieOrg/Makie.jl/pull/3138).
- Fixed incorrect placement of contourlabels with transform functions [#3083](https://github.com/MakieOrg/Makie.jl/pull/3083)
- Fixed automatic normal generation for meshes with shading and no normals [#3041](https://github.com/MakieOrg/Makie.jl/pull/3041).
- Added the `triplot` and `voronoiplot` recipes from DelaunayTriangulation.jl [#3102](https://github.com/MakieOrg/Makie.jl/pull/3102), [#3159](https://github.com/MakieOrg/Makie.jl/pull/3159).

## [0.19.7] - 2023-07-22

- Allow arbitrary functions to color `streamplot` lines by passing a `Function` to `color`.  This must accept `Point` of the appropriate dimension and return a `Point`, `Vec`, or other arraylike object [#2002](https://github.com/MakieOrg/Makie.jl/pull/2002).
- `arrows` can now take input of the form `x::AbstractVector, y::AbstractVector, [z::AbstractVector,] f::Function`, where `f` must return a `VecTypes` of the appropriate dimension [#2597](https://github.com/MakieOrg/Makie.jl/pull/2597).
- Exported colorbuffer, and added `colorbuffer(axis::Axis; include_decorations=false, colorbuffer_kws...)`, to get an image of an axis with or without decorations [#3078](https://github.com/MakieOrg/Makie.jl/pull/3078).
- Fixed an issue where the `linestyle` of some polys was not applied to the stroke in CairoMakie. [#2604](https://github.com/MakieOrg/Makie.jl/pull/2604)
- Add `colorscale = identity` to any plotting function using a colormap. This works with any scaling function like `log10`, `sqrt` etc. Consequently, `scale` for `hexbin` is replaced with `colorscale` [#2900](https://github.com/MakieOrg/Makie.jl/pull/2900).
- Add `alpha=1.0` argument to all basic plots, which supports independently adding an alpha component to colormaps and colors. Multiple alphas like in `plot(alpha=0.2, color=RGBAf(1, 0, 0, 0.5))`, will get multiplied [#2900](https://github.com/MakieOrg/Makie.jl/pull/2900).
- `hexbin` now supports any per-observation weights which StatsBase respects - `<: StatsBase.AbstractWeights`, `Vector{Real}`, or `nothing` (the default). [#2804](https://github.com/MakieOrg/Makie.jl/pulls/2804)
- Added a new Axis type, `PolarAxis`, which is an axis with a polar projection.  Input is in `(r, theta)` coordinates and is transformed to `(x, y)` coordinates using the standard polar-to-cartesian transformation.
  Generally, its attributes are very similar to the usual `Axis` attributes, but `x` is replaced by `r` and `y` by `θ`.
  It also inherits from the theme of `Axis` in this manner, so should work seamlessly with Makie themes [#2990](https://github.com/MakieOrg/Makie.jl/pull/2990).
- `inherit` now has a new signature `inherit(scene, attrs::NTuple{N, Symbol}, default_value)`, allowing recipe authors to access nested attributes when trying to inherit from the parent Scene.
  For example, one could inherit from `scene.Axis.yticks` by `inherit(scene, (:Axis, :yticks), $default_value)` [#2990](https://github.com/MakieOrg/Makie.jl/pull/2990).
- Fixed incorrect rendering of 3D heatmaps [#2959](https://github.com/MakieOrg/Makie.jl/pull/2959)
- Deprecated `flatten_plots` in favor of `collect_atomic_plots`. Using the new `collect_atomic_plots` fixed a bug in CairoMakie where the z-level of plots within recipes was not respected. [#2793](https://github.com/MakieOrg/Makie.jl/pull/2793)
- Fixed incorrect line depth in GLMakie [#2843](https://github.com/MakieOrg/Makie.jl/pull/2843)
- Fixed incorrect line alpha in dense lines in GLMakie [#2843](https://github.com/MakieOrg/Makie.jl/pull/2843)
- Fixed DataInspector interaction with transformations [#3002](https://github.com/MakieOrg/Makie.jl/pull/3002)
- Added option `WGLMakie.activate!(resize_to_body=true)`, to make plots resize to the VSCode plotpane. Resizes to the HTML body element, so may work outside VSCode [#3044](https://github.com/MakieOrg/Makie.jl/pull/3044), [#3042](https://github.com/MakieOrg/Makie.jl/pull/3042).
- Fixed DataInspector interaction with transformations [#3002](https://github.com/MakieOrg/Makie.jl/pull/3002).
- Fixed incomplete stroke with some Bezier markers in CairoMakie and blurry strokes in GLMakie [#2961](https://github.com/MakieOrg/Makie.jl/pull/2961)
- Added the ability to use custom triangulations from DelaunayTriangulation.jl [#2896](https://github.com/MakieOrg/Makie.jl/pull/2896).
- Adjusted scaling of scatter/text stroke, glow and anti-aliasing width under non-uniform 2D scaling (Vec2f markersize/fontsize) in GLMakie [#2950](https://github.com/MakieOrg/Makie.jl/pull/2950).
- Scaled `errorbar` whiskers and `bracket` correctly with transformations [#3012](https://github.com/MakieOrg/Makie.jl/pull/3012).
- Updated `bracket` when the screen is resized or transformations change [#3012](https://github.com/MakieOrg/Makie.jl/pull/3012).

## [0.19.6] - 2023-06-09

- Fixed broken AA for lines with strongly varying linewidth [#2953](https://github.com/MakieOrg/Makie.jl/pull/2953).
- Fixed WGLMakie JS popup [#2976](https://github.com/MakieOrg/Makie.jl/pull/2976).
- Fixed `legendelements` when children have no elements [#2982](https://github.com/MakieOrg/Makie.jl/pull/2982).
- Bumped compat for StatsBase to 0.34 [#2915](https://github.com/MakieOrg/Makie.jl/pull/2915).
- Improved thread safety [#2840](https://github.com/MakieOrg/Makie.jl/pull/2840).

## [0.19.5] - 2023-05-12

- Added `loop` option for GIF outputs when recording videos with `record` [#2891](https://github.com/MakieOrg/Makie.jl/pull/2891).
- Fixed line rendering issues in GLMakie [#2843](https://github.com/MakieOrg/Makie.jl/pull/2843).
- Fixed incorrect line alpha in dense lines in GLMakie [#2843](https://github.com/MakieOrg/Makie.jl/pull/2843).
- Changed `scene.clear` to an observable and made changes in `Scene` Observables trigger renders in GLMakie [#2929](https://github.com/MakieOrg/Makie.jl/pull/2929).
- Added contour labels [#2496](https://github.com/MakieOrg/Makie.jl/pull/2496).
- Allowed rich text to be used in Legends [#2902](https://github.com/MakieOrg/Makie.jl/pull/2902).
- Added more support for zero length Geometries [#2917](https://github.com/MakieOrg/Makie.jl/pull/2917).
- Made CairoMakie drawing for polygons with holes order independent [#2918](https://github.com/MakieOrg/Makie.jl/pull/2918).
- Fixes for `Makie.inline!()`, allowing now for `Makie.inline!(automatic)` (default), which is better at automatically opening a window/ inlining a plot into plotpane when needed [#2919](https://github.com/MakieOrg/Makie.jl/pull/2919) [#2937](https://github.com/MakieOrg/Makie.jl/pull/2937).
- Block/Axis doc improvements [#2940](https://github.com/MakieOrg/Makie.jl/pull/2940) [#2932](https://github.com/MakieOrg/Makie.jl/pull/2932) [#2894](https://github.com/MakieOrg/Makie.jl/pull/2894).

## [0.19.4] - 2023-03-31

- Added export of `hidezdecorations!` from MakieLayout [#2821](https://github.com/MakieOrg/Makie.jl/pull/2821).
- Fixed an issue with GLMakie lines becoming discontinuous [#2828](https://github.com/MakieOrg/Makie.jl/pull/2828).

## [0.19.3] - 2023-03-21

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

## [0.19.1] - 2023-01-01

- Add `show_data` method for `band` which shows the min and max values of the band at the x position of the cursor [#2497](https://github.com/MakieOrg/Makie.jl/pull/2497).
- Added `xlabelrotation`, `ylabelrotation` (`Axis`) and `labelrotation` (`Colorbar`) [#2478](https://github.com/MakieOrg/Makie.jl/pull/2478).
- Fixed forced rasterization in CairoMakie svg files when polygons with colors specified as (color, alpha) tuples were used [#2535](https://github.com/MakieOrg/Makie.jl/pull/2535).
- Do less copies of Observables in Attributes + plot pipeline [#2443](https://github.com/MakieOrg/Makie.jl/pull/2443).
- Add Search Page and tweak Result Ordering [#2474](https://github.com/MakieOrg/Makie.jl/pull/2474).
- Remove all global attributes from TextureAtlas implementation and fix julia#master [#2498](https://github.com/MakieOrg/Makie.jl/pull/2498).
- Use new Bonito, implement WGLMakie picking, improve performance and fix lots of WGLMakie bugs [#2428](https://github.com/MakieOrg/Makie.jl/pull/2428).

## [0.19.0] - 2022-12-03

- **Breaking** The attribute `textsize` has been removed everywhere in favor of the attribute `fontsize` which had also been in use.
  To migrate, search and replace all uses of `textsize` to `fontsize` [#2387](https://github.com/MakieOrg/Makie.jl/pull/2387).
- Added rich text which allows to more easily use superscripts and subscripts as well as differing colors, fonts, fontsizes, etc. for parts of a given text [#2321](https://github.com/MakieOrg/Makie.jl/pull/2321).

## [0.18.4] - 2022-12-02

- Added the `waterfall` plotting function [#2416](https://github.com/JuliaPlots/Makie.jl/pull/2416).
- Add support for `AbstractPattern` in `WGLMakie` [#2432](https://github.com/MakieOrg/Makie.jl/pull/2432).
- Broadcast replaces deprecated method for quantile [#2430](https://github.com/MakieOrg/Makie.jl/pull/2430).
- Fix CairoMakie's screen re-using [#2440](https://github.com/MakieOrg/Makie.jl/pull/2440).
- Fix repeated rendering with invisible objects [#2437](https://github.com/MakieOrg/Makie.jl/pull/2437).
- Fix hvlines for GLMakie [#2446](https://github.com/MakieOrg/Makie.jl/pull/2446).

## [0.18.3] - 2022-11-17

- Add `render_on_demand` flag for `GLMakie.Screen`. Setting this to `true` will skip rendering until plots get updated. This is the new default [#2336](https://github.com/MakieOrg/Makie.jl/pull/2336), [#2397](https://github.com/MakieOrg/Makie.jl/pull/2397).
- Clean up OpenGL state handling in GLMakie [#2397](https://github.com/MakieOrg/Makie.jl/pull/2397).
- Fix salting [#2407](https://github.com/MakieOrg/Makie.jl/pull/2407).
- Fixes for [GtkMakie](https://github.com/jwahlstrand/GtkMakie.jl) [#2418](https://github.com/MakieOrg/Makie.jl/pull/2418).

## [0.18.2] - 2022-11-03

- Fix Axis3 tick flipping with negative azimuth [#2364](https://github.com/MakieOrg/Makie.jl/pull/2364).
- Fix empty!(fig) and empty!(ax) [#2374](https://github.com/MakieOrg/Makie.jl/pull/2374), [#2375](https://github.com/MakieOrg/Makie.jl/pull/2375).
- Remove stencil buffer [#2389](https://github.com/MakieOrg/Makie.jl/pull/2389).
- Move Arrows and Wireframe to MakieCore [#2384](https://github.com/MakieOrg/Makie.jl/pull/2384).
- Skip legend entry if label is nothing [#2350](https://github.com/MakieOrg/Makie.jl/pull/2350).

## [0.18.1] - 2022-10-24

- fix heatmap interpolation [#2343](https://github.com/MakieOrg/Makie.jl/pull/2343).
- move poly to MakieCore [#2334](https://github.com/MakieOrg/Makie.jl/pull/2334)
- Fix picking warning and update_axis_camera [#2352](https://github.com/MakieOrg/Makie.jl/pull/2352).
- bring back inline!, to not open a window in VSCode repl [#2353](https://github.com/MakieOrg/Makie.jl/pull/2353).

## [0.18.0] - 2022-10-12

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

## [0.17.13] - 2022-08-04

- Fixed boundingboxes [#2184](https://github.com/MakieOrg/Makie.jl/pull/2184).
- Fixed highclip/lowclip in meshscatter, poly, contourf, barplot [#2183](https://github.com/MakieOrg/Makie.jl/pull/2183).
- Fixed gridline updates [#2196](https://github.com/MakieOrg/Makie.jl/pull/2196).
- Fixed glDisablei argument order, which crashed some Intel drivers.

## [0.17.12] - 2022-07-22

- Fixed stackoverflow in show [#2167](https://github.com/MakieOrg/Makie.jl/pull/2167).

## [0.17.11] - 2022-07-21

- `rainclouds`(!) now supports `violin_limits` keyword argument, serving the same.
role as `datalimits` in `violin` [#2137](https://github.com/MakieOrg/Makie.jl/pull/2137).
- Fixed an issue where nonzero `strokewidth` results in a thin outline of the wrong color if `color` and `strokecolor` didn't match and weren't transparent. [#2096](https://github.com/MakieOrg/Makie.jl/pull/2096).
- Improved performance around Axis(3) limits [#2115](https://github.com/MakieOrg/Makie.jl/pull/2115).
- Cleaned up stroke artifacts in scatter and text [#2096](https://github.com/MakieOrg/Makie.jl/pull/2096).
- Compile time improvements [#2153](https://github.com/MakieOrg/Makie.jl/pull/2153).
- Mesh and Surface now interpolate between values instead of interpolating between colors for WGLMakie + GLMakie [#2097](https://github.com/MakieOrg/Makie.jl/pull/2097).

## [0.17.10] - 2022-07-13

- Bumped compatibility bound of `GridLayoutBase.jl` to `v0.9.0` which fixed a regression with `Mixed` and `Outside` alignmodes in nested `GridLayout`s [#2135](https://github.com/MakieOrg/Makie.jl/pull/2135).

## [0.17.9] - 2022-07-12

- Patterns (`Makie.AbstractPattern`) are now supported by `CairoMakie` in `poly` plots that don't involve `mesh`, such as `bar` and `poly` [#2106](https://github.com/MakieOrg/Makie.jl/pull/2106/).
- Fixed regression where `Block` alignments could not be specified as numbers anymore [#2108](https://github.com/MakieOrg/Makie.jl/pull/2108).
- Added the option to show mirrored ticks on the other side of an Axis using the attributes `xticksmirrored` and `yticksmirrored` [#2105](https://github.com/MakieOrg/Makie.jl/pull/2105).
- Fixed a bug where a set of `Axis` wouldn't be correctly linked together if they were only linked in pairs instead of all at the same time [#2116](https://github.com/MakieOrg/Makie.jl/pull/2116).

## [0.17.7] - 2022-06-19

- Improved `Menu` performance, now it should be much harder to reach the boundary of 255 scenes in GLMakie. `Menu` also takes a `default` keyword argument now and can be scrolled if there is too little space available.

## [0.17.6] - 2022-06-17

- **EXPERIMENTAL**: Added support for multiple windows in GLMakie through `display(GLMakie.Screen(), figure_or_scene)` [#1771](https://github.com/MakieOrg/Makie.jl/pull/1771).
- Added support for RGB matrices in `heatmap` with GLMakie [#2036](https://github.com/MakieOrg/Makie.jl/pull/2036)
- `Textbox` doesn't defocus anymore on trying to submit invalid input [#2041](https://github.com/MakieOrg/Makie.jl/pull/2041).
- `text` now takes the position as the first argument(s) like `scatter` and most other plotting functions, it is invoked `text(x, y, [z], text = "text")`. Because it is now of conversion type `PointBased`, the positions can be given in all the usual different ways which are implemented as conversion methods. All old invocation styles such as `text("text", position = Point(x, y))` still work to maintain backwards compatibility [#2020](https://github.com/MakieOrg/Makie.jl/pull/2020).

## [0.17.5] - 2022-06-10

- Fixed a regression with `linkaxes!` [#2039](https://github.com/MakieOrg/Makie.jl/pull/2039).

## [0.17.4] - 2022-06-09

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

## [0.17.3] - 2022-05-20

- Switched to `MathTeXEngine v0.4`, which improves the look of LaTeXStrings [#1952](https://github.com/MakieOrg/Makie.jl/pull/1952).
- Added subtitle capability to `Axis` [#1859](https://github.com/MakieOrg/Makie.jl/pull/1859).
- Fixed a bug where scaled colormaps constructed using `Makie.cgrad` were not interpreted correctly.

## [0.17.2] - 2022-05-16

- Changed the default font from `Dejavu Sans` to `TeX Gyre Heros Makie` which is the same as `TeX Gyre Heros` with slightly decreased descenders and ascenders. Decreasing those metrics reduced unnecessary whitespace and alignment issues. Four fonts in total were added, the styles Regular, Bold, Italic and Bold Italic. Also changed `Axis`, `Axis3` and `Legend` attributes `titlefont` to `TeX Gyre Heros Makie Bold` in order to separate it better from axis labels in multifacet arrangements [#1897](https://github.com/MakieOrg/Makie.jl/pull/1897).

## [0.17.1] - 2022-05-13

- Added word wrapping. In `Label`, `word_wrap = true` causes it to use the suggested width and wrap text to fit. In `text`, `word_wrap_width > 0` can be used to set a pixel unit line width. Any word (anything between two spaces without a newline) that goes beyond this width gets a newline inserted before it [#1819](https://github.com/MakieOrg/Makie.jl/pull/1819).
- Improved `Axis3`'s interactive performance [#1835](https://github.com/MakieOrg/Makie.jl/pull/1835).
- Fixed errors in GLMakie's `scatter` implementation when markers are given as images. [#1917](https://github.com/MakieOrg/Makie.jl/pull/1917).
- Removed some method ambiguities introduced in v0.17 [#1922](https://github.com/MakieOrg/Makie.jl/pull/1922).
- Add an empty default label, `""`, to each slider that doesn't have a label in `SliderGrid` [#1888](https://github.com/MakieOrg/Makie.jl/pull/1888).

## [0.17.0] - 2022-05-05

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

## [0.16.4] - 2022-02-16

- Fixed WGLMakie performance bug and added option to set fps via `WGLMakie.activate!(fps=30)`.
- Implemented `nan_color`, `lowclip`, `highclip` for `image(::Matrix{Float})` in shader.
- Cleaned up mesh shader and implemented `nan_color`, `lowclip`, `highclip` for `mesh(m; color::Matrix{Float})` on the shader.
- Allowed `GLMakie.Buffer` `GLMakie.Sampler` to be used in `GeometryBasics.Mesh` to partially update parts of a mesh/texture and different interpolation and clamping modes for the texture.

## [0.16.0] - 2022-01-07

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

## [0.15.3] - 2021-10-16

- The functions `labelslidergrid!` and `labelslider!` now set fixed widths for the value column with a heuristic. It is possible now to pass `Formatting.format` format strings as format specifiers in addition to the previous functions.
- Fixed 2D arrow rotations in `streamplot` [#1352](https://github.com/MakieOrg/Makie.jl/pull/1352).

## [0.15.2] - 2021-08-26

- Reenabled Julia 1.3 support.
- Use [MathTexEngine v0.2](https://github.com/Kolaru/MathTeXEngine.jl/releases/tag/v0.2.0).
- Depend on new GeometryBasics, which changes all the Vec/Point/Quaternion/RGB/RGBA - f0 aliases to just f. For example, `Vec2f0` is changed to `Vec2f`. Old aliases are still exported, but deprecated and will be removed in the next breaking release. For more details and an upgrade script, visit [GeometryBasics#97](https://github.com/JuliaGeometry/GeometryBasics.jl/pull/97).
- Added `hspan!` and `vspan!` functions [#1264](https://github.com/MakieOrg/Makie.jl/pull/1264).

## [0.15.1] - 2021-08-21

- Switched documentation framework to Franklin.jl.
- Added a specialization for `volumeslices` to DataInspector.
- Fixed 1 element `hist` [#1238](https://github.com/MakieOrg/Makie.jl/pull/1238) and make it easier to move `hist` [#1150](https://github.com/MakieOrg/Makie.jl/pull/1150).

## [0.15.0] - 2021-07-15

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

[Unreleased]: https://github.com/MakieOrg/Makie.jl/compare/v0.20.8...HEAD
[0.20.8]: https://github.com/MakieOrg/Makie.jl/compare/v0.20.7...v0.20.8
[0.20.7]: https://github.com/MakieOrg/Makie.jl/compare/v0.20.6...v0.20.7
[0.20.6]: https://github.com/MakieOrg/Makie.jl/compare/v0.20.5...v0.20.6
[0.20.5]: https://github.com/MakieOrg/Makie.jl/compare/v0.20.4...v0.20.5
[0.20.4]: https://github.com/MakieOrg/Makie.jl/compare/v0.20.3...v0.20.4
[0.20.3]: https://github.com/MakieOrg/Makie.jl/compare/v0.20.2...v0.20.3
[0.20.2]: https://github.com/MakieOrg/Makie.jl/compare/v0.20.1...v0.20.2
[0.20.1]: https://github.com/MakieOrg/Makie.jl/compare/v0.20.0...v0.20.1
[0.20.0]: https://github.com/MakieOrg/Makie.jl/compare/v0.19.12...v0.20.0
[0.19.12]: https://github.com/MakieOrg/Makie.jl/compare/v0.19.11...v0.19.12
[0.19.11]: https://github.com/MakieOrg/Makie.jl/compare/v0.19.10...v0.19.11
[0.19.10]: https://github.com/MakieOrg/Makie.jl/compare/v0.19.9...v0.19.10
[0.19.9]: https://github.com/MakieOrg/Makie.jl/compare/v0.19.8...v0.19.9
[0.19.8]: https://github.com/MakieOrg/Makie.jl/compare/v0.19.7...v0.19.8
[0.19.7]: https://github.com/MakieOrg/Makie.jl/compare/v0.19.6...v0.19.7
[0.19.6]: https://github.com/MakieOrg/Makie.jl/compare/v0.19.5...v0.19.6
[0.19.5]: https://github.com/MakieOrg/Makie.jl/compare/v0.19.4...v0.19.5
[0.19.4]: https://github.com/MakieOrg/Makie.jl/compare/v0.19.3...v0.19.4
[0.19.3]: https://github.com/MakieOrg/Makie.jl/compare/v0.19.1...v0.19.3
[0.19.1]: https://github.com/MakieOrg/Makie.jl/compare/v0.19.0...v0.19.1
[0.19.0]: https://github.com/MakieOrg/Makie.jl/compare/v0.18.4...v0.19.0
[0.18.4]: https://github.com/MakieOrg/Makie.jl/compare/v0.18.3...v0.18.4
[0.18.3]: https://github.com/MakieOrg/Makie.jl/compare/v0.18.2...v0.18.3
[0.18.2]: https://github.com/MakieOrg/Makie.jl/compare/v0.18.1...v0.18.2
[0.18.1]: https://github.com/MakieOrg/Makie.jl/compare/v0.18.0...v0.18.1
[0.18.0]: https://github.com/MakieOrg/Makie.jl/compare/v0.17.13...v0.18.0
[0.17.13]: https://github.com/MakieOrg/Makie.jl/compare/v0.17.12...v0.17.13
[0.17.12]: https://github.com/MakieOrg/Makie.jl/compare/v0.17.11...v0.17.12
[0.17.11]: https://github.com/MakieOrg/Makie.jl/compare/v0.17.10...v0.17.11
[0.17.10]: https://github.com/MakieOrg/Makie.jl/compare/v0.17.9...v0.17.10
[0.17.9]: https://github.com/MakieOrg/Makie.jl/compare/v0.17.7...v0.17.9
[0.17.7]: https://github.com/MakieOrg/Makie.jl/compare/v0.17.6...v0.17.7
[0.17.6]: https://github.com/MakieOrg/Makie.jl/compare/v0.17.5...v0.17.6
[0.17.5]: https://github.com/MakieOrg/Makie.jl/compare/v0.17.4...v0.17.5
[0.17.4]: https://github.com/MakieOrg/Makie.jl/compare/v0.17.3...v0.17.4
[0.17.3]: https://github.com/MakieOrg/Makie.jl/compare/v0.17.2...v0.17.3
[0.17.2]: https://github.com/MakieOrg/Makie.jl/compare/v0.17.1...v0.17.2
[0.17.1]: https://github.com/MakieOrg/Makie.jl/compare/v0.17.0...v0.17.1
[0.17.0]: https://github.com/MakieOrg/Makie.jl/compare/v0.16.4...v0.17.0
[0.16.4]: https://github.com/MakieOrg/Makie.jl/compare/v0.16.0...v0.16.4
[0.16.0]: https://github.com/MakieOrg/Makie.jl/compare/v0.15.3...v0.16.0
[0.15.3]: https://github.com/MakieOrg/Makie.jl/compare/v0.15.2...v0.15.3
[0.15.2]: https://github.com/MakieOrg/Makie.jl/compare/v0.15.1...v0.15.2
[0.15.1]: https://github.com/MakieOrg/Makie.jl/compare/v0.15.0...v0.15.1
