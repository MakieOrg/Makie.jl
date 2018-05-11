function convert_arguments(P::Type, args::Vararg{Signal, N}) where N
    args_c = map(args...) do args...
        convert_arguments(P, args...)
    end
    ntuple(Val{N}) do i
        map(x-> x[i], args_c)
    end
end
convert_arguments(P, y::RealVector) = convert_arguments(0 .. length(y), y)
convert_arguments(P, x::RealVector, y::RealVector) = (Point2f0.(x, y),)
convert_arguments(P, x::RealVector, y::RealVector, z::RealVector) = (Point3f0.(x, y, z),)
convert_arguments(::Type{Text}, x::AbstractString) = (String(x),)
convert_arguments(P, x::AbstractVector{<: VecTypes}) = (x,)
convert_arguments(P, x::GeometryPrimitive) = (decompose(Point, x),)


function convert_arguments(P, x::AbstractVector{Pair{Point{N, T}, Point{N, T}}}) where {N, T}
    (reinterpret(Point{N, T}, x),)
end

function convert_arguments(P, x::AbstractMatrix, y::AbstractMatrix, z::AbstractMatrix)
    (Float32.(x), Float32.(y), Float32.(z))
end
function convert_arguments(P, x::AbstractVector, y::AbstractVector, z::AbstractMatrix)
    (x, y, z)
end
function convert_arguments(P, x::ClosedInterval, y::ClosedInterval, z::AbstractMatrix)
    (x, y, z)
end
function convert_arguments(P, x::ClosedInterval, y::ClosedInterval, z)
    convert_arguments(P, to_range(x), to_range(y), z)
end
function convert_arguments(P, data::AbstractMatrix)
    n, m = Float64.(size(data))
    (0.0 .. n, 0.0 .. m, data)
end

function convert_arguments(P, data::Array{T, 3}) where T
    n, m, k = Float64.(size(data))
    (0.0 .. n, 0.0 .. m, 0.0 .. k, data)
end
function convert_arguments(P, x::AbstractVector, y::AbstractVector, z::AbstractVector, i::AbstractArray{T, 3}) where T
    (x, y, z, i)
end
function convert_arguments(P, x::ClosedInterval, y::ClosedInterval, z::ClosedInterval, i::AbstractArray{T, 3}) where T
    (x, y, z, i)
end
function convert_arguments(P, x::AbstractVector, y::AbstractVector, z::AbstractVector, f::Function)
    _x, _y, _z = ntuple(Val{3}) do i
        A = (x, y, z)[i]
        reshape(A, ntuple(j-> j != i ? 1 : length(A), Val{3}))
    end
    (x, y, z, f.(_x, _y, _z))
end

function convert_arguments(P, x::AbstractVector{T1}, y::AbstractVector{T2}, f::Function) where {T1, T2}
    if !applicable(f, x[1], y[1])
        error("You need to pass a function with signature f(x::$T1, y::$T2). Found: $f")
    end
    T = typeof(f(x[1], y[1]))
    z = similar(x, T, (length(x), length(y)))
    z .= f.(x, y')
    (x, y, z)
end

function convert_arguments(P, x::Rect)
    # TODO fix the order of decompose
    convert_arguments(P, decompose(Point2f0, x)[[1, 2, 4, 3, 1]])
end

convert_arguments(::Type{Mesh}, m::AbstractMesh) = (m,)
function convert_arguments(
        T::Type{Mesh},
        x::RealVector, y::RealVector, z::RealVector,
        indices::AbstractVector
    )
    convert_arguments(T, Point3f0.(x, y, z), indices)
end
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

function convert_arguments(
        MT::Type{Mesh},
        x::RealVector, y::RealVector, z::RealVector
    )
    convert_arguments(MT, Point3f0.(x, y, z))
end
function convert_arguments(
        MT::Type{Mesh},
        xyz::AbstractVector{<: VecTypes{3, T}}
    ) where T
    faces = reinterpret(GLTriangle, UInt32[0:(length(xyz)-1);])
    convert_arguments(MT, xyz, faces)
end
function convert_arguments(MT::Type{Mesh}, xy::AbstractVector{<: VecTypes{2, T}}) where T
    convert_arguments(MT, Point3f0.(first.(xy), last.(xy), 0.0))
end
