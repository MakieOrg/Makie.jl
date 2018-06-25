
## General function signatures and usage

### Create a new plot inside a new scene object
`func(args...; kw_args...)`

where `func` are the atomics function, e.g. `lines`, `scatter`, `surface`, etc.
For a list of the available atomics functions, see [Atomic functions overview](@ref).


### Create a new plot as a subscene of the specified `scene` object
`func(scene::SceneLike, args...; kw_args...)`


### Add a plot in-place to the `current_scene()`
`func!(args...; kw_args...)`


### Add a plot in-place to the specified `scene` as a subscene
`func!(scene::SceneLike, args...; kw_args...)`

## Detailed function signatures
The input arguments are handled by the `convert_arguments` function, which handles
a large variety of inputs.
The signatures accepted by `convert_arguments` are also those accepted by the
plotting functions.

Accepted signatures are as follows:
