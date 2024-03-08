function convert_arguments(::Type{<: Wireframe}, x::AbstractVector, y::AbstractVector, z::AbstractMatrix)
    (ngrid(x, y)..., z)
end

xvector(x::AbstractVector, len) = x
xvector(x::ClosedInterval, len) = range(minimum(x), stop=maximum(x), length=len)
xvector(x::AbstractMatrix, len) = x

yvector(x, len) = xvector(x, len)'
yvector(x::AbstractMatrix, len) = x

function plot!(plot::Wireframe{<: Tuple{<: Any, <: Any, <: AbstractMatrix}})
    points_faces = lift(plot, plot[1:3]...) do x, y, z
        M, N = size(z)
        points = vec(Point3f.(xvector(x, M), yvector(y, N), z))
        # Connect the vetices with faces, as one would use for a 2D Rectangle
        # grid with M,N grid points
        faces = decompose(LineFace{GLIndex}, Tesselation(Rect2(0, 0, 1, 1), (M, N)))
        connect(points, faces)
    end
    linesegments!(plot, Attributes(plot), points_faces)
end

function plot!(plot::Wireframe{Tuple{T}}) where T
    points = lift(plot, plot[1]) do g
        # get the point representation of the geometry
        indices = decompose(LineFace{GLIndex}, g)
        points = decompose(Point, g)
        if isnothing(indices)
            # Some primitives don't have line faces defined, so we just connect each line segment
            return collect(reinterpret(eltype(points), connect(points, Line, 1)))
        else
            return connect(points, indices)
        end
    end
    linesegments!(plot, Attributes(plot), points)
end
