
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

same_length_array(array, value::NativeFont) = Iterators.repeated(value, length(array))
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

to_range(x::ClosedInterval) = (minimum(x), maximum(x))
to_range(x::VecTypes{2}) = x
to_range(x::Range) = (minimum(x), maximum(x))
