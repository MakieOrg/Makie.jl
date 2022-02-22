t_using = @elapsed using CairoMakie
t_plot = @elapsed save("test.png", scatter(1:4))
rm("test.png")
println("($t_using, $t_plot)")
