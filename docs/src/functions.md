# Functions

The follow document lists the atomic plotting functions and their usage.
These are the most atomic primitive which one can stack together to form more complex plots.

For styling options of each function, see the keyword arguments list for each function -- consult the [Help functions](@ref).

For a general overview of styling and to see the default parameters, refer to the chapter [Themes](@ref).

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


## Scatter

```@docs
scatter
```

The below is automatically inserted using `@example_database("scatter", "surface")`

@example_database("scatter", "surface")

The below is automatically inserted using `@example_database("scatter")`

@example_database("scatter")
@example_database("Stars")
@example_database("Unicode Marker")


## Meshscatter

```@docs
meshscatter
```

@example_database("Meshscatter Function")


## Lines

```@docs
lines
```

@example_database("Line Function")

![](lines.png)


## Surface

```@docs
surface
```

@example_database("Surface")
@example_database("Surface with image")

## Contour

```@docs
contour
```

@example_database("contour")

The below is automatically inserted using `@example_database(contour)`

@example_database(contour)

The below is automatically inserted using `example_database(contour)`

example_database(contour)

## Wireframe

```@docs
wireframe
```

@example_database("Wireframe of a Surface")
@example_database("Wireframe of a Mesh")
@example_database("Wireframe of Sphere")

## Mesh

```@docs
mesh
```

@example_database("Load Mesh")
@example_database("Colored Mesh")
@example_database("Textured Mesh")


## Heatmap

```@docs
heatmap
```

@example_database("Heatmap")


## Volume

```@docs
volume

```

@example_database("Volume Function")


## TODOs

```
image
volume
text
poly
```
