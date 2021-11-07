using JLD
using GLMakie, GeometryBasics, ColorSchemes

function poly_3d(points3d)
    xy = Point2f.(points3d)
    f = faces(GeometryBasics.Polygon(xy))
    return normal_mesh(Point3f.(points3d), f)
end
function getBuilding(basePoints, h)
    n = length(basePoints)
    bottom_poly = [Point3f(basePoints[i][1], basePoints[i][2], 0) for i in 1:n]
    top_poly = [Point3f(basePoints[i][1], basePoints[i][2], h) for i in 1:n]
    top = poly_3d(top_poly)
    bottom = poly_3d(bottom_poly)
    combined = merge([top, bottom])
    nvertices = length(top.position)
    connection = Makie.band_connect(nvertices)
    m = GeometryBasics.Mesh(GeometryBasics.coordinates(combined), vcat(faces(combined), connection))
    recmesh = GeometryBasics.normal_mesh(m)
    uvs = [Point2f(p[3], 0) for p in GeometryBasics.coordinates(recmesh)] # normalize this so zmax = 1
    recmesh = GeometryBasics.Mesh(
        meta(GeometryBasics.coordinates(recmesh); normals=normals(recmesh), uv = uvs),
        faces(recmesh))
end

file = load("buildings.jld")

zoneBuildings = file["polyBase"]
heightBuildings = file["heights"]

meshes = [getBuilding(zoneBuildings[i], heightBuildings[i]/235.2000122) 
    for i in 1:length(heightBuildings)]
meshCollect = merge(meshes)
# it will be also good to have a different color per mesh... I don't know how to do it
# after the merge.
texture = reshape(get(colorschemes[:plasma], 0:0.01:1), 1, 101)

fig, ax, = mesh(meshCollect; color=texture, shading = false,
    figure = (;resolution = (2400, 1200)),
    axis = (; type =Axis3, aspect=(1, 0.5, 0.2), azimuth = 17.88,
    elevation = 0.14, perspectiveness=0.5))
fig