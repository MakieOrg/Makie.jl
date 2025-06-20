using Makie
using Makie:
    NoConversion,
    conversion_trait,
    convert_single_argument,
    PointBased,
    EndPoints
using Logging
using Makie.SparseArrays
using GeometryBasics

function apply_conversion(trait, args...)
    expanded = Makie.expand_dimensions(trait, args...)
    if isnothing(expanded)
        return Makie.convert_arguments(trait, args...)
    else
        return Makie.convert_arguments(trait, expanded...)
    end
end

@testset "tuples" begin
    @test convert_arguments(PointBased(), [(1, 2), (1.0, 1.0f0)]) == (Point{2, Float64}[[1.0, 2.0], [1.0, 1.0]],)
end

struct CustomType
    v::Float64
end

Makie.convert_single_argument(c::CustomType) = c.v
Makie.convert_single_argument(cs::AbstractArray{<:CustomType}) = [c.v for c in cs]
# Example of the U type
struct UnitSquare
    origin::Point2
end
function Makie.convert_single_argument(ss::Vector{UnitSquare})
    return map(ss) do s
        return Rect(s.origin..., 1, 1)
    end
end

@testset "single_convert_arguments recursion" begin
    # issue https://github.com/MakieOrg/Makie.jl/issues/3655
    xs = 1:10
    ys = CustomType.(Float64.(1:10))
    @test Makie.convert_arguments(Rangebars, ys, xs .- 1, xs .+ 1)[1] isa Vector{<:Vec3}
    square = UnitSquare(Point2(0, 0))
    data = [square]
    after_conversion = Makie.convert_single_argument(data)
    expected_conversion = [Rect(0, 0, 1, 1)]
    # Although the types are the same
    @test typeof(after_conversion) == typeof(expected_conversion)
    @test expected_conversion == Makie.convert_arguments(Poly, data)[1]
    m = Makie.to_spritemarker(:circle)
    res = Makie.convert_arguments(Poly, m)[1]
    @test res isa Vector{<:Point2}
end


@testset "wrong arguments" begin
    # Only works for recipes defined via the new recipe with typed arguments
    @test_throws ArgumentError scatter(1im)
    @test_throws ArgumentError scatter(1im, 1im)
    @test_throws ArgumentError scatter(Figure(), 1im)
    f = Figure()
    ax = Axis(f[1, 1])
    @test_throws ArgumentError scatter!(ax, 1im)
    @test_throws ArgumentError scatter(rand(Point4f, 10))
    @test_throws ArgumentError lines(1im)
    @test_throws ArgumentError linesegments(1im)
    @test_throws ArgumentError volume(1im)
    @test_throws ArgumentError image(1im)
    @test_throws ArgumentError heatmap(1im)
end

