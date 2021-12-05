# RadeonProRender Backend

experimental ray tracing using AMDs [RadeonProRender](https://radeon-pro.github.io/RadeonProRenderDocs/en/index.html).
While it's created by AMD and tailored to Radeon GPUs, it still works just as well for NVidia and Intel GPUs using OpenCL.
It also works on the CPU and even has a hybrid modus to use GPUs and CPUs in tandem to render images.

## Activating and working with RPMakie

To use the backend, just call `activate!` like with all other backends. There are a few extra parameters for RPRMakie:

```julia:docs
# hideall
using RPRMakie, Markdown
println("~~~")
println(Markdown.html(@doc RPRMakie.activate!))
println("~~~")
```
\textoutput{docs}

Since RPRMakie is quite the unique backend and still experimental, there are several gotchas when working with it.

```julia
fig = Figure()
radiance = 10000
# Lights are much more important for ray tracing,
# so most examples will use extra lights and environment lights.
# Note, that RPRMakie is the only backend
# supporting multiple light sources and EnvironmentLights right now
lights = [
    EnvironmentLight(0.5, load(RPR.assetpath("studio026.exr"))),
    PointLight(Vec3f(0, 0, 20), RGBf(radiance, radiance, radiance))]

# Only LScene is supported right now,
# since the other projections don't map to the pysical acurate Camera in RPR.
ax = LScene(fig[1, 1]; scenekw=(lights=lights,))

# to create materials, one needs access to the RPR context.
# Note, if you create an RPRScreen manually, don't display the scene or fig anymore, since that would create a new RPR context, in which resources from the manually created Context would be invalid. Since RPRs error handling is pretty bad, this usually results in Segfaults.
# See below how to render a picture with a manually created context
screen = RPRScreen(ax.scene; iterations=10, plugin=RPR.Northstar)
matsys = screen.matsys
context = screen.context
# You can use lots of materials from RPR.
# Note, that this API may change in the future to a backend  independent representation
# Or at least one, that doesn't need to access the RPR context
mat = RPR.Chrome(matsys)
# The material attribute is specific to RPRMakie and gets ignored by other Backends. This may change in the future
mesh!(ax, Sphere(Point3f, 0), material=mat)

# There are three main ways to turn a Makie scene into a picture:
# Get the colorbuffer of the RPRScreen. RPRScreen also has `show` overloaded for the mime `image\png` so it should display in IJulia/Jupyter/VSCode.
image = colorbuffer(screen)::Matrix{RGB{N0f8}}
# Replace a specific (sub) LScene with RPR, and display the whole scene interactively in GLMakie
using GLMakie
refres = Observable(nothing) # Optional observable that triggers
GLMakie.activate!(); display(fig) # Make sure to display scene first in GLMakie
# Replace the scene with an interactively rendered RPR output.
# See more about this in the GLMakie interop example
context, task = RPRMakie.replace_scene_rpr!(ax.scene, screen; refresh=refresh)
# If one doesn't create the RPRScreen manually to create custom materials,
# display(ax.scene), show(io, MIME"image/png", ax.scene), save("rpr.png", ax.scene)
# Should work just like with other backends.
# Note, that only the scene from LScene can be displayed directly, but soon, `display(fig)` should also work.
```


There are several examples showing different aspects of how to use RPRMakie.
The examples are in https://github.com/JuliaPlots/Makie.jl/tree/master/RPRMakie/examples

## MaterialX and predefined materials (materials.jl)

there are several predefined materials one can use in RadeonProRender.
RPR also supports the [MaterialX](https://www.materialx.org/) standard to load a wide range of predefined Materials. Make sure to use the Northstar backend for `Matx` materials.

~~~
<img src="/assets/materials.png">
~~~

## Advanced custom material (earth_topography.jl)

~~~
<img src="/assets/topographie.png">
~~~

## GLMakie interop (opengl_interop.jl)

RPRMakie doesn't support layouting and sub scenes yet, but you can replace a single scene with a RPR renedered, interactive window.
This is especially handy, to show 2d graphics and interactive UI elements next to a ray traced scene and interactively tune camera and material parameters.

~~~
<video autoplay controls src="/assets/opengl_interop.mp4">
</video>
~~~

## Animations (lego.jl)

Not all objects support updating via Observables yet, but translations, camera etc are already covered and can be used together with Makie's standard animation API.

~~~
<video autoplay controls src="/assets/lego_walk.mp4">
</video>
~~~

## Earth example

~~~
<img src="/assets/earth.png">
~~~
