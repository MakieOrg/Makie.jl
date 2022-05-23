t_using = (tstart = time(); using CairoMakie; time() - tstart)
t_plot = (tstart = time(); save("test.png", scatter(1:4; color=1:4, colormap=:turbo, markersize=20, visible=true)); time() - tstart)
rm("test.png")
println("($t_using, $t_plot)")
