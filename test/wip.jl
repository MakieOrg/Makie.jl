#!/usr/bin/julia
#####################
#       Notes       #
#####################
# Shadercleanup:
#   -> For now I will leave the shitty push! robj + pipeline situation as it is
#      to later implement a better way, redoing all the visualizes into also
#      returning what pipeline.
#
# Renderingcleanup:
#   -> Right now the way that the screenbuffer is displayed to the plot window
#      requires there to be at least one pipeline is inside the pipelines of the Screen.
#      This should probably change.
#
# VertexArraycleanup:
#   -> Instancing is now done the other way around to what it should be.
#   -> All different meshscatters etc don't work due to this issue.
#   -> :position is where the instancing happens.
#
# generalcleanup:
#   -> Put finalizer(free) for all the GLobjects!
#   -> So many speedups possible!
#
# What doesn't work:
#   -> everything with instancing
#   -> heatmap



using Makie
scene = Scene()
function xy_data(x, y)
    r = sqrt(x^2 + y^2)
    r == 0.0 ? 1f0 : (sin(r)/r)
end

r = linspace(-2, 2, 50)
surf_func(i) = [Float32(xy_data(x*i, y*i)) for x = r, y = r]
z = surf_func(20)
surf = surface!(scene, r, r, z)
empty!(scene.plots)


wf = wireframe!(scene, r, r, Makie.lift(x-> x .+ 1.0, surf[3]),
    linewidth = 2f0, color = Makie.lift(x-> to_colormap(x)[5], surf[:colormap]))

begin
    large_sphere = Sphere(Point3f0(0), 1f0)
    positions = decompose(Point3f0, large_sphere)
    meshscatter(positions, color = RGBAf0(0.9, 0.2, 0.4, 1), markersize = 0.5)
end

mesh([(0.0, 0.0), (0.5, 1.0), (1.0, 0.0)], color = [:red, :green, :blue], shading = false)


heatmap(rand(32, 32))
2401/3
