# This file was generated, do not modify it. # hide
__result = begin # hide
    using GLMakie
GLMakie.activate!() # hide
Makie.inline!(true) # hide

fig = Figure()
ax = LScene(fig[1, 1], scenekw=(show_axis=false,))

x = LinRange(0, π, 50)
y = LinRange(0, 2π, 100)
z = LinRange(0, 3π, 150)

lsgrid = labelslidergrid!(
  fig,
  ["yz plane - x axis", "xz plane - y axis", "xy plane - z axis"],
  [1:length(x), 1:length(y), 1:length(z)]
)
fig[2, 1] = lsgrid.layout

vol = [cos(X)*sin(Y)*sin(Z) for X ∈ x, Y ∈ y, Z ∈ z]
plt = volumeslices!(ax, x, y, z, vol)

# connect sliders to `volumeslices` update methods
sl_yz, sl_xz, sl_xy = lsgrid.sliders

on(sl_yz.value) do v; plt[:update_yz][](v) end
on(sl_xz.value) do v; plt[:update_xz][](v) end
on(sl_xy.value) do v; plt[:update_xy][](v) end

set_close_to!(sl_yz, .5length(x))
set_close_to!(sl_xz, .5length(y))
set_close_to!(sl_xy, .5length(z))

# cam3d!(ax.scene, projectiontype=Makie.Orthographic)

fig
end # hide
save(joinpath(@OUTPUT, "example_5203360342513263086.png"), __result) # hide

nothing # hide