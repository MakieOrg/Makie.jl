

"""
Returns (N1, N2) with `N1 x N2 == n`. N2 might become 1
"""
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


# TODO upgrade GeometryTypes to do these kind of things.
# Problem: I don't really want to introduce a depedency on intervals
function Base.in(point::StaticVector{N}, rectangle::HyperRectangle{N}) where N
    mini, maxi = minimum(rectangle), maximum(rectangle)
    for i = 1:N
        point[i] in (mini[i] .. maxi[i]) || return false
    end
    return true
end

to_range(x::ClosedInterval) = (minimum(x), maximum(x))
to_range(x::VecTypes{2}) = x
to_range(x::AbstractRange) = (minimum(x), maximum(x))
