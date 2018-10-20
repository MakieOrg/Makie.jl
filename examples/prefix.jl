# untyped generic code: perfect to inject our own types :)
function magic(y, func)
    l = length(y)
    k = ceil(Int, log2(l))
    for j=1:k, i=2^j:2^j:min(l, 2^k)
        y[i] = func(y[i-2^(j-1)], y[i])
    end
    for j=(k-1):-1:1, i=3*2^(j-1):2^j:min(l, 2^k)
        y[i] = func(y[i-2^(j-1)], y[i])
    end
    y
end
import Base: getindex, setindex!, length, size

mutable struct AccessArray <: AbstractArray{Nothing, 1}
    length::Int
    read::Vector
    history::Vector
end

function AccessArray(length, read = [], history = [])
    AccessArray(length, read, history)
end

length(A::AccessArray) = A.length
size(A::AccessArray) = (A.length,)

function getindex(A::AccessArray, i)
    push!(A.read, i)
    return
end

function setindex!(A::AccessArray, x, i)
    push!(A.history, (A.read, [i]))
    A.read = []
end

import Base.+
+(a::Nothing, b::Nothing)=a
A = magic(AccessArray(8), +)

using Makie, GeometryTypes
function render(A::AccessArray)
    olast = depth = 0
    for y in A.history
        (any(y[1] .≤ olast)) && (depth += 1)
        olast = maximum(y[2])
    end
    maxdepth = depth
    olast = depth = 0
    C = []
    for y in A.history
        (any(y[1] .≤ olast)) && (depth += 1)
        push!(C, ((y...,), A.length, maxdepth, depth))
        olast = maximum(y[2])
    end
    msize = 0.1
    outsize = 0.15
    x1 = Point2f0.(first.(first.(first.(C))), last.(C) .+ outsize .+ 0.05)
    x2 = Point2f0.(last.(first.(first.(C))), last.(C) .+ outsize .+ 0.05)
    x3 = Point2f0.(first.(last.(first.(C))), last.(C) .+ 1)
    connections = Point2f0[]

    yoff = Point2f0(0, msize / 2)
    ooff = Point2f0(0, outsize / 2 + 0.05)
    for i = 1:length(x3)
        push!(connections, x3[i] .- ooff, x1[i] .+ yoff, x3[i] .- ooff, x2[i] .+ yoff)
    end
    node_theme = Theme(
        markersize = msize, strokewidth = 3,
        strokecolor = :black, color = (:white, 0.0),
        axis = (
            ticks = (ranges = (1:8, 1:5),),
            names = (axisnames = ("Array Index", "Depth"),),
            frame = (axis_position = :none,)
        )
    )
    s = scatter(node_theme, x1)
    scatter!(node_theme, x2)
    scatter!(x3, color = :white, markersize = 0.2, strokewidth = 4, strokecolor = :black)
    scatter!(x3, color = :red, marker = '+', markersize = outsize)
    linesegments!(connections, color = :red)
    s
end
render(A)
