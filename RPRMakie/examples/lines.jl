using GLMakie, GeometryBasics, RPRMakie, RadeonProRender
using Colors, FileIO
using Colors: N0f8
RPR = RadeonProRender

begin
    context = RPR.Context()
    matsys = RPR.MaterialSystem(context, 0)
    fig = Figure()
    ax = LScene(fig[1, 1])
    diffuse = RPR.DiffuseMaterial(matsys)
    fig = Figure(resolution=(1000, 1000))
    ax = LScene(fig[1, 1])
    points = Point3f[]

    for i in 4:10
        n = i + 1
        y = LinRange(0, i, n)
        y2 = (y ./ 2) .- 2
        xyz = Point3f.((i-5) ./ 2, y2, sin.(y) .+ 1)
        lines!(ax, xyz, linewidth=5)
        append!(points, xyz)
    end
    meshscatter!(ax, points, material=RPR.Plastic(matsys))
    display(fig)
    refresh = Observable(nothing)
    context, task, rpr_scene = RPRMakie.replace_scene_rpr!(ax.scene, context, matsys; refresh);
end;
