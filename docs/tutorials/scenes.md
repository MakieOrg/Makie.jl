# Scene tutorial

\begin{examplefigure}{name = "name_a"}
```julia
using GLMakie, Makie
GLMakie.activate!()
scene = Scene(;
    # clear everything behind scene
    clear = true,
    # the camera struct of the scene.
    visible = true,
    ssao = Makie.SSAO(),
    # Creates lights from theme, which right now defaults to `
    # set_theme!(lightposition=:eyeposition, ambient=RGBf(0.5, 0.5, 0.5))`
    lights = Makie.automatic,
    backgroundcolor = :gray,
    resolution = (500, 500)
)
```
\end{examplefigure}

By default, the scenes goes from -1 to 1.
So to draw a rectangle outlining the screen, the following rectangle does the job:

\begin{examplefigure}{name = "name_b"}
 ```julia
lines!(scene, Rect2f(-1, -1, 2, 2), linewidth=5, color=:black)
scene
```
\end{examplefigure}

this is, because the projection matrix and view matrix are the identity matrix by default, and Makie's default unit space is what's called `Clip space` in the OpenGL world

```julia:ex-scene
cam = Makie.camera(scene) # this is how to access the scenes camera
```

One can change the mapping, to e.g. draw from -3 to 5:

\begin{examplefigure}{name = "name_c"}
 ```julia
cam.projection[] = Makie.orthographicprojection(-3f0, 5f0, -3f0, 5f0, -100f0, 100f0)
scene
```
\end{examplefigure}

one can also change the camera to a perspective 3d projection:

\begin{examplefigure}{name = "name_d"}
 ```julia
w, h = size(scene)
cam.projection[] = Makie.perspectiveprojection(45f0, Float32(w / h), 0.1f0, 100f0)
# Now, we also need to change the view matrix
# to "put" the camera into some place.
cam.view[] = Makie.lookat(Vec3f(10), Vec3f(0), Vec3f(0, 0, 1))
scene
```
\end{examplefigure}

## Scenes and subwindows

Create a scene with a subwindow

\begin{examplefigure}{name = "subwindow-1"}
```julia
scene = Scene(backgroundcolor=:gray)
subwindow = Scene(scene, px_area=Rect(100, 100, 200, 200), clear=true, backgroundcolor=:white)
scene
```
\end{examplefigure}

One needs to manually set the camera
and center the camera to the content of the scene

\begin{examplefigure}{name = "subwindow-2"}
```julia
cam3d!(subwindow)
meshscatter!(subwindow, rand(Point3f, 10), color=:gray)
center!(subwindow)
scene
```
\end{examplefigure}


Instead of a white background, we can also stop clearing the background
to make the scene see-through, and give it an outline instead.
The easiest way to create an outline is, to make a sub scene with a projection that goes from 0..1 for the whole window.

\begin{examplefigure}{name = "subwindow-3"}
```julia
subwindow.clear = false
relative_space = Makie.camrelative(subwindow)
# this draws a line at the scene window boundary
lines!(relative_space, Rect(0, 0, 1, 1))
scene
```
\end{examplefigure}

Every scene also holds a reference to all global window events, which can be used to e.g. move the subwindow. If you execute the below in GLMakie, you can move the window around by pressing left mouse & ctrl:

```julia
on(scene.events.mouseposition) do mousepos
    if ispressed(subwindow, Mouse.left & Keyboard.left_control)
        subwindow.px_area[] = Rect(Int.(mousepos)..., 200, 200)
    end
end
```

One can also use camrelative and campixel together with the normal Axis,
to e.g. plot in the middle of the axis:

\begin{examplefigure}{name = "subwindow-4"}
```julia
figure, axis, plot_object = scatter(1:4)
relative_projection = Makie.camrelative(axis.scene);
scatter!(relative_projection, [Point2f(0.5)], color=:red)
# offset & text are in pixelspace
text!(relative_projection, "Hi", position=Point2f(0.5), offset=Vec2f(5))
lines!(relative_projection, Rect(0, 0, 1, 1), color=:blue, linewidth=3)
figure
```
\end{examplefigure}

## Scenes and Transformations

These are all camera transformations of the object.
In contrast, there are also scene transformations, or commonly referred to as world transformations.
To learn more about the different spaces, [learn opengl](https://learnopengl.com/Getting-started/Coordinate-Systems) offers some pretty nice explanations

The "world" transformations are implemented via the `Transformation` struct in Makie. Scenes and plots both contain these, so these types are considered as "Makie.Transformable".
The transformation of a scene will get inherited by all plots added to the scene.
An easy way to manipulate any `Transformable` is via these 3 functions:


\begin{examplefigure}{name = "name_e"}
 ```julia
