# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str # hide
__result = begin # hide
    using GLMakie
GLMakie.activate!()

fig = Figure()
pl = PointLight(Point3f(0), RGBf(20, 20, 20))
al = AmbientLight(RGBf(0.2, 0.2, 0.2))
lscene = LScene(fig[1, 1], show_axis=false, scenekw = (lights = [pl, al], backgroundcolor=:black, clear=true))
# now you can plot into lscene like you're used to
p = meshscatter!(lscene, randn(300, 3), color=:gray)
fig
end # hide
save(joinpath(@OUTPUT, "example_4071121853107237662.png"), __result; ) # hide

nothing # hide