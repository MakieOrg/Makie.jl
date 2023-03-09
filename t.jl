f = Figure(resolution = (800, 600))
ax = Axis(f[1, 1])
x = range(0, 10, length=100)
y = sin.(x)
lines!(ax, x, y)
limits!(ax,0,10,-1,1 )
f
save("test_fig.png", f, px_per_unit = 2)
