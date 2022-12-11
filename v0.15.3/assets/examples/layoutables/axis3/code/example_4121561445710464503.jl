# This file was generated, do not modify it. # hide
__result = begin # hide
  
using GLMakie
using FileIO
GLMakie.activate!() # hide
Makie.inline!(true) # hide

f = Figure()

brain = load(assetpath("brain.stl"))
colors = [tri[1][2] for tri in brain for i in 1:3]

azimuths = [0, 0.2pi, 0.4pi]
elevations = [-0.2pi, 0, 0.2pi]

for (i, elevation) in enumerate(elevations)
    for (j, azimuth) in enumerate(azimuths)
        ax = Axis3(f[i, j], aspect = :data,
        title = "elevation = $(round(elevation/pi, digits = 2))π\nazimuth = $(round(azimuth/pi, digits = 2))π",
        elevation = elevation, azimuth = azimuth,
        protrusions = (0, 0, 0, 40))

        hidedecorations!(ax)
        mesh!(brain, color = colors, colormap = :thermal)
    end
end

f

  end # hide
  save(joinpath(@OUTPUT, "example_4121561445710464503.png"), __result) # hide
  
  nothing # hide