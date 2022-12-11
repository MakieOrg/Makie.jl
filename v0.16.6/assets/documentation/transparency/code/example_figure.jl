# This file was generated, do not modify it. # hide
__result = begin # hide
    using GLMakie
GLMakie.activate!() # hide

fig = Figure(resolution = (800, 400))
ax1 = LScene(fig[1, 1], show_axis=false)
p1 = mesh!(ax1, Rect2f(-2, -2, 4, 4), color = :red, shading = false, transparency = true)
p2 = mesh!(ax1, Rect2f(-2, -2, 4, 4), color = :blue, shading = false, transparency = true)
p3 = mesh!(ax1, Rect2f(-2, -2, 4, 4), color = :red, shading = false, transparency = true)
for (dz, p) in zip((-1, 0, 1), (p1, p2, p3))
    translate!(p, 0, 0, dz)
end

ax2 = LScene(fig[1, 2], show_axis=false)
p1 = mesh!(ax2, Rect2f(-1.5, -1, 3, 3), color = (:red, 0.5), shading = false, transparency=true)
p2 = mesh!(ax2, Rect2f(-1.5, -2, 3, 3), color = (:blue, 0.5), shading = false, transparency=true)
rotate!(p1, Vec3f(0, 1, 0), 0.1)
rotate!(p2, Vec3f(0, 1, 0), -0.1)
fig
end # hide
save(joinpath(@OUTPUT, "example_8109595117423421616.png"), __result) # hide

nothing # hide