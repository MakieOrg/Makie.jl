# Functions

The follow document lists the primitive plotting functions from `basic_drawing.jl`, and their usage.
These are the most atomic operations which one can stack together to form more complex plots.

For styling options of each function, see the keyword arguments list for each function -- consult the [Help functions](@ref).

For a general overview of styling and to see the default parameters, refer to the chapter [Themes](@ref).



## Scatter

```@docs
scatter
```

@library[example] "Scatter Function" "Stars" "Unicode Marker"

The below is automatically inserted using `example_database("scatter", "surface")`

example_database("scatter", "surface")

The below is automatically inserted using `example_database("scatter")`

example_database("scatter")


## Meshscatter

```@docs
meshscatter
```

@library[example] "Meshscatter Function"


## Lines

```@docs
lines
```

@library[example] "Line Function"

![](lines.png)


## Surface

```@docs
surface
```

@library[example] "Surface Function" "Surface with image"

## Contour

```@docs
contour
```

@library[example] "contour"

The below is automatically inserted using `@example_database(contour)`

@example_database(contour)

The below is automatically inserted using `example_database(contour)`

example_database(contour)

## Wireframe

```@docs
wireframe
```

@library[example] "Wireframe of a Surface" "Wireframe of a Mesh" "Wireframe of Sphere"


## Mesh

```@docs
mesh
```


@library[example] "Colored Mesh" "Load Mesh" "Textured Mesh"


## Heatmap

```@docs
heatmap
```

@library[example] "Heatmap Function"


## Volume

```@docs
volume

```

@library[example] "Volume Function"


```
image
volume
text
poly
```
