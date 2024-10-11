# Transformations

Every plot and every scene contains a `Transformation` object which holds the `transform_func` and generates the `model` matrix.

## Model Transformations

The `model` matrix is composed of a translation, scaling and rotation, with the rotation acting first and the translation acting last.
The translation is set by `translate!()`, the scaling by `scale!()` and the rotation by `rotate!()`.
Furthermore you can change the origin used for scaling and rotating with `translate_origin!()`.

```@figure backend=GLMakie
using GLMakie

box = Rect2f(0.9, -0.1, 0.2, 0.2)

f = Figure(size = (500, 450))
a = Axis(f[1, 1], aspect = DataAspect())
xlims!(a, 0.2, 1.2); a.xticks[] = 0.1:0.2:1.1
ylims!(a, -0.2, 0.8); a.yticks[] = -0.1:0.2:0.7

# Initial plot for reference
scatterlines!(a, box, color = 1:4, markersize = 20, linewidth = 5)

# Transformed plot
p2 = scatterlines!(a, box, color = 1:4, markersize = 20, linewidth = 5)
translate_origin!(p2, 1,0,0) # apply rotation & scaling relative to the center of the box
scale!(p2, 2, 2)             # double x, y
Makie.rotate!(p2, pi/2)      # 90° rotation
translate!(p2, -0.5, 0.5)    # translate 0.5 left, 0.5 up

f
```

By default, calling these functions will overwrite the value set by a previous invocation.
So if you call `translate!(plot, 1,0,0); translate!(plot, 0,1,0)` the translation will be `(0,1,0)`.
To accumulate transformation you need to add `Accum` as the first argument, e.g. `translate!(Accum, plot, 0,1,0)`.

## Transformation Function

The `transform_func` is a function that gets applied to the input data of a plot after `convert_arguments()` (type normalization) and dim_converts (handling of units and categorical value).
It is typically managed by an Axis.
For example, if you set `ax.xscale[] = log`, the underlying `ax.scene` will have it's transformation function set to `(log, indentity)` which will propagate to the plots inside the axis/scene.

```julia
using Makie
f, a, p = scatter(1:10);
Makie.transform_func(a.scene) # (identity, identity)
Makie.transform_func(p) # (identity, identity)
a.xscale[] = log
Makie.transform_func(a.scene) # (log, identity)
Makie.transform_func(p) # (log, identity)
```

You can set the transformation function of a plot by updating `plot.transformation.transform_func[] = new_func`.
This will also change the transformation function of each child plot.
Note that this will be reset when the plots parent transformation function changes, e.g. if `ax.xscale` is set in the example above.
Another option is to create the plot with an explicitly given `Transformation` object, which can detach the plots transformation from its parent.

## Scene Transformation

The Scene also holds onto a `Transformation` object.
It's `transform_func` acts as a default for any plot added to the scene.
Its `model` transformation acts as a secondary transformation to any plot, i.e. it is applied aftr the plots own model transformation `scene.transformation.model[] * plot.transformation.model[]`.
The scene itself, i.e. its viewport, is not affected by the `Transformation` object.

## Constructors

As eluded to in the transformation function section there are some cases where constructing a `Transformation` yourself can be useful.
For example, you may want to apply `transform_func` before running a triangulation algorithm in a recipe so that the triangulation doesn't get distorted.
Or you may want to chain transformations of a series of plots to keep them relative to each other (see below).
There are a few constructors which are helpful to know for this.

If you want to fully detach a plot from its parents transformations, you can create it with `transformation = Transformation()`.
If you want to remove only the `transform_func` but not model transformations, you can use `transformation = Transformation(parent, transform_func = identity)`.
You can also pass different starting values for `translation`, `scale` and `rotation` to these functions.
This will not affect whether the parents model transformations are considered.
