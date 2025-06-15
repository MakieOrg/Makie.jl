scene = Scene(camera = campixel!)

# Components
poly!(
    scene, Point2f[(50, 150), (150, 200), (150, 300), (50, 350), (50, 150)],
    color = :lightgreen, strokecolor = :green, strokewidth = 2
)
poly!(
    scene, Point2f[(200, 200), (400, 200), (400, 300), (200, 300), (200, 200)],
    color = :lightblue, strokecolor = :blue, strokewidth = 2
)
poly!(
    scene, Point2f[(450, 150), (550, 250), (450, 350), (450, 150)],
    color = (:red, 0.3), strokecolor = :red, strokewidth = 2
)
text!(
    scene, [100, 300, 500], [400, 400, 400], text = ["tail", "shaft", "tip"],
    fontsize = 20, align = (:center, :center)
)

# widths
errorbars!(
    scene, [50, 200, 450] .- 15, [250, 250, 250], [100, 50, 100],
    direction = :y, color = :black, whiskerwidth = 10
)
text!(
    scene, [50, 200, 450] .- 30, [250, 250, 250], text = ["tailwidth", "shaftwidth", "tipwidth"],
    fontsize = 16, align = (:center, :center), rotation = pi / 2
)

# lengths
rangebars!(
    scene, [150, 150, 150] .- 15, [50, 200, 450], [150, 400, 550],
    direction = :x, color = :black, whiskerwidth = 10
)
text!(
    scene, [100, 300, 500], [150, 150, 150] .- 30, text = ["taillength", "shaftlength = automatic", "tiplength"],
    fontsize = 16, align = (:center, :center)
)

# align
rangebars!(
    scene, [80], [50], [550],
    direction = :x, color = :black, whiskerwidth = 10
)
text!(
    scene, [50, 300, 550], [80, 80, 80] .- 15, text = ["0", "align", "1"],
    fontsize = 16, align = (:center, :center)
)

# scale
rangebars!(
    scene, [30], [50], [550],
    direction = :x, color = :black, whiskerwidth = 10
)
text!(
    scene, [300], [30] .- 15, text = ["lengthscale * norm(direction)"],
    fontsize = 16, align = (:center, :center)
)

Makie.save("arrow_components.png", scene)
