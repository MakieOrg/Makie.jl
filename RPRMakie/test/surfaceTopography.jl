using GLMakie, NetCDF, ColorSchemes
GLMakie.activate!()
using YAXArrays.Datasets: open_mfdataset

cs = collect(keys(colorschemes))
cmapIdx = Node(1)
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

#funcs = [theme_black, theme_dark, theme_light]
#func = Node(funcs[end])
set_theme!()
fig = Figure(resolution = (1200,800),fontsize = 15) # figure_padding = -450,
ax = Axis3(fig, aspect = (1,0.6,0.1), azimuth = -0.65π, elevation = 0.225π,
    viewmode = :fitzoom, perspectiveness = 0.5, protrusions = (0, 0, 0, 0))
menu = Menu(fig[1, 4], options = ["black", "grey90", "silver"], direction = :up)
color = Node("black")
menu.is_open =  false
#menu2 = Menu(fig, options = zip(["black", "dark", "default"], funcs))

pltobj = surface!(ax, lon, lat, data; colormap = cmap_alpha, backlight = 1.0f0,
    colorrange =(-6500,5500), transparency = false)
surface!(ax, lon, lat, fill(mindata, size(data)); colorrange = (0,1),
    lowclip = color, shading = false, transparency = true)
objb = band!(ax, lower, upper; color = color)
band!(ax, lowerL, upperL; color = color)
band!(ax, lowerR, upperR; color = color)
band!(ax, lowerB, upperB; color = color)

cbar  =Colorbar(fig, pltobj,label = "ETOPO1 [m]", ticklabelsize = 15,
    flipaxis = true, tickalign =1, vertical = true, ticksize=15, height = Relative(0.35))
hidespines!(ax)
hidedecorations!(ax; grid = true)
sl = Slider(fig[1, 3], range = 1:length(cs), startvalue = 44, horizontal = false)
    connect!(cmapIdx, sl.value)
fig[1, 4] = vgrid!(
    Label(fig, "Base color", width = nothing), menu,
    #Label(fig, "Function", width = nothing), menu2;
    tellheight = false, width = 100
    )
on(menu.selection) do s
    color[] = s
end
#on(menu2.selection) do s
#    func[] = s
#end
fig[1,1] = ax
fig[1,2] = cbar
fig[0,1] = Label(fig, @lift("Colormap: $(cs[$cmapIdx]), $(cmapIdx.val)"), textsize = 20,
    tellheight = true, tellwidth = false)
display(fig)
#end
