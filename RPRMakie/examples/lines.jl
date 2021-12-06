using GeometryBasics, RPRMakie
using Colors, FileIO
using Colors: N0f8

begin
    fig = Figure(; resolution=(1000, 1000))
    ax = LScene(fig[1, 1])
    points = Point3f[]
    for i in 4:10
        n = i + 1
        y = LinRange(0, i, n)
        y2 = (y ./ 2) .- 2
        xyz = Point3f.((i - 5) ./ 2, y2, sin.(y) .+ 1)
        lines!(ax, xyz; linewidth=5, color=:red)
        append!(points, xyz)
    end
    meshscatter!(ax, points, color=:green)
    ax.scene
end
