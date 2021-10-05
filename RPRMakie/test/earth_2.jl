using Downloads: download
using FileIO, Makie, Colors
using RadeonProRender, RPRMakie
RPR = RadeonProRender

earth_img = load(download("https://upload.wikimedia.org/wikipedia/commons/5/56/Blue_Marble_Next_Generation_%2B_topography_%2B_bathymetry.jpg"))
n = 1024 ÷ 4 # 2048
θ = LinRange(0,pi,n)
φ = LinRange(-pi,pi,2*n)
xe = [cos(φ)*sin(θ) for θ in θ, φ in φ]
ye = [sin(φ)*sin(θ) for θ in θ, φ in φ]
ze = [cos(θ) for θ in θ, φ in φ]

fig = Figure(; resolution = (1500,1500))
ax = LScene(fig[1, 1])
surface!(ax, xe, ye, ze, color = earth_img,
    lightposition = Vec3f0(-2, -3, -3),
    ambient = Vec3f0(0.75, 0.75, 0.75),
)

isdefined(Main, :context) && RPR.release(context)
context = RPR.Context()

RPRMakie.to_rpr_scene(context, ax.scene)

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
