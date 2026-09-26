# This file was generated, do not modify it. # hide
points = Node(Point2f[(0, 0)])

fig, ax = scatter(points)
limits!(ax, 0, 30, 0, 30)

frames = 1:30

record(fig, "append_animation.mp4", frames;
        framerate = 30) do frame
    new_point = Point2f(frame, frame)
    points[] = push!(points[], new_point)
end
nothing # hide