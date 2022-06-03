t_using = (tstart = time(); using CairoMakie; time() - tstart)

function test()
    screen = display(scatter(1:4; color=1:4, colormap=:turbo, markersize=20, visible=true))
    Makie.colorbuffer(screen)
end
t_plot = (tstart = time(); test(); time() - tstart)
using BenchmarkTools

b = @btime test()

rm("test.png")
println("($t_using, $t_plot)")
