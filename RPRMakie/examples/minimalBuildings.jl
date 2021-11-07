using JLD
using GLMakie, GeometryBasics, ColorSchemes
using RadeonProRender, RPRMakie
RPR = RadeonProRender

function poly_3d(points3d)
    xy = Point2f.(points3d)
    f = faces(GeometryBasics.Polygon(xy))
    return normal_mesh(Point3f.(points3d), f)
end

function getBuilding(basePoints, h)
    n = length(basePoints)
    bottom_poly = [Point3f(basePoints[i][1] + 122.72998, basePoints[i][2] - 45.500004, 0) .* Point3f(100, 100, 1) for i in 1:n]
    top_poly = [Point3f(basePoints[i][1] + 122.72998, basePoints[i][2] - 45.500004, h) .* Point3f(100, 100, 1) for i in 1:n]
    top = poly_3d(top_poly)
    bottom = poly_3d(bottom_poly)
    combined = merge([top, bottom])
    nvertices = length(top.position)
    connection = Makie.band_connect(nvertices)
    m = GeometryBasics.Mesh(GeometryBasics.coordinates(combined), vcat(faces(combined), connection))
    recmesh = GeometryBasics.normal_mesh(m)
    uvs = [Point2f(p[3], 0) for p in GeometryBasics.coordinates(recmesh)] # normalize this so zmax = 1
    recmesh = GeometryBasics.Mesh(
        meta(GeometryBasics.coordinates(recmesh); normals=normals(recmesh), uv=uvs),
        faces(recmesh))
end

file = load(joinpath(@__DIR__, "buildings.jld"))

zoneBuildings = file["polyBase"]
heightBuildings = file["heights"]

meshes = [getBuilding(zoneBuildings[i], heightBuildings[i]/235.2000122)
    for i in 1:length(heightBuildings)]
meshCollect = merge(meshes)
# it will be also good to have a different color per mesh... I don't know how to do it
# after the merge.
texture = reshape(get(colorschemes[:plasma], 0:0.01:1), 101, 1)
begin
    context = RPR.Context()
    matsys = RPR.MaterialSystem(context, 0)
    fig, ax, pl = mesh(meshCollect; color=texture, show_axis=false, figure = (;resolution = (1200, 800)), material=RPR.Plastic(matsys))
    mini, maxi = extrema(Rect3f(meshCollect))
    w = maxi .- mini
    mesh!(ax, Rect3f(Vec3f(mini[1], mini[2]- (w[1]/3), -0.1), Vec3f(w[1], w[1], 0.1)), color=:white)
    middle = Point3f(mini .+ w./2)
    sphere = Sphere(middle - Point3f(0, 0, w[3]/2), w[2]/2.2)
    glassmat = RPR.Glass(matsys)
    glassmat.refraction_ior = Vec3f(1.2)
    glassmat.refraction_absorption_distance = Vec3f(250)
    glassmat.refraction_caustics = false
    mesh!(ax, normal_mesh(Tesselation(sphere, 100)), material = glassmat, color=:white)
    display(fig)
    context, task, rpr_scene = RPRMakie.replace_scene_rpr!(ax.scene, context, matsys)

end

light = RPR.PointLight(context)
transform!(light, Makie.translationmatrix(Vec3f(middle) .+ Vec3f(0, 0, 1)))
RPR.setradiantpower!(light, 10, 10, 10)
push!(rpr_scene, light)
