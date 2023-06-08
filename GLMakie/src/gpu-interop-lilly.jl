using GLMakie, StaticArrays


fig = Figure(resolution=(800,600))
ax = Axis(fig[1, 1]; limits=(0, 1, 0, 1),autolimitaspect = 1)
hidedecorations!(ax)
ax.scene.clear[] = false
ax.blockscene.clear[] = false
fig.scene.clear[] = false

N = 1024
p = rand(Point2f, N)
dp = Point2f(0.005, 0.01)
p1 = p .+ Ref(dp)
sp = scatter!(ax, p1, color=:black)
display(fig)
for i in 1:20
    p .= p1
    p1 .+= Ref(dp)
    sp[1] = p1
    sleep(1/60)
end
