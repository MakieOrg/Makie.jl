# https://www.rayshader.com/
using FileIO, ArchGDAL, GLMakie
file = joinpath(@__DIR__, "dem_01.tif.zip")
tif_file = joinpath(@__DIR__, "dem_01.tif")
zip = download("https://tylermw.com/data/dem_01.tif.zip", file)
localtif = ArchGDAL.readraster(tif_file)
matr = collect(localtif)


using RPRMakie
begin
    RPRMakie.activate!(resource=RPR.GPU1, iterations=100, plugin=RPR.Northstar)
    fig = Figure()
    radiance = 1000
    lights = [EnvironmentLight(0.5, load(RPR.assetpath("studio026.exr"))),
              PointLight(Vec3f(5), RGBf(radiance, radiance, radiance * 1.1))]
    ax = LScene(fig[1, 1]; scenekw=(; lights=lights), show_axis=false)
    sp = surface!(ax, -1000 .. 1000, -1000 .. 1000, matr[:, :, 1])
    center!(ax.scene)
    display(ax.scene)
end

using GeometryBasics

begin
    x = sp[1]
    y = sp[2]
    z = sp[3]

    function grid(x, y, z, trans)
        space = to_value(get(sp, :space, :data))
        g = map(CartesianIndices(z)) do i
            p = Point3f(Makie.get_dim(x, i, 1, size(z)), Makie.get_dim(y, i, 2, size(z)), z[i])
            return Makie.apply_transform(trans, p, space)
        end
        return vec(g)
    end

    positions = lift(grid, x, y, z, Makie.transform_func_obs(sp))
    r = Tesselation(Rect2f((0, 0), (1, 1)), size(z[]))
    # decomposing a rectangle into uv and triangles is what we need to map the z coordinates on
    # since the xyz data assumes the coordinates to have the same neighouring relations
    # like a grid
    faces = decompose(GLTriangleFace, r)
    uv = decompose_uv(r)
    # with this we can beuild a mesh
    m = GeometryBasics.uv_normal_mesh(GeometryBasics.Mesh(meta(vec(positions[]), uv=uv), faces))
    display(Makie.mesh(m); backend=GLMakie)
end
