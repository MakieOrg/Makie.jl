using Makie, GeometryTypes, Colors

scene = Scene()
# this is just a work around that will be gone immediatly after I figure out how to best
# insert default cameras into the scene
r = linspace(0, 3, 4)
a = axis(r, r)
center!(scene, 0.2)

pos = lift_node(getindex.(scene, (:mouseposition, :time, :camera))...) do mpos, t, cam
    map(linspace(0, 2pi, 60)) do i
        circle = Point2f0(sin(i), cos(i))
        mouse = to_world(Point2f0(mpos), cam)
        secondary = (sin((i * 10f0) + t) * 0.09) * normalize(circle)
        (secondary .+ circle) .+ mouse
    end
end


p1 = lines(pos)
p2 = scatter(
    pos, markersize = 0.1f0,
    marker = :star5,
    color = lift_node(x-> x .+ 0.2, p1[:color])
)


p1[:color] = RGBA(1, 0, 0, 0.1)
p2[:marker] = 'π'
p2[:markersize] = 0.2
p2[:marker] = 'o'

for i = linspace(0.01, 0.4, 100)
    p2[:markersize] = i
    yield()
    sleep(0.01)
end

