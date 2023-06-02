################################################################################
#                               Type Conversions                               #
################################################################################
const RangeLike = Union{AbstractRange, AbstractVector, ClosedInterval}

# if no plot type based conversion is defined, we try using a trait
function convert_arguments(T::PlotFunc, args...; kw...)
    ct = conversion_trait(T)
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
    single_converted = recursively_convert_argument.(args)
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
        x
    else
        recursively_convert_argument(newx)
    end
end

################################################################################
#                          Single Argument Conversion                          #
################################################################################

# if no specific conversion is defined, we don't convert
convert_single_argument(x) = x

# replace missings with NaNs
function convert_single_argument(a::AbstractArray{<:Union{Missing, <:Real}})
    [ismissing(x) ? NaN32 : convert(Float32, x) for x in a]
end

# same for points
function convert_single_argument(a::AbstractArray{<:Union{Missing, <:Point{N}}}) where N
    [ismissing(x) ? Point{N, Float32}(NaN32) : Point{N, Float32}(x) for x in a]
end

################################################################################
#                                  PointBased                                  #
################################################################################

"""
Wrap a single point or equivalent object in a single-element array.
"""
function convert_arguments(::PointBased, x::Real, y::Real)
    ([Point2f(x, y)],)
end

function convert_arguments(::PointBased, x::Real, y::Real, z::Real)
    ([Point3f(x, y, z)],)
end

function convert_arguments(::PointBased, position::VecTypes{N, <: Number}) where N
    ([convert(Point{N, Float32}, position)],)
end

function convert_arguments(::PointBased, positions::AbstractVector{<: VecTypes{N, <: Number}}) where N
    (elconvert(Point{N, Float32}, positions),)
end

function convert_arguments(::PointBased, positions::SubArray{<: VecTypes, 1})
    # TODO figure out a good subarray solution
    (positions,)
end

