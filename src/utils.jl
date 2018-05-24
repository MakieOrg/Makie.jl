
function qrotation(axis::StaticVector{N, T}, theta) where {N, T <: Real}
    if length(axis) != 3
        error("Must be a 3-vector")
    end
    u = normalize(axis)
    thetaT = convert(eltype(u), theta)
    s = sin(thetaT / T(2))
    x = Vec4f0(s * u[1], s * u[2], s * u[3], cos(thetaT / T(2)))
    # qnormalize(x)
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
    Vec4f0(
        q[4] * w[1] + q[1] * w[4] + q[2] * w[3] - q[3] * w[2],
        q[4] * w[2] - q[1] * w[3] + q[2] * w[4] + q[3] * w[1],
        q[4] * w[3] + q[1] * w[2] - q[2] * w[1] + q[3] * w[4],
        q[4] * w[4] - q[1] * w[1] - q[2] * w[2] - q[3] * w[3],
    )
end


function drawbrush(scene)
    brush = to_node(Point2f0[])
    waspressed_t_lastpos = Ref((false, time(), Point2f0(0)))
    cam = scene[:screen].cameras[:orthographic_pixel]
    Makie.to_world(Point2f0(0,0), cam)
    lift_node(scene, :mouseposition) do mp
        if ispressed(scene, Makie.Mouse.left)
            waspressed, t, lastpos = waspressed_t_lastpos[]
            append!(brush, [Makie.to_world(Point2f0(mp), cam)])
            if !waspressed
                waspressed_t_lastpos[] = (true, time(), mp)
            else
                waspressed_t_lastpos[] = (true, t, mp)
            end
        else
            waspressed_t_lastpos[] = (false, 0, Point2f0(0))
        end
        return
    end
end



function close2square(n::Real)
    # a cannot be greater than the square root of n
    # b cannot be smaller than the square root of n
    # we get the maximum allowed value of a
    amax = floor(Int, sqrt(n));
    if 0 == rem(n, amax)
        # special case where n is a square number
        return (amax, div(n, amax))
    end
    # Get its prime factors of n
    primeFactors  = factor(n);
    # Start with a factor 1 in the list of candidates for a
    candidates = [1]
    for (f, _) in primeFactors
        # Add new candidates which are obtained by multiplying
        # existing candidates with the new prime factor f
        # Set union ensures that duplicate candidates are removed
        candidates = union(candidates, f .* candidates)
        # throw out candidates which are larger than amax
        filter!(x-> x <= amax, candidates)
    end
    # Take the largest factor in the list d
    (candidates[end], div(n, candidates[end]))
end
to_vector(x::AbstractVector, len, T) = convert(Vector{T}, x)
to_vector(x::ClosedInterval, len, T) = linspace(T.(extrema(x))..., len)
same_length_array(array, value::Font) = Iterators.repeated(value, length(array))
function extrema_nan(x::ClosedInterval)
    (minimum(x), maximum(x))
end



function Base.in(point::StaticVector{N}, rectangle::HyperRectangle{N}) where N
    mini, maxi = minimum(rectangle), maximum(rectangle)
    for i = 1:N
        point[i] in (mini[i] .. maxi[i]) || return false
    end
    return true
end

to_range(x) = optimal_ticks_and_labels((minimum(x), maximum(x)))
to_range(x::VecTypes{2}) = optimal_ticks_and_labels((x[1], x[2]))
