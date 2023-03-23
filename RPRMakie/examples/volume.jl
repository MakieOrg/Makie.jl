using RPRMakie, ProgressMeter
using Makie, NIfTI, FileIO
using GLMakie
r = LinRange(-1, 1, 100)
cube = [(x .^ 2 + y .^ 2 + z .^ 2) for x = r, y = r, z = r]

RPRMakie.activate!(
    iterations = 32,
    plugin=RPR.Northstar, 
    resource = RPR.RPR_CREATION_FLAGS_ENABLE_CPU | RPR.RPR_CREATION_FLAGS_ENABLE_METAL
)

brain = Float32.(niread(Makie.assetpath("brain.nii.gz")).raw)
radiance = 5000
lights = Makie.AbstractLight[
    EnvironmentLight(1.0, load(RPR.assetpath("studio026.exr"))),
    PointLight(Vec3f(10), RGBf(radiance, radiance, radiance * 1.1))
]

fig = Figure(; resolution=(1000, 1000));
ax = LScene(fig[1, 1]; show_axis=false, scenekw=(lights=lights,));
vp = Makie.volume!(
    ax, 
    #=0..3, 0..3.78, 0..3.18,
    brain=#
    0..3, 0..3, 0..3,
    [z for x in 1:10, y in 1:10, z in 1:10];
    algorithm=:absorption, 
    absorption=1f0, 
    colormap = Reverse(:plasma)
)
vp.absorption[] = 0.5f0
vp.colormap[] = :turbo

scr = RPRMakie.Screen(ax.scene; iterations = 10)

record(ax.scene, "volume_cube.mp4"; backend = RPRMakie, iterations = 15, framerate = 15) do io
    @showprogress for a in LinRange(0, 3, 30)[2:end]
        vp.absorption[] = Float32(a)
        recordframe!(io)
    end
end

Makie.save("test.png", ax.scene; update=false, backend=RPRMakie, iterations=3)
