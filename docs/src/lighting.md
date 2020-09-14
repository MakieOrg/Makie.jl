# Lighting

For 3-D scenes, GLMakie offers several attributes to control the lighting of the scene. These are set per plot.

- `ambient::Vec3f0`: Objects should never be completely dark; we use an ambient light to simulate background lighting, and give the object some color. Each element of the vector represents the intensity of color in R, G or B respectively.
- `diffuse::Vec3f0`: Simulates the directional impact which the light source has on the plot object. This is the most visually significant component of the lighting model; the more a part of an object faces the light source, the brighter it becomes. Each element of the vector represents the intensity of color in R, G or B respectively.
- `specular::Vec3f0`: Simulates the bright spot of a light that appears on shiny objects. Specular highlights are more inclined to the color of the light than the color of the object. Each element of the vector represents the intensity of color in R, G or B respectively.

- `shininess::Float32`: Controls the shininess of the object. Higher shininess reduces the size of the highlight, and makes it sharper. This value must be positive.
- `lightposition::Vec3f0`: The location of the main light source; by default, the light source is at the location of the camera.

You can find more information on how these were implemented [here](https://learnopengl.com/Lighting/Basic-Lighting).

## SSAO

GLMakie also implements [_screen-space ambient occlusion_](https://learnopengl.com/Advanced-Lighting/SSAO), which is an algorithm to more accurately simulate the scattering of light. There are a couple of controllable attributes nested within the `SSAO` toplevel attribute:

- `radius` sets the range of SSAO. You may want to scale this up or
  down depending on the limits of your coordinate system
- `bias` sets the minimum difference in depth required for a pixel to
  be occluded. Increasing this will typically make the occlusion
  effect stronger.
- `blur` sets the range of the blur applied to the occlusion texture.
  The texture contains a (random) pattern, which is washed out by
  blurring. Small `blur` will be faster, sharper and more patterned.
  Large `blur` will be slower and smoother. Typically `blur = 2` is
  a good compromise.

## Examples

```@example 1
using FileIO, MakieGallery, Makie

# Set up sliders to control lighting attributes
s1, ambient = textslider(0f0:0.01f0:1f0, "ambient", start = 0.55f0)
s2, diffuse = textslider(0f0:0.025f0:2f0, "diffuse", start = 0.4f0)
s3, specular = textslider(0f0:0.025f0:2f0, "specular", start = 0.2f0)
s4, shininess = textslider(2f0.^(2f0:8f0), "shininess", start = 32f0)

# Set up (r, θ, ϕ) for lightposition
s5, radius = textslider(2f0.^(0.5f0:0.25f0:20f0), "light pos r", start = 2f0)
s6, theta = textslider(0:5:180, "light pos theta", start = 30f0)
s7, phi = textslider(0:5:360, "light pos phi", start = 45f0)

# transform signals into required types
la = map(Vec3f0, ambient)
ld = map(Vec3f0, diffuse)
ls = map(Vec3f0, specular)
lp = map(radius, theta, phi) do r, theta, phi
    r * Vec3f0(
        cosd(phi) * sind(theta),
        sind(phi) * sind(theta),
        cosd(theta)
    )
end
# Set up sphere mesh and visualize light source
scene1 = mesh(
    Sphere(Point3f0(0), 1f0), color=:red,
    ambient = la, diffuse = ld, specular = ls, shininess = shininess,
    lightposition = lp
)
scatter!(scene1, map(v -> [v], lp), color=:yellow, markersize=0.2f0)

# Set up surface plot + light source
r = range(-10, 10, length=1000)
zs = [sin(2x+y) for x in r, y in r]
scene2 = surface(
    r, r, zs,
    ambient = la, diffuse = ld, specular = ls, shininess = shininess,
    lightposition = lp
)
scatter!(scene2, map(v -> [v], lp), color=:yellow, markersize=1f0)

# Set up textured mesh + light source
catmesh = FileIO.load(MakieGallery.assetpath("cat.obj"))
scene3 = mesh(
    catmesh, color = MakieGallery.loadasset("diffusemap.png"),
    ambient = la, diffuse = ld, specular = ls, shininess = shininess,
    lightposition = lp
)
scatter!(scene3, map(v -> [v], lp), color=:yellow, markersize=.1f0)

# Combine scene
scene = Scene(resolution=(700, 500))
vbox(hbox(s4, s3, s2, s1, s7, s6, s5), hbox(scene1, scene2), scene3, parent=scene)
```

```@example 1
# SSAO (Screen Space Ambient Occlusion) has a couple of per-scene
# attributes.
# - `radius` sets the range of SSAO. You may want to scale this up or
#   down depending on the limits of your coordinate system
# - `bias` sets the minimum difference in depth required for a pixel to
#   be occluded. Increasing this will typically make the occlusion
#   effect stronger.
# - `blur` sets the range (in pixels) of the blur applied to the
#   occlusion texture. The texture contains a (random) pattern, which is
#   washed out by blurring. Small `blur` will be faster, sharper and
#   more patterned. Large `blur` will be slower and smoother. Typically
#   `blur = 2` is a good compromise.
s1, radius = textslider(0.0f0:0.1f0:2f0, "Radius", start = 0.2f0)
s2, bias = textslider(0f0:0.005f0:0.1f0, "Bias", start = 0.015f0)
s3, blur = textslider(Int32(0):Int32(1):Int32(5), "Blur", start = Int32(2))
ssao_attrib = Attributes(radius=radius, bias=bias, blur=blur)

floor_pos = [
    Point3f0(x + 0.05rand(), y + 0.05rand(), 0.08rand())
    for x in 0.05:0.1:1.0 for y in 0.05:0.1:1.0
]
tile = Rect3D(Point3f0(-0.8, -0.8, -0.3), Vec3f0(1.6, 1.6, 0.6))

sphere_pos = 0.8rand(Point3f0, 50) .+ [Point3f0(0.1, 0.1, 0.2)]
sphere_colors = RNG.rand(RGBf0, length(sphere_pos))
sphere = Sphere(Point3f0(0), 1f0)

scene1 = Scene(SSAO=ssao_attrib)
meshscatter!(scene1, floor_pos, marker=tile, color=:lightgray, ssao=true, shading=false)
meshscatter!(scene1, sphere_pos, marker=sphere, color=sphere_colors, ssao=true)

scene2 = Scene()
meshscatter!(scene2, floor_pos, marker=tile, color=:lightgray, ssao=false, shading=false)
meshscatter!(scene2, sphere_pos, marker=sphere, color=sphere_colors, ssao=false)

scene = Scene(resolution=(900, 500))
hbox(vbox(s1, s2, s3), vbox(scene1, scene2), parent=scene)
```
