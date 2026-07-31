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
