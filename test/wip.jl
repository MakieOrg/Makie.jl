#!/usr/bin/julia
#####################
#       Notes       #
#####################
# Shadercleanup:
#   -> For now I will leave the shitty push! robj + pipeline situation as it is to later implement a better way, redoing all the visualizes into also returning what pipeline

# Rendering issues:
#   -> I'm not sure where the issue lies, but for sure it's not at vao or fbo stage,
#      it worked with those in there already. It has to be around the rendering.
#   -> I just found out that it was possible to mix and match post render functions,
#      maybe that's the issue, there were specific postender functions? Not sure.
#   -> I don't know it seems that that was just used to define the correct vao function,
#      which should be handled by the vao alread.

#   -> glClear clears all colors?
#   -> I think I isolated the issue to the vertexarray + shader!

# Renderingcleanup:
#   -> Right now the way that the screenbuffer is displayed to the plot window requires there to be
#      at least one pipeline is inside the pipelines of the Screen. This should probably change.

#TODO generalcleanup: Put finalizer(free) for all the GLobjects!



using Makie
begin
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
end

screen = Makie.global_gl_screen()
Makie.renderloop(screen)
