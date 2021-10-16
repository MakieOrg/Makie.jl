using Downloads: download
using FileIO, Makie, Colors, GeoJSON, FileIO, Downloads, GeoMakie
using RadeonProRender, RPRMakie
RPR = RadeonProRender

earth_img = load(download("https://upload.wikimedia.org/wikipedia/commons/5/56/Blue_Marble_Next_Generation_%2B_topography_%2B_bathymetry.jpg"))


# data from
# https://github.com/telegeography/www.submarinecablemap.com
urlPoints = "https://raw.githubusercontent.com/telegeography/www.submarinecablemap.com/master/web/public/api/v3/landing-point/landing-point-geo.json"

landPoints = Downloads.download(urlPoints, IOBuffer())
land_geoPoints = GeoJSON.read(seekstart(landPoints))
toPoints = GeoMakie.geo2basic(land_geoPoints)

function toCartesian(lon, lat; r = 1.02, cxyz = (0,0,0) )
    lat, lon = lat*π/180, lon*π/180
    cxyz[1] + r * cos(lat) * cos(lon), cxyz[2] + r * cos(lat) * sin(lon), cxyz[3] + r *sin(lat)
end

n = 1024 ÷ 4 # 2048
θ = LinRange(0,pi,n)
φ = LinRange(-pi,pi,2*n)
xe = [cos(φ)*sin(θ) for θ in θ, φ in φ]
ye = [sin(φ)*sin(θ) for θ in θ, φ in φ]
ze = [cos(θ) for θ in θ, φ in φ]
fig = Figure(; resolution = (1500,1500))
ax = LScene(fig[1, 1], scenekw=(show_axis=false,))
surface!(ax, xe, ye, ze, color = earth_img)
toPoints3D = [Point3f0([toCartesian(point[1], point[2])...]) for point in toPoints]
meshscatter!(ax, toPoints3D, color = 1:length(toPoints3D), markersize = 0.01, colormap = :plasma)

isdefined(Main, :context) && RPR.release(context)
context = RPR.Context()

RPRMakie.to_rpr_scene(context, ax.scene)

fb_size = (1500, 1500)
frame_buffer = RPR.FrameBuffer(context, RGBA, fb_size)
frame_bufferSolved = RPR.FrameBuffer(context, RGBA, fb_size)
set!(context, RPR.RPR_AOV_COLOR, frame_buffer)
set_standard_tonemapping!(context)

begin
    clear!(frame_buffer)
    RPR.rprContextSetParameterByKey1u(context, RPR.RPR_CONTEXT_ITERATIONS, 100)
    RPR.render(context)
    RPR.rprContextResolveFrameBuffer(context, frame_buffer, frame_bufferSolved, false)
    RPR.save(frame_bufferSolved, "test.png")
end
