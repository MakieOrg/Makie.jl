function convert_arguments(::Type{<:Wireframe}, x::AbstractVector, y::AbstractVector, z::AbstractMatrix)
    return (ngrid(x, y)..., z)
end

xvector(x::AbstractVector, len) = x
xvector(x::ClosedInterval, len) = range(minimum(x), stop = maximum(x), length = len)
xvector(x::AbstractMatrix, len) = x

yvector(x, len) = xvector(x, len)'
yvector(x::AbstractMatrix, len) = x

function plot!(plot::Wireframe{<:Tuple{<:Any, <:Any, <:AbstractMatrix}})
    map!(plot, [:converted_1, :converted_2, :converted_3], :points_faces) do x, y, z
        M, N = size(z)
        points = vec(Point3f.(xvector(x, M), yvector(y, N), z))
        # Connect the vetices with faces, as one would use for a 2D Rectangle
        # grid with M,N grid points
        faces = decompose(LineFace{GLIndex}, Tessellation(Rect2(0, 0, 1, 1), (M, N)))
        connect(points, faces)
    end
    return linesegments!(plot, Attributes(plot), plot.points_faces)
end

function plot!(plot::Wireframe{Tuple{T}}) where {T}
    map!(plot, [:converted_1], :points) do g
        # get the point representation of the geometry
        indices = decompose(LineFace{GLIndex}, g)
        points = decompose(Point, g)
        if isnothing(indices)
            # Some primitives don't have line faces defined, so we just connect each line segment
            return collect(reinterpret(eltype(points), connect(points, Line, 1)))
        else
            x = collect(reinterpret(eltype(points), connect(points, indices)))
            return x
        end
    end
    return linesegments!(plot, Attributes(plot), plot.points)
end
