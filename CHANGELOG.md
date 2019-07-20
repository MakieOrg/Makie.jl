# `master`


# v0.9.8
## User interface changes
- Recipe docstrings are now associated with two functions instead of six (#116).
- New title recipe! (#99)
- Fix buttons not respecting some attributes, and add a padding option (#114).
- Add `showlibrary(grad::Symbol)` function to show color libraries in `PlotUtils.jl` (#116).
- Add `showgradients` function to show an Array of gradients, indicated by Symbols (#116).
- Fix incorrect frame duration in `record`. (#132)
- Fix `save(path, io::VideoStream)` when file type is `.mkv` (#137).
- Improve camera zooming (#140).

## Internal/other changes
- Change default alignment of buttons to (:center, :center) (#115)
- Document a lot of recipes and functions
- Export `HyperRectangle`, `update_limits!`, `update!`, and more...
- Update `VideoStream`, `save` docstrings.
- Rework tests to use `MakieGallery` (pretty big feature on the backend)
- Enable Travis CI!
