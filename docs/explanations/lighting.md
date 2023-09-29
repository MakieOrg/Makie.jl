# Lighting

The Lighting capabilities of Makie differ between backends and plot types.
It is implemented for mesh related plot types (`mesh`, `meshscatter`, `surface`), their derivatives (e.g. 3D `arrows`) and to some degree `volume` plots (and `contour3d`).
With respect to Backends:

- GLMakie implements the baseline lighting model and will act as our default for this page.
- WGLMakie implements a simplified version of GLMakie's lighting.
- CairoMakie implements limited lighting due to its limited 3D capabilities
- RPRMakie implements parts of Makies lighting model but can also use more sophisticated methods from RadeonProRender.

## Material Attributes

In 3D rendering a material describes how an object reacts to light.
This can include the color of an object, how bright and sharp specular reflections are, how metallic it looks, how rough it is and more.
In Makie however the model is still fairly simple and limited.
Currently the following material attributes are available:
- `diffuse::Vec3f = Vec3f(0.4)`: controls how strong the diffuse reflections of an object are in the red, green and blue color channel. A diffuse reflection is one where incoming light is scattered in every direction. The strength of this reflection is based on the amount of light hitting the surface, which is proportional to `dot(-light_direction, normal)`. It generally makes up the main color of an object in light.
- `specular::Vec3f = Vec3f(0,2)`: controls the strength of specular reflection in the red, green and blue color channels. A specular reflection is a direct reflection of light, i.e. one where the incoming angle `dot(-light_direction, normal)` matches the outgoing angle `dot(-camera_direction, normal)`. It responsible for bright spots on objects. Note that this does not take the color of the object into account, as specular reflections typically match the light color.
- `shininess::Float32 = 32f0`: controls how sharp specular reflections are. Low shininess will allow a larger difference between incoming outgoing angle to take effect, creating a larger and smoother bright spot. High shininess will respectively reduce the size of the bright spot and increase its sharpness. This value must be positive.

!!! note
    RPRMakie does not use these material attributes.
    Instead it relies on RadeonProRender's material system, which is passed through the `material` attribute.
    See the [RPRMakie page](https://docs.makie.org/stable/documentation/backends/rprmakie/) for examples.


## Lights

Lights are controlled through the `lights` vector in a `scene`. We currently implement the following lights:

{{doc AmbientLight}}

{{doc PointLight}}

{{doc DirectionalLight}}

{{doc SpotLight}}

{{doc EnvironmentLight}}

Note that the availability between the different light types depends on the backend and on the `shading` attribute.
The latter controls the lighting model that is being used per plot.
It's default value depends on the number and types of lights used.
Currently the following options exist:
- `shading = NoShading` disables light calculations, resulting in the plain color of an object being shown.
- `shading = FastShading` enables a simplified lighting model which only allows for one `AmbientLight` and one `PointLight`.
- `shading = MultiLightShading` is a GLMakie exclusive option which enables up to 64 light sources as well as `DirectionalLight` and `SpotLight`.

Beyond that there is also the `backlight = 0f0` attribute, which mixes a second weighted light calculation using inverted normals with the primary one.

By default

!!! note
    The `shading` attribute cannot be adjusted dynamically, as it affects which shader is used for a given plot.

For reference all the lighting calculations (except ambient) in GLMakie, WGLMakie and to some extend CairoMakie end up using the [Blinn-Phong reflection model](https://en.wikipedia.org/wiki/Blinn%E2%80%93Phong_reflection_model) which essentially boilds down to

```julia
function blinn_phong(
        diffuse, specular, shininess, normal, object_color,
        light_color, light_direction, camera_direction
    )
    diffuse_coefficient = max(dot(light_direction, -normal), 0.0)
    H = normalize(light_direction + camera_direction)
    specular_coefficient = max(dot(H, -normal), 0.0)^shininess
    return light_color * (
        diffuse * diffuse_coefficient * object_color +
        specular * specular_coefficient
    )
end
```

The different light sources control the `light_direction` and may further adjust the result of this function. For example, `SpotLight` adds a factor which reduces light intensity outside its area.

## SSAO

GLMakie also implements [_screen-space ambient occlusion_](https://learnopengl.com/Advanced-Lighting/SSAO), which is an algorithm to more accurately simulate the scattering of light. There are a couple of controllable scene attributes nested within the `SSAO` toplevel attribute:

- `radius` sets the range of SSAO. You may want to scale this up or
  down depending on the limits of your coordinate system
- `bias` sets the minimum difference in depth required for a pixel to
  be occluded. Increasing this will typically make the occlusion
  effect stronger.
- `blur` sets the (pixel) range of the blur applied to the occlusion texture.
  The texture contains a (random) pattern, which is washed out by
  blurring. Small `blur` will be faster, sharper and more patterned.
  Large `blur` will be slower and smoother. Typically `blur = 2` is
  a good compromise.

!!! note
    The SSAO postprocessor is turned off by default to save on resources. To turn it on, set `GLMakie.activate!(ssao=true)`, close any existing GLMakie window and reopen it.

## Matcap

A matcap (material capture) is a texture which is applied based on the normals of a given mesh. They typically include complex materials and lighting and offer a cheap way to apply those to any mesh. You may pass a matcap via the `matcap` attribute of a `mesh`, `meshscatter` or `surface` plot. Setting `shading = NoShading` is suggested. You can find a lot matcaps [here](https://github.com/nidorx/matcaps).

## Availability

Here we want to give a brief overview about what is supported in which backend.
This assumes shading is enabled, i.e. that `shading != NoShading`.
If `shading` is specified the option requires the respective value.

| Feature | GLMakie | WGLMakie | CairoMakie | RPRMakie |
| ------- | ------- | -------- | ---------- | -------- |
| material attributes | Yes | Yes | Limited | via RPR Materials |
| Multiple Lights | `shading = MultiLightShading` | No | No | Yes |
| AmbientLight, PointLight | Yes | Yes | Limited | Yes |
| SpotLight, DirectionalLight | `shading = MultiLightShading` | No | No | Yes |
| PointLight with attentuation | `shading = MultiLightShading` | No | No | No |
| EnvironmentLight | No | No | No | Yes |
| backlight attribute | Yes | Yes | Limited | No |
| SSAO | Yes | No | No | inbuilt |
| Matcap | Yes | Yes | Limited | via RPR Materials |

## Examples

#### SSAO

\begin{examplefigure}{}
```julia
using GLMakie
GLMakie.activate!(ssao=true)
GLMakie.closeall() # close any open screen

fig = Figure()
ssao = Makie.SSAO(radius = 5.0, blur = 3)
ax = LScene(fig[1, 1], scenekw = (ssao=ssao,))
# SSAO attributes are per scene
ax.scene.ssao.bias[] = 0.025

box = Rect3(Point3f(-0.5), Vec3f(1))
positions = [Point3f(x, y, rand()) for x in -5:5 for y in -5:5]
meshscatter!(ax, positions, marker=box, markersize=1, color=:lightblue, ssao=true)
fig
```
\end{examplefigure}

```julia:disable-ssao
GLMakie.activate!(ssao=false) # hide
GLMakie.closeall() # hide
```

#### Matcap

\begin{examplefigure}{}
```julia
using FileIO
using GLMakie
GLMakie.activate!() # hide
catmesh = FileIO.load(assetpath("cat.obj"))
gold = FileIO.load(download("https://raw.githubusercontent.com/nidorx/matcaps/master/1024/E6BF3C_5A4719_977726_FCFC82.png"))

mesh(catmesh, matcap=gold, shading = NoShading)
```
\end{examplefigure}
