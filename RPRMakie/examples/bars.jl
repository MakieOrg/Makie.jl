using GLMakie, GeometryBasics
using GLMakie, GeometryBasics, RPRMakie, RadeonProRender
using Colors, FileIO
using Colors: N0f8
RPR = RadeonProRender

begin
    context = RPR.Context()
    matsys = RPR.MaterialSystem(context, 0)
    rectMesh = FRect3D(Vec3f0(-0.5, -0.5, 0), Vec3f0(1))
    recmesh = GeometryBasics.normal_mesh(rectMesh)
    pos = [Point3f(i, j, 0) ./ 10 for i in 1:10 for j in 1:10]
    z = rand(10,10)
    fig = Figure(resolution=(1200, 800), fontsize=26)
    ax = LScene(fig[1, 1])
    mat  = RPR.Plastic(matsys)
    meshscatter!(
        ax, pos, marker = recmesh, markersize = Vec3f.(0.1, 0.1, z[:]), material=mat, color=1:length(pos))
    ax.scene[OldAxis][1] = Rect3f(Vec3f(0), Vec3f(1, 1, 1.2))
    display(fig)
    context, task, rpr_scene = RPRMakie.replace_scene_rpr!(ax.scene, context, matsys)
end
