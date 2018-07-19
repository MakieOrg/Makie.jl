scene = text(
    "boundingbox", raw = true,
    align = (:left, :center),
    position = (200, 150)
)
campixel!(scene)
linesegments!(boundingbox(scene), raw = true)

offset = 0
for a_lign in (:center, :left, :right), b_lign in (:center, :left, :right)
    t = text!(
        "boundingbox", raw = true,
        align = (a_lign, b_lign),
        position = (200, 200 + offset)
    )[end]
    linesegments!(boundingbox(t), raw = true)
    offset += 50
end
offset
a = Point2f0.(200, 150:50:offset)
b = Point2f0.(0, 150:50:offset)
c = Point2f0.(500, 150:50:offset)
yrange = 150:50:offset
#axis2d!(linspace(0, 500, length(yrange)), yrange)


mesh(IRect(0, 0, 200, 200))

poly(IRect(0, 0, 200, 200), linewidth = 5, linecolor = :red, color = (:black, 0.4))


scene = poly([Rect(0, 0, 20, 20)])
scene = scatter!(Rect(0, 0, 20, 20), color = :red, markersize = 2, raw = true)


scatter(rand(10), color = rand(10), colorrange = nothing, colormap = :Spectral)


import RDatasets
singers = RDatasets.dataset("lattice","singer")
x = singers[:VoicePart]
x2 = sort(collect(unique(x)))
xidx = map(x-> findfirst(x2, x), x)
boxplot(xidx, singers[:Height], strokewidth = 2, strokecolor = :green)
wireframe(Rect(0, 0, 10, 10), linewidth = 10, color = :gray)
using Makie
scene = poly([Rect(-2, -2, 9, 14)], strokewidth = 0.0, scale_plot = false, color = (:black, 0.4))
poly!([Rect(5, 0, -5, 10)], strokewidth = 2, strokecolor = (:gray, 0.4), color = :white, scale_plot = false)
histogram(rand(100000))
y = rand(10)
x = bar(1:10, y, color = y)

# @test begin
lines(Rect(0, 0, 1, 1), linewidth = 4, scale_plot = false)
scatter!([Point2f0(0.5, 0.5)], markersize = 1, marker = 'I', scale_plot = false)
# end

using Makie
lines(rand(10), rand(10), color = rand(10), linewidth = 10)
lines(rand(10), rand(10), color = rand(RGBAf0, 10), linewidth = 10)
meshscatter(rand(10), rand(10), rand(10), color = rand(10))
meshscatter(rand(10), rand(10), rand(10), color = rand(RGBAf0, 10))
