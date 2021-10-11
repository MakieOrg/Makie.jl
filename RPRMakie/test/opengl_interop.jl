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
mat = RPR.MaterialNode(matsys, RPR.RPR_MATERIAL_NODE_MICROFACET)

fig, ax, pl = surface(f.(u,v'),
             g.(u,v'),
             h.(u,v'),
             ambient=Vec3f0(0.5),
             diffuse=Vec3f0(1),
             specular=0.5,
             colormap=:balance,
             show_axis=false, material=mat)

lsgrid = labelslidergrid!(
    fig,
    ["roughness", "ior"],
    [0:0.01:1.0, 1:0.1:5];
    width = 350,
    tellheight = false)
fig[1, 2] = lsgrid.layout
refresh = Observable(nothing)
on(lsgrid.sliders[1].value) do value
    set!(mat, RPR.RPR_MATERIAL_INPUT_ROUGHNESS, Vec4f(value)...)
    update(refresh)
end

on(lsgrid.sliders[2].value) do value
    # set!(mat, RPR.RPR_MATERIAL_INPUT_IOR, Vec4f(value)...)
    # update(refresh)
end

display(fig)
context, task = RPRMakie.replace_scene_rpr!(ax.scene, context, matsys; refresh=refresh)