"""
Enables to use scatter like a surface plot with x::Vector, y::Vector, z::Matrix
spanning z over the grid spanned by x y
"""
function convert_arguments(::PointBased, x::AbstractVector, y::AbstractVector, z::AbstractMatrix)
    (vec(Point3f.(x, y', z)),)
end

function convert_arguments(p::PointBased, x::AbstractInterval, y::AbstractInterval, z::AbstractMatrix)
    return convert_arguments(p, to_linspace(x, size(z, 1)), to_linspace(y, size(z, 2)), z)
end

"""
    convert_arguments(P, x, y, z)::(Vector)

Takes vectors `x`, `y`, and `z` and turns it into a vector of 3D points of the values
from `x`, `y`, and `z`.
`P` is the plot Type (it is optional).
"""
convert_arguments(::PointBased, x::RealVector, y::RealVector, z::RealVector) = (Point3f.(x, y, z),)

"""
    convert_arguments(P, x)::(Vector)

Takes an input GeometryPrimitive `x` and decomposes it to points.
`P` is the plot Type (it is optional).
"""
convert_arguments(p::PointBased, x::GeometryPrimitive) = convert_arguments(p, decompose(Point, x))

function convert_arguments(::PointBased, pos::AbstractMatrix{<: Number})
    (to_vertices(pos),)
end

convert_arguments(P::PointBased, x::AbstractVector{<:Real}, y::AbstractVector{<:Real}) = (Point2f.(x, y),)

convert_arguments(P::PointBased, x::AbstractVector{<:Real}, y::AbstractVector{<:Real}, z::AbstractVector{<:Real}) = (Point3f.(x, y, z),)

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
#convert_arguments(::PointBased, x::RealVector, y::RealVector) = (Point2f.(x, y),)
convert_arguments(P::PointBased, x::ClosedInterval, y::RealVector) = convert_arguments(P, LinRange(extrema(x)..., length(y)), y)
convert_arguments(P::PointBased, x::RealVector, y::ClosedInterval) = convert_arguments(P, x, LinRange(extrema(y)..., length(x)))


"""
    convert_arguments(P, x)::(Vector)

Takes an input `Rect` `x` and decomposes it to points.

`P` is the plot Type (it is optional).
"""
function convert_arguments(P::PointBased, x::Rect2)
    # TODO fix the order of decompose
    return convert_arguments(P, decompose(Point2f, x)[[1, 2, 4, 3]])
end

function convert_arguments(P::PointBased, mesh::AbstractMesh)
    return convert_arguments(P, decompose(Point3f, mesh))
end

function convert_arguments(PB::PointBased, linesegments::FaceView{<:Line, P}) where {P<:AbstractPoint}
    # TODO FaceView should be natively supported by backends!
    return convert_arguments(PB, collect(reinterpret(P, linesegments)))
end

function convert_arguments(P::PointBased, rect::Rect3)
    return (decompose(Point3f, rect),)
end

function convert_arguments(P::Type{<: LineSegments}, rect::Rect3)
    f = decompose(LineFace{Int}, rect)
    p = connect(decompose(Point3f, rect), f)
    return convert_arguments(P, p)
end

function convert_arguments(::Type{<: Lines}, rect::Rect3)
    points = unique(decompose(Point3f, rect))
    push!(points, Point3f(NaN)) # use to seperate linesegments
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
function convert_arguments(PB::PointBased, linestring::Union{Array{<:LineString}, MultiLineString})
    arr = Point2f[]; n = length(linestring)
    for idx in 1:n
        append!(arr, convert_arguments(PB, linestring[idx])[1])
        if idx != n # don't add NaN at the end
            push!(arr, Point2f(NaN))
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
        push!(arr, Point2f(NaN))
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
function convert_arguments(PB::PointBased, mp::Union{Array{<:Polygon}, MultiPolygon})
    arr = Point2f[]
    n = length(mp)
    for idx in 1:n
        converted = convert_arguments(PB, mp[idx])[1] # this should always be a Tuple{<: Vector{Point}}
        append!(arr, converted)
        if idx != n # don't add NaN at the end
            push!(arr, Point2f(NaN))
        end
    end
    return (arr,)
end

function convert_arguments(::PointBased, b::BezierPath)
    b2 = replace_nonfreetype_commands(b)
    points = Point2f[]
    last_point = Point2f(NaN)
    last_moveto = false

    function poly3(t, p0, p1, p2, p3)
        Point2f((1-t)^3 .* p0 .+ t*p1*(3*(1-t)^2) + p2*(3*(1-t)*t^2) .+ p3*t^3)
    end

    for command in b2.commands
        if command isa MoveTo
            last_point = command.p
            last_moveto = true
        elseif command isa LineTo
            if last_moveto
                isempty(points) || push!(points, Point2f(NaN, NaN))
                push!(points, last_point)
            end
            push!(points, command.p)
            last_point = command.p
            last_moveto = false
        elseif command isa CurveTo
            if last_moveto
                isempty(points) || push!(points, Point2f(NaN, NaN))
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
#                                 SurfaceLike                                  #
################################################################################

function edges(v::AbstractVector)
    l = length(v)
    if l == 1
        return [v[1] - 0.5, v[1] + 0.5]
    else
        # Equivalent to
        # mids = 0.5 .* (v[1:end-1] .+ v[2:end])
        # borders = [2v[1] - mids[1]; mids; 2v[end] - mids[end]]
        borders = [0.5 * (v[max(1, i)] + v[min(end, i+1)]) for i in 0:length(v)]
        borders[1] = 2borders[1] - borders[2]
        borders[end] = 2borders[end] - borders[end-1]
        return borders
    end
end

function adjust_axes(::DiscreteSurface, x::AbstractVector{<:Number}, y::AbstractVector{<:Number}, z::AbstractMatrix)
    x̂, ŷ = map((x, y), size(z)) do v, sz
        return length(v) == sz ? edges(v) : v
    end
    return x̂, ŷ, z
end

adjust_axes(::SurfaceLike, x, y, z) = x, y, z

"""
    convert_arguments(SL::SurfaceLike, x::VecOrMat, y::VecOrMat, z::Matrix)

If `SL` is `Heatmap` and `x` and `y` are vectors, infer from length of `x` and `y`
whether they represent edges or centers of the heatmap bins.
If they are centers, convert to edges. Convert eltypes to `Float32` and return
outputs as a `Tuple`.
"""
function convert_arguments(SL::SurfaceLike, x::AbstractVecOrMat{<: Number}, y::AbstractVecOrMat{<: Number}, z::AbstractMatrix{<: Union{Number, Colorant}})
    return map(el32convert, adjust_axes(SL, x, y, z))
end
function convert_arguments(SL::SurfaceLike, x::AbstractVecOrMat{<: Number}, y::AbstractVecOrMat{<: Number}, z::AbstractMatrix{<:Number})
    return map(el32convert, adjust_axes(SL, x, y, z))
end

convert_arguments(sl::SurfaceLike, x::AbstractMatrix, y::AbstractMatrix) = convert_arguments(sl, x, y, zeros(size(y)))

"""
    convert_arguments(P, x, y, z)::Tuple{ClosedInterval, ClosedInterval, Matrix}

Takes 2 ClosedIntervals's `x`, `y`, and an AbstractMatrix `z`, and converts the closed range to
linspaces with size(z, 1/2)
`P` is the plot Type (it is optional).
"""
function convert_arguments(P::SurfaceLike, x::ClosedInterval, y::ClosedInterval, z::AbstractMatrix)
    convert_arguments(P, to_linspace(x, size(z, 1)), to_linspace(y, size(z, 2)), z)
end

"""
    convert_arguments(P, Matrix)::Tuple{ClosedInterval, ClosedInterval, Matrix}

Takes an `AbstractMatrix`, converts the dimesions `n` and `m` into `ClosedInterval`,
and stores the `ClosedInterval` to `n` and `m`, plus the original matrix in a Tuple.

`P` is the plot Type (it is optional).
"""
function convert_arguments(sl::SurfaceLike, data::AbstractMatrix)
    n, m = Float32.(size(data))
    convert_arguments(sl, 0f0 .. n, 0f0 .. m, el32convert(data))
end

function convert_arguments(ds::DiscreteSurface, data::AbstractMatrix)
    n, m = Float32.(size(data))
    convert_arguments(ds, edges(1:n), edges(1:m), el32convert(data))
end

function convert_arguments(SL::SurfaceLike, x::AbstractVector{<:Number}, y::AbstractVector{<:Number}, z::AbstractVector{<:Number})
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
    convert_arguments(SL, x_centers, y_centers, zs)
end


"""
    convert_arguments(P, x, y, f)::(Vector, Vector, Matrix)

Takes vectors `x` and `y` and the function `f`, and applies `f` on the grid that `x` and `y` span.
This is equivalent to `f.(x, y')`.
`P` is the plot Type (it is optional).
"""
function convert_arguments(sl::SurfaceLike, x::AbstractVector{T1}, y::AbstractVector{T2}, f::Function) where {T1, T2}
    if !applicable(f, x[1], y[1])
        error("You need to pass a function with signature f(x::$T1, y::$T2). Found: $f")
    end
    T = typeof(f(x[1], y[1]))
    z = similar(x, T, (length(x), length(y)))
    z .= f.(x, y')
    return convert_arguments(sl, x, y, z)
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
function convert_arguments(::VolumeLike, data::AbstractArray{T, 3}) where T
    n, m, k = Float32.(size(data))
    return (0f0 .. n, 0f0 .. m, 0f0 .. k, el32convert(data))
end

function convert_arguments(::VolumeLike, x::RangeLike, y::RangeLike, z::RangeLike, data::AbstractArray{T, 3}) where T
    return (x, y, z, el32convert(data))
end
"""
    convert_arguments(P, x, y, z, i)::(Vector, Vector, Vector, Matrix)

Takes 3 `AbstractVector` `x`, `y`, and `z` and the `AbstractMatrix` `i`, and puts everything in a Tuple.

`P` is the plot Type (it is optional).
"""
function convert_arguments(::VolumeLike, x::AbstractVector, y::AbstractVector, z::AbstractVector, i::AbstractArray{T, 3}) where T
    (x, y, z, el32convert(i))
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
        reshape(A, ntuple(j-> j != i ? 1 : length(A), Val(3)))
    end
    return (x, y, z, el32convert.(f.(_x, _y, _z)))
end

################################################################################
#                                <:Lines                                       #
################################################################################

function convert_arguments(::Type{<: Lines}, x::Rect2)
    # TODO fix the order of decompose
    points = decompose(Point2f, x)
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
    (elconvert(Point{N, Float32}, reinterpret(Point{N, T}, positions)),)
end

function convert_arguments(::Type{<: LineSegments}, x::Rect2)
    # TODO fix the order of decompose
    points = decompose(Point2f, x)
    return (points[[1, 2, 2, 4, 4, 3, 3, 1]],)
end

################################################################################
#                                    <:Text                                    #
################################################################################

"""
    convert_arguments(x)::(String)

Takes an input `AbstractString` `x` and converts it to a string.
"""
# convert_arguments(::Type{<: Text}, x::AbstractString) = (String(x),)


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
    convert_arguments(T, Point3f.(x, y, z))
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

function convert_arguments(::Type{<:Mesh}, mesh::GeometryBasics.Mesh{N}) where {N}
    # Make sure we have normals!
    if !hasproperty(mesh, :normals)
        n = normals(mesh)
        # Normals can be nothing, when it's impossible to calculate the normals (e.g. 2d mesh)
        if n !== nothing
            mesh = GeometryBasics.pointmeta(mesh, decompose(Vec3f, n))
        end
    end
    # If already correct eltypes for GL, we can pass the mesh through as is
    if eltype(metafree(coordinates(mesh))) == Point{N, Float32} && eltype(faces(mesh)) == GLTriangleFace
        return (mesh,)
    else
        # Else, we need to convert it!
        return (GeometryBasics.mesh(mesh, pointtype=Point{N, Float32}, facetype=GLTriangleFace),)
    end
end

function convert_arguments(
        MT::Type{<:Mesh},
        meshes::AbstractVector{<: Union{AbstractMesh, AbstractPolygon}}
    )
    return (meshes,)
end

function convert_arguments(
        MT::Type{<:Mesh},
        xyz::Union{AbstractPolygon, AbstractVector{<: AbstractPoint{2}}}
    )
    return convert_arguments(MT, triangle_mesh(xyz))
end

function convert_arguments(MT::Type{<:Mesh}, geom::GeometryPrimitive)
    # we convert to UV mesh as default, because otherwise the uv informations get lost
    # - we can still drop them, but we can't add them later on
    return (GeometryBasics.uv_normal_mesh(geom),)
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
    return convert_arguments(T, Point3f.(x, y, z), indices)
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
    m = normal_mesh(to_vertices(vertices), to_triangles(indices))
    (m,)
end

################################################################################
#                             Function Conversions                             #
################################################################################

function convert_arguments(P::PlotFunc, r::AbstractVector, f::Function)
    ptype = plottype(P, Lines)
    to_plotspec(ptype, convert_arguments(ptype, r, f.(r)))
end

function convert_arguments(P::PlotFunc, i::AbstractInterval, f::Function)
    x, y = PlotUtils.adapted_grid(f, endpoints(i))
    ptype = plottype(P, Lines)
    to_plotspec(ptype, convert_arguments(ptype, x, y))
end

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

# OffsetArrays conversions
function convert_arguments(sl::SurfaceLike, wm::OffsetArray)
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
float32type(x::Type) = Float32
float32type(::Type{<: RGB}) = RGB{Float32}
float32type(::Type{<: RGBA}) = RGBA{Float32}
float32type(::Type{<: Colorant}) = RGBA{Float32}
float32type(x::AbstractArray{T}) where T = float32type(T)
float32type(x::T) where T = float32type(T)
el32convert(x::AbstractArray) = elconvert(float32type(x), x)
el32convert(x::AbstractArray{Float32}) = x
el32convert(x::Observable) = lift(el32convert, x)
el32convert(x) = convert(float32type(x), x)

function el32convert(x::AbstractArray{T, N}) where {T<:Union{Missing, <: Number}, N}
    return map(x) do elem
        return (ismissing(elem) ? NaN32 : convert(Float32, elem))::Float32
    end::Array{Float32, N}
end
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
    vert3f0 = T != Float32 ? Point3f.(verts) : verts
    return reinterpret(Point3f, vert3f0)
end

function to_vertices(verts::AbstractVector{<: VecTypes})
    to_vertices(to_ndim.(Point3f, verts, 0.0))
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

function to_vertices(verts::AbstractMatrix{T}, ::Val{1}) where T <: Number
    N = size(verts, 1)
    if T == Float32 && N == 3
        reinterpret(Point{N, T}, elconvert(T, vec(verts)))
    else
        let N = Val(N), lverts = verts
            broadcast(1:size(verts, 2), N) do vidx, n
                to_ndim(Point3f, ntuple(i-> lverts[i, vidx], n), 0.0)
            end
        end
    end
end

function to_vertices(verts::AbstractMatrix{T}, ::Val{2}) where T <: Number
    let N = Val(size(verts, 2)), lverts = verts
        broadcast(1:size(verts, 1), N) do vidx, n
            to_ndim(Point3f, ntuple(i-> lverts[vidx, i], n), 0.0)
        end
    end
end


################################################################################
#                            Attribute conversions                             #
################################################################################

convert_attribute(x, key::Key, ::Key) = convert_attribute(x, key)
convert_attribute(s::SceneLike, x, key::Key, ::Key) = convert_attribute(s, x, key)
convert_attribute(s::SceneLike, x, key::Key) = convert_attribute(x, key)
convert_attribute(x, key::Key) = x

convert_attribute(color, ::key"color") = to_color(color)

convert_attribute(colormap, ::key"colormap") = to_colormap(colormap)
convert_attribute(rotation, ::key"rotation") = to_rotation(rotation)
convert_attribute(font, ::key"font") = to_font(font)
convert_attribute(align, ::key"align") = to_align(align)

convert_attribute(p, ::key"highclip") = to_color(p)
convert_attribute(p::Nothing, ::key"highclip") = p
convert_attribute(p, ::key"lowclip") = to_color(p)
convert_attribute(p::Nothing, ::key"lowclip") = p
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
to_color(c::Symbol) = to_color(string(c))
to_color(c::String) = parse(RGBA{Float32}, c)
to_color(c::AbstractArray) = to_color.(c)
to_color(c::AbstractArray{<: Colorant, N}) where N = convert(Array{RGBAf, N}, c)
to_color(p::AbstractPattern) = p
function to_color(c::Tuple{<: Any,  <: Number})
    col = to_color(c[1])
    return RGBAf(Colors.color(col), alpha(col) * c[2])
end

convert_attribute(b::Billboard{Float32}, ::key"rotations") = to_rotation(b.rotation)
convert_attribute(b::Billboard{Vector{Float32}}, ::key"rotations") = to_rotation.(b.rotation)
convert_attribute(r::AbstractArray, ::key"rotations") = to_rotation.(r)
convert_attribute(r::StaticVector, ::key"rotations") = to_rotation(r)
convert_attribute(r, ::key"rotations") = to_rotation(r)

convert_attribute(c, ::key"markersize", ::key"scatter") = to_2d_scale(c)
convert_attribute(c, ::key"markersize", ::key"meshscatter") = to_3d_scale(c)
to_2d_scale(x::Number) = Vec2f(x)
to_2d_scale(x::VecTypes) = to_ndim(Vec2f, x, 1)
to_2d_scale(x::Tuple{<:Number, <:Number}) = to_ndim(Vec2f, x, 1)
to_2d_scale(x::AbstractVector) = to_2d_scale.(x)

to_3d_scale(x::Number) = Vec3f(x)
to_3d_scale(x::VecTypes) = to_ndim(Vec3f, x, 1)
to_3d_scale(x::AbstractVector) = to_3d_scale.(x)


convert_attribute(x, ::key"uv_offset_width") = Vec4f(x)
convert_attribute(x::AbstractVector{Vec4f}, ::key"uv_offset_width") = x


convert_attribute(c::Number, ::key"glowwidth") = Float32(c)
convert_attribute(c::Number, ::key"strokewidth") = Float32(c)

convert_attribute(c, ::key"glowcolor") = to_color(c)
convert_attribute(c, ::key"strokecolor") = to_color(c)

convert_attribute(x::Nothing, ::key"linestyle") = x

#     `AbstractVector{<:AbstractFloat}` for denoting sequences of fill/nofill. e.g.
#
# [0.5, 0.8, 1.2] will result in 0.5 filled, 0.3 unfilled, 0.4 filled. 1.0 unit is one linewidth!
convert_attribute(A::AbstractVector, ::key"linestyle") = [float(x - A[1]) for x in A]

# A `Symbol` equal to `:dash`, `:dot`, `:dashdot`, `:dashdotdot`
convert_attribute(ls::Union{Symbol,AbstractString}, ::key"linestyle") = line_pattern(ls, :normal)

function convert_attribute(ls::Tuple{<:Union{Symbol,AbstractString},<:Any}, ::key"linestyle")
    line_pattern(ls[1], ls[2])
end

function line_pattern(linestyle, gaps)
    pattern = line_diff_pattern(linestyle, gaps)
    isnothing(pattern) ? pattern : float.([0.0; cumsum(pattern)])
end

"The linestyle patterns are inspired by the LaTeX package tikZ as seen here https://tex.stackexchange.com/questions/45275/tikz-get-values-for-predefined-dash-patterns."

function line_diff_pattern(ls::Symbol, gaps = :normal)
    if ls === :solid
        nothing
    elseif ls === :dash
        line_diff_pattern("-", gaps)
    elseif ls === :dot
        line_diff_pattern(".", gaps)
    elseif ls === :dashdot
        line_diff_pattern("-.", gaps)
    elseif ls === :dashdotdot
        line_diff_pattern("-..", gaps)
    else
        error(
            """
            Unkown line style: $ls. Available linestyles are:
            :solid, :dash, :dot, :dashdot, :dashdotdot
            or a sequence of numbers enumerating the next transparent/opaque region.
            This sequence of numbers must be cumulative; 1 unit corresponds to 1 line width.
            """
        )
    end
end

function line_diff_pattern(ls_str::AbstractString, gaps = :normal)
    dot = 1
    dash = 3
    check_line_pattern(ls_str)

    dot_gap, dash_gap = convert_gaps(gaps)

    pattern = Float64[]
    for i in 1:length(ls_str)
        curr_char = ls_str[i]
        next_char = i == lastindex(ls_str) ? ls_str[firstindex(ls_str)] : ls_str[i+1]
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
    pattern
end

"Checks if the linestyle format provided as a string contains only dashes and dots"
function check_line_pattern(ls_str)
    isnothing(match(r"^[.-]+$", ls_str)) &&
        throw(ArgumentError("If you provide a string as linestyle, it must only consist of dashes (-) and dots (.)"))

    nothing
end

function convert_gaps(gaps)
  error_msg = "You provided the gaps modifier $gaps when specifying the linestyle. The modifier must be `∈ ([:normal, :dense, :loose])`, a real number or a collection of two real numbers."
  if gaps isa Symbol
      gaps in [:normal, :dense, :loose] || throw(ArgumentError(error_msg))
      dot_gaps  = (normal = 2, dense = 1, loose = 4)
      dash_gaps = (normal = 3, dense = 2, loose = 6)

      dot_gap  = getproperty(dot_gaps, gaps)
      dash_gap = getproperty(dash_gaps, gaps)
  elseif gaps isa Real
      dot_gap = gaps
      dash_gap = gaps
  elseif length(gaps) == 2 && eltype(gaps) <: Real
      dot_gap, dash_gap = gaps
  else
      throw(ArgumentError(error_msg))
  end
  (dot_gap = dot_gap, dash_gap = dash_gap)
end

convert_attribute(c::Tuple{<: Number, <: Number}, ::key"position") = Point2f(c[1], c[2])
convert_attribute(c::Tuple{<: Number, <: Number, <: Number}, ::key"position") = Point3f(c)
convert_attribute(c::VecTypes{N}, ::key"position") where N = Point{N, Float32}(c)

"""
    Text align, e.g.:
"""
to_align(x::Tuple{Symbol, Symbol}) = Vec2f(alignment2num.(x))
to_align(x::Vec2f) = x

const FONT_CACHE = Dict{String, NativeFont}()

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
    get!(FONT_CACHE, str) do
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
        font = FreeTypeAbstraction.findfont(str; additional_fonts=fontpath)
        if font === nothing
            @warn("Could not find font $str, using TeX Gyre Heros Makie")
            return to_font("TeX Gyre Heros Makie")
        end
        return font
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


"""
    rotation accepts:
    to_rotation(b, quaternion)
    to_rotation(b, tuple_float)
    to_rotation(b, vec4)
"""
to_rotation(s::Quaternionf) = s
to_rotation(s::Quaternion) = Quaternionf(s.data...)

function to_rotation(s::VecTypes{N}) where N
    if N == 4
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
to_rotation(r::AbstractVector{<: Quaternionf}) = r

convert_attribute(x, ::key"colorrange") = to_colorrange(x)
to_colorrange(x) = isnothing(x) ? nothing : Vec2f(x)

convert_attribute(x, ::key"fontsize") = to_fontsize(x)
to_fontsize(x::Number) = Float32(x)
to_fontsize(x::AbstractVector{T}) where T <: Number = el32convert(x)
to_fontsize(x::Vec2) = Vec2f(x)
to_fontsize(x::AbstractVector{T}) where T <: Vec2 = Vec2f.(x)

convert_attribute(x, ::key"linewidth") = to_linewidth(x)
to_linewidth(x) = Float32(x)
to_linewidth(x::AbstractVector) = el32convert(x)

# ColorBrewer colormaps that support only 8 colors require special handling on the backend, so we show them here.
const colorbrewer_8color_names = String.([
    :Accent,
    :Dark2,
    :Pastel2,
    :Set2
])

const plotutils_names = String.(union(
    keys(PlotUtils.ColorSchemes.colorschemes),
    keys(PlotUtils.COLORSCHEME_ALIASES),
    keys(PlotUtils.MISC_COLORSCHEMES)
))

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
end


to_colormap(cm, categories::Integer) = error("`to_colormap(cm, categories)` is deprecated. Use `Makie.categorical_colors(cm, categories)` for categorical colors, and `resample_cmap(cmap, ncolors)` for continous resampling.")

"""
    categorical_colors(colormaplike, categories::Integer)

Creates categorical colors and tries to match `categories`.
Will error if color scheme doesn't contain enough categories. Will drop the n last colors, if request less colors than contained in scheme.
"""
function categorical_colors(cols::AbstractVector{<: Colorant}, categories::Integer)
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
    if cs_string in all_gradient_names
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
            or look at http://docs.makie.org/dev/generated/colors#Colormap-reference.
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

An `AbstractVector{T}` with any object that [`to_color`](@ref) accepts.
"""
to_colormap(cm::AbstractVector)::Vector{RGBAf} = map(to_color, cm)
to_colormap(cm::AbstractVector{<: Colorant}) = convert(Vector{RGBAf}, cm)

function to_colormap(cs::Tuple{<: Union{Reverse, Symbol, AbstractString}, Real})::Vector{RGBAf}
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
    if cs_string in all_gradient_names
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
            or look at http://docs.makie.org/dev/generated/colors#Colormap-reference.
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

# Enum values: `IsoValue` `Absorption` `MaximumIntensityProjection` `AbsorptionRGBA` `AdditiveRGBA` `IndexedAbsorptionRGBA`
function convert_attribute(value, ::key"algorithm")
    if isa(value, RaymarchAlgorithm)
        return Int32(value)
    elseif isa(value, Int32) && value in 0:5
        return value
    elseif value == 7
        return value # makie internal contour implementation
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
    convert_attribute(get(vals, Symbol(value)) do
        error("$value is not a valid volume algorithm. It must be one of $(keys(vals))")
    end, k)
end

const DEFAULT_MARKER_MAP = Dict{Symbol, BezierPath}()

function default_marker_map()
    # The bezier markers should not look out of place when used together with text
    # where both markers and text are given the same size, i.e. the marker and fontsizes
    # should correspond approximately in a visual sense.

    # All the basic bezier shapes are approximately built in a 1 by 1 square centered
    # around the origin, with slight deviations to match them better to each other.

    # An 'x' of DejaVu sans is only about 55pt high at 100pt font size, so if the marker
    # shapes are just used as is, they look much too large in comparison.
    # To me, a factor of 0.75 looks ok compared to both uppercase and lowercase letters of Dejavu.
    if isempty(DEFAULT_MARKER_MAP)
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
    end
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
end

"""
    FastPixel()

Use

```julia
scatter(..., marker=FastPixel())
```

For significant faster plotting times for large amount of points.
Note, that this will draw markers always as 1 pixel.
"""
struct FastPixel end

"""
Vector of anything that is accepted as a single marker will give each point it's own marker.
Note that it needs to be a uniform vector with the same element type!
"""
to_spritemarker(marker::AbstractVector) = map(to_spritemarker, marker)
to_spritemarker(marker::AbstractVector{Char}) = marker # Don't dispatch to the above!
to_spritemarker(x::FastPixel) = x
to_spritemarker(x::Circle) = x
to_spritemarker(::Type{<: Circle}) = Circle
to_spritemarker(::Type{<: Rect}) = Rect
to_spritemarker(x::Rect) = x
to_spritemarker(b::BezierPath) = b
to_spritemarker(b::Polygon) = BezierPath(b)
to_spritemarker(b) = error("Not a valid scatter marker: $(typeof(b))")

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
to_spritemarker(marker::Matrix{<: AbstractFloat}) = el32convert(marker)

"""
Any AbstractMatrix{<: Colorant} or other image type
"""
to_spritemarker(marker::AbstractMatrix{<: Colorant}) = marker

"""
A `Symbol` - Available options can be printed with `available_marker_symbols()`
"""
function to_spritemarker(marker::Symbol)
    if haskey(default_marker_map(), marker)
        return to_spritemarker(default_marker_map()[marker])
    else
        @warn("Unsupported marker: $marker, using ● instead")
        return '●'
    end
end




convert_attribute(value, ::key"marker", ::key"scatter") = to_spritemarker(value)
convert_attribute(value, ::key"isovalue", ::key"volume") = Float32(value)
convert_attribute(value, ::key"isorange", ::key"volume") = Float32(value)

function convert_attribute(value::Symbol, ::key"marker", ::key"meshscatter")
    if value === :Sphere
        return normal_mesh(Sphere(Point3f(0), 1f0))
    else
        error("Unsupported marker: $(value)")
    end
end

function convert_attribute(value::AbstractGeometry, ::key"marker", ::key"meshscatter")
    return normal_mesh(value)
end

convert_attribute(value, ::key"diffuse") = Vec3f(value)
convert_attribute(value, ::key"specular") = Vec3f(value)
