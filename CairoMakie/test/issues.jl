@testset "plotlist no ambiguity (#4038)" begin
    f = plotlist([Makie.SpecApi.Scatter(1:10)])
    Makie.colorbuffer(f; backend=CairoMakie)
    plotlist!([Makie.SpecApi.Scatter(1:10)])
end

@testset "multicolor line clipping (#4313)" begin
    fig, ax, p = contour(rand(20, 20))
    xlims!(ax, 0, 10)
    Makie.colorbuffer(fig; backend = CairoMakie)
end

@testset "scatter with all points clipped (#XXXX)" begin
    fig = Figure()
    ax = Axis3(fig[1, 1])
    # all points outside the clip volume -> unclipped_indices is empty
    scatter!(ax, [0.5, 0.5], [0.5, 0.5], [-10.0, -10.0])
    limits!(ax, 0, 1, 0, 1, 0, 1)
    Makie.colorbuffer(fig; backend = CairoMakie)
    # broadcast_foreach_index returns without error on empty indices
    @test Makie.broadcast_foreach_index((args...) -> error("unreachable"), UInt32[], 1:3, 1:3) === nothing
end

@testset "Float64 normals #5797" begin
    m = normal_mesh(Sphere(Point3f(0), 1f0), normaltype = Vec3d)
    f, a, p = mesh(m)
    @assert eltype(p.normals[]) === Vec3d
    colorbuffer(f) # should not error
end