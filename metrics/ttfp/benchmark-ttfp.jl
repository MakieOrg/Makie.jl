
t_using = (tstart = time(); using CairoMakie; time() - tstart)

t_plot = (tstart = time(); save("test.png", scatter(1:4)); time() - tstart)
rm("test.png")
print("($t_using, $t_plot)")
