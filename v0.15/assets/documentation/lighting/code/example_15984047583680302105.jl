# This file was generated, do not modify it. # hide
__result = begin # hide
  
using GLMakie
GLMakie.activate!() # hide
GLMakie.enable_SSAO[] = true
close(GLMakie.global_gl_screen()) # close any open screen

# Alternatively:
# fig = Figure()
# scene = LScene(fig[1, 1], scenekw = (SSAO = (radius = 5.0, blur = 3), show_axis=false, camera=cam3d!))
# scene.scene[:SSAO][:bias][] = 0.025

scene = Scene(show_axis = false)

# SSAO attributes are per scene
scene[:SSAO][:radius][] = 5.0
scene[:SSAO][:blur][] = 3
scene[:SSAO][:bias][] = 0.025

box = Rect3(Point3f(-0.5), Vec3f(1))
positions = [Point3f(x, y, rand()) for x in -5:5 for y in -5:5]
meshscatter!(scene, positions, marker=box, markersize=1, color=:lightblue, ssao=true)
scene

GLMakie.enable_SSAO[] = false # hide
close(GLMakie.global_gl_screen()) # hide
scene # hide

  end # hide
  save(joinpath(@OUTPUT, "example_15984047583680302105.png"), __result) # hide
  
  nothing # hide