sphere_plot = mesh!(scene, Sphere(Point3f(0), 0.5), color=:red)
scale!(scene, 2, 2, 2)
rotate!(scene, Vec3f(1, 0, 0), 0.5) # 0.5 rad around the y axis
scene
```
\end{examplefigure}

One can also transform the plot objects directly, which then adds the transformation from the plot object on top of the transformation from the scene.
One can add subscenes and interact with those dynamically.
Makie offers here what's usually referred to as a scene graph.

\begin{examplefigure}{name = "name_x"}
 ```julia
translate!(sphere_plot, Vec3f(0, 0, 1))
scene
```
\end{examplefigure}

The scene graph can be used to create rigid transformations, like for a robot arm:

\begin{examplefigure}{name = "name_6"}
 ```julia
parent = Scene()
cam3d!(parent)
camc = cameracontrols(parent)
update_cam!(parent, camc, Vec3f(0, 8, 0), Vec3f(4.0, 0, 0))
s1 = Scene(parent, camera=parent.camera)
mesh!(s1, Rect3f(Vec3f(0, -0.1, -0.1), Vec3f(5, 0.2, 0.2)))
s2 = Scene(s1, camera=parent.camera)
mesh!(s2, Rect3f(Vec3f(0, -0.1, -0.1), Vec3f(5, 0.2, 0.2)), color=:red)
translate!(s2, 5, 0, 0)
s3 = Scene(s2, camera=parent.camera)
mesh!(s3, Rect3f(Vec3f(-0.2), Vec3f(0.4)), color=:blue)
translate!(s3, 5, 0, 0)
parent
```
\end{examplefigure}


\begin{examplefigure}{name = "name_7"}
```julia
# Now, rotate the "joints"
rotate!(s2, Vec3f(0, 1, 0), 0.5)
rotate!(s3, Vec3f(1, 0, 0), 0.5)
parent
```
\end{examplefigure}

With this basic principle, we can even bring robots to life :)
[Kevin Moerman](https://github.com/Kevin-Mattheus-Moerman) was so nice to supply a Lego mesh, which we're going to animate!
When the scene graph is really just about a transformation Graph, one can use the Transformation struct directly, which is what we're going to do here.
This is more efficient and easier than creating a scene for each model.

```julia:ex-scene
using MeshIO, FileIO, GeometryBasics

colors = Dict(
    "eyes" => "#000",
    "belt" => "#000059",
    "arm" => "#009925",
    "leg" => "#3369E8",
    "torso" => "#D50F25",
    "head" => "yellow",
    "hand" => "yellow"
)

origins = Dict(
    "arm_right" => Point3f(0.1427, -6.2127, 5.7342),
    "arm_left" => Point3f(0.1427, 6.2127, 5.7342),
    "leg_right" => Point3f(0, -1, -8.2),
    "leg_left" => Point3f(0, 1, -8.2),
)

rotation_axes = Dict(
    "arm_right" => Vec3f(0.0000, -0.9828, 0.1848),
    "arm_left" => Vec3f(0.0000, 0.9828, 0.1848),
    "leg_right" => Vec3f(0, -1, 0),
    "leg_left" => Vec3f(0, 1, 0),
)

function plot_part!(scene, parent, name::String)
    m = load(assetpath("lego_figure_" * name * ".stl"))
    color = colors[split(name, "_")[1]]
    trans = Transformation(parent)
    ptrans = Makie.transformation(parent)
    origin = get(origins, name, nothing)
    if !isnothing(origin)
        centered = m.position .- origin
        m = GeometryBasics.Mesh(meta(centered; normals=m.normals), faces(m))
        translate!(trans, origin)
    else
        translate!(trans, -ptrans.translation[])
    end
    return mesh!(scene, m; color=color, transformation=trans)
