using GLMakie, GeometryBasics, RPRMakie, RadeonProRender
using Colors, FileIO
using Colors: N0f8

f = (u, v) -> cos(v) * (6 - (5 / 4 + sin(3 * u)) * sin(u - 3 * v))
g = (u, v) -> sin(v) * (6 - (5 / 4 + sin(3 * u)) * sin(u - 3 * v))
h = (u, v) -> -cos(u - 3 * v) * (5 / 4 + sin(3 * u));
u = range(0; stop = 2π, length = 150)
v = range(0; stop = 2π, length = 150)
radiance = 500
lights = [
    EnvironmentLight(1.0, load(RPR.assetpath("studio026.exr"))),
    PointLight(Vec3f(10), RGBf(radiance, radiance, radiance * 1.1)),
    AmbientLight(RGBf(0.5, 0.5, 0.5)),
]

fig = Figure(; size = (1500, 1000))
ax = LScene(fig[1, 1]; show_axis = false, scenekw = (lights = lights,))
screen = RPRMakie.Screen(size(ax.scene); plugin = RPR.Northstar, resource = RPR.RPR_CREATION_FLAGS_ENABLE_GPU0)
material = RPR.UberMaterial(screen.matsys)

surface!(
    ax, f.(u, v'), g.(u, v'), h.(u, v'); diffuse = Vec3f(1), specular = 0.5,
    colormap = :balance, material = material
)

function Input(fig, val::RGB)
    hue = Slider(fig; range = 1:380, width = 200)
    lightness = Slider(fig; range = LinRange(0, 1, 100), width = 200)
    labels = [Label(fig, "hue"; halign = :left), Label(fig, "light"; halign = :left)]
    layout = grid!(hcat(labels, [hue, lightness]))
    hsl = HSL(val)
    set_close_to!(hue, hsl.h)
    set_close_to!(lightness, hsl.l)
    color = map((h, l) -> RGB(HSL(h, 0.9, l)), hue.value, lightness.value)
    return color, layout
end

function Input(fig, val::Vec4)
    s = Slider(fig; range = LinRange(0, 1, 100), width = 200)
    set_close_to!(s, first(val))
    return map(x -> Vec4f(x), s.value), s
end

function Input(fig, val::Bool)
    toggle = Toggle(fig; active = val)
    return toggle.active, toggle
end

sliders = (
    reflection_color = Input(fig, RGB(0, 0, 0)), reflection_weight = Input(fig, Vec4(0)),
    reflection_roughness = Input(fig, Vec4(0)), reflection_anisotropy = Input(fig, Vec4(0)),
    reflection_anisotropy_rotation = Input(fig, Vec4(0)), reflection_mode = Input(fig, Vec4(0)),
    reflection_ior = Input(fig, Vec4(0)), reflection_metalness = Input(fig, Vec4(0)),
    refraction_color = Input(fig, RGB(0, 0, 0)), refraction_weight = Input(fig, Vec4(0)),
    refraction_roughness = Input(fig, Vec4(0)), refraction_ior = Input(fig, Vec4(0)),
    refraction_absorption_color = Input(fig, RGB(0, 0, 0)),
    refraction_absorption_distance = Input(fig, Vec4(0)), refraction_caustics = Input(fig, true),
    sss_scatter_color = Input(fig, RGB(0, 0, 0)), sss_scatter_distance = Input(fig, Vec4(0)),
    sss_scatter_direction = Input(fig, Vec4(0)), sss_weight = Input(fig, Vec4(0)),
    sss_multiscatter = Input(fig, false), backscatter_weight = Input(fig, Vec4(0)),
    backscatter_color = Input(fig, RGB(0, 0, 0)),
)

labels = []
inputs = []
refresh = Observable(nothing)
for (key, (obs, input)) in pairs(sliders)
    push!(labels, Label(fig, string(key); justification = :left))
    push!(inputs, input)
    on(obs) do value
        @show key value
        setproperty!(material, key, value)
        return notify(refresh)
    end
end

fig[1, 2] = grid!(hcat(labels, inputs); width = 500)
GLMakie.activate!()

cam = cameracontrols(ax.scene)
cam.eyeposition[] = Vec3f(22, 0, 17)
cam.lookat[] = Vec3f(0, 0, -1)
cam.upvector[] = Vec3f(0, 0, 1)
cam.fov[] = 30

GLMakie.activate!(inline = false)
display(fig; inline = false, backend = GLMakie)
RPRMakie.activate!(iterations = 1, plugin = RPR.Northstar, resource = RPR.GPU0)
context, task = RPRMakie.replace_scene_rpr!(ax.scene, screen; refresh = refresh);
nothing

# Change light parameters interactively
# begin
#     lights[1].intensity[] = 1.5
#     lights[2].radiance[] = RGBf(1000, 1000, 1000)
#     lights[2].position[] = Vec3f(3, 10, 10)
#     notify(refresh)
# end
