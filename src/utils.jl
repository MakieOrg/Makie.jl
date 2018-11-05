same_length_array(array, value::NativeFont) = Iterators.repeated(value, length(array))

# TODO upgrade GeometryTypes to do these kind of things.
# Problem: I don't really want to introduce a depedency on intervals
function Base.in(point::StaticVector{N}, rectangle::HyperRectangle{N}) where N
    mini, maxi = minimum(rectangle), maximum(rectangle)
    for i = 1:N
        point[i] in (mini[i] .. maxi[i]) || return false
    end
    return true
end
