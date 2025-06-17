using NCDatasets, ColorSchemes, RPRMakie
using ImageShow

# Taken from https://lazarusa.github.io/BeautifulMakie/GeoPlots/topography/
cmap = dataset = Dataset(joinpath(@__DIR__, "ETOPO1_halfdegree.nc"))
lon = dataset["lon"][:]
lat = dataset["lat"][:]

data = Float32.(dataset["ETOPO1avg"][:, :])
function toCartesian(lon, lat; r = 1, cxyz = (0, 0, 0))
    lat, lon = lat * π / 180, lon * π / 180
    x = cxyz[1] + (r + 80_000) * cos(lat) * cos(lon)
    y = cxyz[2] + (r + 80_000) * cos(lat) * sin(lon)
    z = cxyz[3] + (r + 80_000) * sin(lat)
    return (x, y, z) ./ 80_000
end

function lonlat3D(lon, lat, data; cxyz = (0, 0, 0))
    xyzw = zeros(size(data)..., 3)
    for (i, lon) in enumerate(lon), (j, lat) in enumerate(lat)
        x, y, z = toCartesian(lon, lat; r = data[i, j], cxyz = cxyz)
        xyzw[i, j, 1] = x
        xyzw[i, j, 2] = y
        xyzw[i, j, 3] = z
    end
    return xyzw[:, :, 1], xyzw[:, :, 2], xyzw[:, :, 3]
end
# this is needed in order to have a closed surface
lonext = cat(collect(lon), lon[1]; dims = 1)
dataext = begin
    tmpdata = zeros(size(lon)[1] + 1, size(lat)[1])
    tmpdata[1:size(lon)[1], :] = data
    tmpdata[size(lon)[1] + 1, :] = data[1, :]
    tmpdata
end
#now let's plot that surface!
xetopo, yetopo, zetopo = lonlat3D(lonext, lat, dataext)

begin
    r = 30
    lights = [PointLight(Vec3f(2, 1, 3), RGBf(r, r, r))]
    fig = Figure(; size = (1200, 1200), backgroundcolor = :black)
    ax = LScene(fig[1, 1]; show_axis = false) #, scenekw=(lights=lights,))
    pltobj = surface!(ax, xetopo, yetopo, zetopo; color = dataext, colormap = :hot, colorrange = (-6000, 5000))
    cam = cameracontrols(ax.scene)
    cam.fov[] = 10
    cam.eyeposition[] = Vec3f(3, 1, 1)
    cam.lookat[] = Vec3f(0)
    cam.upvector[] = Vec3f(0, 0, 1)
    Makie.update_cam!(ax.scene, cam)
    RPRMakie.activate!(; iterations = 32, plugin = RPR.Tahoe)
    display(ax.scene)
end
