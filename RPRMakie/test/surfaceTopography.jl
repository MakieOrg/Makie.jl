using GLMakie, NetCDF, ColorSchemes
GLMakie.activate!()
using YAXArrays.Datasets: open_mfdataset

cs = collect(keys(colorschemes))
cmapIdx = Node(1)
cmapIdx
cmap = @lift(cs[$cmapIdx]) # @lift(Reverse(cs[$cmapIdx]))
ncolors = 101
colors = @lift(to_colormap($cmap, ncolors))
# some transparencies in the colors
g(x) = 0.5 + 0.5*tanh((x+3)/3)
alphas = g.(LinRange(-10,10, ncolors))
cmap_alpha = @lift(RGBAf0.($colors, alphas))

dataset = open_mfdataset(joinpath(@__DIR__, "ETOPO1_halfdegree.nc"))
lon = dataset.lon.values
lat = dataset.lat.values
data = dataset.ETOPO1avg.data[:,:]
mindata = minimum(data)
front = data[:, end]
back = data[:, 1]
left = data[1, :]
right = data[end, :]

lower = [Point3f(i,-90, mindata) for i in lon]
upper = [Point3f(i,-90, front[idx]) for (idx,i) in enumerate(lon)]

lowerB = [Point3f(i,90, mindata) for i in lon]
upperB = [Point3f(i,90, back[idx]) for (idx,i) in enumerate(lon)]

lowerL = [Point3f(-180, i, mindata) for i in lat]
upperL = [Point3f(-180,i, left[idx]) for (idx,i) in enumerate(lat)]

lowerR = [Point3f(180, i, mindata) for i in lat]
upperR = [Point3f(180,i, right[idx]) for (idx,i) in enumerate(lat)]

fig = Figure()
ax = LScene(fig[1, 1], scenekw=(show_axis=false,))
mini, maxi = extrema(data)
data_norm = ((data .- mini) ./ (maxi-mini)) .* 20
crange = (((-6500,5500) .- mini) ./ (maxi-mini) .* 20)
pltobj = surface!(ax, lon, lat, data_norm, colorrange=crange, colormap=[:black, :brown, :green], backlight = 1.0f0)
color = :black
display(fig)
# surface!(ax, lon, lat, fill(0, size(data)); colorrange = (0,1),
    # lowclip = color, shading = false, transparency = true)
# objb = band!(ax, lower, upper; color = color)
# band!(ax, lowerL, upperL; color = color)
# band!(ax, lowerR, upperR; color = color)
# band!(ax, lowerB, upperB; color = color)
using RadeonProRender, GeometryBasics, Colors, Makie
using ReferenceTests, Colors
using RPRMakie
RPR = RadeonProRender

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
    RPR.rprContextSetParameterByKey1u(context, RPR.RPR_CONTEXT_ITERATIONS, 2)
    RPR.render(context)
    RPR.rprContextResolveFrameBuffer(context, frame_buffer, frame_bufferSolved, false)
    RPR.save(frame_bufferSolved, "test.png")
end
