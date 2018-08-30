using Makie, Colors, FixedPointNumbers

scene = scatter(rand(10), rand(10));
scene = image(rand(300, 300));
scene = heatmap(rand(300, 300));
y = range(-0.997669, stop = 0.997669, length = 23)
scene = contour(range(-0.99, stop = 0.99, length = 23), y, rand(23, 23), levels = 10);
center!(scene);
yield()
x = Makie.CairoBackend.CairoScreen(scene, "test2.csv");
display(x, scene);

using Makie
using ImageFiltering

x = range(-2, stop = 2, length = 21)
y = x
z = x .* exp.(-x .^ 2 .- (y') .^ 2);
scene = contour(x, y, z, levels = 10, linewidth = 3);
u, v = ImageFiltering.imgradients(z, KernelFactors.ando3);
arrows!(x, y, u, v, arrowsize = 0.05);
center!(scene);
yield()
x = Makie.CairoBackend.CairoScreen(scene, "test2.csv");
display(x, scene);
