using Makie
using Makie.GeometryBasics

function two_quads_mesh()
    ps = [Point2f(x, y) for y in 0:1 for x in 0:2]
    quads = [QuadFace{Int}(1, 2, 5, 4), QuadFace{Int}(2, 3, 6, 5)]
    return GeometryBasics.Mesh(ps, quads)
end

nonzero_wings(wing_indices, wing_widths, corner) =
    Set((i, w) for (i, w) in zip(wing_indices[(2corner - 1):2corner], wing_widths[(2corner - 1):2corner]) if i != 0)

@testset "mesh stroke edge data" begin
    @testset "convert_arguments keeps non-triangular faces" begin
        m = Makie.convert_arguments(Makie.Mesh, two_quads_mesh())[1]
        @test eltype(faces(m)) == QuadFace{Int64}
    end

    @testset "two quads" begin
        m = Makie.convert_arguments(Makie.Mesh, two_quads_mesh())[1]
        gl_faces = decompose(GLTriangleFace, m)
        @test gl_faces == GLTriangleFace[(1, 2, 5), (1, 5, 4), (2, 3, 6), (2, 6, 5)]

        widths, wing_indices, wing_widths = Makie.stroke_edge_data(m, gl_faces, :boundary)
        @test widths == Vec3f[(1, 0, 0), (0, 1, 1), (1, 1, 0), (0, 1, 0)]

        widths_all, wing_indices_all, wing_widths_all = Makie.stroke_edge_data(m, gl_faces, :all)
        @test widths_all == Vec3f[(1, 0.5, 0), (0, 1, 1), (1, 1, 0), (0, 1, 0.5)]

        # triangle (2, 6, 5): the bands of boundary edges 2-1 and 2-3 continue across the
        # quad diagonals into this triangle, so corner 2 must carry them as wings
        @test nonzero_wings(wing_indices[4], wing_widths[4], 1) == Set([(1, 1.0f0), (3, 1.0f0)])
        @test nonzero_wings(wing_indices_all[4], wing_widths_all[4], 1) == Set([(1, 1.0f0), (3, 1.0f0)])
    end

    @testset "degenerate edges are not stroked" begin
        pole = Point3f(0, 0, 1)
        ps = [pole, pole, Point3f(1, 0, 0), Point3f(0, 1, 0)]
        m = GeometryBasics.Mesh(ps, [QuadFace{Int}(1, 2, 3, 4)])
        gl_faces = decompose(GLTriangleFace, m)
        @test gl_faces == GLTriangleFace[(1, 2, 3), (1, 3, 4)]
        widths, _, _ = Makie.stroke_edge_data(m, gl_faces, :boundary)
        @test widths[1][1] == 0.0f0
    end

    @testset "out-of-plane wings are dropped" begin
        ps = Point3f[(0, 0, 0), (1, 0, 0), (1, 1, 0), (0, 1, 0), (0, 0, 1), (1, 0, 1), (1, 1, 1), (0, 1, 1)]
        fs = [
            QuadFace{Int}(1, 4, 3, 2), QuadFace{Int}(5, 6, 7, 8),
            QuadFace{Int}(1, 2, 6, 5), QuadFace{Int}(2, 3, 7, 6),
            QuadFace{Int}(3, 4, 8, 7), QuadFace{Int}(4, 1, 5, 8),
        ]
        m = GeometryBasics.Mesh(ps, fs)
        gl_faces = decompose(GLTriangleFace, m)
        @test gl_faces[5] == GLTriangleFace(1, 2, 6)
        _, wing_indices, wing_widths = Makie.stroke_edge_data(m, gl_faces, :all)
        # corner 1 of triangle (1, 2, 6) on the y = 0 face: edge 1-5 lies in the face
        # plane and is kept, edge 1-4 of the perpendicular z = 0 face is dropped
        @test nonzero_wings(wing_indices[5], wing_widths[5], 1) == Set([(5, 0.5f0)])
    end

    @testset "duplicated vertices are matched by position" begin
        ps = [Point2f(x, y) for y in 0:1 for x in 0:2]
        quads = [QuadFace{Int}(1, 2, 5, 4), QuadFace{Int}(2, 3, 6, 5)]
        per_face_normals = GeometryBasics.FaceView(
            [Vec3f(0, 0, 1), Vec3f(0, 0, 1)],
            [QuadFace{Int}(1, 1, 1, 1), QuadFace{Int}(2, 2, 2, 2)]
        )
        m3 = GeometryBasics.Mesh([Point3f(p[1], p[2], 0) for p in ps], quads; normal = per_face_normals)
        m = Makie.convert_arguments(Makie.Mesh, m3)[1]
        @test length(coordinates(m)) == 8
        gl_faces = decompose(GLTriangleFace, m)
        widths, _, _ = Makie.stroke_edge_data(m, gl_faces, :boundary)
        @test widths == Vec3f[(1, 0, 0), (0, 1, 1), (1, 1, 0), (0, 1, 0)]
        widths_all, _, _ = Makie.stroke_edge_data(m, gl_faces, :all)
        @test widths_all == Vec3f[(1, 0.5, 0), (0, 1, 1), (1, 1, 0), (0, 1, 0.5)]
    end

    @testset "band stroke attributes do not reach the inner mesh" begin
        f, ax, pl = band(1:5, fill(0.0, 5), fill(1.0, 5), strokewidth = 3, strokecolor = collect(1.0:5.0))
        inner_mesh, inner_lines = pl.plots
        @test inner_mesh isa Makie.Mesh
        @test inner_mesh.strokewidth[] == 0.0f0
        @test inner_mesh.strokecolor[] == Makie.RGBAf(0, 0, 0, 0)
        @test inner_lines.linewidth[] == 3.0f0
        @test inner_lines.color[] == Float32[1, 2, 3, 4, 5, 1, 1, 2, 3, 4, 5]
    end

    @testset "wings masked by equally wide own edges are dropped" begin
        ps = Point3f[(1, 1, 1), (1, -1, -1), (-1, 1, -1), (-1, -1, 1)]
        fs = GLTriangleFace[(1, 3, 2), (1, 2, 4), (1, 4, 3), (2, 3, 4)]
        m = GeometryBasics.Mesh(ps, fs)
        widths, wing_indices, _ = Makie.stroke_edge_data(m, fs, :all)
        @test widths == fill(Vec3f(0.5), 4)
        @test wing_indices == fill(zero(Vec{6, Int32}), 4)
    end

    @testset "surface stroke data" begin
        zs = Float64[1 4; 2 5; 3 6]
        f, a, pl = surface(1:3, 1:2, zs)
        Makie.register_surface_stroke_data!(pl.attributes)
        @test pl.stroke_edge_widths[] == Vec3f[]
        @test pl.stroke_data_packed[] == fill(Vec4f(0), 9)

        pl.strokewidth = 5
        @test pl.stroke_edge_widths[] == Vec3f[(1, 0, 0), (0, 1, 1), (1, 1, 0), (0, 1, 0)]
        pl.strokeedges = :all
        @test pl.stroke_edge_widths[] == Vec3f[(1, 0.5, 0), (0, 1, 1), (1, 1, 0), (0, 1, 0.5)]

        packed = pl.stroke_data_packed[]
        @test length(packed) == 9 * 2 * 2
        ps = pl.positions_transformed_f32c[]
        for (t, face) in enumerate(pl.stroke_faces[])
            for i in 1:3
                expected_width = pl.stroke_edge_widths[][t][i]
                @test packed[9 * (t - 1) + i] == Vec4f(ps[face[i]]..., expected_width)
            end
        end
    end

    @testset "NaN grid cells get zeroed stroke data slots" begin
        zs = Float64[1 1 1; 1 1 1; 1 1 NaN]
        f, a, pl = surface(1:3, 1:3, zs, strokewidth = 2, strokeedges = :all)
        Makie.register_surface_stroke_data!(pl.attributes)
        @test length(pl.stroke_faces[]) == 6
        packed = pl.stroke_data_packed[]
        @test length(packed) == 9 * 2 * 4
        cell22 = (9 * 2 * 3 + 1):(9 * 2 * 4)
        @test all(iszero, packed[cell22])
        for instance in 0:2
            slots = (9 * 2 * instance + 1):(9 * 2 * (instance + 1))
            @test !all(iszero, packed[slots])
        end
    end

    @testset "stroke_edge_widths computation is gated on strokewidth" begin
        f, ax, pl = mesh(two_quads_mesh())
        @test pl.stroke_edge_widths[] == Vec3f[]
        pl.strokewidth = 5
        @test pl.stroke_edge_widths[] == Vec3f[(1, 0, 0), (0, 1, 1), (1, 1, 0), (0, 1, 0)]
        pl.strokeedges = :all
        @test pl.stroke_edge_widths[] == Vec3f[(1, 0.5, 0), (0, 1, 1), (1, 1, 0), (0, 1, 0.5)]
        pl.strokewidth = 0
        @test pl.stroke_edge_widths[] == Vec3f[]
    end
end
