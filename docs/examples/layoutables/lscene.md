

# LScene

If you need a normal Makie scene in a layout, for example for 3D plots, you have
to use `LScene` right now. It's just a wrapper around the normal `Scene` that
makes it layoutable. The underlying Scene is accessible via the `scene` field.
You can plot into the `LScene` directly, though.

You can pass keyword arguments to the underlying `Scene` object to the `scenekw` keyword.
Currently, it can be necessary to pass a couple of attributes explicitly to make sure they
are not inherited from the main scene (which has a pixel camera and no axis, e.g.).

\begin{examplefigure}{}
```
using GLMakie
GLMakie.activate!()

fig = Figure()

lscene = LScene(fig[1, 1], scenekw = (camera = cam3d!, raw = false))

# now you can plot into lscene like you're used to
meshscatter!(lscene, randn(100, 3))
fig
```
\end{examplefigure}