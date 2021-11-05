using Downloads: download
using GLMakie
using FileIO, Makie, Colors, GeoJSON, GeoMakie
using RadeonProRender, RPRMakie, GeometryBasics
RPR = RadeonProRender

earth_img = load(download("https://upload.wikimedia.org/wikipedia/commons/5/56/Blue_Marble_Next_Generation_%2B_topography_%2B_bathymetry.jpg"))
# data from
# https://github.com/telegeography/www.submarinecablemap.com
urlPoints = "https://raw.githubusercontent.com/telegeography/www.submarinecablemap.com/master/web/public/api/v3/landing-point/landing-point-geo.json"

landPoints = download(urlPoints, IOBuffer())
land_geoPoints = GeoJSON.read(seekstart(landPoints))
toPoints = GeoMakie.geo2basic(land_geoPoints)

function toCartesian(lon, lat; r = 1.02, cxyz = (0,0,0) )
    lat, lon = lat*π/180, lon*π/180
    cxyz[1] + r * cos(lat) * cos(lon), cxyz[2] + r * cos(lat) * sin(lon), cxyz[3] + r *sin(lat)
end

begin
    context = RPR.Context()
    matsys = RPR.MaterialSystem(context, 0)

    n = 1024 ÷ 4 # 2048
    θ = LinRange(0,pi,n)
    φ = LinRange(-pi,pi,2*n)
    xe = [cos(φ)*sin(θ) for θ in θ, φ in φ]
    ye = [sin(φ)*sin(θ) for θ in θ, φ in φ]
    ze = [cos(θ) for θ in θ, φ in φ]
    fig = Figure(; resolution = (1500,1500), backgroundcolor=:black)
    ax = LScene(fig[1, 1], scenekw=(show_axis=false,))
    surface!(ax, xe, ye, ze, color = earth_img)
    toPoints3D = [Point3f0([toCartesian(point[1], point[2])...]) for point in toPoints]
    meshscatter!(ax, toPoints3D, color = 1:length(toPoints3D), markersize = 0.006, colormap = :plasma)

    display(fig)

    refresh = Observable(nothing)

    context, task = RPRMakie.replace_scene_rpr!(ax.scene, context, matsys; refresh)
end

# begin
#     mesh!(ax, m, material=athmo)
#     athmo = RPR.UberMaterial(matsys)
#     athmo.color = Vec4f(1, 1, 1, 1)
#     athmo.diffuse_weight = Vec4f(0, 0, 0, 0)
#     athmo.diffuse_roughness = Vec4f(0)

#     athmo.reflection_ior = Vec4f(1.0)
#     athmo.refraction_color = Vec4f(0.5, 0.5, 0.7, 0)
#     athmo.refraction_weight = Vec4f(1)
#     athmo.refraction_roughness = Vec4f(0)
#     athmo.refraction_ior =Vec4f(1.0)
#     athmo.refraction_absorption_color = Vec4f(0.9, 0.3, 0.1, 1)
#     athmo.refraction_absorption_distance = Vec4f(1)
#     athmo.refraction_caustics = false

#     athmo.sss_scatter_color = Vec4f(1.4, 0.8, 0.3, 0)
#     athmo.sss_scatter_distance = Vec4f(0.3)
#     athmo.sss_scatter_direction = Vec4f(0)
#     athmo.sss_weight = Vec4f(1)
#     athmo.backscatter_weight = Vec4f(1)
#     athmo.backscatter_color = Vec4f(0.9, 0.1, 0.1, 1)

#     athmo.reflection_mode = UInt(RPR.RPR_UBER_MATERIAL_IOR_MODE_PBR)
#     athmo.emission_mode = UInt(RPR.RPR_UBER_MATERIAL_EMISSION_MODE_DOUBLESIDED)
#     athmo.coating_mode = UInt(RPR.RPR_UBER_MATERIAL_IOR_MODE_PBR)
#     athmo.sss_multiscatter = true
#     athmo.refraction_thin_surface = false
#     notify(refresh)
# end
