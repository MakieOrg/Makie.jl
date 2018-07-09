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
#   -> contour
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
surf = surface!(scene, r, r, z)[end]


wf = wireframe!(scene, r, r, Makie.lift(x-> x .+ 1.0, surf[3]),
    linewidth = 2f0, color = Makie.lift(x-> to_colormap(x)[5], surf[:colormap]))

screen = Makie.global_gl_screen()


function test(x, y, z)
    xy = [x, y, z]
    ((xy') * eye(3, 3) * xy) / 20
end
x = linspace(-2pi, 2pi, 100)
scene = Scene()
c = contour!(scene, x, x, x, test, levels = 10)[end]
xm, ym, zm = minimum(scene.limits[])
# c[4] == fourth argument of the above plotting command
contour!(scene, x, x, map(v-> v[1, :, :], c[4]), transformation = (:xy, zm))
heatmap!(scene, x, x, map(v-> v[:, 1, :], c[4]), transformation = (:xz, ym))
contour!(scene, x, x, map(v-> v[:, :, 1], c[4]), fillrange=true, transformation = (:yz, xm))

y = linspace(-0.997669, 0.997669, 23)
@edit contour(linspace(-0.99, 0.99, 23), y, rand(23, 23), levels = 10)

@edit contour
