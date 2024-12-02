# Clip Planes

A clip plane is a plane which separates space into two sections, one which is drawn and one which is not.
Makie allows you to specify up to 8 clip planes on the scene or plot level.
These clip planes are given in world space, meaning they interact with a plot object after the `transform_func` (e.g. `log` scaling) and the `model` matrix (i.e. `translate!(plot, ...)`, `rotate!(plot, ...)` and `scale!(plot, ...)`) have been applied.
They do not interact with a plot if `plot.space[] in (:pixel, :relative, :clip)`.

## Examples

```@figure backend=GLMakie
box = Rect3f(Point3f(-1), Vec3f(2))
sphere = Sphere(Point3f(0), 0.5f0)
points = [0.7f0 * Point3f(cos(x) * sin(y), cos(x) * cos(y), sin(x)) for x in 0:8 for y in 0:8]
clip_planes = [Plane3f(Point3f(0), Vec3f(-0.5, -1, 0))]

f = Figure(size = (900, 350))

# Hide some plots in a box
Label(f[1, 1], "No clipping", tellwidth = false)
a = LScene(f[2, 1])

mesh!(a, box, color = :gray)
meshscatter!(a, points)
mesh!(a, sphere, color = :orange)

# Add a clip plane to the box to reveal the other plots
Label(f[1, 2], "Plot based clipping", tellwidth = false)
a = LScene(f[2, 2])

# backlight = 1 enables two-sided shading
mesh!(a, Rect3f(Point3f(-1), Vec3f(2)), color = :gray, backlight = 1, clip_planes = clip_planes)
meshscatter!(a, points)
mesh!(a, sphere, color = :orange)

# Adding the clip plane to the scene will make every plot inherit them
Label(f[1, 3], "Scene based clipping", tellwidth = false)
a = LScene(f[2, 3])
a.scene.theme[:clip_planes] = clip_planes

mesh!(a, Rect3f(Point3f(-1), Vec3f(2)), color = :gray, backlight = 1)
meshscatter!(a, points, backlight = 1)
mesh!(a, sphere, color = :orange, backlight = 1)

f
```