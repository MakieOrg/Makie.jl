# wireframe

{{doc wireframe}}

### Examples

\begin{examplefigure}{}
```julia
using GLMakie
GLMakie.activate!() # hide
Makie.inline!(true) # hide

x, y = collect(-8:0.5:8), collect(-8:0.5:8)
z = [sinc(√(X^2 + Y^2) / π) for X ∈ x, Y ∈ y]

wireframe(x, y, z, axis=(type=Axis3,), color=:black)
```
\end{examplefigure}
