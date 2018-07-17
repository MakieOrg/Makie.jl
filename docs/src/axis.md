# Axis

The axis is just a scene object, making it easy to manipulate and share between plots.
Axis objects also contains the mapping you want to apply to the data and can interactively be changed.
An Axis object can be created from any boundingbox and inserted into any plot.

You can access the axis of a `scene` by doing

```
axis = scene[Axis]
```


## Raw mode
When the axis is accessed using `axis2d` or `axis3d`, the plotting will be in raw mode, i.e. the camera will not be activated.

@library[example] "Axis 2D"


@library[example] "Axis 3D"

### Interacting with the Axis

One can quite easily interact with the attributes of the axis like with any other plot:

@library[example] "Axis Custom"
