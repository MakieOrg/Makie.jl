using GLMakie, GeometryBasics, RPRMakie, RadeonProRender
using Colors
using Colors: N0f8
RPR = RadeonProRender

f = (u, v) -> cos(v)*(6 - (5/4 +sin(3*u))*sin(u-3*v))
g = (u, v) -> sin(v)*(6 - (5/4 +sin(3*u))*sin(u-3*v))
h = (u, v) -> -cos(u-3*v) * (5/4 +sin(3*u));
u = range(0, stop=2π, length=150)
v = range(0, stop=2π, length=150)

RPR.release(context)
context = RPR.Context(resource=RPR.RPR_CREATION_FLAGS_ENABLE_GPU0)
matsys = RPR.MaterialSystem(context, 0)
material = RPR.UberMaterial(matsys)

for (k, v) in pairs(RPR.defaults(RPR.UberMaterial))
    setproperty!(material, k, v)
end

fig, ax, pl = surface(f.(u,v'),
             g.(u,v'),
             h.(u,v'),
             ambient=Vec3f0(0.5),
             diffuse=Vec3f0(1),
             specular=0.5,
             colormap=:balance, figure=(resolution=(1500, 1000),),
             show_axis=false, material=material)

function Input(fig, val::RGB)
    hue = Slider(fig, range = 1:380, width=200)
    lightness = Slider(fig, range = LinRange(0, 1, 100), width=200)
    labels = [Label(fig, "hue"; halign = :left), Label(fig, "light"; halign = :left)]
    layout = grid!(hcat(labels, [hue, lightness]))
    hsl = HSL(val)
    set_close_to!(hue, hsl.h)
    set_close_to!(lightness, hsl.l)
    color = map((h, l)-> RGB(HSL(h, 0.9, l)), hue.value, lightness.value)
    return color, layout
end

function Input(fig, val::Vec4)
    s = Slider(fig, range = LinRange(0, 1, 100), width=200)
    set_close_to!(s, first(val))
    return map(x-> Vec4f(x), s.value), s
end

function Input(fig, val::Bool)
    toggle = Toggle(fig, active = val)
    return toggle.active, toggle
end


sliders = (
    reflection_color = Input(fig, RGB(0, 0, 0)),
    reflection_weight = Input(fig, Vec4(0)),
    reflection_roughness = Input(fig, Vec4(0)),
    reflection_anisotropy = Input(fig, Vec4(0)),
    reflection_anisotropy_rotation = Input(fig, Vec4(0)),
    reflection_mode = Input(fig, Vec4(0)),
    reflection_ior = Input(fig, Vec4(0)),
    reflection_metalness = Input(fig, Vec4(0)),

    refraction_color = Input(fig, RGB(0, 0, 0)),
    refraction_weight = Input(fig, Vec4(0)),
    refraction_roughness = Input(fig, Vec4(0)),
    refraction_ior = Input(fig, Vec4(0)),
    refraction_absorption_color = Input(fig, RGB(0, 0, 0)),
    refraction_absorption_distance = Input(fig, Vec4(0)),
    refraction_caustics = Input(fig, Vec4(0)),

    sss_scatter_color = Input(fig, RGB(0, 0, 0)),
    sss_scatter_distance = Input(fig, Vec4(0)),
    sss_scatter_direction = Input(fig, Vec4(0)),
    sss_weight = Input(fig, Vec4(0)),
    sss_multiscatter = Input(fig, false),
    backscatter_weight = Input(fig, Vec4(0)),
    backscatter_color = Input(fig, RGB(0, 0, 0)),
)

labels = []
inputs = []
refresh = Observable(nothing)
for (key, (obs, input)) in pairs(sliders)
    push!(labels, Label(fig, string(key); align=:left))
    push!(inputs, input)
    on(obs) do value
        setproperty!(material, key, value)
        notify(refresh)
    end
end

fig[1, 2] = grid!(hcat(labels, inputs), width=500)

display(fig)
context, task = RPRMakie.replace_scene_rpr!(ax.scene, context, matsys; refresh=refresh)
