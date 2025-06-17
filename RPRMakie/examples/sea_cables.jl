# by Lazaro Alonso
# taken from: https://lazarusa.github.io/BeautifulMakie/GeoPlots/submarineCables3D/
using GeoMakie, Downloads
using GeoJSON, GeoInterface
using FileIO
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
feat = GeoInterface.features(land_geoCables)
toLines = GeoInterface.coordinates.(GeoInterface.geometry.(feat))

# broken lines at -180 and 180... they should
# be the same line and be in the same array.

# some 3D transformations
function toCartesian(lon, lat; r = 1.02, cxyz = (0, 0, 0))
    x = cxyz[1] + r * cosd(lat) * cosd(lon)
    y = cxyz[2] + r * cosd(lat) * sind(lon)
    z = cxyz[3] + r * sind(lat)
    return (x, y, z)
end

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
# the actual plot !
RPRMakie.activate!(; iterations = 100)
scene = with_theme(theme_dark()) do
    fig = Figure(; size = (1000, 1000))
    radiance = 30
    lights = [
        EnvironmentLight(0.5, load(RPR.assetpath("starmap_4k.tif"))),
        PointLight(Vec3f(1, 1, 3), RGBf(radiance, radiance, radiance)),
    ]
    ax = LScene(fig[1, 1]; show_axis = false, scenekw = (lights = lights,))
    n = 1024 ÷ 4 # 2048
    θ = LinRange(0, pi, n)
    φ = LinRange(-pi, pi, 2 * n)
    xe = [cos(φ) * sin(θ) for θ in θ, φ in φ]
    ye = [sin(φ) * sin(θ) for θ in θ, φ in φ]
    ze = [cos(θ) for θ in θ, φ in φ]
    surface!(ax, xe, ye, ze; color = earth_img)
    meshscatter!(toPoints3D; color = 1:length(toPoints3D), markersize = 0.005, colormap = :plasma)
    colors = Makie.DEFAULT_PALETTES.color[]
    c = Iterators.cycle(colors)
    foreach(((l, c),) -> lines!(ax, l; linewidth = 2, color = c), zip(splitLines3D, c))
    ax.scene.camera_controls.eyeposition[] = Vec3f(1.5)
    return ax.scene
end

save("submarin_cables.png", scene)
