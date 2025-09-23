# I'm not too proud of this code duplication -
# but first of all we want to keep dependencies small, and second,
# the bool in Quaternions.Quaternion is annoying for OpenGL + and an array of
# Quaternions.
# TODO replace this file by just `using Quaternions`

struct Quaternion{T}
    data::NTuple{4, T}
    Quaternion{T}(x::NTuple{4, Any}) where {T} = new{T}(T.(x))
    Quaternion{T}(x::NTuple{4, T}) where {T} = new{T}(x)
end

Base.eltype(::Quaternion{T}) where {T} = T
Base.eltype(::Type{Quaternion{T}}) where {T} = T
Base.length(::Type{<:Quaternion}) = 4
Base.length(::Quaternion) = 4

const Quaternionf = Quaternion{Float32}
const SMat{N, L} = Mat{N, N, T, L} where {T}

function Base.show(io::IO, q::Quaternion)
    pm(x) = x < 0 ? " - $(-x)" : " + $x"
    return print(io, q[4], pm(q[1]), "im", pm(q[2]), "jm", pm(q[3]), "km")
end

Random.rand(mt::AbstractRNG, ::Random.SamplerType{Quaternion}) = rand(mt, Quaternion{Float64})
Random.rand(mt::AbstractRNG, ::Random.SamplerType{Quaternion{T}}) where {T} = Quaternion(rand(mt, T), rand(mt, T), rand(mt, T), 1.0)

Quaternion{T}(x1, x2, x3, s) where {T} = Quaternion{T}((x1, x2, x3, s))
Base.convert(T::Type{<:Quaternion}, x::NTuple{4, Any}) = T(x)
function Base.convert(T::Type{Quaternion{T1}}, x::Quaternion{T2}) where {T1, T2}
    return T(T2.(x.data))
end
Quaternion(x1, x2, x3, s) = Quaternion(promote(x1, x2, x3, s))
Quaternion(x::NTuple{4, T}) where {T} = Quaternion{T}(x)
Base.getindex(x::Quaternion, i::Integer) = x.data[i]
function Base.isapprox(x::Quaternion, y::Quaternion; kwargs...)
    return all(isapprox.(x.data, y.data; kwargs...))
end

function qrotation(axis::StaticVector{3}, theta::Number)
    u = normalize(axis)
    s = sin(theta / 2)
    return Quaternion(s * u[1], s * u[2], s * u[3], cos(theta / 2))
end

function Base.broadcast(f, arg1::Quaternion, arg2::Quaternion)
    return Quaternion(f.(arg1.data, arg2.data))
end

Base.abs(q::Quaternion) = sqrt(sum(q.data .^ 2))

LinearAlgebra.normalize(q::Quaternion) = q / abs(q)

Base.:(/)(q::Quaternion, x::Real) = Quaternion(q[1] / x, q[2] / x, q[3] / x, q[4] / x)

function Base.:(*)(quat::Quaternion, vec::P) where {P <: StaticVector{2}}
    T = eltype(vec)
    x3 = quat * Vec(vec[1], vec[2], T(0))
    return P(x3[1], x3[2])
end

function Base.:(*)(quat::Quaternion{T}, vec::P) where {T, P <: StaticVector{3}}
    num = quat[1] * T(2)
    num2 = quat[2] * T(2)
    num3 = quat[3] * T(2)

    num4 = quat[1] * num
    num5 = quat[2] * num2
    num6 = quat[3] * num3

    num7 = quat[1] * num2
    num8 = quat[1] * num3
    num9 = quat[2] * num3

    num10 = quat[4] * num
    num11 = quat[4] * num2
    num12 = quat[4] * num3

    return P(
        (1.0f0 - (num5 + num6)) * vec[1] + (num7 - num12) * vec[2] + (num8 + num11) * vec[3],
        (num7 + num12) * vec[1] + (1.0f0 - (num4 + num6)) * vec[2] + (num9 - num10) * vec[3],
        (num8 - num11) * vec[1] + (num9 + num10) * vec[2] + (1.0f0 - (num4 + num5)) * vec[3]
    )
end

function Base.:(*)(quat::Quaternion, bb::Rect3{T}) where {T}
    points = corners(bb)
    bb = Rect3{T}()
    for i in eachindex(points)
        bb = update_boundingbox(bb, Point3{T}(quat * points[i]))
    end
    return bb
