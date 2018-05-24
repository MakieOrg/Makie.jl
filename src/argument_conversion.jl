function convert_arguments(P, x::ClosedInterval, y::ClosedInterval, z::AbstractMatrix)
    (x, y, z)
end
function convert_arguments(P, x::ClosedInterval, y::ClosedInterval, z)
    convert_arguments(P, to_range(x), to_range(y), z)
end
function convert_arguments(P, data::Array{T, 3}) where T
    n, m, k = Float64.(size(data))
    (0.0 .. n, 0.0 .. m, 0.0 .. k, data)
end
