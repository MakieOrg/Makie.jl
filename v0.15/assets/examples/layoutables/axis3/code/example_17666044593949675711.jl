# This file was generated, do not modify it. # hide
__result = begin # hide
  
using GLMakie
GLMakie.activate!() # hide
Makie.inline!(true) # hide

f = Figure()

r = LinRange(-1, 1, 100)
cube = [(x.^2 + y.^2 + z.^2) for x = r, y = r, z = r]
cube_with_holes = cube .* (cube .> 1.4)

viewmodes = [:fitzoom, :fit, :stretch]

for (j, viewmode) in enumerate(viewmodes)
    for (i, azimuth) in enumerate([1.1, 1.275, 1.45] .* pi)
        ax = Axis3(f[i, j], aspect = :data,
            azimuth = azimuth,
            viewmode = viewmode, title = "$viewmode")
        hidedecorations!(ax)
        ax.protrusions = (0, 0, 0, 20)
        volume!(cube_with_holes, algorithm = :iso, isorange = 0.05, isovalue = 1.7)
    end
end

f

  end # hide
  save(joinpath(@OUTPUT, "example_17666044593949675711.png"), __result) # hide
  
  nothing # hide