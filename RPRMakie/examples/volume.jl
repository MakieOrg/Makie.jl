using RPRMakie
using Makie, NIfTI, FileIO
using GLMakie
r = LinRange(-1, 1, 100)
cube = [(x .^ 2 + y .^ 2 + z .^ 2) for x in r, y in r, z in r]

brain = Float32.(niread(Makie.assetpath("brain.nii.gz")).raw)
radiance = 5000
lights = [
    EnvironmentLight(1.0, load(RPR.assetpath("studio026.exr"))),
    PointLight(Vec3f(10), RGBf(radiance, radiance, radiance * 1.1)),
]
fig = Figure(; size = (1000, 1000))
ax = LScene(fig[1, 1]; show_axis = false, scenekw = (lights = lights,))
Makie.volume!(ax, 0 .. 3, 0 .. 3.78, 0 .. 3.18, brain, algorithm = :absorption, absorption = 0.3)
display(ax.scene; iterations = 5000)
