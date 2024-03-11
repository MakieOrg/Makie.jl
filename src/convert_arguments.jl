################################################################################
#                               Type Conversions                               #
################################################################################


const RangeLike = Union{AbstractVector, ClosedInterval, Tuple{Any,Any}}

# if no plot type based conversion is defined, we try using a trait
function convert_arguments(T::PlotFunc, args...; kw...)
    ct = conversion_trait(T, args...)
    try
        convert_arguments(ct, args...; kw...)
    catch e
        if e isa MethodError
            try
                convert_arguments_individually(T, args...)
            catch ee
                if ee isa MethodError
                    error(
                        """
                        `Makie.convert_arguments` for the plot type $T and its conversion trait $ct was unsuccessful.

                        The signature that could not be converted was:
                        $(join("::" .* string.(typeof.(args)), ", "))

                        Makie needs to convert all plot input arguments to types that can be consumed by the backends (typically Arrays with Float32 elements).
                        You can define a method for `Makie.convert_arguments` (a type recipe) for these types or their supertypes to make this set of arguments convertible (See http://docs.makie.org/stable/documentation/recipes/index.html).

                        Alternatively, you can define `Makie.convert_single_argument` for single arguments which have types that are unknown to Makie but which can be converted to known types and fed back to the conversion pipeline.
                        """
                    )
                else
                    rethrow(ee)
                end
            end
        else
            rethrow(e)
        end
    end
end

# in case no trait matches we try to convert each individual argument
# and reconvert the whole tuple in order to handle missings centrally, e.g.
function convert_arguments_individually(T::PlotFunc, args...)
    # convert each single argument until it doesn't change type anymore
    single_converted = map(recursively_convert_argument, args)
    # if the type of args hasn't changed this function call didn't help and we error
    if typeof(single_converted) == typeof(args)
        throw(MethodError(convert_arguments, (T, args...)))
    end
    # otherwise we try converting our newly single-converted args again because
    # now a normal conversion method might work again
    convert_arguments(T, single_converted...)
end

function recursively_convert_argument(x)
    newx = convert_single_argument(x)
    if typeof(newx) == typeof(x)
        return x
    else
        return recursively_convert_argument(newx)
    end
end

################################################################################
#                          Single Argument Conversion                          #
################################################################################

# if no specific conversion is defined, we don't convert
convert_single_argument(x) = x

# replace missings with NaNs
function convert_single_argument(a::AbstractArray{<:Union{Missing, <:Real}})
    return float_convert(a)
end

# same for points
function convert_single_argument(a::AbstractArray{<:Union{Missing, <:Point{N, PT}}}) where {N, PT}
    T = float_type(PT)
    return Point{N,T}[ismissing(x) ? Point{N,T}(NaN) : Point{N,T}(x) for x in a]
end

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
    return ([Point{N,float_type(T)}(position)],)
end

function convert_arguments(::PointBased, positions::AbstractVector{<: VecTypes{N, T}}) where {N, T <: Real}
    return (float_convert(positions),)
end

function convert_arguments(::PointBased, positions::SubArray{<: VecTypes, 1})
    # TODO figure out a good subarray solution
    (positions,)
end

