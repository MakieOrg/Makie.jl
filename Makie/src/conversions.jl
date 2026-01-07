################################################################################
#                               Type Conversions                               #
################################################################################
const RangeLike = Union{AbstractVector, ClosedInterval, Tuple{Real, Real}}

function convert_arguments(CT::ConversionTrait, args...)
    expanded = expand_dimensions(CT, args...)
    if !isnothing(expanded)
        return convert_arguments(CT, expanded...)
    end
    return args
end

function convert_arguments(T::Type{<:AbstractPlot}, args...; kw...)
    # landing here means, that there is no matching `convert_arguments` method for the plot type
    # Meaning, it needs to be a conversion trait, or it needs single_convert_arguments or expand_dimensions
    CT = conversion_trait(T, args...)

    # Try single argument convert after
    arguments_converted = map(convert_single_argument, args)
    if arguments_converted !== args
        # This changed something, so we start back with convert_arguments
        return convert_arguments(T, arguments_converted...; kw...)
    end
    # next we try to convert the arguments with the conversion trait
    trait_converted = convert_arguments(CT, args...; kw...)
    trait_converted !== args && return convert_arguments(T, trait_converted...; kw...)
    # else we give up!
    return args
end

################################################################################
#                          Single Argument Conversion                          #
################################################################################

# if no specific conversion is defined, we don't convert
convert_single_argument(@nospecialize(x)) = x

# replace `missing`s with `NaN`s
function convert_single_argument(a::AbstractArray{<:Union{Missing, <:Real}})
    return float_convert(a)
end

# same for points
function convert_single_argument(a::AbstractArray{<:Union{Missing, <:Point{N, PT}}}) where {N, PT}
    T = float_type(PT)
    return Point{N, T}[ismissing(x) ? Point{N, T}(NaN) : Point{N, T}(x) for x in a]
end

function convert_single_argument(a::AbstractArray{Any})
    isempty(a) && return a
    return convert_single_argument([x for x in a])
end

# Leave concretely typed vectors alone (AbstractArray{<:Union{Missing, <:Real}} also dispatches for `Vector{Float32}`)
convert_single_argument(a::AbstractArray{T}) where {T <: Real} = a
convert_single_argument(a::AbstractArray{<:Point{N, T}}) where {N, T} = a
convert_single_argument(a::OffsetArray{<:Point}) = OffsetArrays.no_offset_view(a)


################################################################################
#                                  PointBased                                  #
################################################################################

"""
Wrap a single point or equivalent object in a single-element array.
"""
function convert_arguments(::PointBased, x::Real, y::Real)
    T = float_type(x, y)
    return ([Point{2, T}(x, y)],)
end

function convert_arguments(::PointBased, x::Real, y::Real, z::Real)
    T = float_type(x, y, z)
    return ([Point{3, T}(x, y, z)],)
end

function convert_arguments(::PointBased, position::VecTypes{N, T}) where {N, T <: Real}
    _T = @isdefined(T) ? T : Float64
    return ([Point{N, float_type(_T)}(position)],)
end

function convert_arguments(::PointBased, positions::AbstractVector{<:VecTypes{N, T}}) where {N, T <: Real}
    # VecTypes{N, T} will have T undefined if tuple has different number types
    _T = @isdefined(T) ? T : Float64
    if !(N in (2, 3))
        throw(ArgumentError("Only 2D and 3D points are supported."))
    end
    return (elconvert(Point{N, float_type(_T)}, positions),)
end

function convert_arguments(T::PointBased, positions::OffsetVector)
    return convert_arguments(T, OffsetArrays.no_offset_view(positions))
end

function convert_arguments(::PointBased, positions::SubArray{<:VecTypes, 1})
    # TODO figure out a good subarray solution
    return (positions,)
end

