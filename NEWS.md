# News

- Added `stairs` plot recipe. [#1086](https://github.com/JuliaPlots/Makie.jl/pull/1086)
- Removed `FigurePosition` and `FigureSubposition` types. Indexing into a `Figure` like `fig[1, 1]` now returns `GridPosition` and `GridSubposition` structs, which can be used in the same way as the types they replace. Because of an underlying change in `GridLayoutBase.jl`, it is now possible to do `Axis(gl[1, 1])` where `gl` is a `GridLayout` that is a sublayout of a `Figure`'s top layout. [#1075](https://github.com/JuliaPlots/Makie.jl/pull/1075)
- Bar plots and histograms have a new option for adding text labels. [#1069](https://github.com/JuliaPlots/Makie.jl/pull/1069)
