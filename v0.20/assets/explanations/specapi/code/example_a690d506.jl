# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str                       # hide
__result = begin                                       # hide
    using GLMakie
using DelimitedFiles
using Makie.FileIO
import Makie.SpecApi as S
using Random
GLMakie.activate!(inline = true) # hide

Random.seed!(123)

volcano = readdlm(Makie.assetpath("volcano.csv"), ',', Float64)
brain = load(assetpath("brain.stl"))
r = LinRange(-1, 1, 100)
cube = [(x .^ 2 + y .^ 2 + z .^ 2) for x = r, y = r, z = r]

density_plots = map(x -> S.Density(x * randn(200) .+ 3x, color=:y), 1:5)
brain_mesh = S.Mesh(brain, colormap=:Spectral, color=[tri[1][2] for tri in brain for i in 1:3])
volcano_contour = S.Contourf(volcano; colormap=:inferno)
cube_contour = S.Contour(cube, alpha=0.5)

ax_densities = S.Axis(; plots=density_plots, yautolimitmargin = (0, 0.1))
ax_volcano = S.Axis(; plots=[volcano_contour])
ax_brain = S.Axis3(; plots=[brain_mesh], protrusions = (50, 20, 10, 0))
ax_cube = S.Axis3(; plots=[cube_contour], protrusions = (50, 20, 10, 0))

spec_column_vector = S.GridLayout([ax_densities, ax_volcano, ax_brain]);
spec_matrix = S.GridLayout([ax_densities ax_volcano; ax_brain ax_cube]);
spec_row = S.GridLayout([spec_column_vector spec_matrix], colsizes = [Auto(), Auto(4)])

f, ax, pl = plot(S.GridLayout(spec_row); figure = (; fontsize = 10))
end                                                    # hide
sz = size(Makie.parent_scene(__result))                # hide
open(joinpath(@OUTPUT, "example_a690d506_size.txt"), "w") do io # hide
    print(io, sz[1], " ", sz[2])                       # hide
end                                                    # hide
save(joinpath(@OUTPUT, "example_a690d506.png"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
 # hide
nothing # hide