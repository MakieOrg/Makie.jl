using Makie, Colors, FixedPointNumbers

scene = scatter(rand(10), rand(10));
scene = heatmap(rand(300, 300));
center!(scene);
yield()
x = Makie.CairoBackend.CairoScreen(scene, "test2.csv");
display(x, scene);
