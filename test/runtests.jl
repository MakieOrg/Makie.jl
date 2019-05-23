using WGLMakie, AbstractPlotting

scatter(rand(4))
s = surface(0..1, 0..1, rand(100, 100))
ls = colorlegend(s[end], show_axis = false, camera = cam2d!, scale_plot = false)
scene = vbox(s, ls)

using FileIO
img = load(joinpath(homedir(), "Desktop", "profile.jpg"))
