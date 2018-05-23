"""
    convert_arguments(P, ???)

??? --> Simon said this is to be removed
P is the plot Type (it is optional).
"""
function convert_arguments(P::Type, args::Vararg{Signal, N}) where N
    args_c = map(args...) do args...
        convert_arguments(P, args...)
    end
    ntuple(Val{N}) do i
        map(x-> x[i], args_c)
    end
end

"""
    convert_arguments(P, y)::(Vector)

Takes vector y and generates a range from 1 to the length of y, for plotting on
an arbitrary x axis.
P is the plot Type (it is optional).
"""
convert_arguments(P, y::RealVector) = convert_arguments(1 .. length(y), y)

"""
    convert_arguments(P, x, y)::(Vector)

Takes vectors x and y and turns it into a vector of 2D points of the values
from x and y.
P is the plot Type (it is optional).
"""
convert_arguments(P, x::RealVector, y::RealVector) = (Point2f0.(x, y),)

"""
    convert_arguments(P, x, y, z)::(Vector)

Takes vectors x, y, and z and turns it into a vector of 3D points of the values
from x, y, and z.
P is the plot Type (it is optional).
"""
convert_arguments(P, x::RealVector, y::RealVector, z::RealVector) = (Point3f0.(x, y, z),)

"""
    convert_arguments(x)::(String)

Takes an input AbstractString x and converts it to a string.
"""
convert_arguments(::Type{Text}, x::AbstractString) = (String(x),)

"""
    convert_arguments(P, x)::(Vector)

Accepts a vector x of the types in VecTypes.
P is the plot Type (it is optional).
"""
convert_arguments(P, x::AbstractVector{<: VecTypes}) = (x,)

"""
    convert_arguments(P, x)::(Vector)

Takes an input GeometryPrimitive x and decomposes it to points.
P is the plot Type (it is optional).
"""
convert_arguments(P, x::GeometryPrimitive) = (decompose(Point, x),)


function convert_arguments(P, x::AbstractVector{Pair{Point{N, T}, Point{N, T}}}) where {N, T}
    (reinterpret(Point{N, T}, x),)
end

"""
    convert_arguments(P, x, y, z)::Tuple{Matrix, Matrix, Matrix}

Takes 3 inputs of AbstractMatrix x, y, and z, converts them to Float32 and
outputs them in a Tuple.
P is the plot Type (it is optional).
"""
function convert_arguments(P, x::AbstractMatrix, y::AbstractMatrix, z::AbstractMatrix)
    (Float32.(x), Float32.(y), Float32.(z))
end

"""
    convert_arguments(P, x, y, z)::Tuple{Vector, Vector, Matrix}

Takes 2 AbstractVector's x, y, and an AbstractMatrix z, and puts them in a Tuple.
P is the plot Type (it is optional).
"""
function convert_arguments(P, x::AbstractVector, y::AbstractVector, z::AbstractMatrix)
    (x, y, z)
end

"""
    convert_arguments(P, x, y, z)::Tuple{ClosedInterval, ClosedInterval, Matrix}

Takes 2 ClosedIntervals's x, y, and an AbstractMatrix z, and puts them in a Tuple.
P is the plot Type (it is optional).
"""
function convert_arguments(P, x::ClosedInterval, y::ClosedInterval, z::AbstractMatrix)
    (x, y, z)
end

"""
    convert_arguments(P, x, y, z)::(ClosedInterval, ClosedInterval, Matrix)

Takes 2 ClosedIntervals's x, y, and z, converts the intervals x and y into a range,
and and puts everything in a Tuple.
P is the plot Type (it is optional).
"""
function convert_arguments(P, x::ClosedInterval, y::ClosedInterval, z)
    convert_arguments(P, to_range(x), to_range(y), z)
end

"""
    convert_arguments(P, Matrix)::Tuple{ClosedInterval, ClosedInterval, Matrix}

Takes a matrix, converts the dimesions n and m into closed intervals,
and stores the closed intervals to n and m, plus the original matrix in a Tuple.
P is the plot Type (it is optional).
"""
function convert_arguments(P, data::AbstractMatrix)
    n, m = Float64.(size(data))
    (0.0 .. n, 0.0 .. m, data)
end

"""
    convert_arguments(P, Matrix)::Tuple{ClosedInterval, ClosedInterval, Matrix}

Takes an array of {T, 3}, converts the dimesions n, m and k into closed intervals,
and stores the closed intervals to n, m and k, plus the original array in a Tuple.
P is the plot Type (it is optional).
"""
function convert_arguments(P, data::Array{T, 3}) where T
    n, m, k = Float64.(size(data))
    (0.0 .. n, 0.0 .. m, 0.0 .. k, data)
end

