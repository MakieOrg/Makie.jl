# by Lazaro Alonso
# taken from: https://lazarusa.github.io/BeautifulMakie/GeoPlots/submarineCables3D/
using GeoMakie, Downloads
using GeoJSON, GeoInterface
using HDF5, FileIO
using RPRMakie
# data from
# https://github.com/telegeography/www.submarinecablemap.com
urlPoints = "https://raw.githubusercontent.com/telegeography/www.submarinecablemap.com/master/web/public/api/v3/landing-point/landing-point-geo.json"
urlCables = "https://raw.githubusercontent.com/telegeography/www.submarinecablemap.com/master/web/public/api/v3/cable/cable-geo.json"

landPoints = Downloads.download(urlPoints, IOBuffer())
landCables = Downloads.download(urlCables, IOBuffer())

land_geoPoints = GeoJSON.read(seekstart(landPoints))
land_geoCables = GeoJSON.read(seekstart(landCables))

toPoints = GeoMakie.geo2basic(land_geoPoints)
#toLines = GeoMakie.geo2basic(land_geoCables) # this should probably be supported.
feat = GeoInterface.features(land_geoCables)
toLines = GeoInterface.coordinates.(GeoInterface.geometry.(feat))

# broken lines at -180 and 180... they should
# be the same line and be in the same array.

# also the coastlines data
# this data can be download from here:
# https://github.com/lazarusA/BeautifulMakie/tree/main/_assets/data
worldxm = h5open(joinpath(@__DIR__, "world_xm.h5"), "r")
world_110m = read(worldxm["world_110m"])
close(worldxm)
lonw, latw = world_110m["lon"], world_110m["lat"]
# some 3D transformations
function toCartesian(lon, lat; r=1.02, cxyz=(0, 0, 0))
    lat, lon = lat * π / 180, lon * π / 180
    return cxyz[1] + r * cos(lat) * cos(lon), cxyz[2] + r * cos(lat) * sin(lon), cxyz[3] + r * sin(lat)
end

function lonlat3D2(lon, lat; cxyz=(0, 0, 0))
    xyzw = zeros(length(lon), 3)
    for (i, lon) in enumerate(lon)
        x, y, z = toCartesian(lon, lat[i]; cxyz=cxyz)
        xyzw[i, 1] = x
        xyzw[i, 2] = y
        xyzw[i, 3] = z
    end
    return xyzw[:, 1], xyzw[:, 2], xyzw[:, 3]
end

xw, yw, zw = lonlat3D2(lonw, latw)
toPoints3D = [Point3f([toCartesian(point[1], point[2])...]) for point in toPoints]

splitLines3D = []
for i in 1:length(toLines)
    for j in 1:length(toLines[i])
        ptsLines = toLines[i][j]
        tmp3D = []
        for k in 1:length(ptsLines)
            x, y = ptsLines[k]
            x, y, z = toCartesian(x, y)
            push!(tmp3D, [x, y, z])
        end
        push!(splitLines3D, Point3f.(tmp3D))
    end
end

earth_img = load(Downloads.download("https://upload.wikimedia.org/wikipedia/commons/5/56/Blue_Marble_Next_Generation_%2B_topography_%2B_bathymetry.jpg"))
Makie.inline!(true)
# the actual plot !
RPRMakie.activate!(; iterations=100)
scene = with_theme(theme_dark()) do
    fig = Figure(; resolution=(1000, 1000))
    radiance = 30
    lights = [EnvironmentLight(0.5, load(RPR.assetpath("starmap_4k.tif"))),
              PointLight(Vec3f(1, 1, 3), RGBf(radiance, radiance, radiance))]
    ax = LScene(fig[1, 1]; show_axis=false, scenekw=(lights=lights,))
    # lines!(ax, xw, yw, zw, color = :white, linewidth = 0.15)
    n = 1024 ÷ 4 # 2048
    θ = LinRange(0, pi, n)
    φ = LinRange(-pi, pi, 2 * n)
    xe = [cos(φ) * sin(θ) for θ in θ, φ in φ]
    ye = [sin(φ) * sin(θ) for θ in θ, φ in φ]
    ze = [cos(θ) for θ in θ, φ in φ]
    surface!(ax, xe, ye, ze; color=earth_img)
    meshscatter!(toPoints3D; color=1:length(toPoints3D), markersize=0.005, colormap=:plasma)
    colors = Makie.default_palettes.color[]
    c = Iterators.cycle(colors)
    foreach(((l, c),) -> lines!(ax, l; linewidth=2, color=c), zip(splitLines3D, c))
    ax.scene.camera_controls.eyeposition[] = Vec3f(1.5)
    return ax.scene
end

save("submarin_cables.png", scene)
