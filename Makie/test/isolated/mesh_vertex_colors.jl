using Makie
using Makie: color_per_mesh, Pattern, LinePattern

@testset "mesh_vertex_paint_eltype" begin
    @test Makie.mesh_vertex_paint_eltype(RGBAf[RGBAf(1, 0, 0, 1), RGBAf(0, 1, 0, 1)]) === RGBAf
    p1 = Pattern('x')
    p2 = Pattern('/')
    @test Makie.mesh_vertex_paint_eltype(LinePattern[p1, p2]) === LinePattern
    v = Any[RGBAf(1, 0, 0, 1), p1]
    @test Makie.mesh_vertex_paint_eltype(v) == Union{RGBAf, LinePattern}
end

@testset "color_per_mesh" begin
    verts = [4, 4, 4, 4]
    colors = RGBAf[RGBAf(1, 0, 0, 1), RGBAf(0, 1, 0, 1), RGBAf(0, 0, 1, 1), RGBAf(1, 1, 0, 1)]
    expanded = color_per_mesh(colors, verts)
    @test length(expanded) == 16
    @test all(==(RGBAf(1, 0, 0, 1)), expanded[1:4])
    @test all(==(RGBAf(0, 1, 0, 1)), expanded[5:8])

    pats = [Pattern('x'), Pattern('/'), Pattern('-'), Pattern('+')]
    expanded_p = color_per_mesh(pats, verts)
    @test length(expanded_p) == 16
    @test all(i -> expanded_p[i] == pats[1], 1:4)

    mixed = Any[RGBAf(1, 0, 0, 1), RGBAf(0, 1, 0, 1), Pattern('x'), Pattern('/')]
    expanded_m = color_per_mesh(mixed, verts)
    @test length(expanded_m) == 16
    @test expanded_m[1] isa RGBAf
    @test expanded_m[9] isa LinePattern
end

@testset "barplot and poly with patterns (no display)" begin
    fig = Figure()
    ax = Axis(fig[1, 1])
    vals = [1, 2, 3, 4]
    @test barplot!(ax, vals, color = [Pattern('x'), Pattern('/'), Pattern('-'), Pattern('+')]) isa BarPlot
end

@testset "barplot mixed solid colors and LinePattern (resolve)" begin
    fig = Figure()
    ax = Axis(fig[1, 1])
    @test barplot!(ax, 1:2, color = [:red, Pattern('x')]) isa BarPlot
    fig2 = Figure()
    ax2 = Axis(fig2[1, 1])
    pattern = Pattern('x', backgroundcolor = :white)
    @test barplot!(ax2, 1:4, color = [:red, :green, :blue, pattern]) isa BarPlot
    fig3 = Figure()
    ax3 = Axis(fig3[1, 1])
    @test barplot!(
        ax3, 1:4, color = [:red, :green, Makie.Pattern('x', backgroundcolor = :orange), Makie.Pattern('/')],
    ) isa BarPlot
end
