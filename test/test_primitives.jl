using Makie

text()
fig, ax, p = meshscatter(1:5, (1:5) .+ 5, rand(5))
fig, ax, p = scatter(1:5, rand(5))
fig, ax, p = mesh(Sphere(Point3f(0), 1.0))
fig, ax, p = linesegments(1:5, rand(5))
fig, ax, p = lines(1:5, rand(5))
fig, ax, p = surface(rand(4, 7))
fig, ax, p = volume(rand(4, 4, 4))
begin
    fig, ax, p = heatmap(rand(4, 4))
    scatter!(Makie.point_iterator(p) |> collect, color=:red, markersize=10)
    display(fig)
end

fig, ax, p = image(rand(4, 5))
scatter!(Makie.point_iterator(p) |> collect, color=:red, markersize=10)
display(fig)

begin
    fig, ax, p = scatter(1:5, rand(5))
    linesegments!(Makie.data_limits(ax.scene), color=:red)
    display(fig)
end