"""
Enables to use scatter like a surface plot with x::Vector, y::Vector, z::Matrix
spanning z over the grid spanned by x y
"""
function convert_arguments(::PointBased, x::RealArray, y::RealVector, z::RealArray)
    T = float_type(x, y, z)
    (vec(Point{3, T}.(x, y', z)),)
end

function convert_arguments(::PointBased, x::RealVector, y::RealVector, z::RealVector)
    T = float_type(x, y, z)
    return (Point{3,T}.(x, y, z),)
end


function convert_arguments(p::PointBased, x::AbstractInterval, y::AbstractInterval, z::RealArray)
    return convert_arguments(p, to_linspace(x, size(z, 1)), to_linspace(y, size(z, 2)), z)
end

"""
    convert_arguments(P, x, y, z)::(Vector)

Takes vectors `x`, `y`, and `z` and turns it into a vector of 3D points of the values
from `x`, `y`, and `z`.
`P` is the plot Type (it is optional).
"""
function convert_arguments(::PointBased, x::RealArray, y::RealMatrix, z::RealArray)
    T = float_type(x, y, z)
    (vec(Point{3, T}.(x, y, z)),)
end


function convert_arguments(::PointBased, x::RealVector, y::RealVector)
    return (Point{2,float_type(x, y)}.(x, y),)
end

"""
    convert_arguments(P, x)::(Vector)

Takes an input GeometryPrimitive `x` and decomposes it to points.
`P` is the plot Type (it is optional).
"""
function convert_arguments(p::PointBased, x::GeometryPrimitive{Dim, T}) where {Dim, T}
    return convert_arguments(p, decompose(Point{Dim, float_type(T)}, x))
end

function convert_arguments(::PointBased, pos::AbstractMatrix{<: Real})
    (to_vertices(pos),)
end

"""
    convert_arguments(P, y)::Vector
Takes vector `y` and generates a range from 1 to the length of `y`, for plotting on
an arbitrary `x` axis.

`P` is the plot Type (it is optional).
"""
convert_arguments(P::PointBased, y::RealVector) = convert_arguments(P, keys(y), y)

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
function convert_arguments(P::PointBased, x::Rect2{T}) where T
    # TODO fix the order of decompose
    return convert_arguments(P, decompose(Point2{float_type(T)}, x)[[1, 2, 4, 3]])
end

function convert_arguments(P::PointBased, mesh::AbstractMesh)
    return convert_arguments(P, coordinates(mesh))
end

function convert_arguments(PB::PointBased, linesegments::FaceView{<:Line, P}) where {P<:AbstractPoint}
    # TODO FaceView should be natively supported by backends!
    return convert_arguments(PB, collect(reinterpret(P, linesegments)))
end

function convert_arguments(::PointBased, rect::Rect3{T}) where {T}
    return (decompose(Point3{float_type(T)}, rect),)
end

function convert_arguments(P::Type{<: LineSegments}, rect::Rect3{T}) where {T}
    f = decompose(LineFace{Int}, rect)
    p = connect(decompose(Point3{float_type(T)}, rect), f)
    return convert_arguments(P, p)
end

function convert_arguments(::Type{<: Lines}, rect::Rect3{T}) where {T}
    PT = Point3{float_type(T)}
    points = unique(decompose(PT, rect))
    push!(points, PT(NaN)) # use to seperate linesegments
    return (points[[1, 2, 3, 4, 1, 5, 6, 2, 9, 6, 8, 3, 9, 5, 7, 4, 9, 7, 8]],)
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
function convert_arguments(PB::PointBased, linestring::Union{Array{<:LineString{N, T}}, MultiLineString{N, T}}) where {N, T}
    T_out = float_type(T)
    arr = Point{N, T_out}[]; n = length(linestring)
    for idx in 2:n
        append!(arr, convert_arguments(PB, linestring[idx])[1])
        if idx != n # don't add NaN at the end
            push!(arr, Point2{T_out}(NaN))
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
    arr = Point{N,float_type(T)}[]
    n = length(mp)
    for idx in 1:n
        converted = convert_arguments(PB, mp[idx])[1] # this should always be a Tuple{<: Vector{Point}}
        append!(arr, converted)
        if idx != n # don't add NaN at the end
            push!(arr, Point2(NaN))
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
        Point2d((1-t)^3 .* p0 .+ t*p1*(3*(1-t)^2) + p2*(3*(1-t)*t^2) .+ p3*t^3)
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

function edges(v::AbstractVector{T}) where T
    T_out = float_type(T)
    l = length(v)
    if l == 1
        return T_out[v[1] - 0.5, v[1] + 0.5]
    else
        # Equivalent to
        # mids = 0.5 .* (v[1:end-1] .+ v[2:end])
        # borders = [2v[1] - mids[1]; mids; 2v[end] - mids[end]]
        borders = T_out[0.5 * (v[max(1, i)] + v[min(end, i+1)]) for i in 0:length(v)]
        borders[1] = 2borders[1] - borders[2]
        borders[end] = 2borders[end] - borders[end-1]
        return borders
    end
end

function adjust_axes(::CellGrid, x::AbstractVector{<:Number}, y::AbstractVector{<:Number}, z::AbstractMatrix)
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
function convert_arguments(ct::GridBased, x::AbstractVecOrMat{<:Real}, y::AbstractVecOrMat{<:Real},
                           z::AbstractMatrix{<:Union{Real,Colorant}})
    nx, ny, nz = adjust_axes(ct, x, y, z)
    return (float_convert(nx), float_convert(ny), el32convert(nz))
end

convert_arguments(ct::VertexGrid, x::AbstractMatrix, y::AbstractMatrix) = convert_arguments(ct, x, y, zeros(size(y)))

"""
    convert_arguments(P, x::RangeLike, y::RangeLike, z::AbstractMatrix)

Takes one or two ClosedIntervals `x` and `y` and converts them to closed ranges
with size(z, 1/2).
"""
function convert_arguments(P::GridBased, x::RangeLike, y::RangeLike, z::AbstractMatrix{<: Union{Real, Colorant}})
    convert_arguments(P, to_linspace(x, size(z, 1)), to_linspace(y, size(z, 2)), z)
end

"""
    convert_arguments(::ImageLike, mat::AbstractMatrix)

Generates `ClosedInterval`s of size `0 .. size(mat, 1/2)` as x and y values.
"""
function convert_arguments(::ImageLike, data::AbstractMatrix{<: Union{Real, Colorant}})
    n, m = Float32.(size(data))
    return (Float32(0) .. n, Float32(0) .. m, el32convert(data))
end

function print_range_warning(side::String, value)
    @warn "Encountered an `AbstractVector` with value $value on side $side in `convert_arguments` for the `ImageLike` trait. Using an `AbstractVector` to specify one dimension of an `ImageLike` is deprecated because `ImageLike` sides always need exactly two values, start and stop. Use interval notation `start .. stop` or a two-element tuple `(start, stop)` instead."
end

function convert_arguments(::ImageLike, xs::RangeLike, ys::RangeLike,
                           data::AbstractMatrix{<:Union{Real,Colorant}})
    if xs isa AbstractVector
        print_range_warning("x", xs)
    end
    if ys isa AbstractVector
        print_range_warning("y", ys)
    end
    # having minimum and maximum here actually invites bugs
    _interval(v::Union{Interval,AbstractVector}) = float_convert(minimum(v)) .. float_convert(maximum(v))
    _interval(t::Tuple{Any, Any}) = float_convert(t[1]) .. float_convert(t[2])
    x = _interval(xs)
    y = _interval(ys)
    return (x, y, el32convert(data))
end

function convert_arguments(ct::GridBased, data::AbstractMatrix{<:Union{Real,Colorant}})
    n, m = Float32.(size(data))
    convert_arguments(ct, 1f0 .. n, 1f0 .. m, el32convert(data))
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

"""
    convert_arguments(P, Matrix)::Tuple{ClosedInterval, ClosedInterval, ClosedInterval, Matrix}

Takes an array of `{T, 3} where T`, converts the dimesions `n`, `m` and `k` into `ClosedInterval`,
and stores the `ClosedInterval` to `n`, `m` and `k`, plus the original array in a Tuple.

`P` is the plot Type (it is optional).
"""
function convert_arguments(::VolumeLike, data::RealArray{3})
    n, m, k = Float32.(size(data))
    return (0f0 .. n, 0f0 .. m, 0f0 .. k, el32convert(data))
end

function convert_arguments(::VolumeLike, x::RangeLike, y::RangeLike, z::RangeLike,
                           data::RealArray{3})
    return (el32convert(x), el32convert(y), el32convert(z), el32convert(data))
end
"""
    convert_arguments(P, x, y, z, i)::(Vector, Vector, Vector, Matrix)

Takes 3 `AbstractVector` `x`, `y`, and `z` and the `AbstractMatrix` `i`, and puts everything in a Tuple.

`P` is the plot Type (it is optional).
"""
function convert_arguments(::VolumeLike, x::RealVector, y::AbstractVector, z::RealVector, i::RealArray{3})
    (el32convert(x), el32convert(y), el32convert(z), el32convert(i))
end

################################################################################
#                                <:Lines                                       #
################################################################################

function convert_arguments(::Type{<: Lines}, x::Rect2{T}) where T
    # TODO fix the order of decompose
    points = decompose(Point2{float_type(T)}, x)
    return (points[[1, 2, 4, 3, 1]],)
end

################################################################################
#                                <:LineSegments                                #
################################################################################

"""
Accepts a Vector of Pair of Points (e.g. `[Point(0, 0) => Point(1, 1), ...]`)
to encode e.g. linesegments or directions.
"""
function convert_arguments(::Type{<: LineSegments}, positions::AbstractVector{E}) where E <: Union{Pair{A, A}, Tuple{A, A}} where A <: VecTypes{N, T} where {N, T}
    return (float_convert(reinterpret(Point{N,T}, positions)),)
end

function convert_arguments(::Type{<: LineSegments}, x::Rect2{T}) where T
    # TODO fix the order of decompose
    points = decompose(Point2{float_type(T)}, x)
    return (points[[1, 2, 2, 4, 4, 3, 3, 1]],)
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
    convert_arguments(T, Point3{float_type(x, y, z)}.(x, y, z))
end
"""
    convert_arguments(Mesh, xyz::AbstractVector)::GLNormalMesh

Takes an input mesh and a vector `xyz` representing the vertices of the mesh, and
creates indices under the assumption, that each triplet in `xyz` forms a triangle.
"""
function convert_arguments(
        MT::Type{<:Mesh},
        xyz::AbstractVector
    )
    faces = connect(UInt32.(0:length(xyz)-1), GLTriangleFace)
    # TODO support faceview natively
    return convert_arguments(MT, xyz, collect(faces))
end

function convert_arguments(::Type{<:Mesh}, mesh::GeometryBasics.Mesh{N, T}) where {N, T}
    # Make sure we have normals!
    if !hasproperty(mesh, :normals)
        n = normals(metafree(decompose(Point, mesh)), faces(mesh))
        # Normals can be nothing, when it's impossible to calculate the normals (e.g. 2d mesh)
        if !isnothing(n)
            mesh = GeometryBasics.pointmeta(mesh; normals=decompose(Vec3f, n))
        end
    end
    # If already correct eltypes for GL, we can pass the mesh through as is
    # if eltype(metafree(coordinates(mesh))) == Point{N, Float32} && eltype(faces(mesh)) == GLTriangleFace
    if eltype(faces(mesh)) == GLTriangleFace
        return (mesh,)
    else
        # Else, we need to convert it!
        return (GeometryBasics.mesh(mesh, pointtype=Point{N, T}, facetype=GLTriangleFace),)
    end
end

function convert_arguments(
        ::Type{<:Mesh},
        meshes::AbstractVector{<: Union{AbstractMesh, AbstractPolygon}}
    )
    return (meshes,)
end

function convert_arguments(
        MT::Type{<:Mesh},
        xyz::Union{AbstractPolygon, AbstractVector{<: AbstractPoint{2}}}
    )
    m = GeometryBasics.mesh(xyz; pointtype=float_type(xyz), facetype=GLTriangleFace)
    return convert_arguments(MT, m)
end

function convert_arguments(::Type{<:Mesh}, geom::GeometryPrimitive{N, T}) where {N, T <: Real}
    # we convert to UV mesh as default, because otherwise the uv informations get lost
    # - we can still drop them, but we can't add them later on
    m = GeometryBasics.mesh(geom; pointtype=Point{N,T}, uv=Vec2f, normaltype=Vec3f, facetype=GLTriangleFace)
    return (m,)
end

"""
    convert_arguments(Mesh, x, y, z, indices)::GLNormalMesh

Takes real vectors x, y, z and constructs a triangle mesh out of those, using the
faces in `indices`, which can be integers (every 3 -> one triangle), or GeometryBasics.NgonFace{N, <: Integer}.
"""
function convert_arguments(
        T::Type{<: Mesh},
        x::RealVector, y::RealVector, z::RealVector,
        indices::AbstractVector
    )
    return convert_arguments(T, Point3{float_type(x, y, z)}.(x, y, z), indices)
end

"""
    convert_arguments(Mesh, vertices, indices)::GLNormalMesh

Takes `vertices` and `indices`, and creates a triangle mesh out of those.
See [`to_vertices`](@ref) and [`to_triangles`](@ref) for more information about
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
        ns = normals(vs, fs)
        m = GeometryBasics.Mesh(meta(vs; normals=ns), fs)
    else
        # TODO, we don't need to add normals here, but maybe nice for type stability?
        m = GeometryBasics.Mesh(meta(vs; normals=fill(Vec3f(0, 0, 1), length(vs))), fs)
    end
    return (m,)
end


################################################################################
#                             Function Conversions                             #
################################################################################


# Allow the user to pass a function to `arrows` which determines the direction
# and magnitude of the arrows.  The function must accept `Point2f` as input.
# and return Point2f or Vec2f or some array like structure as output.
function convert_arguments(::Type{<:Arrows}, x::AbstractVector, y::AbstractVector, f::Function)
    points = Point2{float_type(x, y)}.(x, y')
    f_out = Vec2{float_type(x, y)}.(f.(points))
    return (vec(points), vec(f_out))
end

function convert_arguments(::Type{<:Arrows}, x::AbstractVector, y::AbstractVector, z::AbstractVector,
                           f::Function)
    points = [Point3{float_type(x, y, z)}(x, y, z) for x in x, y in y, z in z]
    f_out = Vec3{float_type(x, y, z)}.(f.(points))
    return (vec(points), vec(f_out))
end

"""
    convert_arguments(P, x, y, z, f)::(Vector, Vector, Vector, Matrix)

Takes `AbstractVector` `x`, `y`, and `z` and the function `f`, evaluates `f` on the volume
spanned by `x`, `y` and `z`, and puts `x`, `y`, `z` and `f(x,y,z)` in a Tuple.

`P` is the plot Type (it is optional).
"""
function convert_arguments(::VolumeLike, x::AbstractVector, y::AbstractVector, z::AbstractVector, f::Function)
    if !applicable(f, x[1], y[1], z[1])
        error("You need to pass a function with signature f(x, y, z). Found: $f")
    end
    _x, _y, _z = ntuple(Val(3)) do i
        A = (x, y, z)[i]
        return reshape(A, ntuple(j -> j != i ? 1 : length(A), Val(3)))
    end
    return (el32convert(x), el32convert(y), el32convert(z), el32convert(f.(_x, _y, _z)))
end

function convert_arguments(P::PlotFunc, r::AbstractVector, f::Function)
    return convert_arguments(P, r, map(f, r))
end

function convert_arguments(P::PlotFunc, i::AbstractInterval, f::Function)
    x, y = PlotUtils.adapted_grid(f, endpoints(i))
    return convert_arguments(P, x, y)
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

to_linspace(interval, N) = range(minimum(interval), stop = maximum(interval), length = N)

"""
Converts the elemen array type to `T1` without making a copy if the element type matches
"""
elconvert(::Type{T1}, x::AbstractArray{T2, N}) where {T1, T2, N} = convert(AbstractArray{T1, N}, x)

function elconvert(::Type{T}, x::AbstractArray{<: Union{Missing, <:Real}}) where {T}
    return map(x) do elem
        return (ismissing(elem) ? T(NaN) : convert(T, elem))
    end
end

float_type(a, rest...) = float_type(typeof(a), map(typeof, rest)...)
float_type(a::AbstractArray, rest::AbstractArray...) = float_type(float_type(a), map(float_type, rest)...)
float_type(a::Type, rest::Type...) = float_type(promote_type(a, rest...))
float_type(::Type{Float64}) = Float64
float_type(::Type{Float32}) = Float32
float_type(::Type{<:Real}) = Float64
float_type(::Type{<:Union{Int8,UInt8,Int16,UInt16}}) = Float32
float_type(::Type{<:Union{Float16}}) = Float32
float_type(::Type{Point{N,T}}) where {N,T} = Point{N,float_type(T)}
float_type(::Type{Vec{N,T}}) where {N,T} = Vec{N,float_type(T)}
float_type(::Type{NTuple{N, T}}) where {N,T} = Point{N,float_type(T)}
float_type(::Type{Tuple{T1, T2}}) where {T1,T2} = Point2{promote_type(float_type(T1), float_type(T2))}
float_type(::Type{Tuple{T1, T2, T3}}) where {T1,T2,T3} = Point3{promote_type(float_type(T1), float_type(T2), float_type(T3))}
float_type(::AbstractArray{T}) where {T} = float_type(T)

float_convert(x) = convert(float_type(x), x)
float_convert(x::AbstractArray{Float32}) = x
float_convert(x::AbstractArray{Float64}) = x
float_convert(x::AbstractArray) = elconvert(float_type(x), x)
float_convert(x::Observable) = lift(float_convert, x)
float_convert(x::AbstractArray{<:Union{Missing, T}}) where {T<:Real} = elconvert(float_type(T), x)

float32type(::Type{<:Real}) = Float32
float32type(::Type{Point{N,T}}) where {N,T} = Point{N,float32type(T)}
float32type(::Type{Vec{N,T}}) where {N,T} = Vec{N,float32type(T)}

# We may want to always use UInt8 for colors?
float32type(::Type{<: RGB}) = RGB{Float32}
float32type(::Type{<: RGBA}) = RGBA{Float32}
float32type(::Type{<: Colorant}) = RGBA{Float32}
float32type(::AbstractArray{T}) where T = float32type(T)
float32type(::T) where {T} = float32type(T)

el32convert(x::ClosedInterval) = Float32(minimum(x)) .. Float32(maximum(x))
el32convert(x::AbstractArray) = elconvert(float32type(x), x)
el32convert(x::AbstractArray{<:Union{Missing, T}}) where {T<:Real} = elconvert(float32type(T), x)
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
    reinterpret(GLTriangleFace, idx0)
end

function to_triangles(faces::AbstractVector{TriangleFace{T}}) where T
    elconvert(GLTriangleFace, faces)
end

function to_triangles(faces::AbstractMatrix{T}) where T <: Integer
    @assert size(faces, 2) == 3
    return broadcast(1:size(faces, 1), 3) do fidx, n
        GLTriangleFace(ntuple(i-> faces[fidx, i], n))
    end
end

"""
    to_vertices(v)

Converts a representation of vertices `v` to its canonical representation as a
`Vector{Point3f}`. `v` can be:

- An `AbstractVector` of 3-element `Tuple`s or `StaticVector`s,

- An `AbstractVector` of `Tuple`s or `StaticVector`s, in which case exta dimensions will
  be either truncated or padded with zeros as required,

- An `AbstractMatrix`"
  - if `v` has 2 or 3 rows, it will treat each column as a vertex,
  - otherwise if `v` has 2 or 3 columns, it will treat each row as a vertex.
"""
function to_vertices(verts::AbstractVector{<: VecTypes{3, T}}) where T
    T_out = float_type(T)
    vert3 = T != T_out ? map(Point3{T_out}, verts) : verts
    return reinterpret(Point3{T_out}, vert3)
end

function to_vertices(verts::AbstractVector{<: VecTypes{N, T}}) where {N, T}
    return map(Point{N, float_type(T)}, verts)
end

function to_vertices(verts::AbstractMatrix{<: Number})
    if size(verts, 1) in (2, 3)
        to_vertices(verts, Val(1))
    elseif size(verts, 2) in (2, 3)
        to_vertices(verts, Val(2))
    else
        error("You are using a matrix for vertices which uses neither dimension to encode the dimension of the space. Please have either size(verts, 1/2) in the range of 2-3. Found: $(size(verts))")
    end
end

function to_vertices(verts::AbstractMatrix{T}, ::Val{1}) where T <: Real
    N = size(verts, 1)
    if T == float_type(T) && N == 3
        reinterpret(Point{N, T}, elconvert(T, vec(verts)))
    else
        let N = Val(N); lverts = verts; T_out = float_type(T)
            broadcast(1:size(verts, 2), N) do vidx, n
                Point(ntuple(i-> T_out(lverts[i, vidx]), n))
            end
        end
    end
end

function to_vertices(verts::AbstractMatrix{T}, ::Val{2}) where T <: Real
    let N = Val(size(verts, 2));  lverts = verts; T_out = float_type(T)
        broadcast(1:size(verts, 1), N) do vidx, n
            Point(ntuple(i-> T_out(lverts[vidx, i]), n))
        end
    end
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
    rets[1]
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
