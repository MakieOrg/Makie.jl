# Changelog

## Unreleased

- Fixed `streamplot` and `contour` plots not considering transform functions in arrow/text rotation [#5249](https://github.com/MakieOrg/Makie.jl/pull/5249)
- `LogTicks` now work well with `pseudolog10` [#5135](https://github.com/MakieOrg/Makie.jl/pull/5135)
- Fixed `Symlog10` to work correctly with lower or upper thresholds smaller than 1, and adds a `linscale` argument [#5279](https://github.com/MakieOrg/Makie.jl/pull/5279)
- Fixed `xlims!`/`ylims!` not fully propagating to linked axis [#5239](https://github.com/MakieOrg/Makie.jl/pull/5239)
- Added support for plotting units with DynamicQuantities.jl [#5280](https://github.com/MakieOrg/Makie.jl/pull/5280)
- Adjusted compute nodes to keep unspecialized types when transitioning from one graph to another [#5302](https://github.com/MakieOrg/Makie.jl/pull/5302)

## [0.24.6] - 2025-08-19

- Widened types for axis keys [#5243](https://github.com/MakieOrg/Makie.jl/pull/5243)
- Fixed `getlimits(::Axis3)` error related to unchecked access of `:visible` attribute.
- Add simple compression for arrays containing only the same value in WGLMakie [#5252](https://github.com/MakieOrg/Makie.jl/pull/5252).
- Fixed 3D `contour` plots not rendering the correct isosurfaces when `colorrange` is given. Also fixed `isorange` not working, tweaked default `isorange`, colormap resolution, and changed colormap extractor for `Colorbar` to ignore alpha. [#5213](https://github.com/MakieOrg/Makie.jl/pull/5213)
- Fixed double application of `alpha` regression in `Band` plots in CairoMakie [#5258](https://github.com/MakieOrg/Makie.jl/pull/5258).
- Updated `boxplot`, `crossbar`, `density`, `hist`, `stephist`, `violin` and `waterfall` to use the new compute graph instead of observables. [#5184](https://github.com/MakieOrg/Makie.jl/pull/5184)

## [0.24.5] - 2025-08-06

- Added new scales based on `ReversibleScale` for use as `colorscale`, `xscale`, and `yscale` attributes. The new scales are `AsinhScale`, `SinhScale`, `LogScale`, `LuptonAsinhScale`, and `PowerScale`.
- Fixed `propertynames(::Attributes)` [#5154](https://github.com/MakieOrg/Makie.jl/pull/5154).
- Fixed cycle error in SpecApi and axis re-creation for plot type changes [#5198](https://github.com/MakieOrg/Makie.jl/pull/5198).
- Fixed incorrect variable name used for `voxels` in `Colorbar` [#5208](https://github.com/MakieOrg/Makie.jl/pull/5208)
- Fixed `Time` ticks breaking when axis limits crossed over midnight [#5212](https://github.com/MakieOrg/Makie.jl/pull/5212).
- Fixed issue where segments of solid `lines` disappeared when positions were large enough [#5216](https://github.com/MakieOrg/Makie.jl/pull/5216)
- Fixed `meshscatter` markers not updating correctly in GLMakie [#5217](https://github.com/MakieOrg/Makie.jl/pull/5217)
- Fixed `volume` plots getting clipped based on the vertices of their bounding box, e.g. when zooming in Axis3 [#5225](https://github.com/MakieOrg/Makie.jl/pull/5225)
- Fixed `Bonito.record_latest` for changes in Makie v0.24 [#5185](https://github.com/MakieOrg/Makie.jl/pull/5185).

## [0.24.4] - 2025-07-17
- Fixed rendering of volumes when the camera is inside the volume [#5164](https://github.com/MakieOrg/Makie.jl/pull/5164)
- Added some validation for compute node initialization (which guards against some error in `map!()` callbacks) [#5170](https://github.com/MakieOrg/Makie.jl/pull/5170)
- Added support for `GeometryBasics.MultiPoint` [#5182](https://github.com/MakieOrg/Makie.jl/pull/5182).
- Moved remaining compute edge checks for safe edge reuse out of debug mode [#5169](https://github.com/MakieOrg/Makie.jl/pull/5169)
- Adjusted compute `map!` to accept mixed array contain Symbols and compute nodes [#5167](https://github.com/MakieOrg/Makie.jl/pull/5167)
- Added `register_projected_positions!()` for projecting data in recipes (from start to finish). Also generalized `register_position_transform!()` and related for use in recipes [#5121](https://github.com/MakieOrg/Makie.jl/pull/5121)
- Added `register_projected_rotations_2d!` for calculating the screen space rotation between data points of a plot. [#5121](https://github.com/MakieOrg/Makie.jl/pull/5121)
- Added `map!(f, plot::Plot, inputs, outputs)` method (accepting a plot instead of a compute graph). [#5121](https://github.com/MakieOrg/Makie.jl/pull/5121)
- Updated `arrows`, `bracket`, `contour`, `contour3d`, `poly`, `streamplot`, `textlabel`, `triplot`, `voronoiplot` and `hexbin` to use the compute graph instead of observables. [#5121](https://github.com/MakieOrg/Makie.jl/pull/5121)
- Fixed `p.text = "..."` erroring with `p = text(..., text = rich(...))` [#5173](https://github.com/MakieOrg/Makie.jl/pull/5173)
- Support Interpolations.jl v0.16 [#5157](https://github.com/MakieOrg/Makie.jl/pull/5157)
- Updated `arc`, `band`, `pie`, `stairs`, `stem`, `tooltip`, `wireframe` and `qqplot` to use the new compute graph instead of observables [#5165](https://github.com/MakieOrg/Makie.jl/pull/5165)
- Added ability to modify ticks and tick format on a `DateTime` or `Time` conversion axis, for example `xticks = (datetimes, labels)` or `xtickformat = "d.m.yyyy"`. The default tick locator for datetimes is improved and the default formatting now reduces the amount of redundant information in neighboring ticks. It is exported as `DateTimeTicks` [#5159](https://github.com/MakieOrg/Makie.jl/pull/5159).
- Fixed missing toggle animation [#5156](https://github.com/MakieOrg/Makie.jl/pull/#5156)
- Fixed broadcast error in `position_on_plot` for mesh [#5196](https://github.com/MakieOrg/Makie.jl/pull/5196)

## [0.24.3] - 2025-07-04

- Fixed empty plotlist [#5150](https://github.com/MakieOrg/Makie.jl/pull/5150).
- Fixed plot attributes with `Dict` as input [#5149](https://github.com/MakieOrg/Makie.jl/pull/5149).
- Fixed arrow marker attributes in `arrows3d` not triggering repositioning of arrows. [#5134](https://github.com/MakieOrg/Makie.jl/pull/5134)
- Fixed h/vlines and h/vspan not considering transform functions correctly. [#5145](https://github.com/MakieOrg/Makie.jl/pull/5145)
- Added `register_projected_positions!()` for projecting data in recipes (from start to finish). Also generalized `register_position_transform!()` and related for use in recipes [#5121](https://github.com/MakieOrg/Makie.jl/pull/5121)
- Moved some compute edge checks out of debug mode to error more consistently on edge overwrite [#5125](https://github.com/MakieOrg/Makie.jl/pull/5125)

## [0.24.2] - 2025-06-27

- Bring back some default attributes for recipes [#5130](https://github.com/MakieOrg/Makie.jl/pull/5130).
- Allow multiple separate link groups in `xaxislinks` and `yaxislinks` arguments of `SpecApi.GridLayout` so that facet layouts can have independently linked columns and rows [#5127](https://github.com/MakieOrg/Makie.jl/pull/5127).

## [0.24.1] - 2025-06-24

- Don't pull plots from invisible scenes and hide Blocks during construction [#5119](https://github.com/MakieOrg/Makie.jl/pull/5119).
- Fixed `dendrogram` docstring and added `x, y, merges` conversion [#5118](https://github.com/MakieOrg/Makie.jl/pull/5118).
- Make sure there's only one inspector per root scene [#5113](https://github.com/MakieOrg/Makie.jl/pull/5113).
- Bring back lowres background for heatmap(Resampler(...)) [#5110](https://github.com/MakieOrg/Makie.jl/pull/5110).
- Fixed forwarding attributes in recipes [#5109](https://github.com/MakieOrg/Makie.jl/pull/5109).

## [0.24.0] - 2025-06-20

- **Breaking** Refactored plots to rely on the newly introduced `ComputeGraph` instead of `Observables`. [#4630](https://github.com/MakieOrg/Makie.jl/pull/4630)
  - **Breaking** `attr = Attributes(plot)` now returns a `ComputeGraph`, which disallows `copy(attr)`, `pop!(attr, ...)`, `attr[:newvar] = ...` and splatting `plot!(...; attr...)`.
  - **Semi-Breaking** `plot(parent, attr, args...; kwargs...)` now only considers applicable attributes in `attr` and prioritizes `kwargs` in case of collisions.
  - **Semi-Breaking** `@recipe Name (args...)` now names converted arguments and requires the number of `args` to match the number of outputs ifrom `convert_arguments()`
  - **Breaking** `replace_automatic!()` has been removed as it was incompatible. `Makie.default_automatic()` can be used as an alternative.
  - **Breaking** `text!()` is no longer a nested structure of text plots.
  - **Breaking** Scene lights have moved to the scene `ComputeGraph` and no longer contain Observables.
  - Fixed synchronous update issues by allowing synchronized update with `Makie.update!(plot, attrib1 = val1, attrib2 = val2, ...)`
  - Improved performance in WGLMakie with better bundling and filtering of updates
  - Improved traceability attribute and argument processing from user input to the backend
- **Breaking** `annotations!()` (not the new `annotation`) has been removed in favor of `text!()`. [#4630](https://github.com/MakieOrg/Makie.jl/pull/4630)
- **Semi-Breaking** Removed various internal text bounding box functions in favor of more user friendly functions like `string_boundingboxes(plot)` [#4630](https://github.com/MakieOrg/Makie.jl/pull/4630)
- **Semi-Breaking** Deprecated `ShadingAlgorithm` for `plot.shading` in favor of a `Bool`. The selection of the algorithm (`FastShading/MultiLightShading`) now happens at the scene level. [#4630](https://github.com/MakieOrg/Makie.jl/pull/4630)
- Fixed 2x2 surfaces not aligning colors correctly in WGLMakie [#4630](https://github.com/MakieOrg/Makie.jl/pull/4630)
- Added support for per-mesh `uv_transform` in `WGLMakie.meshscatter` [#4630](https://github.com/MakieOrg/Makie.jl/pull/4630)
- Fixed `PolarAxis` not considering text rotation correctly for tick label margins [#4630](https://github.com/MakieOrg/Makie.jl/pull/4630)
- Fixed `LaTeXStrings` not projecting lines correctly if `markerspace != :pixel` [#4630](https://github.com/MakieOrg/Makie.jl/pull/4630)
- Fixed incorrect z values for 2x2 `surface()` plots in CairoMakie and WGLMakie. [#5052](https://github.com/MakieOrg/Makie.jl/pull/5052)
- Fixed `arrows3d()` now including lighting attributes. [#5052](https://github.com/MakieOrg/Makie.jl/pull/5052)
- **Breaking** Removed `MakieCore` from Makie's dependencies. Going forward, package extensions are recommended if a lightweight dependency is desired. A quick fix is to change the dependency to `Makie` and replace all `MakieCore` occurrences with `Makie` although this will incur Makie's full load time every time. The alternative is to use a package extension on `Makie` which requires at least Julia 1.9.
- **Breaking** Changed `patchcolor` to opaque colors [#5088](https://github.com/MakieOrg/Makie.jl/pull/5088)
- Fixed `annotation` in the presence of scene transform functions [#5058](https://github.com/MakieOrg/Makie.jl/pull/5058).
- Moved Makie source directory from top level to ./Makie so that Makie itself does not include every other monorepo package when it's installed [#5069](https://github.com/MakieOrg/Makie.jl/pull/5069).
- Removed asset folder and made it an artifact, breaking code that didn't use `Makie.assetpath`. Also introduces `Makie.loadasset(name)`, to directly load the asset [#5074](https://github.com/MakieOrg/Makie.jl/pull/5074).
- Added `fontsize` attribute to `annotation` [#5099](https://github.com/MakieOrg/Makie.jl/pull/5099).

## [0.23.0] - 2025-06-10

- **Breaking** Refactored `arrows` to solve various issues: [#4925](https://github.com/MakieOrg/Makie.jl/pull/4925)
  - **Breaking** `Arrows` as a type is deprecated as the recipe has been split up. Use the `Makie.ArrowLike` conversion trait, `Arrows2D` or `Arrows3D` instead.
  - **Breaking** The `arrows!()` function is deprecated in favor of `arrows2d!()` and `arrows3d!()`. These plot functions differ in how they render arrows and can be used in 2D and 3D interchangeably.
  - **Breaking** The arrow size now considers all components of the arrow, not just the shaft, changing sizes and alignments.
  - **Breaking** `align` no longer accepts `:lineend, :tailend, :headstart` and `:origin`. It now only accepts `:head, :center, :tail` and numbers for fractional alignment. Issues with these alignments not working correctly have been fixed.
  - **Breaking** Attributes `arrowhead, arrowtail, arrowcolor, linecolor, linewidth, arrowsize` are deprecated. See `?arrows2d` and `?arrows3d` or the main docs for replacements.
  - **Breaking** Attributes `linestyle` and `transform_marker` are no longer supported.
  - **Breaking** Outside of `minshaftlength .. maxshaftlength`, arrows now scale as a whole instead of just their shaft.
  - **Breaking** 3D Arrows now try to scale to a size appropriate to the given data. This can be turned off by setting `markerscale` to a static number.
  - Arrows are now split into a tail, shaft and head, allowing for double-headed arrows.
  - 2D arrows are now based on `poly`, fixing self-overlap issues with transparent arrows.
  - 3D arrow tips, or more generally the new `GeometryBasics.Cone` renders with much smoother shading.
  - `argmode = :endpoint` has been added to allow constructing arrows with a start and end point instead of a start point and a direction.
  - Arrows now work correctly with `colorrange`, `alpha`, etc.
  - Transforms (e.g. `log` or `rotate!(plot, ...)`) now only affect the start and end points of arrows, rather than its components. This fixes issues like incorrect tip rotation of 2D arrows and stretching/squishing of 3D arrows.
- Add dim conversion support for Axis3 [#4964](https://github.com/MakieOrg/Makie.jl/pull/4964).
- Added support for vectors of intervals in `hspan` and `vspan` [#5036](https://github.com/MakieOrg/Makie.jl/pull/5036)
- Export `Float64` geometry types `Point3d`, `Vec4d`, `Rect2d` etc. [#5040](https://github.com/MakieOrg/Makie.jl/pull/5040).
- Added `dendrogram` recipe to Makie [#2755](https://github.com/MakieOrg/Makie.jl/pull/2755)
- Added unit support to `Slider` [#5037](https://github.com/MakieOrg/Makie.jl/pull/5037)
- Added `sources` section to all Project.tomls in the monorepo, so that `]dev GLMakie` will download the monorepo and automatically dev Makie and MakieCore. [#4967](https://github.com/MakieOrg/Makie.jl/pull/4967)

## [0.22.10] - 2025-06-03

- Quick fix for the just released `annotation`, `textcolor` now follows `color` by default [#5034](https://github.com/MakieOrg/Makie.jl/pull/5034).

## [0.22.9] - 2025-06-03

- Added conversion method for `annotation` to make it compatible with AlgebraOfGraphics [#5029](https://github.com/MakieOrg/Makie.jl/pull/5029).
- Fixed contour labels text positions update bug [#5010](https://github.com/MakieOrg/Makie.jl/pull/5010).

## [0.22.8] - 2025-06-03

- Added new `annotation` recipe which can be used for labeling many data points with automatically non-overlapping labels, or for more bespoke annotation with manually chosen positions and connecting arrows [#4891](https://github.com/MakieOrg/Makie.jl/pull/4891).
- Fixed precompilation bug in julia dev 1.13 [#5018](https://github.com/MakieOrg/Makie.jl/pull/5018).
- Fixed screen not open assertion and `Makie.isclosed(scene)` in WGLMakie [#5008](https://github.com/MakieOrg/Makie.jl/pull/5008).

## [0.22.7] - 2025-05-23

- Fixed regression in the updating logic of `Legend` [#4979](https://github.com/MakieOrg/Makie.jl/pull/4979).

## [0.22.6] - 2025-05-17

- Added `alpha` keyword to `density` recipe [#4975](https://github.com/MakieOrg/Makie.jl/pull/4975).
- Improved CairoMakie rendering of normal `band`s with array-valued colors [#4989](https://github.com/MakieOrg/Makie.jl/pull/4989).
- Fixed cycling not being consistent when the same plot function was called with different input types (float32 vs float64 lines, for example) [#4960](https://github.com/MakieOrg/Makie.jl/pull/4960)

## [0.22.5] - 2025-05-12

- Added LegendElements for meshscatter, mesh, image, heatmap and surface [#4924](https://github.com/MakieOrg/Makie.jl/pull/4924)
- Moved some of the TextureAtlas logic to JS, speeding up text updates and fixing texture atlas updates [4942](https://github.com/MakieOrg/Makie.jl/pull/4942).
- Added ability to hide and show individual plot elements by clicking their corresponding `Legend` entry [#2276](https://github.com/MakieOrg/Makie.jl/pull/2276).
- Fixed issue with UInt8 voxel data not updating correctly when Observable input is updated [#4914](https://github.com/MakieOrg/Makie.jl/pull/4914)
- Added ticks and minorticks to `PolarAxis`. Ticks and tick labels can now also be mirrored to the other side of a sector style PolarAxis. [#4902](https://github.com/MakieOrg/Makie.jl/pull/4902)
- Fixed `Axis.panbutton` not working [#4932](https://github.com/MakieOrg/Makie.jl/pull/4932)
- Fixed issues with anisotropic markersizes (e.g. `(10, 50)`) causing anti-aliasing to become blurry in GLMakie and WGLMakie. [#4918](https://github.com/MakieOrg/Makie.jl/pull/4918)
- Added `direction = :y` option for vertical `band`s [#4949](https://github.com/MakieOrg/Makie.jl/pull/4949).
- Fixed line-ordering of `lines(::Rect3)` [#4954](https://github.com/MakieOrg/Makie.jl/pull/4954).
- Fixed issue with `sprint`ing to SVG using CairoMakie in Julia 1.11 and above [#4971](https://github.com/MakieOrg/Makie.jl/pull/4971).

## [0.22.4] - 2025-04-11

- Re-added the `apply_transform(f, data, space)` method that was removed in v0.22.3 with a deprecation warning. It will be removed in the next breaking version. [#4916](https://github.com/MakieOrg/Makie.jl/pull/4916)

## [0.22.3] - 2025-04-08

- Added `alpha` attribute to `tricontourf.jl` to control the transparency of filled contours [#4800](https://github.com/MakieOrg/Makie.jl/pull/4800)
- Fixed hexbin using log-scales [#4898](https://github.com/MakieOrg/Makie.jl/pull/4898)
- Updated scope of `space` attribute, restricting it to camera related projections in the conversion-transformation-projection pipeline. (See docs on `space` or the pipeline) [#4792](https://github.com/MakieOrg/Makie.jl/pull/4792)
- Added inheritance options for the `transformation` keyword argument: `:inherit, :inherit_model, :inherit_transform_func, :nothing` (See docs on `transformations` or the pipeline) [#4792](https://github.com/MakieOrg/Makie.jl/pull/4792)
- Fixed GLMakie embedding support for window destruction [#4848](https://github.com/MakieOrg/Makie.jl/pull/4848).
- Adjusted `DataInspector` tooltips for `spy` to be heatmap-like and `datashader` to show the number of binned markers [#4810](https://github.com/MakieOrg/Makie.jl/pull/4810)
- Added `unsafe_set!(::Textbox, ::String)` [#4417](https://github.com/MakieOrg/Makie.jl/pull/4417)
- Improved compatibility of marker attributes with float32convert, fixing issues with scatter markers being render too small with `markerspace = :data` in an Axis [#4869](https://github.com/MakieOrg/Makie.jl/pull/4869)
- Added `font` attribute and fixed faulty selection in `scatter`. Scatter fonts can now be themed with `markerfont`. [#4832](https://github.com/MakieOrg/Makie.jl/pull/4832)
- Fixed categorical `cgrad` interpolating at small enough steps [#4858](https://github.com/MakieOrg/Makie.jl/pull/4858)
- Added `textlabel!()` recipe for plotting text with a background [#4879](https://github.com/MakieOrg/Makie.jl/pull/4879)
- Fixed the computed `colorrange` being out of order with `colorscale = -` or similar colorscale functions that break sorting [#4884](https://github.com/MakieOrg/Makie.jl/pull/4884)
- Added `transform_marker` to arrows [#4871](https://github.com/MakieOrg/Makie.jl/pull/4871)
- Reverted change in `meshscatter` transformation behavior by using `transform_marker = true` as the default [#4871](https://github.com/MakieOrg/Makie.jl/pull/4871)
- Fixed an error with Colorbar for categorical colormaps, where they displayed values out of colorrange and NaN. [#4894](https://github.com/MakieOrg/Makie.jl/pull/4894)
- Fixed minor grid not showing in Axis when minorticks are hidden [#4896](https://github.com/MakieOrg/Makie.jl/pull/4896)
- Fixed issue with small scatter markers disappearing in CairoMakie [#4882](https://github.com/MakieOrg/Makie.jl/pull/4882)
- Added current axis/figure defaults to `resize_to_layout!`, `x/yautolimits`, `hidex/y/decoration!` and `tight_x/y/ticklabel_spacing!` [#4519](https://github.com/MakieOrg/Makie.jl/pull/4519)
- Switched to Julia 1.10 for GLMakie CI due to issues with OpenGL on ubuntu-latest. This may cause GLMakie compatibility with the Julia 1.6 to degrade in the future. [#4913](https://github.com/MakieOrg/Makie.jl/pull/4913)
- Added support for logarithmic units [#4853](https://github.com/MakieOrg/Makie.jl/pull/4853)

## [0.22.2] - 2025-02-26

- Added support for curvilinear grids in `contourf` (contour filled), where `x` and `y` are matrices (`contour` lines were added in [0.22.0]) [#4670](https://github.com/MakieOrg/Makie.jl/pull/4670).
- Updated WGLMakie's threejs version from 0.157 to 0.173, fixing some threejs bugs [#4809](https://github.com/MakieOrg/Makie.jl/pull/4809).
- Moved Axis3 clip planes slightly outside to avoid clipping objects on the border with 0 margin [#4742](https://github.com/MakieOrg/Makie.jl/pull/4742)
- Fixed an issue with transformations not propagating to child plots when their spaces only match indirectly. [#4723](https://github.com/MakieOrg/Makie.jl/pull/4723)
- Added a tutorial on creating an inset plot [#4697](https://github.com/MakieOrg/Makie.jl/pull/4697)
- Enhanced Pattern support: Added general CairoMakie implementation, improved quality, added anchoring, added support in band, density, added tests & fixed various bugs and inconsistencies. [#4715](https://github.com/MakieOrg/Makie.jl/pull/4715)
- Fixed issue with `voronoiplot` for Voronoi tessellations with empty polygons [#4740](https://github.com/MakieOrg/Makie.jl/pull/4740)
- Fixed shader compilation error due to undefined unused variable in volume [#4755](https://github.com/MakieOrg/Makie.jl/pull/4755)
- Added option `update_while_dragging=true` to Slider [#4745](https://github.com/MakieOrg/Makie.jl/pull/4745).
- Added option `lowres_background=true` to Resampler, and renamed `resolution` to `max_resolution` [#4745](https://github.com/MakieOrg/Makie.jl/pull/4745).
- Added option `throttle=0.0` to `async_latest`, to allow throttling while skipping latest updates [#4745](https://github.com/MakieOrg/Makie.jl/pull/4745).
- Fixed issue with `WGLMakie.voxels` not rendering on linux with firefox [#4756](https://github.com/MakieOrg/Makie.jl/pull/4756)
- Updated `voxels` to use `uv_transform` interface instead of `uvmap` to give more control over texture mapping (i.e. to allow rotations) [#4758](https://github.com/MakieOrg/Makie.jl/pull/4758)
- **Breaking** Changed generated `uv`s in `voxels` to more easily align texture maps. Also changed uvs to scale with `gap` so that voxels remain fully covered. [#4758](https://github.com/MakieOrg/Makie.jl/pull/4758)
- Fixed `uv_transform = :rotr90` and `:rotl90` being swapped [#4758](https://github.com/MakieOrg/Makie.jl/pull/4758)
- Cleaned up surface handling in GLMakie: Surface cells are now discarded when there is a nan in x, y or z. Fixed incorrect normal if x or y is nan [#4735](https://github.com/MakieOrg/Makie.jl/pull/4735)
- Cleaned up `volume` plots: Added `:indexedabsorption` and `:additive` to WGLMakie, generalized `:mip` to include negative values, fixed missing conversions for rgba algorithms (`:additive`, `:absorptionrgba`), fixed missing conversion for `absorption` attribute & extended it to `:indexedabsorption` and `absorptionrgba`, added tests and improved docs. [#4726](https://github.com/MakieOrg/Makie.jl/pull/4726)
- Fixed integer underflow in GLMakie line indices which may have caused segmentation faults on mac [#4782](https://github.com/MakieOrg/Makie.jl/pull/4782)
- Added `Axis3.clip` attribute to allow turning off clipping [#4791](https://github.com/MakieOrg/Makie.jl/pull/4791)
- Fixed `Plane(Vec{N, T}(0), dist)` producing a `NaN` normal, which caused WGLMakie to break. (E.g. when rotating Axis3) [#4772](https://github.com/MakieOrg/Makie.jl/pull/4772)
- Changed `inspectable` to be inherited from the parent scenes theme. [#4739](https://github.com/MakieOrg/Makie.jl/pull/4739)
- Reverted change to `poly` which disallowed 3D geometries from being plotted [#4738](https://github.com/MakieOrg/Makie.jl/pull/4738)
- Enabled autocompletion on Block types, e.g. `?Axis.xti...` [#4786](https://github.com/MakieOrg/Makie.jl/pull/4786)
- Added `dpi` metadata to all rendered png files, where `px_per_unit = 1` means 96dpi, `px_per_unit = 2` means 192dpi, and so on. This gives frontends a chance to show plain Makie png images with the correct scaling [#4812](https://github.com/MakieOrg/Makie.jl/pull/4812).
- Fixed issue with voxels not working correctly with `rotate!()` [#4824](https://github.com/MakieOrg/Makie.jl/pull/4824)
- Fixed issue with tick event not triggering in WGLMakie [#4818](https://github.com/MakieOrg/Makie.jl/pull/4818)
- Improved performance of some Blocks, mainly `Textbox` and `Menu` [#4821](https://github.com/MakieOrg/Makie.jl/pull/4821)
- Fixed issue with `PolarAxis` not considering tick visibility in protrusion calculations. [#4823](https://github.com/MakieOrg/Makie.jl/pull/4823)
- Fixed some plots failing to create Legend entries due to missing attributes [#4826](https://github.com/MakieOrg/Makie.jl/pull/4826)

## [0.22.1] - 2025-01-17

- Allow volume textures for mesh color, to e.g. implement a performant volume slice display [#2274](https://github.com/MakieOrg/Makie.jl/pull/2274).
- Fixed `alpha` use in legends and some CairoMakie cases [#4721](https://github.com/MakieOrg/Makie.jl/pull/4721).

## [0.22.0] - 2024-12-12

- Updated to GeometryBasics 0.5: [GeometryBasics#173](https://github.com/JuliaGeometry/GeometryBasics.jl/pull/173), [GeometryBasics#219](https://github.com/JuliaGeometry/GeometryBasics.jl/pull/219) [#4319](https://github.com/MakieOrg/Makie.jl/pull/4319)
  - Removed `meta` infrastructure. Vertex attributes are now passed as kwargs.
  - Simplified GeometryBasics Mesh type, improving compile times
  - Added `FaceView` to allow different vertex attributes to use different indices for specifying data of the same vertex. This can be used to specify per-face data.
  - Added `GeometryBasics.face_normals(points, faces)`
  - Changed the order of `Rect2` coordinates to be counter-clockwise.
  - Updated `Cylinder` to avoid visually rounding off the top and bottom.
  - Added `MetaMesh` to store non-vertex metadata in a GeometryBasics Mesh object. These are now produced by MeshIO for `.obj` files, containing information from `.mtl` files.
  - Fix `Tessellation/tessellation` spelling [GeometryBasics#227](https://github.com/JuliaGeometry/GeometryBasics.jl/pull/227) [#4564](https://github.com/MakieOrg/Makie.jl/pull/4564)
- Added `Makie.mesh` option for `MetaMesh` which applies some of the bundled information [#4368](https://github.com/MakieOrg/Makie.jl/pull/4368), [#4496](https://github.com/MakieOrg/Makie.jl/pull/4496)
- `Voronoiplot`s automatic colors are now defined based on the underlying point set instead of only those generators appearing in the tessellation. This makes the selected colors consistent between tessellations when generators might have been deleted or added. [#4357](https://github.com/MakieOrg/Makie.jl/pull/4357)
- `contour` now supports _curvilinear_ grids, where `x` and `y` are matrices [#4670](https://github.com/MakieOrg/Makie.jl/pull/4670).
- Added `viewmode = :free` and translation, zoom, limit reset and cursor-focus interactions to Axis3. [4131](https://github.com/MakieOrg/Makie.jl/pull/4131)
- Split `marker_offset` handling from marker centering and fix various bugs with it [#4594](https://github.com/MakieOrg/Makie.jl/pull/4594)
- Added `transform_marker` attribute to meshscatter and changed the default behavior to not transform marker/mesh vertices [#4606](https://github.com/MakieOrg/Makie.jl/pull/4606)
- Fixed some issues with meshscatter not correctly transforming with transform functions and float32 rescaling [#4606](https://github.com/MakieOrg/Makie.jl/pull/4606)
- Fixed `poly` pipeline for 3D and/or Float64 polygons that begin from an empty vector [#4615](https://github.com/MakieOrg/Makie.jl/pull/4615).
- `empty!` GLMakie screen instead of closing, fixing issue with reset window position [#3881](https://github.com/MakieOrg/Makie.jl/pull/3881)
- Added option to display the front spines in Axis3 to close the outline box [#2349](https://github.com/MakieOrg/Makie.jl/pull/4305)
- Fixed gaps in corners of `poly(Rect2(...))` stroke [#4664](https://github.com/MakieOrg/Makie.jl/pull/4664)
- Fixed an issue where `reinterpret`ed arrays of line points were not handled correctly in CairoMakie [#4668](https://github.com/MakieOrg/Makie.jl/pull/4668).
- Fixed various issues with `markerspace = :data`, `transform_marker = true` and `rotation` for scatter in CairoMakie (incorrect marker transformations, ignored transformations, Cairo state corruption) [#4663](https://github.com/MakieOrg/Makie.jl/pull/4663)
- Changed deprecation warnings for Vector and Range inputs in `image`, `volume`, `voxels` and `spy` into **errors** [#4685](https://github.com/MakieOrg/Makie.jl/pull/4685)
- Refactored OpenGL cleanup to run immediately rather than on GC [#4699](https://github.com/MakieOrg/Makie.jl/pull/4699)
- It is now possible to change the title of a `GLFW.Window` with `GLMakie.set_title!(screen::Screen, title::String)` [#4677](https://github.com/MakieOrg/Makie.jl/pull/4677).
- Fixed `px_per_unit != 1` not getting fit to the size of the interactive window in GLMakie [#4687](https://github.com/MakieOrg/Makie.jl/pull/4687)
- Changed minorticks to skip computation when they are not visible [#4681](https://github.com/MakieOrg/Makie.jl/pull/4681)
- Fixed indexing error edge case in violin median code [#4682](https://github.com/MakieOrg/Makie.jl/pull/4682)
- Fixed incomplete plot cleanup when cleanup is triggered by an event. [#4710](https://github.com/MakieOrg/Makie.jl/pull/4710)
- Automatically plot Enums as categorical [#4717](https://github.com/MakieOrg/Makie.jl/pull/4717).

## [0.21.18] - 2024-12-12

- Allow for user defined recipes to be used in SpecApi [#4655](https://github.com/MakieOrg/Makie.jl/pull/4655).
- Fix text layouting with empty lines [#4269](https://github.com/MakieOrg/Makie.jl/pull/4269).

## [0.21.17] - 2024-12-05

- Added `backend` and `update` kwargs to `show` [#4558](https://github.com/MakieOrg/Makie.jl/pull/4558)
- Disabled unit prefix conversions for compound units (e.g. `u"m/s"`) to avoid generating incorrect units. [#4583](https://github.com/MakieOrg/Makie.jl/pull/4583)
- Added kwarg to rotate Toggle [#4445](https://github.com/MakieOrg/Makie.jl/pull/4445)
- Fixed orientation of environment light textures in RPRMakie [#4629](https://github.com/MakieOrg/Makie.jl/pull/4629).
- Fixed uint16 overflow for over ~65k elements in WGLMakie picking [#4604](https://github.com/MakieOrg/Makie.jl/pull/4604).
- Improved performance for line plot in CairoMakie [#4601](https://github.com/MakieOrg/Makie.jl/pull/4601).
- Prevent more default actions when canvas has focus [#4602](https://github.com/MakieOrg/Makie.jl/pull/4602).
- Fixed an error in `convert_arguments` for PointBased plots and 3D polygons [#4585](https://github.com/MakieOrg/Makie.jl/pull/4585).
- Fixed polygon rendering issue of `crossbar(..., show_notch = true)` in CairoMakie [#4587](https://github.com/MakieOrg/Makie.jl/pull/4587).
- Fixed `colorbuffer(axis)` for `px_per_unit != 1` [#4574](https://github.com/MakieOrg/Makie.jl/pull/4574).
- Fixed render order of Axis3 frame lines in CairoMakie [#4591](https://github.com/MakieOrg/Makie.jl/pull/4591)
- Fixed color mapping between `contourf` and `Colorbar` [#4618](https://github.com/MakieOrg/Makie.jl/pull/4618)
- Fixed an incorrect comparison in CairoMakie's line clipping code which can cause line segments to disappear [#4631](https://github.com/MakieOrg/Makie.jl/pull/4631)
- Added PointBased conversion for `Vector{MultiLineString}` [#4599](https://github.com/MakieOrg/Makie.jl/pull/4599)
- Added color conversions for tuples, Points and Vecs [#4599](https://github.com/MakieOrg/Makie.jl/pull/4599)
- Added conversions for 1 and 2 value paddings in `Label` and `tooltip` [#4599](https://github.com/MakieOrg/Makie.jl/pull/4599)
- Fixed `NaN` in scatter rotation and markersize breaking Cairo state [#4599](https://github.com/MakieOrg/Makie.jl/pull/4599)
- Fixed heatmap cells being 0.5px/units too large in CairoMakie [4633](https://github.com/MakieOrg/Makie.jl/pull/4633)
- Fixed bounds error when recording video with WGLMakie [#4639](https://github.com/MakieOrg/Makie.jl/pull/4639).
- Added `axis.(x/y)ticklabelspace = :max_auto`, to only grow tickspace but never shrink to reduce jitter [#4642](https://github.com/MakieOrg/Makie.jl/pull/4642).
- The error shown for invalid attributes will now also show suggestions for nearby attributes (if there are any) [#4394](https://github.com/MakieOrg/Makie.jl/pull/4394).
- Added (x/y)axislinks to S.GridLayout and make sure limits don't reset when linking axes [#4643](https://github.com/MakieOrg/Makie.jl/pull/4643).

## [0.21.16] - 2024-11-06

- Added `origin!()` to transformation so that the reference point of `rotate!()` and `scale!()` can be modified [#4472](https://github.com/MakieOrg/Makie.jl/pull/4472)
- Correctly render the tooltip triangle [#4560](https://github.com/MakieOrg/Makie.jl/pull/4560).
- Introduce `isclosed(scene)`, conditionally use `Bonito.LargeUpdate` [#4569](https://github.com/MakieOrg/Makie.jl/pull/4569).
- Allow plots to move between scenes in SpecApi [#4132](https://github.com/MakieOrg/Makie.jl/pull/4132).
- Added empty constructor to all backends for `Screen` allowing `display(Makie.current_backend().Screen(), fig)` [#4561](https://github.com/MakieOrg/Makie.jl/pull/4561).
- Added `subsup` and `left_subsup` functions that offer stacked sub- and superscripts for `rich` text which means this style can be used with arbitrary fonts and is not limited to fonts supported by MathTeXEngine.jl [#4489](https://github.com/MakieOrg/Makie.jl/pull/4489).
- Added the `jitter_width` and `side_nudge` attributes to the `raincloud` plot definition, so that they can be used as kwargs [#4517](https://github.com/MakieOrg/Makie.jl/pull/4517)
- Expand PlotList plots to expose their child plots to the legend interface, allowing `axislegend`show plots within PlotSpecs as individual entries. [#4546](https://github.com/MakieOrg/Makie.jl/pull/4546)
- Implement S.Colorbar(plotspec) [#4520](https://github.com/MakieOrg/Makie.jl/pull/4520).
- Fixed a hang when `Record` was created inside a closure passed to `IOCapture.capture` [#4562](https://github.com/MakieOrg/Makie.jl/pull/4562).
- Added logical size annotation to `text/html` inline videos so that sizes are appropriate independent of the current `px_per_unit` value [#4563](https://github.com/MakieOrg/Makie.jl/pull/4563).

## [0.21.15] - 2024-10-25

- Allowed creation of `Legend` with entries that have no legend elements [#4526](https://github.com/MakieOrg/Makie.jl/pull/4526).
- Improved CairoMakie's 2D mesh drawing performance by ~30% [#4132](https://github.com/MakieOrg/Makie.jl/pull/4132).
- Allow `width` to be set per box in `boxplot` [#4447](https://github.com/MakieOrg/Makie.jl/pull/4447).
- For `Textbox`es in which a fixed width is specified, the text is now scrolled
  if the width is exceeded [#4293](https://github.com/MakieOrg/Makie.jl/pull/4293)
- Changed image, heatmap and surface picking indices to correctly index the relevant matrix arguments. [#4459](https://github.com/MakieOrg/Makie.jl/pull/4459)
- Improved performance of `record` by avoiding unnecessary copying in common cases [#4475](https://github.com/MakieOrg/Makie.jl/pull/4475).
- Fixed usage of `AggMean()` and other aggregations operating on 3d data for `datashader` [#4346](https://github.com/MakieOrg/Makie.jl/pull/4346).
- Fixed forced rasterization when rendering figures with `Axis3` to svg [#4463](https://github.com/MakieOrg/Makie.jl/pull/4463).
- Changed default for `circular_rotation` in Camera3D to false, so that the camera doesn't change rotation direction anymore [4492](https://github.com/MakieOrg/Makie.jl/pull/4492)
- Fixed `pick(scene, rect2)` in WGLMakie [#4488](https://github.com/MakieOrg/Makie.jl/pull/4488)
- Fixed resizing of `surface` data not working correctly. (I.e. drawing out-of-bounds data or only drawing part of the data.) [#4529](https://github.com/MakieOrg/Makie.jl/pull/4529)

## [0.21.14] - 2024-10-11

- Fixed relocatability of GLMakie [#4461](https://github.com/MakieOrg/Makie.jl/pull/4461).
- Fixed relocatability of WGLMakie [#4467](https://github.com/MakieOrg/Makie.jl/pull/4467).
- Fixed `space` keyword for `barplot` [#4435](https://github.com/MakieOrg/Makie.jl/pull/4435).

## [0.21.13] - 2024-10-07

- Optimize SpecApi, reuse Blocks better and add API to access the created block objects [#4354](https://github.com/MakieOrg/Makie.jl/pull/4354).
- Fixed `merge(attr1, attr2)` modifying nested attributes in `attr1` [#4416](https://github.com/MakieOrg/Makie.jl/pull/4416)
- Fixed issue with CairoMakie rendering scene backgrounds at the wrong position [#4425](https://github.com/MakieOrg/Makie.jl/pull/4425)
- Fixed incorrect inverse transformation in `position_on_plot` for lines, causing incorrect tooltip placement in DataInspector [#4402](https://github.com/MakieOrg/Makie.jl/pull/4402)
- Added new `Checkbox` block [#4336](https://github.com/MakieOrg/Makie.jl/pull/4336).
- Added ability to override legend element attributes by pairing labels or plots with override attributes [#4427](https://github.com/MakieOrg/Makie.jl/pull/4427).
- Added threshold before a drag starts which improves false negative rates for clicks. `Button` can now trigger on click and not mouse-down which is the canonical behavior in other GUI systems [#4336](https://github.com/MakieOrg/Makie.jl/pull/4336).
- `PolarAxis` font size now defaults to global figure `fontsize` in the absence of specific `Axis` theming [#4314](https://github.com/MakieOrg/Makie.jl/pull/4314)
- `MultiplesTicks` accepts new option `strip_zero=true`, allowing labels of the form `0x` to be `0` [#4372](https://github.com/MakieOrg/Makie.jl/pull/4372)
- Make near/far of WGLMakie JS 3d camera dynamic, for better depth_shift scaling [#4430](https://github.com/MakieOrg/Makie.jl/pull/4430).

## [0.21.12] - 2024-09-28

- Fix NaN handling in WGLMakie [#4282](https://github.com/MakieOrg/Makie.jl/pull/4282).
- Show DataInspector tooltip on NaN values if `nan_color` has been set to other than `:transparent` [#4310](https://github.com/MakieOrg/Makie.jl/pull/4310)
- Fix `linestyle` not being used in `triplot` [#4332](https://github.com/MakieOrg/Makie.jl/pull/4332)
- Invalid keyword arguments for `Block`s (e.g. `Axis` and `Colorbar`) now throw errors and show suggestions rather than simply throwing [#4392](https://github.com/MakieOrg/Makie.jl/pull/4392)
- Fix voxel clipping not being based on voxel centers [#4397](https://github.com/MakieOrg/Makie.jl/pull/4397)
- Parsing `Q` and `q` commands in svg paths with `BezierPath` is now supported [#4413](https://github.com/MakieOrg/Makie.jl/pull/4413)


## [0.21.11] - 2024-09-13

- Hot fixes for 0.21.10 [#4356](https://github.com/MakieOrg/Makie.jl/pull/4356).
- Set `Voronoiplot`'s preferred axis type to 2D in all cases [#4349](https://github.com/MakieOrg/Makie.jl/pull/4349)

## [0.21.10] - 2024-09-12

- Introduce `heatmap(Resampler(large_matrix))`, allowing to show big images interactively [#4317](https://github.com/MakieOrg/Makie.jl/pull/4317).
- Make sure we wait for the screen session [#4316](https://github.com/MakieOrg/Makie.jl/pull/4316).
- Fix for absrect [#4312](https://github.com/MakieOrg/Makie.jl/pull/4312).
- Fix attribute updates for SpecApi and SpecPlots (e.g. ecdfplot) [#4265](https://github.com/MakieOrg/Makie.jl/pull/4265).
- Bring back `poly` convert arguments for matrix with points as row [#4258](https://github.com/MakieOrg/Makie.jl/pull/4258).
- Fix gl_ClipDistance related segfault on WSL with GLMakie [#4270](https://github.com/MakieOrg/Makie.jl/pull/4270).
- Added option `label_position = :center` to place labels centered over each bar [#4274](https://github.com/MakieOrg/Makie.jl/pull/4274).
- `plotfunc()` and `func2type()` support functions ending with `!` [#4275](https://github.com/MakieOrg/Makie.jl/pull/4275).
- Fixed Boundserror in clipped multicolor lines in CairoMakie [#4313](https://github.com/MakieOrg/Makie.jl/pull/4313)
- Fix float precision based assertions error in GLMakie.volume [#4311](https://github.com/MakieOrg/Makie.jl/pull/4311)
- Support images with reversed axes [#4338](https://github.com/MakieOrg/Makie.jl/pull/4338)

## [0.21.9] - 2024-08-27

- Hotfix for colormap + color updates [#4258](https://github.com/MakieOrg/Makie.jl/pull/4258).

## [0.21.8] - 2024-08-26

- Fix selected list in `WGLMakie.pick_sorted` [#4136](https://github.com/MakieOrg/Makie.jl/pull/4136).
- Apply px per unit in `pick_closest`/`pick_sorted` [#4137](https://github.com/MakieOrg/Makie.jl/pull/4137).
- Support plot(interval, func) for rangebars and band [#4102](https://github.com/MakieOrg/Makie.jl/pull/4102).
- Fixed the broken OpenGL state cleanup for clip_planes which may cause plots to disappear randomly [#4157](https://github.com/MakieOrg/Makie.jl/pull/4157)
- Reduce updates for image/heatmap, improving performance [#4130](https://github.com/MakieOrg/Makie.jl/pull/4130).
- Add an informative error message to `save` when no backend is loaded [#4177](https://github.com/MakieOrg/Makie.jl/pull/4177)
- Fix rendering of `band` with NaN values [#4178](https://github.com/MakieOrg/Makie.jl/pull/4178).
- Fix plotting of lines with OffsetArrays across all backends [#4242](https://github.com/MakieOrg/Makie.jl/pull/4242).

## [0.21.7] - 2024-08-19

- Hot fix for 1D heatmap [#4147](https://github.com/MakieOrg/Makie.jl/pull/4147).

## [0.21.6] - 2024-08-14

- Fix RectangleZoom in WGLMakie [#4127](https://github.com/MakieOrg/Makie.jl/pull/4127)
- Bring back fastpath for regular heatmaps [#4125](https://github.com/MakieOrg/Makie.jl/pull/4125)
- Data inspector fixes (mostly for bar plots) [#4087](https://github.com/MakieOrg/Makie.jl/pull/4087)
- Added "clip_planes" as a new generic plot and scene attribute. Up to 8 world space clip planes can be specified to hide sections of a plot. [#3958](https://github.com/MakieOrg/Makie.jl/pull/3958)
- Updated handling of `model` matrices with active Float32 rescaling. This should fix issues with Float32-unsafe translations or scalings of plots, as well as rotated plots in Float32-unsafe ranges. [#4026](https://github.com/MakieOrg/Makie.jl/pull/4026)
- Added `events.tick` to allow linking actions like animations to the renderloop. [#3948](https://github.com/MakieOrg/Makie.jl/pull/3948)
- Added the `uv_transform` attribute for meshscatter, mesh, surface and image [#1406](https://github.com/MakieOrg/Makie.jl/pull/1406).
- Added the ability to use textures with `meshscatter` in WGLMakie [#1406](https://github.com/MakieOrg/Makie.jl/pull/1406).
- Don't remove underlying VideoStream file when doing save() [#3883](https://github.com/MakieOrg/Makie.jl/pull/3883).
- Fix label/legend for plotlist [#4079](https://github.com/MakieOrg/Makie.jl/pull/4079).
- Fix wrong order for colors in RPRMakie [#4098](https://github.com/MakieOrg/Makie.jl/pull/4098).
- Fixed incorrect distance calculation in `pick_closest` in WGLMakie [#4082](https://github.com/MakieOrg/Makie.jl/pull/4082).
- Suppress keyboard shortcuts and context menu in JupyterLab output [#4068](https://github.com/MakieOrg/Makie.jl/pull/4068).
- Introduce stroke_depth_shift + forward normal depth_shift for Poly [#4058](https://github.com/MakieOrg/Makie.jl/pull/4058).
- Use linestyle for Poly and Density legend elements [#4000](https://github.com/MakieOrg/Makie.jl/pull/4000).
- Bring back interpolation attribute for surface [#4056](https://github.com/MakieOrg/Makie.jl/pull/4056).
- Improved accuracy of framerate settings in GLMakie [#3954](https://github.com/MakieOrg/Makie.jl/pull/3954)
- Fix label_formatter being called twice in barplot [#4046](https://github.com/MakieOrg/Makie.jl/pull/4046).
- Fix error with automatic `highclip` or `lowclip` and scalar colors [#4048](https://github.com/MakieOrg/Makie.jl/pull/4048).
- Correct a bug in the `project` function when projecting using a `Scene`. [#3909](https://github.com/MakieOrg/Makie.jl/pull/3909).
- Add position for `pie` plot [#4027](https://github.com/MakieOrg/Makie.jl/pull/4027).
- Correct a method ambiguity in `insert!` which was causing `PlotList` to fail on CairoMakie. [#4038](https://github.com/MakieOrg/Makie.jl/pull/4038)
- Delaunay triangulations created via `tricontourf`, `triplot`, and `voronoiplot` no longer use any randomisation in the point insertion order so that results are unique. [#4044](https://github.com/MakieOrg/Makie.jl/pull/4044)
- Improve content scaling support for Wayland and fix incorrect mouse scaling on mac [#4062](https://github.com/MakieOrg/Makie.jl/pull/4062)
- Fix: `band` ignored its `alpha` argument in CairoMakie
- Fix `marker=FastPixel()` makersize and markerspace, improve `spy` recipe [#4043](https://github.com/MakieOrg/Makie.jl/pull/4043).
- Fixed `invert_normals` for surface plots in CairoMakie [#4021](https://github.com/MakieOrg/Makie.jl/pull/4021).
- Improve support for embedding GLMakie. [#4073](https://github.com/MakieOrg/Makie.jl/pull/4073)
- Update JS OrbitControls to match Julia OrbitControls [#4084](https://github.com/MakieOrg/Makie.jl/pull/4084).
- Fix `select_point()` [#4101](https://github.com/MakieOrg/Makie.jl/pull/4101).
- Fix `absrect()` and `select_rectangle()` [#4110](https://github.com/MakieOrg/Makie.jl/issues/4110).
- Allow segment-specific radius for `pie` plot [#4028](https://github.com/MakieOrg/Makie.jl/pull/4028).

## [0.21.5] - 2024-07-07

- Fixed tuple argument for `WGLMakie.activate!(resize_to=(:parent, nothing))` [#4009](https://github.com/MakieOrg/Makie.jl/pull/4009).
- validate plot attributes later, for axis specific plot attributes [#3974](https://github.com/MakieOrg/Makie.jl/pull/3974).

## [0.21.4] - 2024-07-02

- Fixed support for GLFW 3.4 on OSX [#3999](https://github.com/MakieOrg/Makie.jl/issues/3999).
- Changed camera variables to Float64 for increased accuracy [#3984](https://github.com/MakieOrg/Makie.jl/pull/3984)
- Allow CairoMakie to render `poly` overloads that internally don't use two child plots [#3986](https://github.com/MakieOrg/Makie.jl/pull/3986).
- Fixes for Menu and DataInspector [#3975](https://github.com/MakieOrg/Makie.jl/pull/3975).
- Add line-loop detection and rendering to GLMakie and WGLMakie [#3907](https://github.com/MakieOrg/Makie.jl/pull/3907).

## [0.21.3] - 2024-06-17

- Fix stack overflows when using `markerspace = :data` with `scatter` [#3960](https://github.com/MakieOrg/Makie.jl/issues/3960).
- CairoMakie: Fix broken SVGs when using non-interpolated image primitives, for example Colorbars, with recent Cairo versions [#3967](https://github.com/MakieOrg/Makie.jl/pull/3967).
- CairoMakie: Add argument `pdf_version` to restrict the PDF version when saving a figure as a PDF [#3845](https://github.com/MakieOrg/Makie.jl/pull/3845).
- Fix DataInspector using invalid attribute strokewidth for plot type Wireframe [#3917](https://github.com/MakieOrg/Makie.jl/pull/3917).
- CairoMakie: Fix incorrect scaling factor for SVGs with Cairo_jll 1.18 [#3964](https://github.com/MakieOrg/Makie.jl/pull/3964).
- Fixed use of Textbox from Bonito [#3924](https://github.com/MakieOrg/Makie.jl/pull/3924)

## [0.21.2] - 2024-05-22

- Added `cycle` to general attribute allowlist so that it works also with plot types that don't set one in their theme [#3879](https://github.com/MakieOrg/Makie.jl/pull/3879).

## [0.21.1] - 2024-05-21

- `boundingbox` now relies on `apply_transform(transform, data_limits(plot))` rather than transforming the corner points of the bounding box [#3856](https://github.com/MakieOrg/Makie.jl/pull/3856).
- Adjusted `Axis` limits to consider transformations more consistently [#3864](https://github.com/MakieOrg/Makie.jl/pull/3864).
- Fix problems with incorrectly disabled attributes in recipes [#3870](https://github.com/MakieOrg/Makie.jl/pull/3870), [#3866](https://github.com/MakieOrg/Makie.jl/pull/3866).
- Fix RPRMakie with Material [#3872](https://github.com/MakieOrg/Makie.jl/pull/3872).
- Support the loop option in html video output [#3697](https://github.com/MakieOrg/Makie.jl/pull/3697).

## [0.21.0] - 2024-05-08

- Add `voxels` plot [#3527](https://github.com/MakieOrg/Makie.jl/pull/3527).
- Added supported markers hint to unsupported marker warn message [#3666](https://github.com/MakieOrg/Makie.jl/pull/3666).
- Fixed bug in CairoMakie line drawing when multiple successive points had the same color [#3712](https://github.com/MakieOrg/Makie.jl/pull/3712).
- Remove StableHashTraits in favor of calculating hashes directly with CRC32c [#3667](https://github.com/MakieOrg/Makie.jl/pull/3667).
- **Breaking (sort of)** Added a new `@recipe` variant which allows documenting attributes directly where they are defined and validating that all attributes are known whenever a plot is created. This is not breaking in the sense that the API changes, but user code is likely to break because of misspelled attribute names etc. that have so far gone unnoticed.
- Add axis converts, enabling unit/categorical support and more [#3226](https://github.com/MakieOrg/Makie.jl/pull/3226).
- **Breaking** Streamlined `data_limits` and `boundingbox` [#3671](https://github.com/MakieOrg/Makie.jl/pull/3671)
  - `data_limits` now only considers plot positions, completely ignoring transformations
  - `boundingbox(p::Text)` is deprecated in favor of `boundingbox(p::Text, p.markerspace[])`. The more internal methods use `string_boundingbox(p)`. [#3723](https://github.com/MakieOrg/Makie.jl/pull/3723)
  - `boundingbox` overwrites must now include a secondary space argument to work `boundingbox(plot, space::Symbol = :data)` [#3723](https://github.com/MakieOrg/Makie.jl/pull/3723)
  - `boundingbox` now always consider `transform_func` and `model`
  - `data_limits(::Scatter)` and `boundingbox(::Scatter)` now consider marker transformations [#3716](https://github.com/MakieOrg/Makie.jl/pull/3716)
- **Breaking** Improved Float64 compatibility of Axis [#3681](https://github.com/MakieOrg/Makie.jl/pull/3681)
  - This added an extra conversion step which only takes effect when Float32 precision becomes relevant. In those cases code using `project()` functions will be wrong as the transformation is not applied. Use `project(plot_or_scene, ...)` or apply the conversion yourself beforehand with `Makie.f32_convert(plot_or_scene, transformed_point)` and use `patched_model = Makie.patch_model(plot_or_scene, model)`.
  - `Makie.to_world(point, matrix, resolution)` has been deprecated in favor of `Makie.to_world(scene_or_plot, point)` to include float32 conversions.
- **Breaking** Reworked line shaders in GLMakie and WGLMakie [#3558](https://github.com/MakieOrg/Makie.jl/pull/3558)
  - GLMakie: Removed support for per point linewidths
  - GLMakie: Adjusted dots (e.g. with `linestyle = :dot`) to bend across a joint
  - GLMakie: Adjusted linestyles to scale with linewidth dynamically so that dots remain dots with changing linewidth
  - GLMakie: Cleaned up anti-aliasing for truncated joints
  - WGLMakie: Added support for linestyles
  - WGLMakie: Added line joints
  - WGLMakie: Added native anti-aliasing which generally improves quality but introduces outline artifacts in some cases (same as GLMakie)
  - Both: Adjusted handling of thin lines which may result in different color intensities
- Fixed an issue with lines being drawn in the wrong direction in 3D (with perspective projection) [#3651](https://github.com/MakieOrg/Makie.jl/pull/3651).
- **Breaking** Renamed attribute `rotations` to `rotation` for `scatter` and `meshscatter` which had been inconsistent with the otherwise singular naming scheme and other plots like `text` [#3724](https://github.com/MakieOrg/Makie.jl/pull/3724).
- Fixed `contourf` bug where n levels would sometimes miss the uppermost value, causing gaps [#3713](https://github.com/MakieOrg/Makie.jl/pull/3713).
- Added `scale` attribute to `violin` [#3352](https://github.com/MakieOrg/Makie.jl/pull/3352).
- Use label formatter in barplot [#3718](https://github.com/MakieOrg/Makie.jl/pull/3718).
- Fix the incorrect shading with non uniform markerscale in meshscatter [#3722](https://github.com/MakieOrg/Makie.jl/pull/3722)
- Add `scale_to=:flip` option to `hist`, which flips the direction of the bars [#3732](https://github.com/MakieOrg/Makie.jl/pull/3732)
- Fixed an issue with the texture atlas not updating in WGLMakie after display, causing new symbols to not show up [#3737](https://github.com/MakieOrg/Makie.jl/pull/3737)
- Added `linecap` and `joinstyle` attributes for lines and linesegments. Also normalized `miter_limit` to 60° across all backends. [#3771](https://github.com/MakieOrg/Makie.jl/pull/3771)

## [0.20.10] 2024-05-07

- Loosened type restrictions for potentially array-valued colors in `Axis` attributes like `xticklabelcolor` [#3826](https://github.com/MakieOrg/Makie.jl/pull/3826).
- Added support for intervals for specifying axis limits [#3696](https://github.com/MakieOrg/Makie.jl/pull/3696)
- Added recipes for plotting intervals to `Band`, `Rangebars`, `H/VSpan` [3695](https://github.com/MakieOrg/Makie.jl/pull/3695)
- Documented `WilkinsonTicks` [#3819](https://github.com/MakieOrg/Makie.jl/pull/3819).
- Added `axislegend(ax, "title")` method [#3808](https://github.com/MakieOrg/Makie.jl/pull/3808).
- Improved thread safety of rendering with CairoMakie (independent `Scene`s only) by locking FreeType handles [#3777](https://github.com/MakieOrg/Makie.jl/pull/3777).
- Adds a tutorial for how to make recipes work with new types [#3816](https://github.com/MakieOrg/Makie.jl/pull/3816).
- Provided an interface to convert markers in CairoMakie separately (`cairo_scatter_marker`) so external packages can overload it. [#3811](https://github.com/MakieOrg/Makie.jl/pull/3811)
- Updated to DelaunayTriangulation v1.0 [#3787](https://github.com/MakieOrg/Makie.jl/pull/3787).
- Added methods `hidedecorations!`, `hiderdecorations!`, `hidethetadecorations!` and  `hidespines!` for `PolarAxis` axes [#3823](https://github.com/MakieOrg/Makie.jl/pull/3823).
- Added `loop` option support for HTML outputs when recording videos with `record` [#3697](https://github.com/MakieOrg/Makie.jl/pull/3697).

## [0.20.9] - 2024-03-29

- Added supported markers hint to unsupported marker warn message [#3666](https://github.com/MakieOrg/Makie.jl/pull/3666).
- Fixed bug in CairoMakie line drawing when multiple successive points had the same color [#3712](https://github.com/MakieOrg/Makie.jl/pull/3712).
- Remove StableHashTraits in favor of calculating hashes directly with CRC32c [#3667](https://github.com/MakieOrg/Makie.jl/pull/3667).
- Fixed `contourf` bug where n levels would sometimes miss the uppermost value, causing gaps [#3713](https://github.com/MakieOrg/Makie.jl/pull/3713).
- Added `scale` attribute to `violin` [#3352](https://github.com/MakieOrg/Makie.jl/pull/3352).
- Use label formatter in barplot [#3718](https://github.com/MakieOrg/Makie.jl/pull/3718).
- Fix the incorrect shading with non uniform markerscale in meshscatter [#3722](https://github.com/MakieOrg/Makie.jl/pull/3722)
- Add `scale_to=:flip` option to `hist`, which flips the direction of the bars [#3732](https://github.com/MakieOrg/Makie.jl/pull/3732)
- Fixed an issue with the texture atlas not updating in WGLMakie after display, causing new symbols to not show up [#3737](https://github.com/MakieOrg/Makie.jl/pull/3737)

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
- Fixed stack overflow error on conversion of gridlike data with `missing`s [#3597](https://github.com/MakieOrg/Makie.jl/pull/3597).
- Fixed mutation of CairoMakie src dir when displaying png files [#3588](https://github.com/MakieOrg/Makie.jl/pull/3588).
- Added better error messages for plotting into `FigureAxisPlot` and `AxisPlot` as Plots.jl users are likely to do [#3596](https://github.com/MakieOrg/Makie.jl/pull/3596).
- Added compat bounds for IntervalArithmetic.jl due to bug with DelaunayTriangulation.jl [#3595](https://github.com/MakieOrg/Makie.jl/pull/3595).
- Removed possibility of three-argument `barplot` [#3574](https://github.com/MakieOrg/Makie.jl/pull/3574).

## [0.20.6] - 2024-02-02

- Fix issues with Camera3D not centering [#3582](https://github.com/MakieOrg/Makie.jl/pull/3582)
- Allowed creating legend entries from plot objects with scalar numbers as colors [#3587](https://github.com/MakieOrg/Makie.jl/pull/3587).

## [0.20.5] - 2024-01-25

- Use plot plot instead of scene transform functions in CairoMakie, fixing misplaced h/vspan. [#3552](https://github.com/MakieOrg/Makie.jl/pull/3552)
- Fix error printing on shader error [#3530](https://github.com/MakieOrg/Makie.jl/pull/3530).
- Update pagefind to 1.0.4 for better headline search [#3534](https://github.com/MakieOrg/Makie.jl/pull/3534).
- Remove unnecessary deps, e.g. Setfield [3546](https://github.com/MakieOrg/Makie.jl/pull/3546).
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
- Added a theme `theme_latexfonts` that uses the latex font family as default fonts [#3147](https://github.com/MakieOrg/Makie.jl/pull/3147), [#3180](https://github.com/MakieOrg/Makie.jl/pull/3180).
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
- Fix CairoMakie's screen reusing [#2440](https://github.com/MakieOrg/Makie.jl/pull/2440).
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
- Added Order Independent Transparency to GLMakie [#1418](https://github.com/MakieOrg/Makie.jl/pull/1418), [#1506](https://github.com/MakieOrg/Makie.jl/pull/1506). This type of transparency is now used with `transparency = true`. The old transparency handling is available with `transparency = false`.
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

- Re-enabled Julia 1.3 support.
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

[Unreleased]: https://github.com/MakieOrg/Makie.jl/compare/v0.24.6...HEAD
[0.24.6]: https://github.com/MakieOrg/Makie.jl/compare/v0.24.5...v0.24.6
[0.24.5]: https://github.com/MakieOrg/Makie.jl/compare/v0.24.4...v0.24.5
[0.24.4]: https://github.com/MakieOrg/Makie.jl/compare/v0.24.3...v0.24.4
[0.24.3]: https://github.com/MakieOrg/Makie.jl/compare/v0.24.2...v0.24.3
[0.24.2]: https://github.com/MakieOrg/Makie.jl/compare/v0.24.1...v0.24.2
[0.24.1]: https://github.com/MakieOrg/Makie.jl/compare/v0.24.0...v0.24.1
[0.24.0]: https://github.com/MakieOrg/Makie.jl/compare/v0.23.0...v0.24.0
[0.23.0]: https://github.com/MakieOrg/Makie.jl/compare/v0.22.10...v0.23.0
[0.22.10]: https://github.com/MakieOrg/Makie.jl/compare/v0.22.9...v0.22.10
[0.22.9]: https://github.com/MakieOrg/Makie.jl/compare/v0.22.8...v0.22.9
[0.22.8]: https://github.com/MakieOrg/Makie.jl/compare/v0.22.7...v0.22.8
[0.22.7]: https://github.com/MakieOrg/Makie.jl/compare/v0.22.6...v0.22.7
[0.22.6]: https://github.com/MakieOrg/Makie.jl/compare/v0.22.5...v0.22.6
[0.22.5]: https://github.com/MakieOrg/Makie.jl/compare/v0.22.4...v0.22.5
[0.22.4]: https://github.com/MakieOrg/Makie.jl/compare/v0.22.3...v0.22.4
[0.22.3]: https://github.com/MakieOrg/Makie.jl/compare/v0.22.2...v0.22.3
[0.22.2]: https://github.com/MakieOrg/Makie.jl/compare/v0.22.1...v0.22.2
[0.22.1]: https://github.com/MakieOrg/Makie.jl/compare/v0.22.0...v0.22.1
[0.22.0]: https://github.com/MakieOrg/Makie.jl/compare/v0.21.18...v0.22.0
[0.21.18]: https://github.com/MakieOrg/Makie.jl/compare/v0.21.17...v0.21.18
[0.21.17]: https://github.com/MakieOrg/Makie.jl/compare/v0.21.16...v0.21.17
[0.21.16]: https://github.com/MakieOrg/Makie.jl/compare/v0.21.15...v0.21.16
[0.21.15]: https://github.com/MakieOrg/Makie.jl/compare/v0.21.14...v0.21.15
[0.21.14]: https://github.com/MakieOrg/Makie.jl/compare/v0.21.13...v0.21.14
[0.21.13]: https://github.com/MakieOrg/Makie.jl/compare/v0.21.12...v0.21.13
[0.21.12]: https://github.com/MakieOrg/Makie.jl/compare/v0.21.11...v0.21.12
[0.21.11]: https://github.com/MakieOrg/Makie.jl/compare/v0.21.10...v0.21.11
[0.21.10]: https://github.com/MakieOrg/Makie.jl/compare/v0.21.9...v0.21.10
[0.21.9]: https://github.com/MakieOrg/Makie.jl/compare/v0.21.8...v0.21.9
[0.21.8]: https://github.com/MakieOrg/Makie.jl/compare/v0.21.7...v0.21.8
[0.21.7]: https://github.com/MakieOrg/Makie.jl/compare/v0.21.6...v0.21.7
[0.21.6]: https://github.com/MakieOrg/Makie.jl/compare/v0.21.5...v0.21.6
[0.21.5]: https://github.com/MakieOrg/Makie.jl/compare/v0.21.4...v0.21.5
[0.21.4]: https://github.com/MakieOrg/Makie.jl/compare/v0.21.3...v0.21.4
[0.21.3]: https://github.com/MakieOrg/Makie.jl/compare/v0.21.2...v0.21.3
[0.21.2]: https://github.com/MakieOrg/Makie.jl/compare/v0.21.1...v0.21.2
[0.21.1]: https://github.com/MakieOrg/Makie.jl/compare/v0.21.0...v0.21.1
[0.21.0]: https://github.com/MakieOrg/Makie.jl/compare/v0.20.10...v0.21.0
[0.20.10]: https://github.com/MakieOrg/Makie.jl/compare/v0.20.9...v0.20.10
[0.20.9]: https://github.com/MakieOrg/Makie.jl/compare/v0.20.8...v0.20.9
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
[0.15.0]: https://github.com/MakieOrg/Makie.jl/compare/v0.14.2...v0.15.0