"""
    convert_arguments(P, x, y, z, i)::(Vector, Vector, Vector, Matrix)

Takes vectors x, y, and z and the matrix i, and puts everything in a Tuple.
P is the plot Type (it is optional).
"""
function convert_arguments(P, x::AbstractVector, y::AbstractVector, z::AbstractVector, i::AbstractArray{T, 3}) where T
    (x, y, z, i)
end

"""
    convert_arguments(P, x, y, z, i)::(ClosedInterval, ClosedInterval, ClosedInterval, Matrix)

Takes closed intervals x, y, and z and the matrix i, and puts everything in a Tuple.
P is the plot Type (it is optional).
"""
function convert_arguments(P, x::ClosedInterval, y::ClosedInterval, z::ClosedInterval, i::AbstractArray{T, 3}) where T
    (x, y, z, i)
end

"""
    convert_arguments(P, x, y, z, f)::(Vector, Vector, Vector, Matrix)

Takes vectors x, y, and z and the function f, evaluates the function on the volume
spanned by x, y and z, and puts x, y, z and f(x,y,z) in a Tuple.
P is the plot Type (it is optional).
"""
function convert_arguments(P, x::AbstractVector, y::AbstractVector, z::AbstractVector, f::Function)
    _x, _y, _z = ntuple(Val{3}) do i
        A = (x, y, z)[i]
        reshape(A, ntuple(j-> j != i ? 1 : length(A), Val{3}))
    end
    (x, y, z, f.(_x, _y, _z))
end


"""
    convert_arguments(P, x, y, f)::(Vector, Vector, Matrix)

Takes vectors x and y and the function f, and applies f on the grid that x and y span.
This is equivalent to f.(x, y').
P is the plot Type (it is optional).
"""
function convert_arguments(P, x::AbstractVector{T1}, y::AbstractVector{T2}, f::Function) where {T1, T2}
    if !applicable(f, x[1], y[1])
        error("You need to pass a function with signature f(x::$T1, y::$T2). Found: $f")
    end
    T = typeof(f(x[1], y[1]))
    z = similar(x, T, (length(x), length(y)))
    z .= f.(x, y')
    (x, y, z)
end

"""
    convert_arguments(P, x)::(Vector)

Takes an input HyperRectangle x and decomposes it to points.
P is the plot Type (it is optional).
"""
function convert_arguments(P, x::Rect)
    # TODO fix the order of decompose
    convert_arguments(P, decompose(Point2f0, x)[[1, 2, 4, 3, 1]])
end

"""
    convert_arguments(x)::(String)

Takes an input Mesh x and stores it in a Tuple.
"""
convert_arguments(::Type{Mesh}, m::AbstractMesh) = (m,)

"""
    convert_arguments(T, x, y, z, indices)::Tuple{Type, Matrix, Vector}

Takes an input mesh, RealVector's x, y and z, and an AbstractVector indices,
and puts it in a Tuple with the Type, the 3D points of the values from x, y and z,
and the indices.
"""
function convert_arguments(
        T::Type{Mesh},
        x::RealVector, y::RealVector, z::RealVector,
        indices::AbstractVector
    )
    convert_arguments(T, Point3f0.(x, y, z), indices)
end

"""
    convert_arguments(Mesh, vertices, indices)::()

Takes an input mesh, a vertices AbstractVector and AbstractVector indices,
and creates a GLNormalMesh.
"""
function convert_arguments(
        ::Type{Mesh},
        vertices::AbstractVector{<: VecTypes{3, T}},
        indices::AbstractVector
    ) where T
    vert3f0 = T != Float32 ? Point3f0.(vertices) : vertices
    vertp3f0 = reinterpret(Point3f0, vert3f0)
    m = GLNormalMesh(vertp3f0, indices)
    (m,)
end

"""
    convert_arguments(MT, x, y, z)::Tuple{Type, Matrix}

Takes an input mesh, RealVector's x, y and z, and puts them in a Tuple with
the type and the 3D points of the values from x, y and z.
"""
function convert_arguments(
        MT::Type{Mesh},
        x::RealVector, y::RealVector, z::RealVector
    )
    convert_arguments(MT, Point3f0.(x, y, z))
end

"""
    convert_arguments(MT, xyz)::()

Takes an input mesh and a matrix xyz, reinterprets xyz as GLTriangle's, and
recursively calls itself.
"""
function convert_arguments(
        MT::Type{Mesh},
        xyz::AbstractVector{<: VecTypes{3, T}}
    ) where T
    faces = reinterpret(GLTriangle, UInt32[0:(length(xyz)-1);])
    convert_arguments(MT, xyz, faces)
end

"""
    convert_arguments(MT, xy)::Tuple{Type, Matrix}

Takes an input mesh, AbstractVector xy, and puts them in a Tuple with
the type and the 3D points of the values from x, y and z = 0.0.
"""
function convert_arguments(MT::Type{Mesh}, xy::AbstractVector{<: VecTypes{2, T}}) where T
    convert_arguments(MT, Point3f0.(first.(xy), last.(xy), 0.0))
end
