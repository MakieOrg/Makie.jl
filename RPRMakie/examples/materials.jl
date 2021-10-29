using GLMakie, GeometryBasics, RPRMakie, RadeonProRender
using Colors, FileIO
using Colors: N0f8
RPR = RadeonProRender

context = RPR.Context()
matsys = RPR.MaterialSystem(context, 0)

materials = [
    RPR.DiffuseMaterial(matsys) RPR.MicrofacetMaterial(matsys);
    RPR.ReflectionMaterial(matsys) RPR.RefractionMaterial(matsys);
    RPR.EmissiveMaterial(matsys) RPR.UberMaterial(matsys);
]

cat = load(GLMakie.assetpath("cat.obj"))

fig = Figure(resolution=(1000, 1000))
ax = LScene(fig[1, 1], scenekw=(show_axis=false,))
palette = reshape(Makie.default_palettes.color[][1:6], size(materials))
for i in CartesianIndices(materials)
    x, y = Tuple(i)
    catmesh = mesh!(ax, cat, material=materials[i], color=palette[i])
    translate!(catmesh, x, y, 0)
end
# materials[3, 1].color = Vec4(200)
display(fig)
context, task = RPRMakie.replace_scene_rpr!(ax.scene, context, matsys)
# fetch(task)


volmat = materials[end, end]

volmat.scattering = Vec3(0, 0, 0)
volmat.absorption = RGB(0.01, 0.01, 0.01)
volmat.multiscatter = true
# volmat.emission = RPR.RPR_MATERIAL_INPUT_EMISSION,
# volmat.scatter_direction = RPR.RPR_MATERIAL_INPUT_G,
