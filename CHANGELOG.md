# Other branches (not yet merged)
- Provided a way to generate a lower quality texture atlas via `set_glyph_resolution!(Low)`
  to make the WebGL backend more lightweight (#166).
- Fixed `scale_plot` not actually working (#166).

# `master`
- Added a custom docstring extension which allows the Attributes of a Recipe to be shown in
  the help mode (#174).
- Documented a lot of internal features (#174).
- Added a new 3d camera type, `cam3d_cad!`(#161).
- Improved warning text when displaying to text or plotpane (#163).
- Ensured that unless `inline!(true)` was called, plots will always display in
  interactive displays, even in Juno (#163).
- Added licenses for fonts shipped with AbstractPlotting (#160).
- Switched from using system `ffmpeg` to using `FFMPEG.jl` (#160).
- Better docstrings for recording functions (#160).
- Let certain attributes passed to mutating plot functions affect the Scene (#160).
- Changed the default theme for `colorlegend` so that it scales with the resolution of the scene.

## Internal changes
- Replaced the `nothing` conversion trait with a new `NoConversion` trait, for clarity (#150).
- A lot of backend API changes to accomodate `WGLMakie` (#160).
- Enabled Gitlab CI!

# v0.9.8
## User interface changes
- Recipe docstrings are now associated with two functions instead of six (#116).
- New title recipe! (#99)
- Fixed buttons not respecting some attributes, and add a padding option (#114).
- Added `showlibrary(grad::Symbol)` function to show color libraries in `PlotUtils.jl` (#116).
- Added `showgradients` function to show an Array of gradients, indicated by Symbols (#116).
- Fixed incorrect frame duration in `record`. (#132)
- Fixed `save(path, io::VideoStream)` when file type is `.mkv` (#137).
- Improveed camera zooming (#140).

## Internal/other changes
- Changeed default alignment of buttons to (:center, :center) (#115)
- Documented a lot of recipes and functions
- Exported `HyperRectangle`, `update_limits!`, `update!`, and more...
- Updated `VideoStream`, `save` docstrings.
- Reworked tests to use `MakieGallery` (pretty big feature on the backend)
- Enabled Travis CI!

## Cleaned up theme merging & scene attribute composition, so this works:
```julia
scatter(rand(4), resolution = (200, 200))
scatter(rand(4), limits = (200, 200))
```
