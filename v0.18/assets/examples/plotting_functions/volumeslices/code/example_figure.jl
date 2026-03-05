# This file was generated, do not modify it. # hide
__result = begin # hide
    using GLMakie
GLMakie.activate!() # hide


fig = Figure()
ax = LScene(fig[1, 1], show_axis=false)

x = LinRange(0, π, 50)
y = LinRange(0, 2π, 100)
z = LinRange(0, 3π, 150)

sgrid = SliderGrid(
    fig[2, 1],
    (label = "yz plane - x axis", range = 1:length(x)),
    (label = "xz plane - y axis", range = 1:length(y)),
    (label = "xy plane - z axis", range = 1:length(z)),
)

lo = sgrid.layout
nc = ncols(lo)

vol = [cos(X)*sin(Y)*sin(Z) for X ∈ x, Y ∈ y, Z ∈ z]
plt = volumeslices!(ax, x, y, z, vol)

# connect sliders to `volumeslices` update methods
sl_yz, sl_xz, sl_xy = sgrid.sliders

on(sl_yz.value) do v; plt[:update_yz][](v) end
on(sl_xz.value) do v; plt[:update_xz][](v) end
on(sl_xy.value) do v; plt[:update_xy][](v) end

set_close_to!(sl_yz, .5length(x))
set_close_to!(sl_xz, .5length(y))
set_close_to!(sl_xy, .5length(z))

# add toggles to show/hide heatmaps
hmaps = [plt[Symbol(:heatmap_, s)][] for s ∈ (:yz, :xz, :xy)]
toggles = [Toggle(lo[i, nc + 1], active = true) for i ∈ 1:length(hmaps)]

map(zip(hmaps, toggles)) do (h, t)
    connect!(h.visible, t.active)
end

# cam3d!(ax.scene, projectiontype=Makie.Orthographic)

fig
end # hide
save(joinpath(@OUTPUT, "example_11872547240983249710.png"), __result; ) # hide

nothing # hide