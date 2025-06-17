using GeometryBasics, RPRMakie
using Colors, FileIO
using Colors: N0f8

function box!(ax, size)
    orig = Vec3f(-2, -2, 0)
    mesh!(
        ax, Rect3f(orig, Vec3f(size, size, 0.1)); color = :white,
        material = (reflection_color = Vec4f(1), reflection_weight = 10.0f0)
    )
    mesh!(ax, Rect3f(orig, Vec3f(0.1, size, size)); color = :white)
    mesh!(ax, Rect3f(orig, Vec3f(size, 0.1, size)); color = :white)
    return
end

begin
    fig = Figure(; size = (1000, 1000))
    radiance = 100
    lights = Makie.AbstractLight[PointLight(Vec3f(10), RGBf(radiance, radiance, radiance * 1.1))]
    ax = LScene(fig[1, 1]; scenekw = (; lights = lights), show_axis = false)
    points = Point3f[]
    for i in 4:10
        n = i + 1
        y = LinRange(0, i, n)
        y2 = (y ./ 2) .- 2
        xyz = Point3f.((i - 5) ./ 2, y2, sin.(y) .+ 1)
        lp = lines!(ax, xyz; linewidth = 10, color = :white)
        append!(points, xyz)
    end
    mat = (; emission_color = :red, emission_weight = Vec3f(5.0f0))
    meshscatter!(ax, points; material = mat)
    box!(ax, 5)
    RPRMakie.activate!(plugin = RPR.Northstar, iterations = 500, resource = RPR.GPU0)
    ax.scene |> display
end
