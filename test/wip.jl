#!/usr/bin/julia
#####################
#       Notes       #
#####################
# Shadercleanup:
#   -> For now I will leave the shitty push! robj + pipeline situation as it is
#      to later implement a better way, redoing all the visualizes into also
#      returning what pipeline.
#   -> Reason why shader for heatmap doesn't compile is that it can't find certain things in the data!
#
# Renderingcleanup:
#   -> Right now the way that the screenbuffer is displayed to the plot window
#      requires there to be at least one pipeline is inside the pipelines of the Screen.
#      This should probably change.
#
# VertexArraycleanup:
#   -> Instancing is now done the other way around to what it should be.
#
#
#
# generalcleanup:
#   -> Put finalizer(free) for all the GLobjects!
#   -> So many speedups possible!
#
# What doesn't work:
#   -> contours
#   -> during the multiple polygon test, does the bottom circle get fully drawn?
#   -> All of these are related to linesegments I think
#
# linesegmentsissues:
#   -> does not get fully drawn
#   -> does not get colored
#   -> sometimes has other weirdness such as moire
#   -> sometimes produces an error like connected sphere (ptrVoid 0 ???)
#   -> linewidth on contour3d does not work




using Makie


begin
    function xy_data(x, y)
        r = sqrt(x*x + y*y)
        r == 0.0 ? 1f0 : (sin(r)/r)
    end
    r = linspace(-1, 1, 100)
    contour3d(r, r, (x,y)-> xy_data(10x, 10y), levels = 20, linewidth = 200000)
end

begin
    large_sphere = Sphere(Point3f0(0), 1f0)
    positions = decompose(Point3f0, large_sphere)
    linepos = view(positions, rand(1:length(positions), 1000))
    scene = lines(linepos, linewidth = 0.1, color = :black)
    scatter!(scene, positions, strokewidth = 10, strokecolor = :white, color = RGBAf0(0.9, 0.2, 0.4, 0.6))
    scene
end

begin
    using GeometryTypes
    scene = Scene(resolution = (500, 500))
    points = decompose(Point2f0, Circle(Point2f0(50), 50f0))
    pol = poly!(scene, points, color = :gray, strokewidth = 10, strokecolor = :red)
    # Optimized forms
    poly!(scene, [Circle(Point2f0(50+300), 50f0)], color = :gray, strokewidth = 10, strokecolor = :red)
    poly!(scene, [Circle(Point2f0(50+i, 50+i), 10f0) for i = 1:100:400], color = :red)
    poly!(scene, [Rectangle{Float32}(50+i, 50+i, 20, 20) for i = 1:100:400], strokewidth = 2, strokecolor = :green)
    linesegments!(scene,
        [Point2f0(50 + i, 50 + i) => Point2f0(i + 70, i + 70) for i = 1:100:400], linewidth = 8, color = :purple
    )
end
