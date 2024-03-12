using Makie:
    NoConversion,
    convert_arguments,
    conversion_trait,
    convert_single_argument,
    ClosedInterval

using Logging

@testset "convert_arguments" begin
    #=
    @testset "NoConversion" begin
        # NoConversion
        struct NoConversionTestType end
        conversion_trait(::NoConversionTestType) = NoConversion()

        let nctt = NoConversionTestType(),
            ncttt = conversion_trait(nctt)
            @test convert_arguments(ncttt, 1, 2, 3) == (1, 2, 3)
        end
    end

    # generates 12% test coverage by testing barely anything
    @testset "changing input types" begin
        input = Observable{Any}(decompose(Point2f, Circle(Point2f(0), 2f0)))
        f, ax, pl = mesh(input)
        m = Makie.triangle_mesh(Circle(Point2f(0), 1f0))
        input[] = m
        @test pl[1][] == m
    end
    =#

    #=
    TODO:
    - consider implementing the commented out conversions
    - consider normalizing the conversions with branches here

    Skipped/Missing:
    - PointBased: SubArray{<: VecTypes, 1}
    - Mesh: AbstractVector{<: Union{AbstractMesh, AbstractPolygon}}
    - GridBased: OffsetArray
    - Axis3D: Rect
    =#

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
                        @test convert_arguments(CT, vol)                isa Tuple{ClosedInterval{Float32}, ClosedInterval{Float32}, ClosedInterval{Float32}, Array{Float32, 3}}
                        @test convert_arguments(CT, i, i, i, vol)       isa Tuple{ClosedInterval{Float32}, ClosedInterval{Float32}, ClosedInterval{Float32}, Array{Float32, 3}}
                        @test convert_arguments(CT, xs, ys, zs, vol)    isa Tuple{Vector{Float32}, Vector{Float32}, Vector{Float32}, Array{Float32, 3}}
                        @test convert_arguments(CT, xs, ys, zs, +)      isa Tuple{Vector{Float32}, Vector{Float32}, Vector{Float32}, Array{Float32, 3}}
                        if T_in == Float32
                            @test convert_arguments(CT, r, r, r, vol)   isa Tuple{AbstractRange{Float32}, AbstractRange{Float32}, AbstractRange{Float32}, Array{Float32, 3}}
                            @test convert_arguments(CT, xs, r, i, vol)  isa Tuple{Vector{Float32}, AbstractRange{Float32}, ClosedInterval{Float32}, Array{Float32, 3}}
                        else
                            @test convert_arguments(CT, r, r, r, vol)   isa Tuple{Vector{Float32}, Vector{Float32}, Vector{Float32}, Array{Float32, 3}}
                            @test convert_arguments(CT, xs, r, i, vol)  isa Tuple{Vector{Float32}, Vector{Float32}, ClosedInterval{Float32}, Array{Float32, 3}}
                        end
                    end
                end

                # Mesh

                @testset "Mesh" begin
                    @test convert_arguments(Makie.Mesh, xs, ys, zs) isa Tuple{<: GeometryBasics.NormalMesh{3, T_out}}
                    @test convert_arguments(Makie.Mesh, ps3) isa Tuple{<: GeometryBasics.NormalMesh{3, T_out}}
                    # not NormalMesh? Many of these do have normals
                    @test convert_arguments(Makie.Mesh, _mesh) isa Tuple{<: GeometryBasics.Mesh{3, T_out}}
                    @test convert_arguments(Makie.Mesh, polygon) isa Tuple{<: GeometryBasics.Mesh{2, T_out}}
                    @test convert_arguments(Makie.Mesh, ps2) isa Tuple{<: GeometryBasics.Mesh{2, T_out}}
                    @test convert_arguments(Makie.Mesh, geom) isa Tuple{<: GeometryBasics.Mesh{3, T_out}}
                    @test convert_arguments(Makie.Mesh, ps2, indices) isa Tuple{<: GeometryBasics.Mesh{2, T_out}}

                    @test convert_arguments(Makie.Mesh, xs, ys, zs, indices) isa Tuple{<: GeometryBasics.NormalMesh{3, T_out}}
                    @test convert_arguments(Makie.Mesh, ps3, indices) isa Tuple{<: GeometryBasics.NormalMesh{3, T_out}}
                    # Note: skipping AbstractVector{<: Union{AbstractMesh, AbstractPolygon}} conversion
                end


                ################################################################
                ### recipes
                ################################################################


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

                # TODO:
                # missing from conversions.jl: arrows 2x, GridBase OffsetArray, PointBase SUbarray
                # everything else
                # Voxel?
                # Arrows
                # recipes

            end

        end
    end

end