end

Base.conj(q::Quaternion) = Quaternion(-q[1], -q[2], -q[3], q[4])

function Base.:(*)(q::Quaternion, w::Quaternion)
    return Quaternion(
        q[4] * w[1] + q[1] * w[4] + q[2] * w[3] - q[3] * w[2],
        q[4] * w[2] - q[1] * w[3] + q[2] * w[4] + q[3] * w[1],
        q[4] * w[3] + q[1] * w[2] - q[2] * w[1] + q[3] * w[4],
        q[4] * w[4] - q[1] * w[1] - q[2] * w[2] - q[3] * w[3],
    )
end

SMat{N, L}(q::Quaternion{T}) where {N, T, L} = Mat{N, N, T, L}(q)

function Mat4{ET}(q::Quaternion{T}) where {T, ET}
    sx, sy, sz = 2q[4] * q[1], 2q[4] * q[2], 2q[4] * q[3]
    xx, xy, xz = 2q[1]^2, 2q[1] * q[2], 2q[1] * q[3]
    yy, yz, zz = 2q[2]^2, 2q[2] * q[3], 2q[3]^2
    T0, T1 = zero(ET), one(ET)
    return Mat{4, 4, ET}(
        T1 - (yy + zz), xy + sz, xz - sy, T0,
        xy - sz, T1 - (xx + zz), yz + sx, T0,
        xz + sy, yz - sx, T1 - (xx + yy), T0,
        T0, T0, T0, T1
    )
end

concrete_type(::Type{Any}, ::Type{T}) where {T} = T
concrete_type(::Type{T}, x) where {T} = T

function Mat3{ET}(q::Quaternion{T}) where {T, ET}
    sx, sy, sz = 2q[4] * q[1], 2q[4] * q[2], 2q[4] * q[3]
    xx, xy, xz = 2q[1]^2, 2q[1] * q[2], 2q[1] * q[3]
    yy, yz, zz = 2q[2]^2, 2q[2] * q[3], 2q[3]^2
    T0, T1 = zero(ET), one(ET)
    return Mat{3, 3, ET}(
        T1 - (yy + zz), xy + sz, xz - sy,
        xy - sz, T1 - (xx + zz), yz + sx,
        xz + sy, yz - sx, T1 - (xx + yy)
    )
end

function orthogonal(v::T) where {T <: StaticVector{3}}
    x, y, z = abs.(v)
    other = x < y ? (x < z ? GeometryBasics.unit(T, 1) : GeometryBasics.unit(T, 3)) : (y < z ? GeometryBasics.unit(T, 2) : GeometryBasics.unit(T, 3))
    return cross(v, other)
end

function rotation_between(u::StaticVector{3, T}, v::StaticVector{3, T}) where {T}
    k_cos_theta = dot(u, v)
    k = sqrt((norm(u)^2) * (norm(v)^2))
    if (k_cos_theta / k) ≈ T(-1)
        # 180 degree rotation around any orthogonal vector
        return Quaternion(normalize(orthogonal(u))..., T(0))
    else
        return normalize(Quaternion(cross(u, v)..., k_cos_theta + k))
    end
end

function quaternion_to_2d_angle(quat::Quaternion)
    # this assumes that the quaternion was calculated from a simple 2d rotation as well
    return 2acos(quat[4]) * (signbit(quat[1]) ? -1 : 1)
end

Base.isinf(q::Quaternion) = any(isinf, q.data)
Base.isnan(q::Quaternion) = any(isnan, q.data)
Base.isfinite(q::Quaternion) = all(isfinite, q.data)
Base.abs2(q::Quaternion) = mapreduce(*, +, q.data, q.data)
function Base.inv(q::Quaternion)
    if isinf(q)
        return quat(
            flipsign(-zero(q[1]), q[1]),
            flipsign(-zero(q[2]), q[2]),
            flipsign(-zero(q[3]), q[3]),
            copysign(zero(q[4]), q[4]),
        )
    end
    a = max(abs(q[4]), abs(q[1]), abs(q[2]), abs(q[3]))
    p = q / a
    iq = conj(p) / (a * abs2(p))
    return iq
end
