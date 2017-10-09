gpuvec(x) = GPUVector(GLBuffer(x))

function to_nd(x, n::Type{Val{N}}, default) where N
    ntuple(n) do i
        i <= length(x) && return x[i]
        default
    end
end


function to_world(point::T, cam) where T <: StaticVector
    x = to_world(
        point,
         inv(Reactive.value(cam.view)) * inv(Reactive.value(cam.projection)),
        T(widths(Reactive.value(cam.window_size)))
    )
    Point2f0(x[1], x[2])
end
function to_world(
        p::StaticVector{N, T},
        prj_view_inv::Mat4,
        cam_res::StaticVector
    ) where {N, T}
    VT = typeof(p)
    clip_space = ((VT(p) ./ VT(cam_res)) .* T(2)) .- T(1)
    pix_space = Vec{4, T}(
        clip_space[1],
        clip_space[2],
        T(0), GLAbstraction.w_component(p)
    )
    ws = prj_view_inv * pix_space
    ws ./ ws[4]
end

function qrotation(axis::StaticVector{N, T}, theta) where {N, T <: Real}
    if length(axis) != 3
        error("Must be a 3-vector")
    end
    u = normalize(axis)
    thetaT = convert(eltype(u), theta)
    s = sin(thetaT / T(2))
    Vec4f0(s * u[1], s * u[2], s * u[3], cos(thetaT / T(2)))
end

qabs(q) = sqrt(dot(q, q))

function qnormalize(q)
    q ./ qabs(q)
end

function qmul(quat::StaticVector{4}, vec::StaticVector{2})
    x3 = qmul(quat, Vec(vec[1], vec[2], 0))
    StaticArrays.similar_type(vec, StaticArrays.Size(2,))(x3[1], x3[2])
end
function qmul(quat::StaticVector{4}, vec::StaticVector{3})
    num = quat[1] * 2f0;
    num2 = quat[2] * 2f0;
    num3 = quat[3] * 2f0;
    num4 = quat[1] * num;
    num5 = quat[2] * num2;
    num6 = quat[3] * num3;
    num7 = quat[1] * num2;
    num8 = quat[1] * num3;
    num9 = quat[2] * num3;
    num10 = quat[4] * num;
    num11 = quat[4] * num2;
    num12 = quat[4] * num3;
    return Point3f0(
        (1f0 - (num5 + num6)) * vec[1] + (num7 - num12) * vec[2] + (num8 + num11) * vec[3],
        (num7 + num12) * vec[1] + (1f0 - (num4 + num6)) * vec[2] + (num9 - num10) * vec[3],
        (num8 - num11) * vec[1] + (num9 + num10) * vec[2] + (1f0 - (num4 + num5)) * vec[3]
    )
end
qconj(q) = Vec4f0(-q[1], -q[2], -q[3], q[4])

function qmul(q::StaticVector{4}, w::StaticVector{4})
    qq = Vec4f0(
        q[4] * w[4] - q[1] * w[1] - q[2] * w[2] - q[3] * w[3],
        q[4] * w[1] + q[1] * w[4] + q[2] * w[3] - q[3] * w[2],
        q[4] * w[2] - q[1] * w[3] + q[2] * w[4] + q[3] * w[1],
        q[4] * w[3] + q[1] * w[2] - q[2] * w[1] + q[3] * w[4],
    )
    qnormalize(qq)
end
