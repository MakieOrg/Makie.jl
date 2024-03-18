using Makie:
    NoConversion,
    convert_arguments,
    conversion_trait,
    convert_single_argument,
    ClosedInterval

using Logging

@testset "convert_arguments" begin
    #=
    TODO:
    - consider implementing the commented out conversions
    - consider normalizing the conversions with branches here

    Skipped/Missing:
    - PointBased: SubArray{<: VecTypes, 1}
    - Mesh: AbstractVector{<: Union{AbstractMesh, AbstractPolygon}}
    - GridBased: OffsetArray
    - Axis3D: Rect
    - datashader
    - rainclouds
    - stats plots
    =#

    function test_mesh_result(mesh_convert, dim, eltype, assert_normals = false)
        @test mesh_convert isa Tuple{<: GeometryBasics.Mesh{dim, eltype}}
        if assert_normals || !isnothing(normals(mesh_convert))
            @test normals(mesh_convert[1]) isa Vector{Vec3f}
        end
        if !isnothing(texturecoordinates(mesh_convert[1]))
            @test texturecoordinates(mesh_convert[1]) isa Vector{Vec2f}
        end
        return
    end

    indices = [1, 2, 3, 2, 3, 4, 5, 6, 7, 8, 9, 10]
    str = "test"
    strings = ["test" for _ in 1:10]

    @testset "input type -> output type" begin
        for (T_in, T_out) in [
                Float32 => Float32, Float64 => Float64,
                UInt32 => Float64, Int32 => Float64, Int64 => Float64
            ]

            @testset "$T_in => $T_out" begin

                # COV_EXCL_START
                xs = rand(T_in, 10)
                ys = rand(T_in, 10)
                zs = rand(T_in, 10)
                v32 = rand(Float32, 10)
                vt = rand(T_in, 1, 10)
                miss = vcat(v32[1:4], missing, zs[6:end])
                nan = vcat(xs[1:4], NaN, zs[6:end])
                r = T_in(1):T_in(1):T_in(10)
                i = T_in(1)..T_in(10)

                ps2 = Point2.(xs, ys)
                ps3 = Point3.(xs, ys, zs)
                miss2 = vcat(Point2.(xs, ys), missing)

                rect2 = Rect2{T_in}(0, 0, 1, 1)
                rect3 = Rect3{T_in}(Point3{T_in}(0), Vec3{T_in}(1))
                geom = Sphere(Point3{T_in}(0), T_in(1))
                _mesh = GeometryBasics.mesh(rect3; pointtype=Point3{T_in}, facetype=GLTriangleFace)
                polygon = Polygon(Point2.(xs, ys))
                line = LineString(Point3.(xs, ys, zs))
                bp = BezierPath([
                    MoveTo(T_in(0), T_in(0)),
                    LineTo(T_in(1), T_in(0)),
                    CurveTo(T_in(1), T_in(1), T_in(0), T_in(1), T_in(3), T_in(0)),
                    EllipticalArc(Point2(T_in(0)), T_in(1), T_in(1), T_in(0), T_in(0), T_in(1)),
                    ClosePath()
                ])

                xgridvec = [x for x in T_in(1):T_in(3) for y in T_in(1):T_in(3)]
                ygridvec = [y for x in T_in(1):T_in(3) for y in T_in(1):T_in(3)]

                m = rand(T_in, 10, 10)
                m2 = rand(T_in, 2, 10)
                m3 = rand(T_in, 10, 3)

                img = rand(RGBf, 10, 10)
                vol = rand(T_in, 10, 10, 10)
                sparse = Makie.SparseArrays.SparseMatrixCSC(m)

                # COV_EXCL_STOP

                ################################################################
                ### primitives
                ################################################################

                # PointBased and Friends

                for CT in (PointBased(), Scatter, MeshScatter, Lines, LineSegments)
                    @testset "$CT" begin
                        # TODO: (missing)
                        # - FaceView
                        # - SubArra{<: VecTypes}

                        @test convert_arguments(CT, xs[1], xs[2])           isa Tuple{Vector{Point2{T_out}}}
                        @test convert_arguments(CT, xs[1], xs[2], xs[3])    isa Tuple{Vector{Point3{T_out}}}
                        @test convert_arguments(CT, ps2[1])                 isa Tuple{Vector{Point2{T_out}}}
                        @test convert_arguments(CT, ps3[1])                 isa Tuple{Vector{Point3{T_out}}}

                        # because indices are Int we end up converting to Float64 no matter what
                        @test convert_arguments(CT, xs)         isa Tuple{Vector{Point2{Float64}}}

                        @test convert_arguments(CT, xs, ys)     isa Tuple{Vector{Point2{T_out}}}
                        @test convert_arguments(CT, xs, v32)    isa Tuple{Vector{Point2{T_out}}}
                        @test convert_arguments(CT, i, ys)      isa Tuple{Vector{Point2{T_out}}}
                        @test convert_arguments(CT, xs, i)      isa Tuple{Vector{Point2{T_out}}}
                        @test convert_arguments(CT, r, ys)      isa Tuple{Vector{Point2{T_out}}}
                        # @test convert_arguments(CT, vt, ys)     isa Tuple{Vector{Point2{T_out}}}
                        # @test convert_arguments(CT, m, m)       isa Tuple{Vector{Point2{T_out}}}

                        @test convert_arguments(CT, xs, ys, zs)     isa Tuple{Vector{Point3{T_out}}}
                        @test convert_arguments(CT, vt, ys, vt)     isa Tuple{Vector{Point3{T_out}}}
                        @test convert_arguments(CT, xs, ys, vt)     isa Tuple{Vector{Point3{T_out}}}
                        @test convert_arguments(CT, xs, ys, v32)    isa Tuple{Vector{Point3{T_out}}}
                        @test convert_arguments(CT, r, v32, zs)     isa Tuple{Vector{Point3{T_out}}}
                        @test convert_arguments(CT, m, m, m)        isa Tuple{Vector{Point3{T_out}}}
                        # TODO: Does this make sense?
                        @test convert_arguments(CT, i, i, m)        isa Tuple{Vector{Point3{T_out}}}
                        # @test convert_arguments(CT, r, i, zs)       isa Tuple{Vector{Point3{T_out}}}
                        # @test convert_arguments(CT, i, i, zs)       isa Tuple{Vector{Point3{T_out}}}

                        # TODO: implement as PointBased conversion?
                        if CT !== PointBased()
                            @test convert_arguments(CT, xs, identity) isa Tuple{Vector{Point2{T_out}}}
                            @test convert_arguments(CT, r, identity)  isa Tuple{Vector{Point2{T_out}}}
                            @test convert_arguments(CT, i, identity)  isa Tuple{Vector{Point2{T_out}}}

                            @test convert_arguments(CT, xs, miss)     isa Tuple{Vector{Point2{T_out}}}
                            @test convert_arguments(CT, miss, ys, zs) isa Tuple{Vector{Point3{T_out}}}

                            @test convert_arguments(CT, miss2)   isa Tuple{Vector{Point2{T_out}}}
                        end

                        @test convert_arguments(CT, ps2)    isa Tuple{Vector{Point2{T_out}}}
                        @test convert_arguments(CT, ps3)    isa Tuple{Vector{Point3{T_out}}}
                        # @test convert_arguments(CT, Point.(miss, ys))   isa Tuple{Vector{Point2{T_out}}}

                        # TODO: Should this be Point?
                        @test convert_arguments(CT, Vec.(xs, ys))     isa Tuple{Vector{Vec2{T_out}}}
                        @test convert_arguments(CT, Vec.(xs, ys, zs)) isa Tuple{Vector{Vec3{T_out}}}
                        # @test convert_arguments(CT, Vec.(miss, ys))   isa Tuple{Vector{Point2{T_out}}}

                        @test convert_arguments(CT, tuple.(xs, ys))      isa Tuple{Vector{Point2{T_out}}}
                        @test convert_arguments(CT, tuple.(xs, v32))     isa Tuple{Vector{Point2{T_out}}}
                        @test convert_arguments(CT, tuple.(xs, ys, zs))  isa Tuple{Vector{Point3{T_out}}}
                        @test convert_arguments(CT, tuple.(v32, ys, zs)) isa Tuple{Vector{Point3{T_out}}}
                        # @test convert_arguments(CT, tuple.(miss, ys))   isa Tuple{Vector{Point2{T_out}}}

                        @test convert_arguments(CT, rect2)      isa Tuple{Vector{Point2{T_out}}}
                        @test convert_arguments(CT, rect3)      isa Tuple{Vector{Point3{T_out}}}
                        @test convert_arguments(CT, geom)       isa Tuple{Vector{Point3{T_out}}}
                        @test convert_arguments(CT, _mesh)      isa Tuple{Vector{Point3{T_out}}}
                        @test convert_arguments(CT, polygon)    isa Tuple{Vector{Point2{T_out}}}
                        @test convert_arguments(CT, [polygon, polygon]) isa Tuple{Vector{Point2{T_out}}}
                        @test convert_arguments(CT, MultiPolygon([polygon, polygon])) isa Tuple{Vector{Point2{T_out}}}
                        @test convert_arguments(CT, line)       isa Tuple{Vector{Point3{T_out}}}
                        @test convert_arguments(CT, [line, line]) isa Tuple{Vector{Point3{T_out}}}
                        @test convert_arguments(CT, MultiLineString([line, line])) isa Tuple{Vector{Point3{T_out}}}
                        @test convert_arguments(CT, bp)         isa Tuple{Vector{Point2d}} # BezierPath uses Float64 internally

                        @test convert_arguments(CT, m2)  isa Tuple{Vector{Point2{T_out}}}
                        @test convert_arguments(CT, m3)  isa Tuple{Vector{Point3{T_out}}}
                    end
                end

                # Special case: LineSegments

                @testset "LineSegments Extras" begin
                    if T_out == T_in
                        @test convert_arguments(LineSegments, Pair.(ps2, ps2))  isa Tuple{<: Base.ReinterpretArray}
                        @test convert_arguments(LineSegments, tuple.(ps2, ps2)) isa Tuple{<: Base.ReinterpretArray}
                    else
                        @test convert_arguments(LineSegments, Pair.(ps2, ps2))  isa Tuple{Vector{Point2{T_out}}}
                        @test convert_arguments(LineSegments, tuple.(ps2, ps2)) isa Tuple{Vector{Point2{T_out}}}
                    end
                end

                # CellGrid & Heatmap

                for CT in (CellGrid(), Heatmap)
                    @testset "$CT" begin
                        @test convert_arguments(CT, m)          isa Tuple{Vector{Float32}, Vector{Float32}, Matrix{Float32}}

                        @test convert_arguments(CT, xs, ys, m)  isa Tuple{Vector{T_out}, Vector{T_out}, Matrix{Float32}}
                        @test convert_arguments(CT, xs, r, m)   isa Tuple{Vector{T_out}, Vector{T_out}, Matrix{Float32}}
                        @test convert_arguments(CT, r, ys, +)   isa Tuple{Vector{T_out}, Vector{T_out}, Matrix{Float32}}
                        @test convert_arguments(CT, i, r, m)    isa Tuple{Vector{T_out}, Vector{T_out}, Matrix{Float32}}
                        @test convert_arguments(CT, i, i, m)    isa Tuple{Vector{T_out}, Vector{T_out}, Matrix{Float32}}
                        @test convert_arguments(CT, r, i, m)    isa Tuple{Vector{T_out}, Vector{T_out}, Matrix{Float32}}
                        @test convert_arguments(CT, xgridvec, ygridvec, xgridvec) isa Tuple{Vector{T_out}, Vector{T_out}, Matrix{Float32}}
                        # TODO OffsetArray
                    end
                end

                # VertexGrid

                for CT in (VertexGrid(), Surface)
                    @testset "$CT" begin
                        @test convert_arguments(CT, xs, ys, m)  isa Tuple{Vector{T_out}, Vector{T_out}, Matrix{Float32}}
                        @test convert_arguments(CT, m, m)       isa Tuple{Matrix{T_out}, Matrix{T_out}, Matrix{Float32}}
                        # TODO: Should these be normalized to Vector?
                        if T_in == T_out
                            @test convert_arguments(CT, xs, r, m)   isa Tuple{Vector{T_out}, AbstractRange{T_out}, Matrix{Float32}}
                            @test convert_arguments(CT, r, ys, +)   isa Tuple{AbstractRange{T_out}, Vector{T_out}, Matrix{Float32}}
                        else
                            @test convert_arguments(CT, xs, r, m)   isa Tuple{Vector{T_out}, Vector{T_out}, Matrix{Float32}}
                            @test convert_arguments(CT, r, ys, +)   isa Tuple{Vector{T_out}, Vector{T_out}, Matrix{Float32}}
                        end
                        @test convert_arguments(CT, m)          isa Tuple{AbstractRange{Float32}, AbstractRange{Float32}, Matrix{Float32}}
                        @test convert_arguments(CT, i, r, m)    isa Tuple{AbstractRange{T_out}, AbstractRange{T_out}, Matrix{Float32}}
                        @test convert_arguments(CT, i, i, m)    isa Tuple{AbstractRange{T_out}, AbstractRange{T_out}, Matrix{Float32}}
                        @test convert_arguments(CT, r, i, m)    isa Tuple{AbstractRange{T_out}, AbstractRange{T_out}, Matrix{Float32}}
                        @test convert_arguments(CT, xgridvec, ygridvec, xgridvec) isa Tuple{Vector{T_out}, Vector{T_out}, Matrix{Float32}}
                        # TODO OffsetArray
                    end
                end

                # ImageLike, Image

                for CT in (ImageLike(), Image)
                    @testset "$CT" begin
                        @test convert_arguments(CT, img)        isa Tuple{ClosedInterval{Float32}, ClosedInterval{Float32}, Matrix{RGBf}}
                        @test convert_arguments(CT, m)          isa Tuple{ClosedInterval{Float32}, ClosedInterval{Float32}, Matrix{Float32}}
                        @test convert_arguments(CT, i, i, m)    isa Tuple{ClosedInterval{T_out}, ClosedInterval{T_out}, Matrix{Float32}}

                        # deprecated
                        Logging.disable_logging(Logging.Warn) # skip warnings
                        @test convert_arguments(CT, xs, ys, m)  isa Tuple{ClosedInterval{T_out}, ClosedInterval{T_out}, Matrix{Float32}}
                        @test convert_arguments(CT, xs, r, m)   isa Tuple{ClosedInterval{T_out}, ClosedInterval{T_out}, Matrix{Float32}}
                        @test convert_arguments(CT, i, r, m)    isa Tuple{ClosedInterval{T_out}, ClosedInterval{T_out}, Matrix{Float32}}
                        @test convert_arguments(CT, r, i, m)    isa Tuple{ClosedInterval{T_out}, ClosedInterval{T_out}, Matrix{Float32}}
                        @test convert_arguments(CT, r, ys, +)   isa Tuple{ClosedInterval{T_out}, ClosedInterval{T_out}, Matrix{Float32}}
                        Logging.disable_logging(Logging.Debug)
                    end
                end

                # VolumeLike, Volume

                for CT in (VolumeLike(), Volume)
                    @testset "$CT" begin
                        # TODO: Should these be normalized more?
                        convert_arguments(CT, vol) isa Tuple{ClosedInterval,ClosedInterval,ClosedInterval,Array{Float32,3}}
                        @test convert_arguments(CT, i, i, i, vol) isa Tuple{ClosedInterval,ClosedInterval,ClosedInterval,Array{Float32,3}}
                        @test convert_arguments(CT, xs, ys, zs, vol) isa Tuple{ClosedInterval,ClosedInterval,ClosedInterval,Array{Float32,3}}
                        @test convert_arguments(CT, xs, ys, zs, +) isa Tuple{ClosedInterval,ClosedInterval,ClosedInterval,Array{Float32,3}}
                        if T_in == Float32
                            @test convert_arguments(CT, r, r, r, vol) isa Tuple{ClosedInterval,ClosedInterval,ClosedInterval,Array{Float32,3}}
                            @test convert_arguments(CT, xs, r, i, vol) isa Tuple{ClosedInterval,ClosedInterval,ClosedInterval,Array{Float32,3}}
                        else
                            @test convert_arguments(CT, r, r, r, vol) isa Tuple{ClosedInterval,ClosedInterval,ClosedInterval,Array{Float32,3}}
                            @test convert_arguments(CT, xs, r, i, vol) isa Tuple{ClosedInterval,ClosedInterval,ClosedInterval,Array{Float32,3}}
                        end
                    end
                end

                # Mesh

                @testset "Mesh" begin
                    test_mesh_result(convert_arguments(Makie.Mesh, xs, ys, zs), 3, T_out, true)
                    test_mesh_result(convert_arguments(Makie.Mesh, ps3), 3, T_out, true)
                    test_mesh_result(convert_arguments(Makie.Mesh, _mesh), 3, T_out, true)
                    test_mesh_result(convert_arguments(Makie.Mesh, geom), 3, T_out, true)
                    test_mesh_result(convert_arguments(Makie.Mesh, xs, ys, zs, indices), 3, T_out, true)
                    test_mesh_result(convert_arguments(Makie.Mesh, ps3, indices), 3, T_out, true)

                    test_mesh_result(convert_arguments(Makie.Mesh, polygon), 2, T_out)
                    test_mesh_result(convert_arguments(Makie.Mesh, ps2), 2, T_out)
                    test_mesh_result(convert_arguments(Makie.Mesh, ps2, indices), 2, T_out)
                end

                # internally converted
                @testset "Text" begin
                    @test convert_arguments(Makie.Text, tuple.(strings, ps2)) isa Tuple{Vector{Tuple{String, Point2{T_in}}}}
                    @test convert_arguments(Makie.Text, tuple.(strings, ps3)) isa Tuple{Vector{Tuple{String, Point3{T_in}}}}
                end


                ################################################################
                ### recipes
                ################################################################

                # If a recipe transforms its input arguments it is fine for it
                # to keep T_in in convert_arguments.

                @testset "Annotations" begin
                    @test convert_arguments(Annotations, strings, ps2) isa Tuple{Vector{Tuple{String, Point{2, T_out}}}}
                    @test convert_arguments(Annotations, strings, ps3) isa Tuple{Vector{Tuple{String, Point{3, T_out}}}}
                end

                @testset "Arrows" begin
                    @test convert_arguments(Arrows, xs, ys, xs, ys) isa Tuple{Vector{Point2{T_out}}, Vector{Vec2{T_out}}}
                    @test convert_arguments(Arrows, xs, ys, m, m) isa Tuple{Vector{Point2{T_out}}, Vector{Vec2{T_out}}}
                    @test convert_arguments(Arrows, xs, ys, zs, xs, ys, zs) isa Tuple{Vector{Point3{T_out}}, Vector{Vec3{T_out}}}
                    @test convert_arguments(Arrows, xs, ys, identity) isa Tuple{Vector{Point2{T_out}}, Vector{Vec2{T_out}}}
                    @test convert_arguments(Arrows, xs, ys, zs, identity) isa Tuple{Vector{Point3{T_out}}, Vector{Vec3{T_out}}}
                end

                @testset "Band" begin
                    @test convert_arguments(Band, xs, ys, zs) isa Tuple{Vector{Point2{T_out}}, Vector{Point2{T_out}}}
                end

                @testset "Bracket" begin
                    @test convert_arguments(Bracket, ps2[1], ps2[2])             isa Tuple{Vector{Tuple{Point2{T_out}, Point2{T_out}}}}
                    @test convert_arguments(Bracket, xs[1], ys[1], xs[2], ys[2]) isa Tuple{Vector{Tuple{Point2{T_out}, Point2{T_out}}}}
                    @test convert_arguments(Bracket, xs, ys, xs, ys)             isa Tuple{Vector{Tuple{Point2{T_out}, Point2{T_out}}}}
                end

                @testset "Errorbars & Rangebars" begin
                    @test convert_arguments(Errorbars, xs, ys, zs)      isa Tuple{Vector{Vec4{T_out}}}
                    @test convert_arguments(Errorbars, xs, ys, xs, ys)  isa Tuple{Vector{Vec4{T_out}}}
                    @test convert_arguments(Errorbars, xs, ys, ps2)     isa Tuple{Vector{Vec4{T_out}}}
                    @test convert_arguments(Errorbars, ps2, zs)         isa Tuple{Vector{Vec4{T_out}}}
                    @test convert_arguments(Errorbars, ps2, xs, ys)     isa Tuple{Vector{Vec4{T_out}}}
                    @test convert_arguments(Errorbars, ps2, ps2)        isa Tuple{Vector{Vec4{T_out}}}
                    @test convert_arguments(Errorbars, ps3)             isa Tuple{Vector{Vec4{T_out}}}

                    @test convert_arguments(Rangebars, xs, ys, zs)      isa Tuple{Vector{Vec3{T_out}}}
                    @test convert_arguments(Rangebars, xs, ps2)         isa Tuple{Vector{Vec3{T_out}}}
                end

                @testset "Poly" begin
                    # TODO: Are these ok? All of these are just reflection...
                    @test convert_arguments(Poly, ps2)          isa Tuple{Vector{Point2{T_in}}}
                    @test convert_arguments(Poly, ps3)          isa Tuple{Vector{Point3{T_in}}}
                    @test convert_arguments(Poly, [polygon])    isa Tuple{Vector{typeof(polygon)}}
                    @test convert_arguments(Poly, [rect2])      isa Tuple{Vector{typeof(rect2)}}
                    @test convert_arguments(Poly, polygon)      isa Tuple{typeof(polygon)}
                    @test convert_arguments(Poly, rect2)        isa Tuple{typeof(rect2)}

                    # And these aren't mesh-like
                    @test convert_arguments(Poly, xs, ys)        isa Tuple{Vector{Point2{T_out}}}
                    # Vector{Vector{...}} ?
                    @test convert_arguments(Poly, xs, ys, zs)    isa Tuple{Vector{Vector{Point3{T_out}}}}

                    @test convert_arguments(Poly, ps2, indices)  isa Tuple{<: GeometryBasics.Mesh{2, T_out}}
                    @test convert_arguments(Poly, ps3, indices)  isa Tuple{<: GeometryBasics.Mesh{3, T_out}}
                end

                @testset "Series" begin
                    @test convert_arguments(Series, m)          isa Tuple{Vector{Vector{Point2{Float64}}}}
                    @test convert_arguments(Series, xs, m)      isa Tuple{Vector{Vector{Point2{T_out}}}}
                    @test convert_arguments(Series, miss, m)    isa Tuple{Vector{Vector{Point2{T_out}}}}
                    @test convert_arguments(Series, [(xs, ys)]) isa Tuple{Vector{Vector{Point2{T_out}}}}
                    @test convert_arguments(Series, (xs, ys))   isa Tuple{Vector{Vector{Point2{T_out}}}}
                    @test convert_arguments(Series, [ps2, ps2]) isa Tuple{Vector{Vector{Point2{T_out}}}}
                end

                @testset "Spy" begin
                    # TODO: assuming internal processing
                    @test convert_arguments(Spy, sparse)            isa Tuple{ClosedInterval{Int}, ClosedInterval{Int}, typeof(sparse)}
                    @test convert_arguments(Spy, xs, ys, sparse)    isa Tuple{typeof(xs), typeof(ys), typeof(sparse)}
                end

                @testset "StreamPlot" begin
                    # TODO: these have a different argument order than other Function plots...
                    @test convert_arguments(StreamPlot, identity, xs, ys)       isa Tuple{typeof(identity), Rect2{T_in}}
                    @test convert_arguments(StreamPlot, identity, i, r)         isa Tuple{typeof(identity), Rect2{T_in}}
                    @test convert_arguments(StreamPlot, identity, xs, ys, zs)   isa Tuple{typeof(identity), Rect3{T_in}}
                    @test convert_arguments(StreamPlot, identity, r, i, zs)     isa Tuple{typeof(identity), Rect3{T_in}}
                    @test convert_arguments(StreamPlot, identity, rect2)        isa Tuple{typeof(identity), Rect2{T_in}}
                    @test convert_arguments(StreamPlot, identity, rect3)        isa Tuple{typeof(identity), Rect3{T_in}}
                end

                @testset "Tooltip" begin
                    @test convert_arguments(Tooltip, xs[1], ys[1], str) isa Tuple{Point2{T_out}, String}
                    @test convert_arguments(Tooltip, xs[1], ys[1])      isa Tuple{Point2{T_out}}
                end

                @testset "Tricontourf" begin
                    @test convert_arguments(Tricontourf, xs, ys, zs) isa Tuple{<: Makie.DelTri.Triangulation{Matrix{T_out}}, Vector{T_out}}
                end

                @testset "Triplot" begin
                    @test convert_arguments(Triplot, ps2)       isa Tuple{Vector{Point2{T_out}}}
                    @test convert_arguments(Triplot, xs, ys)    isa Tuple{Vector{Point2{T_out}}}
                    # TODO: DelTri.Triangulation
                end

                @testset "Voronoiplot" begin
                    @test convert_arguments(Voronoiplot, m)             isa Tuple{Vector{Point3{Float64}}}
                    @test convert_arguments(Voronoiplot, xs, ys, zs)    isa Tuple{Vector{Point3{T_out}}}
                    @test convert_arguments(Voronoiplot, xs, ys)        isa Tuple{Vector{Point2{T_out}}}
                    @test convert_arguments(Voronoiplot, ps2)           isa Tuple{Vector{Point2{T_out}}}
                    @test convert_arguments(Voronoiplot, ps3)           isa Tuple{Vector{Point3{T_out}}}
                    # TODO: VoronoiTessellation
                end

                # pure 3D plots don't implement Float64 -> Float32 rescaling yet
                @testset "Voxels" begin
                    @test convert_arguments(Voxels, vol)                isa Tuple{ClosedInterval{Float32}, ClosedInterval{Float32}, ClosedInterval{Float32}, Array{UInt8, 3}}
                    @test convert_arguments(Voxels, xs, ys, zs, vol)    isa Tuple{ClosedInterval{Float32}, ClosedInterval{Float32}, ClosedInterval{Float32}, Array{UInt8, 3}}
                    @test convert_arguments(Voxels, i, i, i, vol)       isa Tuple{ClosedInterval{Float32}, ClosedInterval{Float32}, ClosedInterval{Float32}, Array{UInt8, 3}}
                end

                @testset "Wireframe" begin
                    @test convert_arguments(Wireframe, xs, ys, zs) isa Tuple{Vector{T_in}, Vector{T_in}, Vector{T_in}}
                end

            end

        end

        # These have nothing to do with Numeric types...
        @testset "Text" begin
            @test convert_arguments(Makie.Text, str) isa Tuple{String}
            @test convert_arguments(Makie.Text, strings) isa Tuple{Vector{String}}
            # TODO glyphcollection
        end
    end

end