# custom vector type to ensure that the conversion can be overridden for vectors
struct MyConvVector <: AbstractVector{Float64} end
Makie.expand_dimensions(::PointBased, ::MyConvVector) = nothing
Makie.convert_arguments(::PointBased, ::MyConvVector) = ([Point(10, 20)],)

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
        @test mesh_convert isa Tuple{<:GeometryBasics.Mesh{dim, eltype}}
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
    strings = fill(str, 10)

    @testset "input type -> output type" begin
        for (T_in, T_out) in [
                Float32 => Float32, Float64 => Float64,
                UInt32 => Float64, Int32 => Float64, Int64 => Float64,
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
                i = T_in(1) .. T_in(10)
                t = (T_in(1), T_out(10))
                ov = Makie.OffsetVector(ys, -5:4)
                rv = collect(r) # regular vector

                ps2 = Point2.(xs, ys)
                ps3 = Point3.(xs, ys, zs)
                miss2 = vcat(Point2.(xs, ys), missing)

                rect2 = Rect2{T_in}(0, 0, 1, 1)
                rect3 = Rect3{T_in}(Point3{T_in}(0), Vec3{T_in}(1))
                geom = Sphere(Point3{T_in}(0), T_in(1))
                _mesh = GeometryBasics.mesh(rect3; pointtype = Point3{T_in}, facetype = GLTriangleFace)
                polygon = Polygon(Point2.(xs, ys))
                polygon3d = Polygon(Point3.(xs, ys, zs))
                line = LineString(Point3.(xs, ys, zs))
                bp = BezierPath(
                    [
                        MoveTo(T_in(0), T_in(0)),
                        LineTo(T_in(1), T_in(0)),
                        CurveTo(T_in(1), T_in(1), T_in(0), T_in(1), T_in(3), T_in(0)),
                        EllipticalArc(Point2(T_in(0)), T_in(1), T_in(1), T_in(0), T_in(0), T_in(1)),
                        ClosePath(),
                    ]
                )

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

                        @test apply_conversion(CT, xs[1], xs[2]) isa Tuple{Vector{Point2{T_out}}}
                        @test apply_conversion(CT, xs[1], xs[2], xs[3]) isa Tuple{Vector{Point3{T_out}}}
                        @test apply_conversion(CT, ps2[1]) isa Tuple{Vector{Point2{T_out}}}
                        @test apply_conversion(CT, ps3[1]) isa Tuple{Vector{Point3{T_out}}}

                        # because indices are Int we end up converting to Float64 no matter what
                        @test apply_conversion(CT, xs) isa Tuple{Vector{Point2{Float64}}}
                        @test apply_conversion(CT, ov) isa Tuple{Vector{Point2{Float64}}}

                        @test apply_conversion(CT, xs, ys) isa Tuple{Vector{Point2{T_out}}}
                        @test apply_conversion(CT, xs, v32) isa Tuple{Vector{Point2{T_out}}}
                        @test apply_conversion(CT, i, ys) isa Tuple{Vector{Point2{T_out}}}
                        @test apply_conversion(CT, xs, i) isa Tuple{Vector{Point2{T_out}}}
                        @test apply_conversion(CT, r, ys) isa Tuple{Vector{Point2{T_out}}}
                        # @test apply_conversion(CT, vt, ys)     isa Tuple{Vector{Point2{T_out}}}
                        # @test apply_conversion(CT, m, m)       isa Tuple{Vector{Point2{T_out}}}

                        @test apply_conversion(CT, xs, ys, zs) isa Tuple{Vector{Point3{T_out}}}
                        @test apply_conversion(CT, vt, ys, vt) isa Tuple{Vector{Point3{T_out}}}
                        @test apply_conversion(CT, xs, ys, vt) isa Tuple{Vector{Point3{T_out}}}
                        @test apply_conversion(CT, xs, ys, v32) isa Tuple{Vector{Point3{T_out}}}
                        @test apply_conversion(CT, r, v32, zs) isa Tuple{Vector{Point3{T_out}}}
                        @test apply_conversion(CT, m, m, m) isa Tuple{Vector{Point3{T_out}}}
                        # TODO: Does this make sense?
                        @test apply_conversion(CT, i, i, m) isa Tuple{Vector{Point3{T_out}}}
                        # @test apply_conversion(CT, r, i, zs)       isa Tuple{Vector{Point3{T_out}}}
                        # @test apply_conversion(CT, i, i, zs)       isa Tuple{Vector{Point3{T_out}}}

                        # TODO: implement as PointBased conversion?
                        if CT !== PointBased()
                            @test apply_conversion(CT, xs, identity) isa Tuple{Vector{Point2{T_out}}}
                            @test apply_conversion(CT, r, identity) isa Tuple{Vector{Point2{T_out}}}
                            @test apply_conversion(CT, i, identity) isa Tuple{Vector{Point2{T_out}}}

                            @test apply_conversion(CT, xs, miss) isa Tuple{Vector{Point2{T_out}}}
                            @test apply_conversion(CT, miss, ys, zs) isa Tuple{Vector{Point3{T_out}}}

                            @test apply_conversion(CT, miss2) isa Tuple{Vector{Point2{T_out}}}
                        end

                        @test apply_conversion(CT, ps2) isa Tuple{Vector{Point2{T_out}}}
                        @test apply_conversion(CT, ps3) isa Tuple{Vector{Point3{T_out}}}
                        # @test apply_conversion(CT, Point.(miss, ys))   isa Tuple{Vector{Point2{T_out}}}

                        # TODO: Should this be Point?
                        @test apply_conversion(CT, Vec.(xs, ys)) isa Tuple{Vector{Point2{T_out}}}
                        @test apply_conversion(CT, Vec.(xs, ys, zs)) isa Tuple{Vector{Point3{T_out}}}
                        # @test apply_conversion(CT, Vec.(miss, ys))   isa Tuple{Vector{Point2{T_out}}}

                        @test apply_conversion(CT, tuple.(xs, ys)) isa Tuple{Vector{Point2{T_out}}}
                        @test apply_conversion(CT, tuple.(xs, v32)) isa Tuple{Vector{Point2{T_out}}}
                        @test apply_conversion(CT, tuple.(xs, ys, zs)) isa Tuple{Vector{Point3{T_out}}}
                        @test apply_conversion(CT, tuple.(v32, ys, zs)) isa Tuple{Vector{Point3{T_out}}}
                        # @test apply_conversion(CT, tuple.(miss, ys))   isa Tuple{Vector{Point2{T_out}}}

                        @test apply_conversion(CT, rect2) isa Tuple{Vector{Point2{T_out}}}
                        @test apply_conversion(CT, rect3) isa Tuple{Vector{Point3{T_out}}}
                        @test apply_conversion(CT, geom) isa Tuple{Vector{Point3{T_out}}}
                        @test apply_conversion(CT, _mesh) isa Tuple{Vector{Point3{T_out}}}
                        @test apply_conversion(CT, polygon) isa Tuple{Vector{Point2{T_out}}}
                        @test apply_conversion(CT, [polygon, polygon]) isa Tuple{Vector{Point2{T_out}}}
                        @test apply_conversion(CT, MultiPolygon([polygon, polygon])) isa Tuple{Vector{Point2{T_out}}}
                        @test apply_conversion(CT, polygon3d) isa Tuple{Vector{Point3{T_out}}}
                        @test apply_conversion(CT, [polygon3d, polygon3d]) isa Tuple{Vector{Point3{T_out}}}
                        @test apply_conversion(CT, MultiPolygon([polygon3d, polygon3d])) isa Tuple{Vector{Point3{T_out}}}
                        @test apply_conversion(CT, line) isa Tuple{Vector{Point3{T_out}}}
                        @test apply_conversion(CT, [line, line]) isa Tuple{Vector{Point3{T_out}}}
                        @test apply_conversion(CT, MultiLineString([line, line])) isa Tuple{Vector{Point3{T_out}}}
                        @test apply_conversion(CT, bp) isa Tuple{Vector{Point2d}} # BezierPath uses Float64 internally

                        @test apply_conversion(CT, m2) isa Tuple{Vector{Point2{T_out}}}
                        @test apply_conversion(CT, m3) isa Tuple{Vector{Point3{T_out}}}

                        @test apply_conversion(CT, MyConvVector()) == ([Point(10, 20)],)
                    end
                end

                # Special case: LineSegments

                @testset "LineSegments Extras" begin
                    if T_out == T_in
                        @test apply_conversion(LineSegments, Pair.(ps2, ps2)) isa Tuple{<:Base.ReinterpretArray}
                        @test apply_conversion(LineSegments, tuple.(ps2, ps2)) isa Tuple{<:Base.ReinterpretArray}
                    else
                        @test apply_conversion(LineSegments, Pair.(ps2, ps2)) isa Tuple{Vector{Point2{T_out}}}
                        @test apply_conversion(LineSegments, tuple.(ps2, ps2)) isa Tuple{Vector{Point2{T_out}}}
                    end
                end

                # CellGrid & Heatmap

                for CT in (CellGrid(), Heatmap)
                    @testset "$CT" begin
                        @test apply_conversion(CT, m) isa
                            Tuple{EndPoints{Float32}, EndPoints{Float32}, Matrix{Float32}}

                        @test apply_conversion(CT, xs, ys, m) isa Tuple{Vector{T_out}, Vector{T_out}, Matrix{Float32}}
                        @test apply_conversion(CT, xs, r, m) isa Tuple{Vector{T_out}, Vector{T_out}, Matrix{Float32}}
                        @test apply_conversion(CT, r, ys, +) isa Tuple{Vector{T_out}, Vector{T_out}, Matrix{Float32}}
                        @test apply_conversion(CT, i, r, m) isa Tuple{Vector{T_out}, Vector{T_out}, Matrix{Float32}}
                        @test apply_conversion(CT, i, i, m) isa
                            Tuple{EndPoints{T_out}, EndPoints{T_out}, Matrix{Float32}}
                        @test apply_conversion(CT, r, i, m) isa Tuple{Vector{T_out}, Vector{T_out}, Matrix{Float32}}
                        @test apply_conversion(CT, xgridvec, ygridvec, xgridvec) isa Tuple{Vector{T_out}, Vector{T_out}, Matrix{Float32}}
                        # TODO OffsetArray
                    end
                end

                # VertexGrid

                for CT in (VertexGrid(), Surface)
                    @testset "$CT" begin
                        @test apply_conversion(CT, xs, ys, m) isa Tuple{Vector{T_out}, Vector{T_out}, Matrix{Float32}}
                        @test apply_conversion(CT, m, m) isa Tuple{Matrix{T_out}, Matrix{T_out}, Matrix{Float32}}
                        # TODO: Should these be normalized to Vector?
                        if T_in == T_out
                            @test apply_conversion(CT, xs, r, m) isa Tuple{Vector{T_out}, AbstractRange{T_out}, Matrix{Float32}}
                            @test apply_conversion(CT, r, ys, +) isa Tuple{AbstractRange{T_out}, Vector{T_out}, Matrix{Float32}}
                        else
                            @test apply_conversion(CT, xs, r, m) isa Tuple{Vector{T_out}, Vector{T_out}, Matrix{Float32}}
                            @test apply_conversion(CT, r, ys, +) isa Tuple{Vector{T_out}, Vector{T_out}, Matrix{Float32}}
                        end
                        @test apply_conversion(CT, m) isa Tuple{AbstractRange{Float32}, AbstractRange{Float32}, Matrix{Float32}}
                        @test apply_conversion(CT, i, r, m) isa Tuple{AbstractRange{T_out}, AbstractRange{T_out}, Matrix{Float32}}
                        @test apply_conversion(CT, i, i, m) isa Tuple{AbstractRange{T_out}, AbstractRange{T_out}, Matrix{Float32}}
                        @test apply_conversion(CT, r, i, m) isa Tuple{AbstractRange{T_out}, AbstractRange{T_out}, Matrix{Float32}}
                        @test apply_conversion(CT, xgridvec, ygridvec, xgridvec) isa Tuple{Vector{T_out}, Vector{T_out}, Matrix{Float32}}
                        # TODO OffsetArray
                    end
                end

                # ImageLike, Image

                for CT in (ImageLike(), Image)
                    @testset "$CT" begin
                        @test apply_conversion(CT, img) isa Tuple{EndPoints{Float32}, EndPoints{Float32}, Matrix{RGBf}}
                        @test apply_conversion(CT, m) isa Tuple{EndPoints{Float32}, EndPoints{Float32}, Matrix{Float32}}

                        # deprecated
                        @test_throws ErrorException apply_conversion(CT, xs, ys, m)
                        @test_throws ErrorException apply_conversion(CT, xs, r, m)
                        @test_throws ErrorException apply_conversion(CT, i, r, m)
                        @test_throws ErrorException apply_conversion(CT, r, i, m)
                        @test_throws ErrorException apply_conversion(CT, r, ys, +)

                        @test apply_conversion(CT, t, t, m) isa Tuple{EndPoints{T_out}, EndPoints{T_out}, Matrix{Float32}}
                        @test apply_conversion(CT, t, i, m) isa Tuple{EndPoints{T_out}, EndPoints{T_out}, Matrix{Float32}}
                        @test apply_conversion(CT, i, t, m) isa Tuple{EndPoints{T_out}, EndPoints{T_out}, Matrix{Float32}}
                        @test apply_conversion(CT, i, i, m) isa Tuple{EndPoints{T_out}, EndPoints{T_out}, Matrix{Float32}}

                        # TODO: Should these exist?
                        # @test apply_conversion(CT, i, i, +) isa Tuple{EndPoints{T_out}, EndPoints{T_out}, Matrix{Float32}}
                        # @test apply_conversion(CT, i, t, +) isa Tuple{EndPoints{T_out}, EndPoints{T_out}, Matrix{Float32}}
                    end
                end

                # VolumeLike, Volume

                for CT in (VolumeLike(), Volume)
                    @testset "$CT" begin
                        # TODO: Should these be normalized more?
                        @test apply_conversion(CT, vol) isa Tuple{EndPoints{Float32}, EndPoints{Float32}, EndPoints{Float32}, Array{Float32, 3}}
                        @test apply_conversion(CT, i, i, i, vol) isa Tuple{EndPoints{T_out}, EndPoints{T_out}, EndPoints{T_out}, Array{Float32, 3}}
                        @test apply_conversion(CT, t, t, t, vol) isa Tuple{EndPoints{T_out}, EndPoints{T_out}, EndPoints{T_out}, Array{Float32, 3}}
                        @test apply_conversion(CT, t, i, t, vol) isa Tuple{EndPoints{T_out}, EndPoints{T_out}, EndPoints{T_out}, Array{Float32, 3}}

                        @test_throws ErrorException apply_conversion(CT, xs, ys, zs, vol)
                        @test_throws ErrorException apply_conversion(CT, xs, ys, zs, +)
                        @test_throws ErrorException apply_conversion(CT, r, r, r, vol)
                        @test_throws ErrorException apply_conversion(CT, xs, r, i, vol)

                        @test apply_conversion(CT, r, r, r, +) isa Tuple{EndPoints{T_out}, EndPoints{T_out}, EndPoints{T_out}, Array{Float32, 3}}
                        @test apply_conversion(CT, rv, rv, rv, +) isa Tuple{EndPoints{T_out}, EndPoints{T_out}, EndPoints{T_out}, Array{Float32, 3}}
                    end
                end

                # Mesh

                @testset "Mesh" begin
                    test_mesh_result(apply_conversion(Makie.Mesh, xs, ys, zs), 3, T_out, true)
                    test_mesh_result(apply_conversion(Makie.Mesh, ps3), 3, T_out, true)
                    test_mesh_result(apply_conversion(Makie.Mesh, _mesh), 3, T_out, true)
                    test_mesh_result(apply_conversion(Makie.Mesh, geom), 3, T_out, true)
                    test_mesh_result(apply_conversion(Makie.Mesh, xs, ys, zs, indices), 3, T_out, true)
                    test_mesh_result(apply_conversion(Makie.Mesh, ps3, indices), 3, T_out, true)

                    test_mesh_result(apply_conversion(Makie.Mesh, polygon), 2, T_out)
                    test_mesh_result(apply_conversion(Makie.Mesh, ps2), 2, T_out)
                    test_mesh_result(apply_conversion(Makie.Mesh, ps2, indices), 2, T_out)
                end

                # internally converted
                @testset "Text" begin
                    @test apply_conversion(Makie.Text, tuple.(strings, ps2)) isa Tuple{Vector{Tuple{String, Point2{T_in}}}}
                    @test apply_conversion(Makie.Text, tuple.(strings, ps3)) isa Tuple{Vector{Tuple{String, Point3{T_in}}}}
                end


                ################################################################
                ### recipes
                ################################################################

                # If a recipe transforms its input arguments it is fine for it
                # to keep T_in in apply_conversion.

                @testset "Arrows" begin
                    @test apply_conversion(Makie.ArrowLike(), xs, ys, xs, ys) isa Tuple{Vector{Point2{T_out}}, Vector{Point2{T_out}}}
                    @test apply_conversion(Makie.ArrowLike(), xs, ys, m, m) isa Tuple{Vector{Point2{T_out}}, Vector{Point2{T_out}}}
                    @test apply_conversion(Makie.ArrowLike(), xs, ys, zs, xs, ys, zs) isa Tuple{Vector{Point3{T_out}}, Vector{Point3{T_out}}}
                    @test apply_conversion(Makie.ArrowLike(), xs, ys, identity) isa Tuple{Vector{Point2{T_out}}, Vector{Point2{T_out}}}
                    @test apply_conversion(Makie.ArrowLike(), xs, ys, zs, identity) isa Tuple{Vector{Point3{T_out}}, Vector{Point3{T_out}}}
                end

                @testset "Band" begin
                    @test apply_conversion(Band, xs, ys, zs) isa Tuple{Vector{Point2{T_out}}, Vector{Point2{T_out}}}
                    @test apply_conversion(Band, i, x -> x .. (x + 1)) isa Tuple{Vector{Point2{T_out}}, Vector{Point2{T_out}}}
                end

                @testset "Bracket" begin
                    @test apply_conversion(Bracket, ps2[1], ps2[2]) isa Tuple{Vector{Tuple{Point2{T_out}, Point2{T_out}}}}
                    @test apply_conversion(Bracket, xs[1], ys[1], xs[2], ys[2]) isa Tuple{Vector{Tuple{Point2{T_out}, Point2{T_out}}}}
                    @test apply_conversion(Bracket, xs, ys, xs, ys) isa Tuple{Vector{Tuple{Point2{T_out}, Point2{T_out}}}}
                end

                @testset "Errorbars & Rangebars" begin
                    @test apply_conversion(Errorbars, xs, ys, zs) isa Tuple{Vector{Vec4{T_out}}}
                    @test apply_conversion(Errorbars, xs, ys, xs, ys) isa Tuple{Vector{Vec4{T_out}}}
                    @test apply_conversion(Errorbars, xs, ys, ps2) isa Tuple{Vector{Vec4{T_out}}}
                    @test apply_conversion(Errorbars, ps2, zs) isa Tuple{Vector{Vec4{T_out}}}
                    @test apply_conversion(Errorbars, ps2, xs, ys) isa Tuple{Vector{Vec4{T_out}}}
                    @test apply_conversion(Errorbars, ps2, ps2) isa Tuple{Vector{Vec4{T_out}}}
                    @test apply_conversion(Errorbars, ps3) isa Tuple{Vector{Vec4{T_out}}}

                    @test apply_conversion(Rangebars, xs, ys, zs) isa Tuple{Vector{Vec3{T_out}}}
                    @test apply_conversion(Rangebars, xs, ps2) isa Tuple{Vector{Vec3{T_out}}}
                    @test apply_conversion(Rangebars, i, x -> x .. (x + 1)) isa Tuple{Vector{Vec3{T_out}}}
                end

                @testset "Poly" begin
                    # TODO: Are these ok? All of these are just reflection...
                    @test apply_conversion(Poly, ps2) isa Tuple{Vector{Point2{T_out}}}
                    @test apply_conversion(Poly, [polygon]) isa Tuple{Vector{typeof(polygon)}}
                    @test apply_conversion(Poly, [rect2]) isa Tuple{Vector{typeof(rect2)}}
                    @test apply_conversion(Poly, polygon) isa Tuple{typeof(polygon)}
                    @test apply_conversion(Poly, rect2) isa Tuple{typeof(rect2)}
                    @test apply_conversion(Poly, ps2, indices) isa Tuple{<:GeometryBasics.Mesh{2, T_out}}
                    @test apply_conversion(Poly, ps3, indices) isa Tuple{<:GeometryBasics.Mesh{3, T_out}}
                end

                @testset "Series" begin
                    @test apply_conversion(Series, m) isa Tuple{Vector{Vector{Point2{Float64}}}}
                    @test apply_conversion(Series, xs, m) isa Tuple{Vector{Vector{Point2{T_out}}}}
                    @test apply_conversion(Series, miss, m) isa Tuple{Vector{Vector{Point2{T_out}}}}
                    @test apply_conversion(Series, [(xs, ys)]) isa Tuple{Vector{Vector{Point2{T_out}}}}
                    @test apply_conversion(Series, (xs, ys)) isa Tuple{Vector{Vector{Point2{T_out}}}}
                    @test apply_conversion(Series, [ps2, ps2]) isa Tuple{Vector{Vector{Point2{T_out}}}}
                end

                @testset "Spy" begin
                    # TODO: assuming internal processing
                    @test apply_conversion(Spy, sparse) isa
                        Tuple{EndPoints{T_out}, EndPoints{T_out}, SparseArrays.SparseMatrixCSC{eltype(sparse), Int64}}
                    @test apply_conversion(Spy, i, i, sparse) isa
                        Tuple{
                        EndPoints{T_out}, EndPoints{T_out},
                        SparseArrays.SparseMatrixCSC{eltype(sparse), Int64},
                    }
                end

                @testset "StreamPlot" begin
                    # TODO: these have a different argument order than other Function plots...
                    @test apply_conversion(StreamPlot, identity, xs, ys) isa Tuple{typeof(identity), Rect2{T_in}}
                    @test apply_conversion(StreamPlot, identity, i, r) isa Tuple{typeof(identity), Rect2{T_in}}
                    @test apply_conversion(StreamPlot, identity, xs, ys, zs) isa Tuple{typeof(identity), Rect3{T_in}}
                    @test apply_conversion(StreamPlot, identity, r, i, zs) isa Tuple{typeof(identity), Rect3{T_in}}
                    @test apply_conversion(StreamPlot, identity, rect2) isa Tuple{typeof(identity), Rect2{T_in}}
                    @test apply_conversion(StreamPlot, identity, rect3) isa Tuple{typeof(identity), Rect3{T_in}}
                end

                @testset "Tooltip" begin
                    @test apply_conversion(Tooltip, xs[1], ys[1], str) isa Tuple{Point2{T_out}, String}
                    @test apply_conversion(Tooltip, xs[1], ys[1]) isa Tuple{Point2{T_out}}
                end

                @testset "Tricontourf" begin
                    @test apply_conversion(Tricontourf, xs, ys, zs) isa Tuple{<:Makie.DelTri.Triangulation{Matrix{T_out}}, Vector{T_out}}
                end

                @testset "Triplot" begin
                    @test apply_conversion(Triplot, ps2) isa Tuple{Vector{Point2{T_out}}}
                    @test apply_conversion(Triplot, xs, ys) isa Tuple{Vector{Point2{T_out}}}
                    # TODO: DelTri.Triangulation
                end

                @testset "Voronoiplot" begin
                    @test apply_conversion(Voronoiplot, m) isa Tuple{Vector{Point3{Float64}}}
                    @test apply_conversion(Voronoiplot, xs, ys, zs) isa Tuple{Vector{Point3{T_out}}}
                    @test apply_conversion(Voronoiplot, xs, ys) isa Tuple{Vector{Point2{T_out}}}
                    @test apply_conversion(Voronoiplot, ps2) isa Tuple{Vector{Point2{T_out}}}
                    @test apply_conversion(Voronoiplot, ps3) isa Tuple{Vector{Point3{T_out}}}
                    # TODO: VoronoiTessellation
                end

                # pure 3D plots don't implement Float64 -> Float32 rescaling yet
                @testset "Voxels" begin
                    @test_throws ErrorException apply_conversion(Voxels, xs, ys, zs, vol)
                    @test apply_conversion(Voxels, vol) isa Tuple{EndPoints{Float32}, EndPoints{Float32}, EndPoints{Float32}, Array{T_in, 3}}
                    @test apply_conversion(Voxels, i, i, i, vol) isa Tuple{EndPoints{Float32}, EndPoints{Float32}, EndPoints{Float32}, Array{T_in, 3}}
                    @test apply_conversion(Voxels, t, t, t, vol) isa Tuple{EndPoints{Float32}, EndPoints{Float32}, EndPoints{Float32}, Array{T_in, 3}}
                    @test apply_conversion(Voxels, i, t, t, vol) isa Tuple{EndPoints{Float32}, EndPoints{Float32}, EndPoints{Float32}, Array{T_in, 3}}
                end

                @testset "Wireframe" begin
                    @test apply_conversion(Wireframe, xs, ys, zs) isa Tuple{Vector{T_in}, Vector{T_in}, Vector{T_in}}
                end

            end
        end

        # These have nothing to do with Numeric types...
        @testset "Text" begin
            @test apply_conversion(Makie.Text, str) isa Tuple{String}
            @test apply_conversion(Makie.Text, strings) isa Tuple{Vector{String}}
            # TODO glyphcollection
        end
    end
end

@testset "Explicit convert_arguments" begin
    function nan_equal(a::Vector, b::Vector)
        length(a) == length(b) || return false
        for (x, y) in zip(a, b)
            (isnan(x) && isnan(y)) || (x == y) || return false
        end
        return true
    end

    @testset "PointBased" begin
        ps = Point2f.([1, 2], [1, 2])
        ls1 = [LineString(ps) for _ in 1:2]
        ls2 = MultiLineString(ls1)
        ls3 = [ls2, ls2]
        ps12 = [ps; [Point2f(NaN)]; ps]
        ps3 = [ps12; [Point2f(NaN)]; ps12]
        @test nan_equal(convert_arguments(PointBased(), ls1)[1], ps12)
        @test nan_equal(convert_arguments(PointBased(), ls2)[1], ps12)
        @test nan_equal(convert_arguments(PointBased(), ls3)[1], ps3)
    end

    @testset "Lines" begin
        r = Rect3f(0, 0, 0, 1, 1, 1)
        ps = Point3f[[0.0, 0.0, 0.0], [0.0, 0.0, 1.0], [0.0, 1.0, 0.0], [0.0, 1.0, 1.0], [1.0, 0.0, 0.0], [1.0, 0.0, 1.0], [1.0, 1.0, 0.0], [1.0, 1.0, 1.0], [NaN, NaN, NaN]]
        ps = ps[[1, 3, 4, 2, 1, 5, 6, 2, 9, 6, 8, 7, 5, 9, 8, 4, 9, 7, 3]]
        @test nan_equal(convert_arguments(Lines, r)[1], ps)
    end
end
