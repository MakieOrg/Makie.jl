# Plot function signatures


## General function signatures and usage

`func(args...; kw_args...)`

where `func` are the function names, e.g. `lines`, `scatter`, `surface`, etc.


### Create a new plot + scene object

`func(scene::SceneLike, args...; kw_args...)`


### Create a new plot as a subscene of a scene object

`func!(args...; kw_args...)`


### Add a plot in-place to the `current_scene()`

`func!(scene::SceneLike, args...; kw_args...)`


### Add a plot in-place to the `current_scene()` as a subscene

`func[!]([scene], kw_args::Attributes, args...)`

`[]` means an optional argument. `Attributes` is a Dictionary of attributes.

See [Plot attributes](@ref) for the available plot attributes.
