using RadeonProRender, GeometryBasics, Colors, Makie
using ReferenceTests
using Makie: translationmatrix
RPR = RadeonProRender
earth = ReferenceTests.loadasset("earth.png")
m = uv_mesh(Tesselation(Sphere(Point3f(0), 1.0f0), 60))
f, ax, mplot = Makie.mesh(m; color=earth, shading=false)
Makie.mesh!(ax, Sphere(Point3f(2, 0, 0), 0.1f0); color=:red)
x, y = collect(-8:0.5:8), collect(-8:0.5:8)
z = [sinc(√(X^2 + Y^2) / π) for X ∈ x, Y ∈ y]
wireframe!(ax, -2..2, -2..2, z)

context = RPR.Context()

to_rpr_scene(context, ax.scene)

fb_size = (1500, 1500)
frame_buffer = RPR.FrameBuffer(context, RGBA, fb_size)
frame_bufferSolved = RPR.FrameBuffer(context, RGBA, fb_size)
set!(context, RPR.RPR_AOV_COLOR, frame_buffer)
set_standard_tonemapping!(context)

begin
    clear!(frame_buffer)
    RPR.rprContextSetParameterByKey1u(context, RPR.RPR_CONTEXT_ITERATIONS, 100)
    RPR.render(context)
    RPR.rprContextResolveFrameBuffer(context, frame_buffer, frame_bufferSolved, false)
    RPR.save(frame_bufferSolved, "test.png")
end
