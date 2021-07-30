# Layout Tutorial

In this tutorial, we will see some of the capabilities of layouts in Makie while
building a complex figure step by step. This is the final result we will create:


\begin{examplefigure}{}
```julia
using CairoMakie
using FileIO
CairoMakie.activate!() # hide

noto_sans = assetpath("fonts", "NotoSans-Regular.ttf")
noto_sans_bold = assetpath("fonts", "NotoSans-Bold.ttf")

f = Figure(backgroundcolor = RGBf0(0.98, 0.98, 0.98),
    resolution = (1000, 700), font = noto_sans)

s1 = f[1, 1] = GridLayout(default_rowgap = 10, default_colgap = 10)

ax = Axis(s1[2, 1])
axtop = Axis(s1[1, 1])
axright = Axis(s1[2, 2])

linkxaxes!(ax, axtop)
linkyaxes!(ax, axright)

data = randn(3, 100, 2) .+ [1, 3, 5]
labels = ["alpha", "beta", "gamma"]

for (label, col) in zip(labels, eachslice(data, dims = 1))
    scatter!(ax, col, label = label)
    density!(axtop, col[:, 1])
    density!(axright, col[:, 2], direction = :y)
end

hidedecorations!(axright, grid = false)
hidedecorations!(axtop, grid = false)
tightlimits!(axright, Left())
tightlimits!(axtop, Bottom())

ax.width = 200

Legend(s1[1, 2], ax, tellheight = true,
    halign = :left, valign = :bottom)

xs = LinRange(0.5, 6, 50)
s = LinRange(0.5, 6, 50)
data1 = [sin(x^1.5) * cos(y^0.5) for x in xs, y in ys] .+ 0.1 .* randn.()
data2 = [sin(x^0.8) * cos(y^1.5) for x in xs, y in ys] .+ 0.1 .* randn.()

s2 = f[2, 1] = GridLayout(default_rowgap = 10, default_colgap = 10)
ax1, hm = contourf(s2[1, 1], xs, ys, data1,
    levels = 6)
ax1.title = "Histological analysis"
contour!(xs, ys, data1, levels = 5, color = :black)
hidexdecorations!(ax1)

_, hm2 = contourf(s2[2, 1], xs, ys, data2,
    levels = 6)
contour!(xs, ys, data2, levels = 5, color = :black)

Colorbar(s2[1:2, 2], hm2, label = "cell group",
    alignmode = Mixed(right = 0))

brain = load(assetpath("brain.stl"))

s3 = f[1:2, 2] = GridLayout()
Axis3(s3[1, 1], title = "Brain activation")
m = mesh!(
    brain,
    color = [tri[1][2] for tri in brain for i in 1:3],
    colormap = Reverse(:magma),
)
Colorbar(s3[1, 2], m, label = "BOLD level")

rowsize!(s3, 1, Auto(1.5))

s4 = s3[2, 1:2] = GridLayout()

axs = [Axis(s4[row, col]) for row in 1:3, col in 1:2]
hidedecorations!.(axs, grid = false, label = false)

for ax in axs
    d = [sum(sin(pi * rand() + k * x) / k for k in 1:10) for x in 0:0.1:10pi] .+ 0.1 .* randn.()
    lines!(ax, d, color = (:black, 0.5))
end

axs[3, 1].xlabel = "Day 1"
axs[3, 2].xlabel = "Day 2"

rowgap!(s4, 5)
colgap!(s4, 5)

Label(s4[1, :, Top()], "EEG traces")

for (i, label) in enumerate(["sleep", "awake", "test"])
    Box(s4[i, 3], color = :gray90)
    Label(s4[i, 3], label, rotation = pi/2, tellheight = false)
end
colgap!(s4, 2, 0)

Label(s1[1, 1, TopLeft()], "A", textsize = 26, font = noto_sans_bold,
 padding = (0, 5, 5, 0), halign = :right)
Label(s2[1, 1, TopLeft()], "B", textsize = 26, font = noto_sans_bold,
 padding = (0, 5, 5, 0), halign = :right)
Label(s3[1, 1, TopLeft()], "C", textsize = 26, font = noto_sans_bold,
 padding = (0, 5, 5, 0), halign = :right)
Label(s4[1, 1, TopLeft()], "D", textsize = 26, font = noto_sans_bold,
 padding = (0, 5, 5, 0), halign = :right)

colsize!(f.layout, 1, Auto(0.8))


f
```
\end{examplefigure}
