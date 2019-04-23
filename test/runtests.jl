using WGLMakie, AbstractPlotting
using Test

AbstractPlotting.set_theme!(resolution = (650, 300))

r = range(0, stop=5pi, length=100)
s = lines(r, sin.(r), linewidth = 3)
d, w = js_display(s);
