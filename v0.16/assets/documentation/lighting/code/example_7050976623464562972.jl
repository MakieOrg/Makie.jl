# This file was generated, do not modify it. # hide
__result = begin # hide
    using WGLMakie
using JSServe

WGLMakie.activate!() # hide
xs = -10:0.1:10
ys = -10:0.1:10
zs = [10 * (cos(x) * cos(y)) * (.1 + exp(-(x^2 + y^2 + 1)/10)) for x in xs, y in ys]

fig, ax, pl = surface(xs, ys, zs, colormap = (:white, :white),

    # Light comes from (0, 0, 15), i.e the sphere
    axis = (
        # Light comes from (0, 0, 15), i.e the sphere
        lightposition = Vec3f(0, 0, 15),
        # base light of the plot only illuminates red colors
        ambient = RGBf(0.3, 0, 0),
    ),
    # light from source (sphere) illuminates yellow colors
    diffuse = Vec3f(0.4, 0.4, 0),
    # reflections illuminate blue colors
    specular = Vec3f(0, 0, 1.0),
    # Reflections are sharp
    shininess = 128f0,
    figure = (resolution=(1000, 800),)
)
mesh!(ax, Sphere(Point3f(0, 0, 15), 1f0), color=RGBf(1, 0.7, 0.3))

app = JSServe.App() do session
    light_rotation = JSServe.Slider(1:360)
    shininess = JSServe.Slider(1:128)

    pointlight = ax.scene.lights[1]
    ambient = ax.scene.lights[2]
    on(shininess) do value
        pl.shininess = value
    end
    on(light_rotation) do degree
        r = deg2rad(degree)
        pointlight.position[] = Vec3f(sin(r)*10, cos(r)*10, 15)
    end
    JSServe.record_states(session, DOM.div(light_rotation, shininess, fig))
end
app
end # hide
println("~~~") # hide
show(stdout, MIME"text/html"(), __result) # hide
println("~~~") # hide
nothing # hide