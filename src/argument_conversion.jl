"""
    convert_arguments(P, x, y, i)::(ClosedInterval, ClosedInterval, Matrix)

Takes closed intervals x, y, and the matrix z, and puts everything in a Tuple.
P is the plot Type (it is optional).
"""
function convert_arguments(P, x::ClosedInterval, y::ClosedInterval, z::AbstractMatrix)
    (x, y, z)
end


"""
    convert_arguments(P, x, y, z)::Tuple{ClosedInterval, ClosedInterval, Matrix}

Takes 2 ClosedIntervals's x, y, and an AbstractMatrix z, and puts them in a Tuple.
P is the plot Type (it is optional).
"""
function convert_arguments(P, x::ClosedInterval, y::ClosedInterval, z)
    convert_arguments(P, to_range(x), to_range(y), z)
end


"""
    convert_arguments(P, x, y, z)::(ClosedInterval, ClosedInterval, ClosedInterval, Matrix)

Takes 2 ClosedIntervals's x, y, and z, converts the intervals x and y into a range,
and and puts everything in a Tuple.
P is the plot Type (it is optional).
"""
function convert_arguments(P, data::Array{T, 3}) where T
    n, m, k = Float64.(size(data))
    (0.0 .. n, 0.0 .. m, 0.0 .. k, data)
end
