# This file was generated, do not modify it. # hide
__result = begin # hide
  
using CairoMakie
CairoMakie.activate!() # hide
Makie.inline!(true) # hide

scene = Scene(camera = campixel!, show_axis = false, resolution = (800, 800))

points = [Point(x, y) .* 200 for x in 1:3 for y in 1:3]
scatter!(scene, points, marker = :circle, markersize = 10px)

symbols = (:left, :center, :right)

for ((justification, halign), point) in zip(Iterators.product(symbols, symbols), points)

    t = text!(scene, "a\nshort\nparagraph",
        color = (:black, 0.5),
        position = point,
        align = (halign, :center),
        justification = justification)

    bb = boundingbox(t)
    wireframe!(scene, bb, color = (:red, 0.2))
end

for (p, al) in zip(points[3:3:end], (:left, :center, :right))
    text!(scene, "align :" * string(al), position = p .+ (0, 80),
        align = (:center, :baseline))
end

for (p, al) in zip(points[7:9], (:left, :center, :right))
    text!(scene, "justification\n:" * string(al), position = p .+ (80, 0),
        align = (:center, :top), rotation = pi/2)
end

scene

  end # hide
  save(joinpath(@OUTPUT, "example_12580848530414642567.png"), __result) # hide
  
  nothing # hide