end
function plot_lego_figure(s, floor=true)
    # Plot hierarchical mesh!
    figure = Dict()
    # Plot hierarchical mesh!
    figure["torso"] = plot_part!(s, s, "torso")
        figure["head"] = plot_part!(s, figure["torso"], "head")
            figure["eyes_mouth"] = plot_part!(s, figure["head"], "eyes_mouth")
        figure["arm_right"] = plot_part!(s, figure["torso"], "arm_right")
            figure["hand_right"] = plot_part!(s, figure["arm_right"], "hand_right")
        figure["arm_left"] = plot_part!(s, figure["torso"], "arm_left")
            figure["hand_left"] = plot_part!(s, figure["arm_left"], "hand_left")
        figure["belt"] = plot_part!(s, figure["torso"], "belt")
            figure["leg_right"] = plot_part!(s, figure["belt"], "leg_right")
            figure["leg_left"] = plot_part!(s, figure["belt"], "leg_left")
    # lift the little guy up
    translate!(figure["torso"], 0, 0, 20)
    # add some floor
    floor && mesh!(s, Rect3f(Vec3f(-400, -400, -2), Vec3f(800, 800, 2)), color=:white)
    return figure
end
```

\begin{showhtml}{}
 ```julia:ex-scene
using WGLMakie, JSServe
wgl = WGLMakie.activate!()
Page(offline=true, exportable=true)
```
\end{showhtml}

\begin{showhtml}{}
```julia:ex-scene
App() do session
    wgl
    s = Scene(resolution=(500, 500))
    cam3d!(s)
    figure = plot_lego_figure(s, false)
    bodies = [
        "arm_left", "arm_right",
        "leg_left", "leg_right"]
    sliders = map(bodies) do name
        slider = if occursin("arm", name)
            JSServe.Slider(-60:4:60)
        else
            JSServe.Slider(-30:4:30)
        end
        rotvec = rotation_axes[name]
        bodymesh = figure[name]
        on(slider) do val
            rotate!(bodymesh, rotvec, deg2rad(val))
        end
        DOM.div(name, slider)
    end
    center!(s)
    JSServe.record_states(session, DOM.div(sliders..., s))
end
```
\end{showhtml}

\begin{examplefigure}{}
```julia
GLMakie.activate!()
radiance = 50000
lights = [
    EnvironmentLight(1.5, rotl90(load(assetpath("sunflowers_1k.hdr"))')),
    PointLight(Vec3f(50, 0, 200), RGBf(radiance, radiance, radiance*1.1)),
]
s = Scene(resolution=(500, 500), lights=lights)
cam3d!(s)
c = cameracontrols(s)
c.near[] = 5
c.far[] = 1000
update_cam!(s, c, Vec3f(100, 30, 80), Vec3f(0, 0, -10))
figure = plot_lego_figure(s)

rot_joints_by = 0.25*pi
total_translation = 50
animation_strides = 10

a1 = LinRange(0, rot_joints_by, animation_strides)
angles = [a1; reverse(a1[1:end-1]); -a1[2:end]; reverse(-a1[1:end-1]);]
nsteps = length(angles); #Number of animation steps
translations = LinRange(0, total_translation, nsteps)
s
```
\end{examplefigure}

We can render an animation with RPRMakie.
RPRMakie is still experimental and rendering out the video is quite slow, so the shown video is prerendered!

```julia
using RPRMakie
# iterate rendering 200 times, to get less noise and more light
RPRMakie.activate!(iterations=200)
Makie.record(s, "lego_walk.mp4", zip(translations, angles)) do (translation, angle)
    #Rotate right arm+hand
    for name in ["arm_left", "arm_right",
                            "leg_left", "leg_right"]
        rotate!(figure[name], rotation_axes[name], angle)
    end
    translate!(figure["torso"], translation, 0, 20)
end
```
~~~
<video autoplay controls>
    <source src="/assets/lego_walk.mp4" type="video/mp4">
</video>
~~~
