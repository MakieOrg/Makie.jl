# mesh

```@docs
mesh
```

```@example
using GLMakie
GLMakie.activate!() # hide
AbstractPlotting.inline!(true) # hide

vertices = [
    0.0 0.0;
    1.0 0.0;
    1.0 1.0;
    0.0 1.0;
]

faces = [
    1 2 3;
    3 4 1;
]

colors = [:red, :green, :blue, :orange]

scene = mesh(vertices, faces, color = colors, shading = false)
```

```@example
using FileIO
using GLMakie
GLMakie.activate!() # hide
AbstractPlotting.inline!(true) # hide

brain = load("../assets/brain.stl")

mesh(
    brain,
    color = [tri[1][2] for tri in brain for i in 1:3],
    colormap = Reverse(:Spectral),
    shininess = 0,
)
```
