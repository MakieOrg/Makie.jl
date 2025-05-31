

# LScene

If you need a normal Makie scene in a layout, for example for 3D plots, you have
to use `LScene` right now. It's just a wrapper around the normal `Scene` that
makes it block. The underlying Scene is accessible via the `scene` field.
You can plot into the `LScene` directly, though.

You can pass keyword arguments to the underlying `Scene` object to the `scenekw` keyword.
Currently, it can be necessary to pass a couple of attributes explicitly to make sure they are not inherited from the main scene.
To see what parameters are applicable, have a look at the [scene docs](@ref Scenes)

```@figure backend=GLMakie

fig = Figure()
pl = PointLight(RGBf(20, 20, 20), Point3f(0))
al = AmbientLight(RGBf(0.2, 0.2, 0.2))
lscene = LScene(fig[1, 1], show_axis=false, scenekw = (lights = [pl, al], backgroundcolor=:black, clear=true))
# now you can plot into lscene like you're used to
p = meshscatter!(lscene, randn(300, 3), color=:gray)
fig
```

## Attributes

```@attrdocs
LScene
```