"""
Enables to use scatter like a surface plot with x::Vector, y::Vector, z::Matrix
spanning z over the grid spanned by x y
"""
function convert_arguments(::PointBased, x::RealArray, y::RealVector, z::RealMatrix)
    T = float_type(x, y, z)
    return (vec(Point{3, T}.(x, y', z)),)
end

function convert_arguments(::PointBased, x::RealVector, y::RealVector, z::RealVector)
    T = float_type(x, y, z)
    return (Point{3, T}.(x, y, z),)
end


function convert_arguments(p::PointBased, x::AbstractInterval, y::AbstractInterval, z::RealMatrix)
    return convert_arguments(p, to_linspace(x, size(z, 1)), to_linspace(y, size(z, 2)), z)
end

"""
    convert_arguments(P, x, y, z)::(Vector)

Takes vectors `x`, `y`, and `z` and turns it into a vector of 3D points of the values
from `x`, `y`, and `z`.
`P` is the plot Type (it is optional).
"""
function convert_arguments(::PointBased, x::RealArray, y::RealMatrix, z::RealMatrix)
    T = float_type(x, y, z)
    return (vec(Point{3, T}.(x, y, z)),)
end


function convert_arguments(::PointBased, x::RealVector, y::RealVector)
    return (Point{2, float_type(x, y)}.(x, y),)
end

"""
    convert_arguments(P, x)::(Vector)

Takes an input GeometryPrimitive `x` and decomposes it to points.
`P` is the plot Type (it is optional).
"""
function convert_arguments(p::PointBased, x::GeometryPrimitive{Dim, T}) where {Dim, T}
    return convert_arguments(p, decompose(Point{Dim, float_type(T)}, x))
end

function convert_arguments(p::PointBased, mp::MultiPoint{Dim, T}) where {Dim, T}
    return convert_arguments(p, mp.points)
end

function convert_arguments(p::PointBased, mp::AbstractVector{<:MultiPoint})
    points = mapreduce(x -> convert_arguments(p, x)[1], vcat, mp)
    return (points,)
end


function convert_arguments(::PointBased, pos::RealMatrix)
    return (to_vertices(pos),)
end


"""
    convert_arguments(P, x, y)::(Vector)

Takes vectors `x` and `y` and turns it into a vector of 2D points of the values
from `x` and `y`.

`P` is the plot Type (it is optional).
"""
convert_arguments(P::PointBased, x::ClosedInterval, y::RealVector) = convert_arguments(P, LinRange(extrema(x)..., length(y)), y)
convert_arguments(P::PointBased, x::RealVector, y::ClosedInterval) = convert_arguments(P, x, LinRange(extrema(y)..., length(x)))


"""
    convert_arguments(P, x)::(Vector)

Takes an input `Rect` `x` and decomposes it to points.

`P` is the plot Type (it is optional).
"""
function convert_arguments(P::PointBased, x::Rect2{T}) where {T}
    return convert_arguments(P, decompose(Point2{float_type(T)}, x))
end

function convert_arguments(P::PointBased, mesh::AbstractMesh)
    return convert_arguments(P, coordinates(mesh))
end

# function convert_arguments(PB::PointBased, linesegments::FaceView{<:Line, P}) where {P<:Point}
#     # TODO FaceView should be natively supported by backends!
#     return convert_arguments(PB, collect(reinterpret(P, linesegments)))
# end

function convert_arguments(::PointBased, rect::Rect3{T}) where {T}
    return (decompose(Point3{float_type(T)}, rect),)
end

function convert_arguments(P::Type{<:LineSegments}, rect::Rect3{T}) where {T}
    f = GeometryBasics.remove_duplicates(decompose(LineFace{Int}, rect))
    p = connect(decompose(Point3{float_type(T)}, rect), f)
    return convert_arguments(P, p)
end

function convert_arguments(::Type{<:Lines}, rect::Rect3{T}) where {T}
    PT = Point3{float_type(T)}
    points = decompose(PT, rect)
    push!(points, PT(NaN)) # use to separate linesegments
    return (points[[1, 3, 4, 2, 1, 5, 6, 2, 9, 6, 8, 7, 5, 9, 8, 4, 9, 7, 3]],)
end
"""

    convert_arguments(PB, LineString)

Takes an input `LineString` and decomposes it to points.
"""
function convert_arguments(PB::PointBased, linestring::LineString)
    return convert_arguments(PB, decompose(Point, linestring))
end

"""
    convert_arguments(PB, Union{Array{<:LineString}, MultiLineString})

Takes an input `Array{LineString}` or a `MultiLineString` and decomposes it to points.
"""
function convert_arguments(PB::PointBased, linestring::Union{AbstractVector{<:LineString{N, T}}, MultiLineString{N, T}, AbstractVector{<:MultiLineString{N, T}}}) where {N, T}
    T_out = float_type(T)
    arr = Point{N, T_out}[]; n = length(linestring)
    for idx in 1:n
        append!(arr, convert_arguments(PB, linestring[idx])[1])
        if idx != n # don't add NaN at the end
            push!(arr, Point{N, T_out}(NaN))
        end
    end
    return (arr,)
end

"""

    convert_arguments(PB, Polygon)

Takes an input `Polygon` and decomposes it to points.
"""
function convert_arguments(PB::PointBased, pol::Polygon)
    converted = convert_arguments(PB, pol.exterior)[1] # this should always be a Tuple{<: Vector{Point}}
    arr = copy(converted)
    if !isempty(arr) && arr[1] != arr[end]
        push!(arr, arr[1]) # close exterior
    end
    for interior in pol.interiors
        push!(arr, Point2(NaN))
        inter = convert_arguments(PB, interior)[1] # this should always be a Tuple{<: Vector{Point}}
        append!(arr, inter)
        if !isempty(inter) && inter[1] != inter[end]
            push!(arr, inter[1]) # close interior
        end
    end
    return (arr,)
end

"""

    convert_arguments(PB, Union{Array{<:Polygon}, MultiPolygon})

Takes an input `Array{Polygon}` or a `MultiPolygon` and decomposes it to points.
"""
function convert_arguments(PB::PointBased, mp::Union{Array{<:Polygon{N, T}}, MultiPolygon{N, T}}) where {N, T}
    arr = Point{N, float_type(T)}[]
    n = length(mp)
    for idx in 1:n
        converted = convert_arguments(PB, mp[idx])[1] # this should always be a Tuple{<: Vector{Point}}
        append!(arr, converted)
        if idx != n # don't add NaN at the end
            push!(arr, Point{N, float_type(T)}(NaN))
        end
    end
    return (arr,)
end

function convert_arguments(::PointBased, b::BezierPath)
    b2 = replace_nonfreetype_commands(b)
    points = Point2d[]
    last_point = Point2d(NaN)
    last_moveto = false

    function poly3(t, p0, p1, p2, p3)
        return Point2d((1 - t)^3 .* p0 .+ t * p1 * (3 * (1 - t)^2) + p2 * (3 * (1 - t) * t^2) .+ p3 * t^3)
    end

    for command in b2.commands
        if command isa MoveTo
            last_point = command.p
            last_moveto = true
        elseif command isa LineTo
            if last_moveto
                isempty(points) || push!(points, Point2d(NaN, NaN))
                push!(points, last_point)
            end
            push!(points, command.p)
            last_point = command.p
            last_moveto = false
        elseif command isa CurveTo
            if last_moveto
                isempty(points) || push!(points, Point2d(NaN, NaN))
                push!(points, last_point)
            end
            last_moveto = false
            for t in range(0, 1, length = 30)[2:end]
                push!(points, poly3(t, last_point, command.c1, command.c2, command.p))
            end
            last_point = command.p
        end
    end
    return (points,)
end


################################################################################
#                                  GridBased                                   #
################################################################################

function edges(v::AbstractVector{T}) where {T}
    T_out = float_type(T)
    l = length(v)
    if l == 1
        return T_out[v[1] - 0.5, v[1] + 0.5]
    else
        # Equivalent to
        # mids = 0.5 .* (v[1:end-1] .+ v[2:end])
        # borders = [2v[1] - mids[1]; mids; 2v[end] - mids[end]]
        borders = T_out[0.5 * (v[max(1, i)] + v[min(end, i + 1)]) for i in 0:length(v)]
        borders[1] = 2borders[1] - borders[2]
        borders[end] = 2borders[end] - borders[end - 1]
        return borders
    end
end

function adjust_axes(::CellGrid, x::RealVector, y::RealVector, z::AbstractMatrix)
    x̂, ŷ = map((x, y), size(z)) do v, sz
        return length(v) == sz ? edges(v) : v
    end
    return x̂, ŷ, z
end

adjust_axes(::VertexGrid, x, y, z) = x, y, z


"""
    convert_arguments(ct::GridBased, x::VecOrMat, y::VecOrMat, z::Matrix)

If `ct` is `Heatmap` and `x` and `y` are vectors, infer from length of `x` and `y`
whether they represent edges or centers of the heatmap bins.
If they are centers, convert to edges. Convert eltypes to `Float32` and return
outputs as a `Tuple`.
"""
function convert_arguments(
        ct::GridBased, x::AbstractVecOrMat{<:Real}, y::AbstractVecOrMat{<:Real},
        z::AbstractMatrix{<:Union{Real, Colorant}}
    )
    nx, ny, nz = adjust_axes(ct, x, y, z)
    return (float_convert(nx), float_convert(ny), el32convert(nz))
end

convert_arguments(ct::VertexGrid, x::RealMatrix, y::RealMatrix) = convert_arguments(ct, x, y, zeros(size(y)))

"""
    convert_arguments(P, x::RangeLike, y::RangeLike, z::AbstractMatrix)

Takes one or two ClosedIntervals `x` and `y` and converts them to closed ranges
with size(z, 1/2).
"""
function convert_arguments(P::GridBased, x::RangeLike, y::RangeLike, z::AbstractMatrix{<:Union{Real, Colorant}})
    return convert_arguments(P, to_linspace(x, size(z, 1)), to_linspace(y, size(z, 2)), z)
end

function convert_arguments(
        ::VertexGrid, x::EndPointsLike, y::EndPointsLike,
        z::AbstractMatrix{<:Union{Real, Colorant}}
    )
    return (to_linspace(x, size(z, 1)), to_linspace(y, size(z, 2)), el32convert(z))
end

function to_endpoints(x::Tuple{<:Real, <:Real})
    T = float_type(x...)
    return EndPoints(T.(x))
end
to_endpoints(x::Interval) = to_endpoints(endpoints(x))
to_endpoints(x::EndPoints) = x

to_endpoints(x::AbstractVector, side, trait) = throw_range_error(x, side, trait)
to_endpoints(x::Union{Tuple, EndPoints, Interval}, side, trait) = to_endpoints(x)

function throw_range_error(value::T, side, trait) where {T}
    error(
        "Encountered `$T` with value $value on side $side in `convert_arguments` for the `$trait`
        conversion. Using `$T` to specify one dimension of `$trait` is deprecated because `$trait`
        sides always need exactly two values, start and stop. Use interval notation `start .. stop`,
        a two-element tuple `(start, stop)` or `Makie.EndPoints(start, stop)` instead."
    )
end

function convert_arguments(
        ::GridBased, x::EndPointsLike, y::EndPointsLike,
        z::AbstractMatrix{<:Union{Real, Colorant}}
    )
    return (to_endpoints(x), to_endpoints(y), el32convert(z))
end

function convert_arguments(
        ::CellGrid, x::EndPoints, y::EndPoints,
        z::AbstractMatrix{<:Union{Real, Colorant}}
    )
    return (x, y, el32convert(z))
end

function get_step(x::EndPoints, n)
    # length 1 step should be 1
    x[1] == x[2] && n == 1 && return 1
    return step(range(x...; length = n))
end

function convert_arguments(
        ::CellGrid, x::EndPointsLike, y::EndPointsLike,
        z::AbstractMatrix{<:Union{Real, Colorant}}
    )

    xe = to_endpoints(x)
    ye = to_endpoints(y)
    xstep = get_step(xe, size(z, 1)) / 2.0
    ystep = get_step(ye, size(z, 2)) / 2.0

    Tx = typeof(xe[1])
    Ty = typeof(ye[1])
    # heatmaps are centered on the edges, so we need to adjust the range
    # This is done in conversions, since it's also how we calculate the boundingbox (heatmapplot.x, heatmap.y)
    # We need the endpoint type here, since convert_arguments((0, 1), (0, 1), z), which only subtracts the step
    # Will end in a stackoverflow, since convert_arguments gets called every time the `args_in != args_out`.
    # If we return a different type with no conversion overload, it stops that recursion
    return (EndPoints{Tx}(xe[1] - xstep, xe[2] + xstep), EndPoints{Ty}(ye[1] - ystep, ye[2] + ystep), el32convert(z))
end

function convert_arguments(
        ::ImageLike, xs::RangeLike, ys::RangeLike,
        data::AbstractMatrix{<:Union{Real, Colorant}}
    )
    x = to_endpoints(xs, "x", ImageLike)
    y = to_endpoints(ys, "y", ImageLike)
    return (x, y, el32convert(data))
end

function convert_arguments(ct::GridBased, x::RealVector, y::RealVector, z::RealVector)
    if !(length(x) == length(y) == length(z))
        error("x, y and z need to have the same length. Lengths are $(length.((x, y, z)))")
    end

    xys = tuple.(x, y)
    if length(unique(xys)) != length(x)
        c = StatsBase.countmap(xys)
        cdup = filter(x -> x[2] > 1, c)
        error("Found duplicate x/y coordinates: $cdup")
    end

    x_centers = sort(unique(x))
    any(isnan, x_centers) && error("x must not have NaN values.")
    y_centers = sort(unique(y))
    any(isnan, y_centers) && error("x must not have NaN values.")
    zs = fill(NaN32, length(x_centers), length(y_centers))
    foreach(zip(x, y, z)) do (xi, yi, zi)
        i = searchsortedfirst(x_centers, xi)
        j = searchsortedfirst(y_centers, yi)
        @inbounds zs[i, j] = zi
    end
    return convert_arguments(ct, x_centers, y_centers, zs)
end

"""
    convert_arguments(P, x, y, f)::(Vector, Vector, Matrix)

Takes vectors `x` and `y` and the function `f`, and applies `f` on the grid that `x` and `y` span.
This is equivalent to `f.(x, y')`.
`P` is the plot Type (it is optional).
"""
function convert_arguments(ct::Union{GridBased, ImageLike}, x::AbstractVector, y::AbstractVector, f::Function)
    if !applicable(f, x[1], y[1])
        error("You need to pass a function with signature f(x::$(eltype(x)), y::$(eltype(y))). Found: $f")
    end
    return convert_arguments(ct, x, y, f.(x, y'))
end

################################################################################
#                                  VolumeLike                                  #
################################################################################

function convert_arguments(
        ::VolumeLike, x::RangeLike, y::RangeLike, z::RangeLike,
        data::RealArray{3}
    )
    return (
        to_endpoints(x, "x", VolumeLike), to_endpoints(y, "y", VolumeLike),
        to_endpoints(z, "z", VolumeLike), el32convert(data),
    )
end

# TODO: Consider using RGB(A){N0f8} for all of these
# RGBA/Vec4 is the native data type for :absorptionrgba, :additive
function convert_arguments(::VolumeLike, x::RangeLike, y::RangeLike, z::RangeLike, data::Array{<:Union{VecTypes{3}, VecTypes{4}, RGB, RGBA}, 3})
    return (
        to_endpoints(x, "x", VolumeLike), to_endpoints(y, "y", VolumeLike),
        to_endpoints(z, "z", VolumeLike), el32convert(data),
    )
end
function convert_arguments(::VolumeLike, x::RangeLike, y::RangeLike, z::RangeLike, data::Array{<:Colors.Color, 3})
    return (
        to_endpoints(x, "x", VolumeLike), to_endpoints(y, "y", VolumeLike),
        to_endpoints(z, "z", VolumeLike), RGBf.(data),
    )
end
function convert_arguments(::VolumeLike, x::RangeLike, y::RangeLike, z::RangeLike, data::Array{<:Colors.TransparentColor, 3})
    return (
        to_endpoints(x, "x", VolumeLike), to_endpoints(y, "y", VolumeLike),
        to_endpoints(z, "z", VolumeLike), RGBAf.(data),
    )
end

################################################################################
#                                <:Lines                                       #
################################################################################

function convert_arguments(::Type{<:Lines}, x::Rect2{T}) where {T}
    points = decompose(Point2{float_type(T)}, x)
    return (points[[1, 2, 3, 4, 1]],)
end

################################################################################
#                                <:LineSegments                                #
################################################################################

"""
Accepts a Vector of Pair of Points (e.g. `[Point(0, 0) => Point(1, 1), ...]`)
to encode e.g. linesegments or directions.
"""
function convert_arguments(::Type{<:LineSegments}, positions::AbstractVector{E}) where {E <: Union{Pair{A, A}, Tuple{A, A}}} where {A <: VecTypes{N, T}} where {N, T}
    return (float_convert(reinterpret(Point{N, T}, positions)),)
end

function convert_arguments(::Type{<:LineSegments}, x::Rect2{T}) where {T}
    points = decompose(Point2{float_type(T)}, x)
    return (points[[1, 2, 2, 3, 3, 4, 4, 1]],)
end

################################################################################
#                                    <:Mesh                                    #
################################################################################

"""
    convert_arguments(Mesh, x, y, z)::GLNormalMesh

Takes real vectors x, y, z and constructs a mesh out of those, under the assumption that
every 3 points form a triangle.
"""
function convert_arguments(
        T::Type{<:Mesh},
        x::RealVector, y::RealVector, z::RealVector
    )
    return convert_arguments(T, Point3{float_type(x, y, z)}.(x, y, z))
end
"""
    convert_arguments(Mesh, xyz::AbstractVector)::GLNormalMesh

Takes an input mesh and a vector `xyz` representing the vertices of the mesh, and
creates indices under the assumption, that each triplet in `xyz` forms a triangle.
"""
function convert_arguments(
        MT::Type{<:Mesh},
        xyz::AbstractVector{<:VecTypes}
    )
    faces = connect(UInt32.(0:(length(xyz) - 1)), GLTriangleFace)
    # TODO support faceview natively
    return convert_arguments(MT, xyz, collect(faces))
end

function convert_arguments(::Type{<:Mesh}, mesh::GeometryBasics.Mesh{N, T}) where {N, T}
    n = nothing
    if !hasproperty(mesh, :normal)
        n = normals(coordinates(mesh), faces(mesh), normaltype = Vec3f)
    end

    mesh = GeometryBasics.mesh(mesh, facetype = GLTriangleFace, pointtype = Point{N, float_type(T)}, normal = n)
    mesh = GeometryBasics.expand_faceviews(mesh) # TODO: can we do this (more) in-place?

    return (mesh,)
end

function convert_arguments(
        T::Type{<:Mesh},
        meshes::AbstractVector{<:GeometryBasics.AbstractGeometry{DIM}}
    ) where {DIM}

    if isempty(meshes)
        return (GeometryBasics.Mesh(Point{DIM, Float32}[], GLTriangleFace[]),)
    end
    converted = [convert_arguments(T, m)[1] for m in meshes]
    return (merge(converted),)
end

function convert_arguments(MT::Type{<:Mesh}, xyz::AbstractPolygon)
    m = GeometryBasics.mesh(xyz; pointtype = float_type(xyz), facetype = GLTriangleFace)
    return convert_arguments(MT, m)
end

# TODO GeometryBasics can't deal with this directly for Integer Points?
function convert_arguments(
        MT::Type{<:Mesh},
        xyz::AbstractVector{<:Point{2}}
    )
    ps = float_convert(xyz)
    m = GeometryBasics.mesh(ps; pointtype = eltype(ps), facetype = GLTriangleFace)
    return convert_arguments(MT, m)
end

function convert_arguments(::Type{<:Mesh}, geom::GeometryPrimitive{N, T}) where {N, T <: Real}
    # we convert to UV mesh as default, because otherwise the uv information gets lost
    # - we can still drop them, but we can't add them later on
    m = GeometryBasics.expand_faceviews(
        GeometryBasics.uv_normal_mesh(
            geom; pointtype = Point{N, float_type(T)},
            uvtype = Vec2f, normaltype = Vec3f, facetype = GLTriangleFace
        )
    )
    return (m,)
end

"""
    convert_arguments(Mesh, x, y, z, indices)::GLNormalMesh

Takes real vectors x, y, z and constructs a triangle mesh out of those, using the
faces in `indices`, which can be integers (every 3 -> one triangle), or GeometryBasics.NgonFace{N, <: Integer}.
"""
function convert_arguments(
        T::Type{<:Mesh},
        x::RealVector, y::RealVector, z::RealVector,
        indices::AbstractVector
    )
    return convert_arguments(T, Point3{float_type(x, y, z)}.(x, y, z), indices)
end

"""
    convert_arguments(Mesh, vertices, indices)::GLNormalMesh

Takes `vertices` and `indices`, and creates a triangle mesh out of those.
See `to_vertices` and `to_triangles` for more information about
accepted types.
"""
function convert_arguments(
        ::Type{<:Mesh},
        vertices::AbstractArray,
        indices::AbstractArray
    )
    vs = to_vertices(vertices)
    fs = to_triangles(indices)
    if eltype(vs) <: Point{3}
        ns = Vec3f.(normals(vs, fs))
        m = GeometryBasics.Mesh(vs, fs; normal = ns)
    else
        # TODO, we don't need to add normals here, but maybe nice for type stability?
        m = GeometryBasics.Mesh(vs, fs; normal = fill(Vec3f(0, 0, 1), length(vs)))
    end
    return (m,)
end


################################################################################
#                             Function Conversions                             #
################################################################################

# Note: AbstractRange must be linear
is_regularly_spaced(x::AbstractRange) = true
function is_regularly_spaced(x::AbstractVector)
    delta = x[2] - x[1]
    return all(i -> x[i] - x[i - 1] ≈ delta, 3:length(x))
end

"""
    convert_arguments(P, x, y, z, f)::(Vector, Vector, Vector, Matrix)

Takes `AbstractVector` `x`, `y`, and `z` and the function `f`, evaluates `f` on the volume
spanned by `x`, `y` and `z`, and puts `x`, `y`, `z` and `f(x,y,z)` in a Tuple.

`P` is the plot Type (it is optional).
"""
function convert_arguments(::VolumeLike, x::RealVector, y::RealVector, z::RealVector, f::Function)
    if !applicable(f, x[1], y[1], z[1])
        error("You need to pass a function with signature f(x, y, z). Found: $f")
    end
    # Verify grid regularity
    is_regularly_spaced(x) || throw_range_error(x, "x", VolumeLike)
    is_regularly_spaced(y) || throw_range_error(y, "y", VolumeLike)
    is_regularly_spaced(z) || throw_range_error(z, "z", VolumeLike)

    _x, _y, _z = ntuple(Val(3)) do i
        A = (x, y, z)[i]
        return reshape(A, ntuple(j -> j != i ? 1 : length(A), Val(3)))
    end

    return (map(v -> to_endpoints((first(v), last(v))), (x, y, z))..., el32convert.(f.(_x, _y, _z)))
end

function convert_arguments(P::Type{<:AbstractPlot}, r::RealVector, f::Function)
    return convert_arguments(P, r, map(f, r))
end

function convert_arguments(P::Type{<:AbstractPlot}, i::AbstractInterval, f::Function)
    x, y = PlotUtils.adapted_grid(f, endpoints(i))
    return convert_arguments(P, x, y)
end

function convert_arguments(P::Type{<:Union{Band, Rangebars}}, i::AbstractInterval, f::Function)
    # f() returns interval for these plottypes
    x, y = PlotUtils.adapted_grid(x -> mean(f(x)), endpoints(i))
    return convert_arguments(P, x, f.(x))
end

# OffsetArrays conversions
function convert_arguments(sl::GridBased, wm::OffsetArray)
    x1, y1 = wm.offsets .+ 1
    nx, ny = size(wm)
    x = range(x1, length = nx)
    y = range(y1, length = ny)
    v = parent(wm)
    return convert_arguments(sl, x, y, v)
end

################################################################################
#                               Helper Functions                               #
################################################################################

to_linspace(interval::Interval, N) = range(leftendpoint(interval), stop = rightendpoint(interval), length = N)
to_linspace(x, N) = range(first(x), stop = last(x), length = N)

"""
Converts the element array type to `T1` without making a copy if the element type matches
"""
function elconvert(::Type{T1}, x::AbstractArray{T2, N}) where {T1, T2, N}
    return convert(AbstractArray{T1, N}, x)
end

function elconvert(::Type{T}, x::AbstractArray{<:Union{Missing, <:Real}}) where {T}
    return map(x) do elem
        return (ismissing(elem) ? T(NaN) : convert(T, elem))
    end
end

float_type(args::Type) = error("Type $(args) not supported")
float_type(a, rest...) = float_type(typeof(a), map(typeof, rest)...)
float_type(a::AbstractArray, rest...) = float_type(float_type(a), map(float_type, rest)...)
float_type(a::AbstractPolygon, rest...) = float_type(float_type(a), map(float_type, rest)...)
float_type(a::Type, rest::Type...) = promote_type(map(float_type, (a, rest...))...)
float_type(::Type{Float64}) = Float64
float_type(::Type{Float32}) = Float32
float_type(::Type{Bool}) = Float32
float_type(::Type{<:Real}) = Float64
float_type(::Type{<:Union{Int8, UInt8, Int16, UInt16}}) = Float32
float_type(::Type{<:Union{Float16}}) = Float32
float_type(::Type{Point{N, T}}) where {N, T} = Point{N, float_type(T)}
float_type(::Type{Vec{N, T}}) where {N, T} = Vec{N, float_type(T)}
float_type(::Type{NTuple{N, T}}) where {N, T} = Point{N, float_type(T)}
float_type(::Type{Tuple{T1, T2}}) where {T1, T2} = Point2{promote_type(float_type(T1), float_type(T2))}
float_type(::Type{Tuple{T1, T2, T3}}) where {T1, T2, T3} = Point3{promote_type(float_type(T1), float_type(T2), float_type(T3))}
float_type(::Type{Union{Missing, T}}) where {T} = float_type(T)
float_type(::Type{Union{Nothing, T}}) where {T} = float_type(T)
float_type(::Type{ClosedInterval{T}}) where {T} = ClosedInterval{T}
float_type(::Type{ClosedInterval}) = ClosedInterval{Float32}
float_type(::AbstractArray{T}) where {T} = float_type(T)
float_type(::AbstractPolygon{N, T}) where {N, T} = Point{N, float_type(T)}

float_convert(x) = convert(float_type(x), x)
float_convert(x::AbstractArray{Float32}) = x
float_convert(x::AbstractArray{Float64}) = x
float_convert(x::AbstractArray) = elconvert(float_type(x), x)
float_convert(x::Observable) = lift(float_convert, x)
float_convert(x::AbstractArray{<:Union{Missing, T}}) where {T <: Real} = elconvert(float_type(T), x)

float32type(::Type{<:Real}) = Float32
float32type(::Type{Point{N, T}}) where {N, T} = Point{N, float32type(T)}
float32type(::Type{Vec{N, T}}) where {N, T} = Vec{N, float32type(T)}

# We may want to always use UInt8 for colors?
float32type(::Type{<:RGB{N0f8}}) = RGB{N0f8}
float32type(::Type{<:RGBA{N0f8}}) = RGBA{N0f8}
float32type(::Type{<:RGB}) = RGB{Float32}
float32type(::Type{<:RGBA}) = RGBA{Float32}
float32type(::Type{<:Colorant}) = RGBA{Float32}
float32type(::AbstractArray{T}) where {T} = float32type(T)
float32type(::T) where {T} = float32type(T)
float32type(T::Type) = MethodError(float32type, (T,))

el32convert(x::ClosedInterval) = Float32(minimum(x)) .. Float32(maximum(x))
el32convert(x::Base.ReinterpretArray) = collect(elconvert(float32type(x), x))
el32convert(x::AbstractArray) = elconvert(float32type(x), x)
el32convert(x::AbstractArray{T}) where {T <: Real} = elconvert(float32type(T), x)
el32convert(x::AbstractArray{<:Union{Missing, T}}) where {T <: Real} = elconvert(float32type(T), x)
el32convert(x::AbstractArray{Float32}) = x
el32convert(x::Observable) = lift(el32convert, x)
el32convert(x) = convert(float32type(x), x)
el32convert(x::Mat{X, Y, T}) where {X, Y, T} = Mat{X, Y, Float32}(x)


"""
    to_triangles(indices)

Convert a representation of triangle point indices `indices` to its canonical representation as a `Vector{Makie.GLTriangleFace}`. `indices` can be any of the following:

- An `AbstractVector{Int}`, containing groups of 3 1-based indices,
- An `AbstractVector{UIn32}`, containing groups of 3 0-based indices,
- An `AbstractVector` of `TriangleFace` objects,
- An `AbstractMatrix` of `Integer`s, where each row is a triangle.
"""
function to_triangles(x::AbstractVector{Int})
    idx0 = UInt32.(x .- 1)
    return to_triangles(idx0)
end

function to_triangles(idx0::AbstractVector{UInt32})
    return reinterpret(GLTriangleFace, idx0)
end

function to_triangles(faces::AbstractVector{TriangleFace{T}}) where {T}
    return elconvert(GLTriangleFace, faces)
end

function to_triangles(faces::AbstractMatrix{T}) where {T <: Integer}
    @assert size(faces, 2) == 3
    return broadcast(1:size(faces, 1), 3) do fidx, n
        GLTriangleFace(ntuple(i -> faces[fidx, i], n))
    end
end

"""
    to_vertices(v)

Converts a representation of vertices `v` to its canonical representation as a
`Vector{Point3f}`. `v` can be:

- An `AbstractVector` of 3-element `Tuple`s or `StaticVector`s,

- An `AbstractVector` of `Tuple`s or `StaticVector`s, in which case extra dimensions will
  be either truncated or padded with zeros as required,

- An `AbstractMatrix`"
  - if `v` has 2 or 3 rows, it will treat each column as a vertex,
  - otherwise if `v` has 2 or 3 columns, it will treat each row as a vertex.
"""
function to_vertices(verts::AbstractVector{<:VecTypes{3, T}}) where {T}
    T_out = float_type(T)
    vert3 = T != T_out ? map(Point3{T_out}, verts) : verts
    return reinterpret(Point3{T_out}, vert3)
end

function to_vertices(verts::AbstractVector{<:VecTypes{N, T}}) where {N, T}
    return map(Point{N, float_type(T)}, verts)
end

function to_vertices(verts::AbstractMatrix{T}) where {T <: Real}
    T_out = float_type(T)
    return if size(verts, 1) in (2, 3)
        to_vertices(verts, T_out, Val(1), Val(size(verts, 1)))
    elseif size(verts, 2) in (2, 3)
        to_vertices(verts, T_out, Val(2), Val(size(verts, 2)))
    else
        error("You are using a matrix for vertices which uses neither dimension to encode the dimension of the space. Please have either size(verts, 1/2) in the range of 2-3. Found: $(size(verts))")
    end
end

function to_vertices(verts::AbstractMatrix{T}, ::Type{Tout}, ::Val{1}, ::Val{N}) where {T <: Real, Tout, N}
    if T == Tout && N == 3
        return reinterpret(Point{N, T}, elconvert(T, vec(verts)))
    else
        return Point{N, Tout}[ntuple(j -> Tout(verts[j, i]), N) for i in 1:size(verts, 2)]
    end
end

function to_vertices(verts::AbstractMatrix{T}, ::Type{Tout}, ::Val{2}, ::Val{N}) where {T <: Real, Tout, N}
    return Point{N, Tout}[ntuple(j -> Tout(verts[i, j]), N) for i in 1:size(verts, 1)]
end


################################################################################
### Unused?
################################################################################

# The following `tryrange` code was copied from Plots.jl
# https://github.com/MakieOrg/Plots.jl/blob/15dc61feb57cba1df524ce5d69f68c2c4ea5b942/src/series.jl#L399-L416

# try some intervals over which the function may be defined
function tryrange(F::AbstractArray, vec)
    rets = [tryrange(f, vec) for f in F] # get the preferred for each
    maxind = maximum(indexin(rets, vec)) # get the last attempt that succeeded (most likely to fit all)
    rets .= [tryrange(f, vec[maxind:maxind]) for f in F] # ensure that all functions compute there
    return rets[1]
end

function tryrange(F, vec)
    for v in vec
        try
            tmp = F(v)
            return v
        catch
        end
    end
    error("$F is not a Function, or is not defined at any of the values $vec")
end


################################################################################
#                            Attribute conversions                             #
################################################################################


# convert_attribute(s::SceneLike, x, key::Key, ::Key) = convert_attribute(s, x, key)
# convert_attribute(s::SceneLike, x, key::Key) = convert_attribute(x, key)
convert_attribute(x, key::Key, ::Key) = convert_attribute(x, key)
convert_attribute(x, key::Key) = x

# Normalize for cycle to be nothing if there's nothing to cycle!
convert_attribute(cycle::Vector, ::key"cycle") = isempty(cycle) ? nothing : Cycle(cycle)
convert_attribute(cycle::Nothing, ::key"cycle") = cycle
convert_attribute(cycle, ::key"cycle") = Cycle(cycle)


convert_attribute(font, ::key"font") = to_font(font)
convert_attribute(align, ::key"align") = to_align(align)

convert_attribute(x::Automatic, ::key"color") = x
convert_attribute(color, ::key"color") = to_color(color)

convert_attribute(colormap, ::key"colormap") = Ref{Any}(colormap)

convert_attribute(c, ::key"highclip") = Ref{Union{Automatic, RGBAf}}(to_color(c))
convert_attribute(::Union{Automatic, Nothing}, ::key"highclip") = Ref{Union{Automatic, RGBAf}}(automatic)
convert_attribute(c, ::key"lowclip") = Ref{Union{Automatic, RGBAf}}(to_color(c))
convert_attribute(::Union{Automatic, Nothing}, ::key"lowclip") = Ref{Union{Automatic, RGBAf}}(automatic)

convert_attribute(x, ::key"colorscale") = Ref{Any}(x)

# TODO: is it worth typing this as Ref{Union{Automatic, VecTypes{2}, Tuple{<: Real, <: Real}}} ?
convert_attribute(x::Automatic, ::key"colorrange") = Ref{Any}(x)
convert_attribute(x, ::key"colorrange") = Ref{Any}(to_colorrange(x))
to_colorrange(x) = isnothing(x) ? nothing : Vec2f(x)

convert_attribute(p, ::key"nan_color") = to_color(p)

struct Palette
    colors::Vector{RGBA{Float32}}
    i::Ref{Int}
    Palette(colors) = new(to_color.(colors), zero(Int))
end
Palette(name::Union{String, Symbol}, n = 8) = Palette(categorical_colors(name, n))

function to_color(p::Palette)
    N = length(p.colors)
    p.i[] = p.i[] == N ? 1 : p.i[] + 1
    return p.colors[p.i[]]
end

to_color(c::Nothing) = c # for when color is not used
to_color(c::Real) = Float32(c)
to_color(c::Colorant) = convert(RGBA{Float32}, c)
to_color(c::VecTypes{3}) = RGBAf(c[1], c[2], c[3], 1)
to_color(c::VecTypes{4}) = RGBAf(c[1], c[2], c[3], c[4])
to_color(c::Symbol) = to_color(string(c))
to_color(c::String) = parse(RGBA{Float32}, c)
to_color(c::AbstractArray) = to_color.(c)
to_color(c::AbstractArray{<:Colorant, N}) where {N} = convert(Array{RGBAf, N}, c)
to_color(p::AbstractPattern) = p
function to_color(c::Tuple{<:Any, <:Number})
    col = to_color(c[1])
    return RGBAf(Colors.color(col), alpha(col) * c[2])
end

convert_attribute(r, ::key"rotation", ::key"scatter") = Ref{Any}(r)
convert_attribute(b::Billboard{Float32}, ::key"rotation") = to_rotation(b.rotation)
convert_attribute(b::Billboard{Vector{Float32}}, ::key"rotation") = to_rotation.(b.rotation)
convert_attribute(r::AbstractArray, ::key"rotation") = to_rotation.(r)
convert_attribute(r::StaticVector, ::key"rotation") = to_rotation(r)
convert_attribute(r, ::key"rotation") = to_rotation(r)

convert_attribute(c, ::key"markersize", ::key"scatter") = to_2d_scale(c)
convert_attribute(c, ::key"markersize", ::key"meshscatter") = to_3d_scale(c)
to_2d_scale(x::Number) = Vec2f(x)
to_2d_scale(x::VecTypes) = to_ndim(Vec2f, x, 1)
to_2d_scale(x::Tuple{<:Number, <:Number}) = to_ndim(Vec2f, x, 1)
to_2d_scale(x::AbstractVector) = to_2d_scale.(x)

to_3d_scale(x::Number) = Vec3f(x)
to_3d_scale(x::VecTypes) = to_ndim(Vec3f, x, 1)
to_3d_scale(x::AbstractVector) = to_3d_scale.(x)

convert_attribute(o, ::key"marker_offset", ::key"scatter") = to_3d_offset(o)
# Is it reasonable to go from offset -> (offset, 0, 0)?
to_3d_offset(x::VecTypes) = to_ndim(Vec3f, x, 0)
to_3d_offset(x::AbstractVector) = to_3d_offset.(x)


## UV Transforms

# defaults that place a cow image the same way as the image
# convert_attribute(::Automatic, ::key"uv_transform", ::key"meshscatter") = Mat{2, 3, Float32}(0, 1, 1, 0, 0, 0)
# convert_attribute(::Automatic, ::key"uv_transform", ::key"mesh") = Mat{2, 3, Float32}(0, 1, 1, 0, 0, 0)
# convert_attribute(::Automatic, ::key"uv_transform", ::key"surface") = Mat{2, 3, Float32}(0, 1, -1, 0, 1, 0)
# convert_attribute(::Automatic, ::key"uv_transform", ::key"image") = Mat{2, 3, Float32}(0, 1, 1, 0, 0, 0)

# defaults matching master
# Note - defaults with Patterns should be identity (handled in backends)
convert_attribute(::Automatic, ::key"uv_transform", ::key"meshscatter") = Mat{2, 3, Float32}(0, 1, -1, 0, 1, 0)
convert_attribute(::Automatic, ::key"uv_transform", ::key"mesh") = Mat{2, 3, Float32}(0, 1, -1, 0, 1, 0)
convert_attribute(::Automatic, ::key"uv_transform", ::key"surface") = Mat{2, 3, Float32}(1, 0, 0, -1, 0, 1)
convert_attribute(::Automatic, ::key"uv_transform", ::key"image") = Mat{2, 3, Float32}(1, 0, 0, -1, 0, 1)

# Careful: Mat <: AbstractArray, which should be handled by other methods
convert_attribute(x::Array, k::key"uv_transform") = convert_attribute.(x, Ref(k))
convert_attribute(x, k::key"uv_transform") = convert_attribute(uv_transform(x), k)
convert_attribute(x::Mat{3, 3}, k::key"uv_transform") = convert_attribute(Mat3f(x), k)
convert_attribute(x::Mat{2, 3}, k::key"uv_transform") = convert_attribute(Mat{2, 3, Float32}(x), k)
convert_attribute(x::Mat3f, ::key"uv_transform") = x[Vec(1, 2), Vec(1, 2, 3)]
convert_attribute(x::Mat{2, 3, Float32}, ::key"uv_transform") = x
convert_attribute(x::Nothing, ::key"uv_transform") = x

function convert_attribute(angle::Real, ::key"uv_transform")
    # To rotate an image with uvs in the 0..1 range we need to translate,
    # rotate, translate back.
    # For patterns and in terms of what's actually happening to the uvs we
    # should not translate at all.
    error(
        "Creating a uv_transform from a rotation angle is not implemented directly because one usually " *
            "needs to translate as well to deal with the 0..1 value range. Use :rotr90, :rotl90, :rot180, " *
            "Makie.uv_transform(angle) or multi-step expression (tuple) instead."
    )
end

"""
    uv_transform(args::Tuple)
    uv_transform(args...)

Returns a 3x3 uv transformation matrix combining all the given arguments. This
lowers to `mapfoldl(uv_transform, *, args)` so operations act from right to left
like matrices `(op3, op2, op1)`.

Note that `Tuple{VecTypes{2, <:Real}, VecTypes{2, <:Real}}` maps to
`uv_transform(translation, scale)` as a special case.
"""
function uv_transform(packed::Tuple)
    combine(a::Mat3f, b::Mat3f) = a * b
    # The arrays have already been copied by uv_transform(array)
    combine(a::Array, b::Mat3f) = a .= a .* Ref(b)
    combine(a::Mat3f, b::Array) = b .= Ref(a) .* b
    combine(a::Array, b::Array) = a .= a .* b

    return mapfoldl(uv_transform, combine, packed)
end
uv_transform(packed...) = uv_transform(packed)

"""
    uv_transform(::UniformScaling)
    uv_transform(::typeof(identity))

Returns a 3x3 identity matrix When passing `I` or `identity`.
"""
uv_transform(::UniformScaling) = Mat{3, 3, Float32}(I)
uv_transform(::typeof(identity)) = Mat{3, 3, Float32}(I)

# repeated for packed uv_transforms
# Careful: Mat <: AbstractArray, which should be handled by other methods
uv_transform(x::Array) = uv_transform.(x)
uv_transform(M::Mat{2, 3}) = Mat3f(M[1], M[2], 0, M[3], M[4], 0, M[5], M[6], 1)

# prefer scale as single argument since it may be useful for patterns
# while just translation is mostly useless
"""
    uv_transform(scale::VecTypes{2})
    uv_transform(translation::VecTypes{2}, scale::VecTypes{2})
    uv_transform(angle::Real)

Creates a 3x3 uv transformation matrix based on the given translation and scale
or rotation angle (around z axis).
"""
uv_transform(x::Tuple{VecTypes{2, <:Real}, VecTypes{2, <:Real}}) = uv_transform(x[1], x[2])
uv_transform(scale::VecTypes{2, <:Real}) = uv_transform(Vec2f(0), scale)
function uv_transform(translation::VecTypes{2, <:Real}, scale::VecTypes{2, <:Real})
    return Mat3f(
        scale[1], 0, 0,
        0, scale[2], 0,
        translation[1], translation[2], 1
    )
end
function uv_transform(angle::Real)
    return Mat3f(
        cos(angle), sin(angle), 0,
        -sin(angle), cos(angle), 0,
        0, 0, 1
    )
end

"""
    uv_transform(action::Symbol)

Creates a 3x3 uv transformation matrix from a given named action. They assume
`0 < uv < 1` and thus may not work correctly with Patterns. The actions include
- `:rotr90` corresponding to `rotr90(texture)`
- `:rotl90` corresponding to `rotl90(texture)`
- `:rot180` corresponding to `rot180(texture)`
- `:swap_xy, :transpose` which corresponds to transposing the texture
- `:flip_x, :flip_y, :flip_xy` which flips the x/y/both axis of a texture
- `:mesh, :meshscatter, :surface, :image` which grabs the default of the corresponding plot type
- `:identity` corresponding to no change/identity
"""
function uv_transform(action::Symbol)
    # TODO: do some explicitly named operations
    if action === :rotr90
        return Mat3f(0, 1, 0, -1, 0, 0, 1, 0, 1)
    elseif action === :rotl90
        return Mat3f(0, -1, 0, 1, 0, 0, 0, 1, 1)
    elseif action === :rot180
        return Mat3f(-1, 0, 0, 0, -1, 0, 1, 1, 1)
    elseif action in (:swap_xy, :transpose)
        return Mat3f(0, 1, 0, 1, 0, 0, 0, 0, 1)
    elseif action in (:flip_x, :invert_x)
        return Mat3f(-1, 0, 0, 0, 1, 0, 1, 0, 1)
    elseif action in (:flip_y, :invert_y)
        return Mat3f(1, 0, 0, 0, -1, 0, 0, 1, 1)
    elseif action in (:flip_xy, :invert_xy)
        return Mat3f(-1, 0, 0, 0, -1, 0, 1, 1, 1)
    elseif action in (:meshscatter, :mesh, :image, :surface)
        M = convert_attribute(automatic, key"uv_transform"(), Key{action}())
        return Mat3f(M[1, 1], M[2, 1], 0, M[1, 2], M[2, 2], 0, M[1, 3], M[2, 3], 1)
        # elseif action == :surface
        # return Mat3f(I)
    elseif action === :identity
        return Mat3f(I)
    else
        error("Transformation :$action not recognized.")
    end
end

convert_attribute(x, ::key"uv_offset_width") = Vec4f(x)
convert_attribute(x::AbstractVector{Vec4f}, ::key"uv_offset_width") = x


convert_attribute(c::Number, ::key"glowwidth") = Float32(c)
convert_attribute(c::Number, ::key"strokewidth") = Float32(c)

convert_attribute(c, ::key"glowcolor") = to_color(c)
convert_attribute(c, ::key"strokecolor") = to_color(c)

####
## Line style conversions
####

convert_attribute(style, ::key"linestyle") = to_linestyle(style)
to_linestyle(::Nothing) = nothing
# add deprecation for old conversion
function convert_attribute(style::AbstractVector, ::key"linestyle")
    @warn "Using a `Vector{<:Real}` as a linestyle attribute is deprecated. Wrap it in a `Linestyle`."
    return to_linestyle(Linestyle(style))
end

"""
    Linestyle(value::Vector{<:Real})

A type that can be used as value for the `linestyle` keyword argument
of plotting functions to arbitrarily customize the linestyle.

The `value` is a vector specifying the boundaries of the dashes in the line.
Values 1 and 2 demarcate the first dash, values 2 and 3 the first gap, and so on.
This means that usually, a pattern should have an odd number of values so that there's
always a gap after a dash.

Here's an example in ASCII code. If we specify `[0, 3, 6, 11, 16]` then we get the following
pattern:

```
#  0  3   6   11   16  3  6   11
#   ---   -----     ---   -----
```
"""
struct Linestyle
    value::Vector{Float32}
end

to_linestyle(style::Linestyle) = Float32[x - style.value[1] for x in style.value]

# TODO only use NTuple{2, <: Real} and not any other container
const GapType = Union{Real, Symbol, Tuple, AbstractVector}

# A `Symbol` equal to `:dash`, `:dot`, `:dashdot`, `:dashdotdot`
to_linestyle(ls::Union{Symbol, AbstractString}) = line_pattern(ls, :normal)

function to_linestyle(ls::Tuple{<:Union{Symbol, AbstractString}, <:GapType})
    return line_pattern(ls[1], ls[2])
end

function line_pattern(linestyle::Symbol, gaps::GapType)
    pattern = line_diff_pattern(linestyle, gaps)
    return isnothing(pattern) ? pattern : Float32[0.0; cumsum(pattern)]
end

"The linestyle patterns are inspired by the LaTeX package tikZ as seen here https://tex.stackexchange.com/questions/45275/tikz-get-values-for-predefined-dash-patterns."

function line_diff_pattern(ls::Symbol, gaps::GapType = :normal)
    if ls === :solid
        return nothing
    elseif ls === :dash
        return line_diff_pattern("-", gaps)
    elseif ls === :dot
        return line_diff_pattern(".", gaps)
    elseif ls === :dashdot
        return line_diff_pattern("-.", gaps)
    elseif ls === :dashdotdot
        return line_diff_pattern("-..", gaps)
    else
        error(
            """
            Unknown line style: $ls. Available linestyles are:
            :solid, :dash, :dot, :dashdot, :dashdotdot
            or a sequence of numbers enumerating the next transparent/opaque region.
            This sequence of numbers must be cumulative; 1 unit corresponds to 1 line width.
            """
        )
    end
end

function line_diff_pattern(ls_str::AbstractString, gaps::GapType = :normal)
    dot = 1
    dash = 3
    check_line_pattern(ls_str)

    dot_gap, dash_gap = convert_gaps(gaps)

    pattern = Float64[]
    for i in 1:length(ls_str)
        curr_char = ls_str[i]
        next_char = i == lastindex(ls_str) ? ls_str[firstindex(ls_str)] : ls_str[i + 1]
        # push dash or dot
        if curr_char == '-'
            push!(pattern, dash)
        else
            push!(pattern, dot)
        end
        # push the gap (use dot_gap only between two dots)
        if (curr_char == '.') && (next_char == '.')
            push!(pattern, dot_gap)
        else
            push!(pattern, dash_gap)
        end
    end
    return pattern
end

"Checks if the linestyle format provided as a string contains only dashes and dots"
function check_line_pattern(ls_str)
    isnothing(match(r"^[.-]+$", ls_str)) &&
        throw(ArgumentError("If you provide a string as linestyle, it must only consist of dashes (-) and dots (.)"))

    return nothing
end

function convert_gaps(gaps::GapType)
    error_msg = "You provided the gaps modifier $gaps when specifying the linestyle. The modifier must be one of the symbols `:normal`, `:dense` or `:loose`, a real number or a tuple of two real numbers."
    if gaps isa Symbol
        gaps in [:normal, :dense, :loose] || throw(ArgumentError(error_msg))
        dot_gaps = (normal = 2, dense = 1, loose = 4)
        dash_gaps = (normal = 3, dense = 2, loose = 6)

        dot_gap = getproperty(dot_gaps, gaps)
        dash_gap = getproperty(dash_gaps, gaps)
    elseif gaps isa Real
        dot_gap = gaps
        dash_gap = gaps
    elseif length(gaps) == 2 && eltype(gaps) <: Real
        dot_gap, dash_gap = gaps
    else
        throw(ArgumentError(error_msg))
    end
    return (dot_gap = dot_gap, dash_gap = dash_gap)
end

function convert_attribute(value::Symbol, ::key"linecap")
    # TODO: make this an enum?
    vals = Dict(:butt => Int32(0), :square => Int32(1), :round => Int32(2))
    return get(vals, value) do
        error("$value is not a valid cap style. It must be one of $(keys(vals)).")
    end
end

function convert_attribute(value::Symbol, ::key"joinstyle")
    # TODO: make this an enum?
    # 0 and 2 are shared between this and linecap. 1 has no equivalent here
    vals = (miter = Int32(0), round = Int32(2), bevel = Int32(3))
    return get(vals, value) do
        error("$value is not a valid joinstyle. It must be one of $(keys(vals)).")
    end
end

"""
    miter_distance_to_angle(distance[, directed = false])

Calculates the inner angle between two joined line segments corresponding to the
distance between the line point (corner at linewidth → 0) and the outer corner.
The distance is given in units of linewidth. If `directed = true` the distance
in line direction is used instead.

With respect to miter limits, a linejoin gets truncated if the corner distance
exceeds a given limit or analogously the angle falls below a certain limit. This
function calculates the angle given a distance.
"""
function miter_distance_to_angle(distance, directed = false)
    if directed
        distance < 0.0 && error("The directed distance cannot be negative.")
        return 2.0 * atan(0.5 / distance)
    else # Cairo style
        distance < 0.5 && error("The undirected distance cannot be smaller than 0.5 as the outer corner is always at least half a linewidth away from the line point.")
        return 2.0 * asin(0.5 / distance)
    end
end

"""
    miter_angle_to_distance(angle, directed = false)

Calculates the inverse of `miter_distance_to_angle` with an angle given in radians.
"""
function miter_angle_to_distance(angle, directed = false)
    0.0 < angle < pi || error("Angle must be between 0 and pi.")
    return directed ? 0.5 / tan(0.5 * angle) : 0.5 / sin(0.5 * angle)
end


convert_attribute(c::Tuple{<:Number, <:Number}, ::key"position") = Point2f(c[1], c[2])
convert_attribute(c::Tuple{<:Number, <:Number, <:Number}, ::key"position") = Point3f(c)
convert_attribute(c::VecTypes{N}, ::key"position") where {N} = Point{N, Float32}(c)

"""
    to_align(align[, error_prefix])

Converts the given align to a `Vec2f`. Can convert `VecTypes{2}` and two
component `Tuple`s with `Real` and `Symbol` elements.

To specify a custom error message you can add an `error_prefix` or use
`halign2num(value, error_msg)` and `valign2num(value, error_msg)` respectively.
"""
to_align(x::AbstractVector) = to_align.(x)
to_align(x::Tuple) = Vec2f(halign2num(x[1]), valign2num(x[2]))
to_align(x::VecTypes{2, <:Real}) = Vec2f(x)

function to_align(v, error_prefix::String)
    try
        return to_align(v)
    catch
        error(error_prefix)
    end
end

"""
    halign2num(align[, error_msg])

Attempts to convert a horizontal align to a Float32 and errors with `error_msg`
if it fails to do so.
"""
halign2num(v::Real, error_msg = "") = Float32(v)
function halign2num(v::Symbol, error_msg = "Invalid halign $v. Valid values are <:Real, :left, :center and :right.")
    if v === :left
        return 0.0f0
    elseif v === :center
        return 0.5f0
    elseif v === :right
        return 1.0f0
    else
        error(error_msg)
    end
end
function halign2num(v, error_msg = "Invalid halign $v. Valid values are <:Real, :left, :center and :right.")
    error(error_msg)
end

"""
    valign2num(align[, error_msg])

Attempts to convert a vertical align to a Float32 and errors with `error_msg`
if it fails to do so.
"""
valign2num(v::Real, error_msg = "") = Float32(v)
function valign2num(v::Symbol, error_msg = "Invalid valign $v. Valid values are <:Real, :bottom, :top, and :center.")
    if v === :top
        return 1.0f0
    elseif v === :bottom
        return 0.0f0
    elseif v === :center
        return 0.5f0
    else
        error(error_msg)
    end
end
function valign2num(v, error_msg = "Invalid valign $v. Valid values are <:Real, :bottom, :top, and :center.")
    error(error_msg)
end

"""
    angle2align(angle::Real)

Converts a given angle to an alignment by projecting the resulting direction on
a unit square and scaling the result to a 0..1 range appropriate for alignments.
"""
function angle2align(angle::Real)
    s, c = sincos(angle)
    scale = 1 / max(abs(s), abs(c))
    return Vec2f(0.5scale * c + 0.5, 0.5scale * s + 0.5)
end


const FONT_CACHE = Dict{String, NativeFont}()
const FONT_CACHE_LOCK = Base.ReentrantLock()

function load_font(filepath)
    font = FreeTypeAbstraction.try_load(filepath)
    if isnothing(font)
        error("Could not load font file \"$filepath\"")
    else
        return font
    end
end

"""
    to_font(str::String)

Loads a font specified by `str` and returns a `NativeFont` object storing the font handle.
A font can either be specified by a file path, such as "folder/with/fonts/font.otf",
or by a (partial) name such as "Helvetica", "Helvetica Bold" etc.
"""
function to_font(str::String)
    return lock(FONT_CACHE_LOCK) do
        return get!(FONT_CACHE, str) do
            # load default fonts without font search to avoid latency
            if str == "default" || str == "TeX Gyre Heros Makie"
                return load_font(assetpath("fonts", "TeXGyreHerosMakie-Regular.otf"))
            elseif str == "TeX Gyre Heros Makie Bold"
                return load_font(assetpath("fonts", "TeXGyreHerosMakie-Bold.otf"))
            elseif str == "TeX Gyre Heros Makie Italic"
                return load_font(assetpath("fonts", "TeXGyreHerosMakie-Italic.otf"))
            elseif str == "TeX Gyre Heros Makie Bold Italic"
                return load_font(assetpath("fonts", "TeXGyreHerosMakie-BoldItalic.otf"))
                # load fonts directly if they are given as font paths
            elseif isfile(str)
                return load_font(str)
            end
            # for all other cases, search for the best match on the system
            fontpath = assetpath("fonts")
            font = FreeTypeAbstraction.findfont(str; additional_fonts = fontpath)
            if font === nothing
                @warn("Could not find font $str, using TeX Gyre Heros Makie")
                return to_font("TeX Gyre Heros Makie")
            end
            return font
        end
    end
end
to_font(x::Vector{String}) = to_font.(x)
to_font(x::NativeFont) = x
to_font(x::Vector{NativeFont}) = x

function to_font(fonts::Attributes, s::Symbol)
    if haskey(fonts, s)
        f = fonts[s][]
        if f isa Symbol
            error("The value for font $(repr(s)) was Symbol $(repr(f)), which is not allowed. The value for a font in the fonts collection cannot be another Symbol and must be resolvable via `to_font(x)`.")
        end
        return to_font(fonts[s][])
    end
    error("The symbol $(repr(s)) is not present in the fonts collection:\n$fonts.")
end

to_font(fonts::Attributes, x) = to_font(x)

to_font(::Automatic) = defaultfont()


"""
    rotation accepts:
    to_rotation(b, quaternion)
    to_rotation(b, tuple_float)
    to_rotation(b, vec4)
"""
to_rotation(s::Quaternionf) = s
to_rotation(s::Quaternion) = Quaternionf(s.data...)

function to_rotation(s::VecTypes{N}) where {N}
    return if N == 4
        Quaternionf(s...)
    elseif N == 3
        rotation_between(Vec3f(0, 0, 1), to_ndim(Vec3f, s, 0.0))
    elseif N == 2
        rotation_between(Vec3f(0, 1, 0), to_ndim(Vec3f, s, 0.0))
    else
        error("The $N dimensional vector $s can't be converted to a rotation.")
    end
end

to_rotation(s::Tuple{VecTypes, Number}) = qrotation(to_ndim(Vec3f, s[1], 0.0), s[2])
to_rotation(angle::Number) = qrotation(Vec3f(0, 0, 1), angle)
to_rotation(r::AbstractVector) = to_rotation.(r)
to_rotation(r::AbstractVector{<:Quaternionf}) = r

convert_attribute(x, ::key"fontsize") = to_fontsize(x)
to_fontsize(x::Number) = Float32(x)
to_fontsize(x::AbstractVector{T}) where {T <: Number} = el32convert(x)
to_fontsize(x::Vec2) = Vec2f(x)
to_fontsize(x::AbstractVector{T}) where {T <: Vec2} = Vec2f.(x)

convert_attribute(x, ::key"linewidth") = to_linewidth(x)
to_linewidth(x) = Float32(x)
to_linewidth(x::AbstractVector) = el32convert(x)

# ColorBrewer colormaps that support only 8 colors require special handling on the backend, so we show them here.
const colorbrewer_8color_names = String.(
    [
        :Accent,
        :Dark2,
        :Pastel2,
        :Set2,
    ]
)

const plotutils_names = String.(
    union(
        keys(PlotUtils.ColorSchemes.colorschemes),
        keys(PlotUtils.COLORSCHEME_ALIASES),
        keys(PlotUtils.MISC_COLORSCHEMES)
    )
)

const all_gradient_names = Set(vcat(plotutils_names, colorbrewer_8color_names))

"""
    available_gradients()

Prints all available gradient names.
"""
function available_gradients()
    println("Gradient Symbol/Strings:")
    for name in sort(collect(all_gradient_names))
        println("    ", name)
    end
    return
end


to_colormap(cm, categories::Integer) = error("`to_colormap(cm, categories)` is deprecated. Use `Makie.categorical_colors(cm, categories)` for categorical colors, and `resample_cmap(cmap, ncolors)` for continuous resampling.")

"""
    categorical_colors(colormaplike, categories::Integer)

Creates categorical colors and tries to match `categories`.
Will error if color scheme doesn't contain enough categories. Will drop the n last colors, if request less colors than contained in scheme.
"""
function categorical_colors(cols::AbstractVector{<:Colorant}, categories::Integer)
    if length(cols) < categories
        error("Not enough colors for number of categories. Categories: $(categories), colors: $(length(cols))")
    end
    return cols[1:categories]
end

function categorical_colors(cols::AbstractVector, categories::Integer)
    return categorical_colors(to_color.(cols), categories)
end

function categorical_colors(cs::Union{String, Symbol}, categories::Integer)
    cs_string = string(cs)
    return if cs_string in all_gradient_names
        if haskey(ColorBrewer.colorSchemes, cs_string)
            return to_colormap(ColorBrewer.palette(cs_string, categories))
        else
            return categorical_colors(to_colormap(cs_string), categories)
        end
    else
        error(
            """
            There is no color gradient named $cs.
            See `available_gradients()` for the list of available gradients,
            or look at https://docs.makie.org/dev/explanations/colors#Colormaps.
            """
        )
    end
end

"""
Reverses the attribute T upon conversion
"""
struct Reverse{T}
    data::T
end

to_colormap(r::Reverse) = reverse(to_colormap(r.data))
to_colormap(cs::ColorScheme) = to_colormap(cs.colors)


"""
    to_colormap(b::AbstractVector)

An `AbstractVector{T}` with any object that `to_color` accepts.
"""
to_colormap(cm::AbstractVector)::Vector{RGBAf} = map(to_color, cm)
to_colormap(cm::AbstractVector{<:Colorant}) = convert(Vector{RGBAf}, cm)

function to_colormap(cs::Tuple{<:Union{Reverse, Symbol, AbstractString}, Real})::Vector{RGBAf}
    cmap = to_colormap(cs[1])
    return RGBAf.(color.(cmap), alpha.(cmap) .* cs[2]) # We need to rework this to conform to the backend interface.
end

"""
    to_colormap(cs::Union{String, Symbol})::Vector{RGBAf}

A Symbol/String naming the gradient. For more on what names are available please see: `available_gradients()`.
For now, we support gradients from `PlotUtils` natively.
"""
function to_colormap(cs::Union{String, Symbol})::Vector{RGBAf}
    cs_string = string(cs)
    return if cs_string in all_gradient_names
        if cs_string in colorbrewer_8color_names # special handling for 8 color only
            return to_colormap(ColorBrewer.palette(cs_string, 8))
        else
            # cs_string must be in plotutils_names
            return to_colormap(PlotUtils.get_colorscheme(Symbol(cs_string)))
        end
    else
        error(
            """
            There is no color gradient named $cs.
            See `Makie.available_gradients()` for the list of available gradients,
            or look at https://docs.makie.org/dev/explanations/colors#Colormaps.
            """
        )
    end
end

# Handle inbuilt PlotUtils types
function to_colormap(cg::PlotUtils.ColorGradient)::Vector{RGBAf}
    # We sample the colormap using cg[val]. This way, we get a concrete representation of
    # the underlying gradient, like it being categorical or using a log scale.
    # 256 is just a high enough constant, without being too big to slow things down.
    return to_colormap(getindex.(Ref(cg), LinRange(first(cg.values), last(cg.values), 256)))
end

"""
    to_colormapping_type(colormap)
Returns `continuous`, `categorical` or `banded` according to the type of the
colormap passed.
Note: Currently recognizes all named colormaps as continuous. To recognize them
as categorical they need to be wrapped in `Categorical(colormap)`.
"""
to_colormapping_type(::Any) = continuous
to_colormapping_type(::Categorical) = categorical
to_colormapping_type(::PlotUtils.CategoricalColorGradient) = banded
to_colormapping_type(x::Tuple{<:Any, <:Real}) = to_colormapping_type(x[1])
to_colormapping_type(x::Reverse) = to_colormapping_type(x.data)
# TODO: Would be nice if we could extract more information like colorscale from
#       PlotUtils, colormapping types from ColorSchemes, ...

# Enum values: `IsoValue` `Absorption` `MaximumIntensityProjection` `AbsorptionRGBA` `AdditiveRGBA` `IndexedAbsorptionRGBA`
function convert_attribute(value, ::key"algorithm")
    if isa(value, RaymarchAlgorithm)
        return Int32(value)
    elseif isa(value, Integer) && value in 0:5
        return Int32(value)
    elseif value == 7
        return Int32(value) # makie internal contour implementation
    else
        error("$value is not a valid volume algorithm. Please have a look at the docstring of `to_volume_algorithm` (in the REPL, `?to_volume_algorithm`).")
    end
end

# Symbol/String: iso, absorption, mip, absorptionrgba, indexedabsorption
function convert_attribute(value::Union{Symbol, String}, k::key"algorithm")
    vals = Dict(
        :iso => IsoValue,
        :absorption => Absorption,
        :mip => MaximumIntensityProjection,
        :absorptionrgba => AbsorptionRGBA,
        :indexedabsorption => IndexedAbsorptionRGBA,
        :additive => AdditiveRGBA,
    )
    return convert_attribute(
        get(vals, Symbol(value)) do
            error("$value is not a valid volume algorithm. It must be one of $(keys(vals))")
        end, k
    )
end

#=
The below is the output from:
```julia
# The bezier markers should not look out of place when used together with text
# where both markers and text are given the same size, i.e. the marker and fontsizes
# should correspond approximately in a visual sense.

# All the basic bezier shapes are approximately built in a 1 by 1 square centered
# around the origin, with slight deviations to match them better to each other.

# An 'x' of DejaVu sans is only about 55pt high at 100pt font size, so if the marker
# shapes are just used as is, they look much too large in comparison.
# To me, a factor of 0.75 looks ok compared to both uppercase and lowercase letters of Dejavu.
size_factor = 0.75
DEFAULT_MARKER_MAP[:rect] = scale(BezierSquare, size_factor)
DEFAULT_MARKER_MAP[:diamond] = scale(rotate(BezierSquare, pi/4), size_factor)
DEFAULT_MARKER_MAP[:hexagon] = scale(bezier_ngon(6, 0.5, pi/2), size_factor)
DEFAULT_MARKER_MAP[:cross] = scale(BezierCross, size_factor)
DEFAULT_MARKER_MAP[:xcross] = scale(BezierX, size_factor)
DEFAULT_MARKER_MAP[:utriangle] = scale(BezierUTriangle, size_factor)
DEFAULT_MARKER_MAP[:dtriangle] = scale(BezierDTriangle, size_factor)
DEFAULT_MARKER_MAP[:ltriangle] = scale(BezierLTriangle, size_factor)
DEFAULT_MARKER_MAP[:rtriangle] = scale(BezierRTriangle, size_factor)
DEFAULT_MARKER_MAP[:pentagon] = scale(bezier_ngon(5, 0.5, pi/2), size_factor)
DEFAULT_MARKER_MAP[:octagon] = scale(bezier_ngon(8, 0.5, pi/2), size_factor)
DEFAULT_MARKER_MAP[:star4] = scale(bezier_star(4, 0.25, 0.6, pi/2), size_factor)
DEFAULT_MARKER_MAP[:star5] = scale(bezier_star(5, 0.28, 0.6, pi/2), size_factor)
DEFAULT_MARKER_MAP[:star6] = scale(bezier_star(6, 0.30, 0.6, pi/2), size_factor)
DEFAULT_MARKER_MAP[:star8] = scale(bezier_star(8, 0.33, 0.6, pi/2), size_factor)
DEFAULT_MARKER_MAP[:vline] = scale(scale(BezierSquare, (0.2, 1.0)), size_factor)
DEFAULT_MARKER_MAP[:hline] = scale(scale(BezierSquare, (1.0, 0.2)), size_factor)
DEFAULT_MARKER_MAP[:+] = scale(BezierCross, size_factor)
DEFAULT_MARKER_MAP[:x] = scale(BezierX, size_factor)
DEFAULT_MARKER_MAP[:circle] = scale(BezierCircle, size_factor)
```
We have to write this out to make sure we rotate/scale don't generate slightly different values between Julia versions.
This would create different hashes, making the caching in the texture atlas fail!
See: https://github.com/MakieOrg/Makie.jl/pull/3394
=#

const DEFAULT_MARKER_MAP = Dict(
    :+ => BezierPath(
        [
            Makie.MoveTo([0.1245, 0.375]),
            Makie.LineTo([0.1245, 0.1245]),
            Makie.LineTo([0.375, 0.1245]),
            Makie.LineTo([0.375, -0.12449999999999999]),
            Makie.LineTo([0.1245, -0.1245]),
            Makie.LineTo([0.12450000000000003, -0.375]),
            Makie.LineTo([-0.12449999999999997, -0.375]),
            Makie.LineTo([-0.12449999999999999, -0.12450000000000003]),
            Makie.LineTo([-0.375, -0.12450000000000006]),
            Makie.LineTo([-0.375, 0.12449999999999994]),
            Makie.LineTo([-0.12450000000000003, 0.12449999999999999]),
            Makie.LineTo([-0.12450000000000007, 0.37499999999999994]),
            Makie.ClosePath(),
        ]
    ),
    :diamond => BezierPath(
        [
            Makie.MoveTo(
                [
                    0.4464931614186469,
                    -5.564531862779532e-17,
                ]
            ),
            Makie.LineTo(
                [
                    2.10398220755128e-17,
                    0.4464931614186469,
                ]
            ),
            Makie.LineTo(
                [
                    -0.4464931614186469,
                    5.564531862779532e-17,
                ]
            ),
            Makie.LineTo(
                [
                    -2.10398220755128e-17,
                    -0.4464931614186469,
                ]
            ),
            Makie.ClosePath(),
        ]
    ),
    :star4 => BezierPath(
        [
            Makie.MoveTo(
                [
                    2.7554554183166277e-17,
                    0.44999999999999996,
                ]
            ),
            Makie.LineTo(
                [
                    -0.13258251920342445,
                    0.13258251920342445,
                ]
            ),
            Makie.LineTo(
                [
                    -0.44999999999999996,
                    5.5109108366332553e-17,
                ]
            ),
            Makie.LineTo(
                [
                    -0.13258251920342445,
                    -0.13258251920342445,
                ]
            ),
            Makie.LineTo(
                [
                    -8.266365659379842e-17,
                    -0.44999999999999996,
                ]
            ),
            Makie.LineTo(
                [
                    0.13258251920342445,
                    -0.13258251920342445,
                ]
            ),
            Makie.LineTo(
                [
                    0.44999999999999996,
                    -1.1021821673266511e-16,
                ]
            ),
            Makie.LineTo([0.13258251920342445, 0.13258251920342445]),
            Makie.ClosePath(),
        ]
    ),
    :star8 => BezierPath(
        [
            Makie.MoveTo(
                [
                    2.7554554183166277e-17,
                    0.44999999999999996,
                ]
            ),
            Makie.LineTo([-0.09471414797008038, 0.2286601772904396]),
            Makie.LineTo(
                [
                    -0.31819804608821867,
                    0.31819804608821867,
                ]
            ),
            Makie.LineTo([-0.2286601772904396, 0.09471414797008038]),
            Makie.LineTo(
                [
                    -0.44999999999999996,
                    5.5109108366332553e-17,
                ]
            ),
            Makie.LineTo(
                [
                    -0.2286601772904396,
                    -0.09471414797008038,
                ]
            ),
            Makie.LineTo(
                [
                    -0.31819804608821867,
                    -0.31819804608821867,
                ]
            ),
            Makie.LineTo(
                [
                    -0.09471414797008038,
                    -0.2286601772904396,
                ]
            ),
            Makie.LineTo(
                [
                    -8.266365659379842e-17,
                    -0.44999999999999996,
                ]
            ),
            Makie.LineTo([0.09471414797008038, -0.2286601772904396]),
            Makie.LineTo(
                [
                    0.31819804608821867,
                    -0.31819804608821867,
                ]
            ),
            Makie.LineTo([0.2286601772904396, -0.09471414797008038]),
            Makie.LineTo(
                [
                    0.44999999999999996,
                    -1.1021821673266511e-16,
                ]
            ),
            Makie.LineTo([0.2286601772904396, 0.09471414797008038]),
            Makie.LineTo([0.31819804608821867, 0.31819804608821867]),
            Makie.LineTo([0.09471414797008038, 0.2286601772904396]),
            Makie.ClosePath(),
        ]
    ),
    :star6 => BezierPath(
        [
            Makie.MoveTo(
                [
                    2.7554554183166277e-17,
                    0.44999999999999996,
                ]
            ),
            Makie.LineTo([-0.11249999999999999, 0.1948557123541832]),
            Makie.LineTo([-0.3897114247083664, 0.22499999999999998]),
            Makie.LineTo(
                [
                    -0.22499999999999998,
                    2.7554554183166277e-17,
                ]
            ),
            Makie.LineTo(
                [
                    -0.3897114247083664,
                    -0.22499999999999998,
                ]
            ),
            Makie.LineTo(
                [
                    -0.11249999999999999,
                    -0.1948557123541832,
                ]
            ),
            Makie.LineTo(
                [
                    -8.266365659379842e-17,
                    -0.44999999999999996,
                ]
            ),
            Makie.LineTo([0.11249999999999999, -0.1948557123541832]),
            Makie.LineTo([0.3897114247083664, -0.22499999999999998]),
            Makie.LineTo(
                [
                    0.22499999999999998,
                    -5.5109108366332553e-17,
                ]
            ),
            Makie.LineTo([0.3897114247083664, 0.22499999999999998]),
            Makie.LineTo([0.11249999999999999, 0.1948557123541832]),
            Makie.ClosePath(),
        ]
    ),
    :rtriangle => BezierPath(
        [
            Makie.MoveTo([0.485, -8.909305463796994e-17]),
            Makie.LineTo([-0.24249999999999994, 0.36375]),
            Makie.LineTo(
                [
                    -0.2425000000000001,
                    -0.36374999999999996,
                ]
            ),
            Makie.ClosePath(),
        ]
    ),
    :x => BezierPath(
        [
            Makie.MoveTo([-0.1771302486872301, 0.35319983720268056]),
            Makie.LineTo([1.39759596452057e-17, 0.17606958851545035]),
            Makie.LineTo([0.17713024868723018, 0.3531998372026805]),
            Makie.LineTo([0.3531998372026805, 0.17713024868723012]),
            Makie.LineTo([0.17606958851545035, -1.025465786723834e-17]),
            Makie.LineTo([0.3531998372026805, -0.17713024868723015]),
            Makie.LineTo([0.17713024868723015, -0.3531998372026805]),
            Makie.LineTo([1.1151998010815531e-17, -0.17606958851545035]),
            Makie.LineTo([-0.17713024868723015, -0.3531998372026805]),
            Makie.LineTo([-0.35319983720268044, -0.17713024868723018]),
            Makie.LineTo(
                [
                    -0.17606958851545035,
                    -1.4873299788782892e-17,
                ]
            ),
            Makie.LineTo([-0.3531998372026805, 0.1771302486872301]),
            Makie.ClosePath(),
        ]
    ),
    :circle => BezierPath(
        [
            Makie.MoveTo([0.3525, 0.0]),
            EllipticalArc(
                [0.0, 0.0], 0.3525, 0.3525, 0.0, 0.0,
                6.283185307179586
            ), Makie.ClosePath(),
        ]
    ),
    :pentagon => BezierPath(
        [
            Makie.MoveTo([2.2962128485971897e-17, 0.375]),
            Makie.LineTo(
                [
                    -0.35664620250463486,
                    0.11588137596845627,
                ]
            ),
            Makie.LineTo(
                [
                    -0.22041946649551392,
                    -0.30338137596845627,
                ]
            ),
            Makie.LineTo(
                [
                    0.22041946649551392,
                    -0.30338137596845627,
                ]
            ),
            Makie.LineTo(
                [
                    0.35664620250463486,
                    0.11588137596845627,
                ]
            ),
            Makie.ClosePath(),
        ]
    ),
    :vline => BezierPath(
        [
            Makie.MoveTo([0.063143668438509, -0.315718342192545]),
            Makie.LineTo([0.063143668438509, 0.315718342192545]),
            Makie.LineTo([-0.063143668438509, 0.315718342192545]),
            Makie.LineTo([-0.063143668438509, -0.315718342192545]),
            Makie.ClosePath(),
        ]
    ),
    :cross => BezierPath(
        [
            Makie.MoveTo([0.1245, 0.375]),
            Makie.LineTo([0.1245, 0.1245]),
            Makie.LineTo([0.375, 0.1245]),
            Makie.LineTo([0.375, -0.12449999999999999]),
            Makie.LineTo([0.1245, -0.1245]),
            Makie.LineTo([0.12450000000000003, -0.375]),
            Makie.LineTo([-0.12449999999999997, -0.375]),
            Makie.LineTo(
                [
                    -0.12449999999999999,
                    -0.12450000000000003,
                ]
            ),
            Makie.LineTo([-0.375, -0.12450000000000006]),
            Makie.LineTo([-0.375, 0.12449999999999994]),
            Makie.LineTo(
                [
                    -0.12450000000000003,
                    0.12449999999999999,
                ]
            ),
            Makie.LineTo(
                [
                    -0.12450000000000007,
                    0.37499999999999994,
                ]
            ),
            Makie.ClosePath(),
        ]
    ),
    :xcross => BezierPath(
        [
            Makie.MoveTo(
                [
                    -0.1771302486872301,
                    0.35319983720268056,
                ]
            ),
            Makie.LineTo(
                [
                    1.39759596452057e-17,
                    0.17606958851545035,
                ]
            ),
            Makie.LineTo([0.17713024868723018, 0.3531998372026805]),
            Makie.LineTo([0.3531998372026805, 0.17713024868723012]),
            Makie.LineTo(
                [
                    0.17606958851545035,
                    -1.025465786723834e-17,
                ]
            ),
            Makie.LineTo(
                [
                    0.3531998372026805,
                    -0.17713024868723015,
                ]
            ),
            Makie.LineTo(
                [
                    0.17713024868723015,
                    -0.3531998372026805,
                ]
            ),
            Makie.LineTo(
                [
                    1.1151998010815531e-17,
                    -0.17606958851545035,
                ]
            ),
            Makie.LineTo(
                [
                    -0.17713024868723015,
                    -0.3531998372026805,
                ]
            ),
            Makie.LineTo(
                [
                    -0.35319983720268044,
                    -0.17713024868723018,
                ]
            ),
            Makie.LineTo(
                [
                    -0.17606958851545035,
                    -1.4873299788782892e-17,
                ]
            ),
            Makie.LineTo([-0.3531998372026805, 0.1771302486872301]),
            Makie.ClosePath(),
        ]
    ),
    :rect => BezierPath(
        [
            Makie.MoveTo([0.315718342192545, -0.315718342192545]),
            Makie.LineTo([0.315718342192545, 0.315718342192545]),
            Makie.LineTo([-0.315718342192545, 0.315718342192545]),
            Makie.LineTo([-0.315718342192545, -0.315718342192545]),
            Makie.ClosePath(),
        ]
    ),
    :ltriangle => BezierPath(
        [
            Makie.MoveTo([-0.485, 2.969768487932331e-17]),
            Makie.LineTo([0.2425, -0.36375]),
            Makie.LineTo([0.24250000000000005, 0.36375]),
            Makie.ClosePath(),
        ]
    ),
    :dtriangle => BezierPath(
        [
            Makie.MoveTo([-0.0, -0.485]),
            Makie.LineTo([0.36375, 0.24250000000000002]),
            Makie.LineTo([-0.36375, 0.24250000000000002]),
            Makie.ClosePath(),
        ]
    ),
    :utriangle => BezierPath(
        [
            Makie.MoveTo([0.0, 0.485]),
            Makie.LineTo([-0.36375, -0.24250000000000002]),
            Makie.LineTo([0.36375, -0.24250000000000002]),
            Makie.ClosePath(),
        ]
    ),
    :star5 => BezierPath(
        [
            Makie.MoveTo(
                [
                    2.7554554183166277e-17,
                    0.44999999999999996,
                ]
            ),
            Makie.LineTo(
                [
                    -0.12343490123748782,
                    0.16989357054233553,
                ]
            ),
            Makie.LineTo([-0.4279754430055618, 0.13905765116214752]),
            Makie.LineTo(
                [
                    -0.19972187340259556,
                    -0.06489357054233552,
                ]
            ),
            Makie.LineTo([-0.2645033597946167, -0.3640576511621475]),
            Makie.LineTo(
                [
                    -3.8576373077105933e-17,
                    -0.21000000000000002,
                ]
            ),
            Makie.LineTo([0.2645033597946167, -0.3640576511621475]),
            Makie.LineTo(
                [
                    0.19972187340259556,
                    -0.06489357054233552,
                ]
            ),
            Makie.LineTo([0.4279754430055618, 0.13905765116214752]),
            Makie.LineTo([0.12343490123748782, 0.16989357054233553]),
            Makie.ClosePath(),
        ]
    ),
    :octagon => BezierPath(
        [
            Makie.MoveTo([2.2962128485971897e-17, 0.375]),
            Makie.LineTo(
                [
                    -0.2651650384068489,
                    0.2651650384068489,
                ]
            ),
            Makie.LineTo([-0.375, 4.5924256971943795e-17]),
            Makie.LineTo(
                [
                    -0.2651650384068489,
                    -0.2651650384068489,
                ]
            ),
            Makie.LineTo([-6.888638049483202e-17, -0.375]),
            Makie.LineTo(
                [
                    0.2651650384068489,
                    -0.2651650384068489,
                ]
            ),
            Makie.LineTo([0.375, -9.184851394388759e-17]),
            Makie.LineTo([0.2651650384068489, 0.2651650384068489]),
            Makie.ClosePath(),
        ]
    ),
    :hline => BezierPath(
        [
            Makie.MoveTo([0.315718342192545, -0.063143668438509]),
            Makie.LineTo([0.315718342192545, 0.063143668438509]),
            Makie.LineTo([-0.315718342192545, 0.063143668438509]),
            Makie.LineTo([-0.315718342192545, -0.063143668438509]),
            Makie.ClosePath(),
        ]
    ),
    :hexagon => BezierPath(
        [
            Makie.MoveTo([2.2962128485971897e-17, 0.375]),
            Makie.LineTo([-0.32475952059030533, 0.1875]),
            Makie.LineTo([-0.32475952059030533, -0.1875]),
            Makie.LineTo([-6.888638049483202e-17, -0.375]),
            Makie.LineTo([0.32475952059030533, -0.1875]),
            Makie.LineTo([0.32475952059030533, 0.1875]),
            Makie.ClosePath(),
        ]
    )
)

function default_marker_map()
    return DEFAULT_MARKER_MAP
end

"""
    available_marker_symbols()

Displays all available marker symbols.
"""
function available_marker_symbols()
    println("Marker Symbols:")
    for (k, v) in default_marker_map()
        println("    :", k)
    end
    return
end

"""
    FastPixel()

Use

```julia
scatter(..., marker=FastPixel())
```

For significantly faster plotting times for large amount of points.
Note, that this will draw markers always as 1 pixel.
"""
struct FastPixel
    marker_type::Cint
end
FastPixel() = FastPixel(1)

"""
Vector of anything that is accepted as a single marker will give each point its own marker.
Note that it needs to be a uniform vector with the same element type!
"""
to_spritemarker(marker::AbstractVector) = map(to_spritemarker, marker)
to_spritemarker(marker::AbstractVector{Char}) = marker # Don't dispatch to the above!
to_spritemarker(x::FastPixel) = x
to_spritemarker(x::Circle) = x
to_spritemarker(::Type{<:Circle}) = Circle
to_spritemarker(::Type{<:Rect}) = Rect
to_spritemarker(x::Rect) = x
to_spritemarker(b::BezierPath) = b
to_spritemarker(b::Polygon) = BezierPath(b)
to_spritemarker(b) = error("Not a valid scatter marker: $(typeof(b))")
to_spritemarker(x::Shape) = x
to_spritemarker(x::UInt32) = x # Texture atlas hash

function to_spritemarker(str::String)
    error("Using strings for multiple char markers is deprecated. Use `collect(string)` or `['x', 'o', ...]` instead. Found: $(str)")
end

"""
    to_spritemarker(b, marker::Char)

Any `Char`, including unicode
"""
to_spritemarker(marker::Char) = marker

"""
Matrix of AbstractFloat will be interpreted as a distancefield (negative numbers outside shape, positive inside)
"""
to_spritemarker(marker::Matrix{<:AbstractFloat}) = el32convert(marker)

"""
Any AbstractMatrix{<: Colorant} or other image type
"""
to_spritemarker(marker::AbstractMatrix{<:Colorant}) = marker

"""
A `Symbol` - Available options can be printed with `available_marker_symbols()`
"""
function to_spritemarker(marker::Symbol)
    if haskey(default_marker_map(), marker)
        return to_spritemarker(default_marker_map()[marker])
    else
        @warn("Unsupported marker: $marker, using ● instead. Available options can be printed with `available_marker_symbols()`")
        return '●'
    end
end


convert_attribute(value, ::key"marker", ::key"scatter") = to_spritemarker(value)
convert_attribute(value, ::key"isovalue", ::key"volume") = Float32(value)
convert_attribute(value, ::key"isorange", ::key"volume") = Float32(value)
convert_attribute(value, ::key"absorption", ::key"volume") = Float32(value)
convert_attribute(value, ::key"gap", ::key"voxels") = ifelse(value <= 0.01, 0.0f0, Float32(value))

function convert_attribute(value::Symbol, ::key"marker", ::key"meshscatter")
    if value === :Sphere
        return normal_mesh(Sphere(Point3f(0), 1.0f0))
    else
        error("Unsupported marker: $(value)")
    end
end

function convert_attribute(value::AbstractGeometry, ::key"marker", ::key"meshscatter")
    return GeometryBasics.expand_faceviews(normal_mesh(value))
end

convert_attribute(value, ::key"diffuse") = Vec3f(value)
convert_attribute(value, ::key"specular") = Vec3f(value)

convert_attribute(value, ::key"backlight") = Float32(value)

convert_attribute(value::Automatic, ::key"shading") = true
function convert_attribute(value::ShadingAlgorithm, ::key"shading")
    if value != NoShading
        @warn "`shading = $value` is deprecated in favor of `shading = true` as a plot attribute. To switch between `FastShading` and `MultiLightShading` explicitly, use scene attributes."
    end
    return value != NoShading
end


convert_attribute(value, ::key"depth_shift") = Float32(value)


# SAMPLER overloads

convert_attribute(s::ShaderAbstractions.Sampler{RGBAf}, k::key"color") = s
function convert_attribute(s::ShaderAbstractions.Sampler{T, N}, k::key"color") where {T, N}
    return ShaderAbstractions.Sampler(
        el32convert(s.data); minfilter = s.minfilter, magfilter = s.magfilter,
        x_repeat = s.repeat[1], y_repeat = s.repeat[min(2, N)],
        z_repeat = s.repeat[min(3, N)], mipmap = s.mipmap,
        anisotropic = s.anisotropic, color_swizzel = s.color_swizzel
    )
end

function el32convert(x::ShaderAbstractions.Sampler{T, N}) where {T, N}
    T32 = float32type(T)
    T32 === T && return x
    data = el32convert(x.data)
    return ShaderAbstractions.Sampler{T32, N, typeof(data)}(
        data, x.minfilter, x.magfilter,
        x.repeat,
        x.anisotropic, mipmap = s.mipmap,
        x.color_swizzel,
        ShaderAbstractions.ArrayUpdater(data, x.updates.update)
    )
end

to_color(sampler::ShaderAbstractions.Sampler) = el32convert(sampler)

assemble_colors(::ShaderAbstractions.Sampler, color, plot) = Observable(el32convert(color[]))

# BUFFER OVERLOAD

GeometryBasics.collect_with_eltype(::Type{T}, vec::ShaderAbstractions.Buffer{T}) where {T} = vec

# Used in Label, maybe useful elsewhere?
to_lrbt_padding(x::Real) = Vec4f(x)
to_lrbt_padding(xy::VecTypes{2}) = Vec4f(xy[1], xy[1], xy[2], xy[2])
to_lrbt_padding(pad::VecTypes{4}) = to_ndim(Vec4f, pad, 0)

convert_attribute(x::Plane, ::key"clip_planes") = Plane3f[x]
convert_attribute(x::Vector{<:Plane}, ::key"clip_planes") = Plane3f.(x)
