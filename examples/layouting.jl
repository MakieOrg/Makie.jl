
@cell "Layouting" [scatter, lines, surface, heatmap] begin
    p1 = scatter(rand(10), markersize = 1)
    p2 = lines(rand(10), rand(10))
    p3 = surface(0..1, 0..1, rand(100, 100))
    p4 = heatmap(rand(100, 100))
    x = 0:0.1:10
    p5 = lines(0:0.1:10, sin.(x))
    pscene = vbox(
        hbox(p1, p2),
        p3,
        hbox(p4, p5, sizes = [0.7, 0.3]),
        sizes = [0.2, 0.6, 0.2]
    )
end
