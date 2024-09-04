"""
spy(z::AbstractSparseArray)
spy(x_range::NTuple{2, Number}, y_range::NTuple{2, Number}, z::AbstractSparseArray)
spy(x_range::ClosedInterval, y_range::ClosedInterval, z::AbstractSparseArray)

Visualizes big sparse matrices.
Usage:
```julia
using SparseArrays, GLMakie
N = 200_000
x = sprand(Float64, N, N, (3(10^6)) / (N*N));
spy(x)
# or if you want to specify the range of x and y:
spy(0..1, 0..1, x)
```
"""
@recipe Spy (x::EndPoints, y::EndPoints, z::RealMatrix) begin
    """
    Can be any of the markers supported by `scatter!`.
    Note, for huge sparse arrays, one should use `FastPixel`, which is a very fast, but can only render square markers.
    So, without `Axis(...; aspect=1)`, the markers won't have the correct size.
    Compare:
    ```julia
    data = sprand(10, 10, 0.5)
    f = Figure()
    spy(f[1, 1], data; marker=FastPixel())
    spy(f[1, 2], data; marker=FastPixel(), axis=(; aspect=1))
    f
    ```
    """
    marker = Rect
    """
    markersize=automatic, will make the marker size fit the data - but can also be set manually.
    """
    markersize = automatic
    """
    By default a frame will be drawn around the data, which uses the `framecolor` attribute for its color.
    """
    framecolor = :black
    """
    Whether or not to draw the frame.
    """
    framevisible = true
    """
    The linewidth of the frame
    """
    framesize = 1
    """
    Per default the color of the markers will be determined by the value in the matrix, but can be overwritten via `color`.
    """
    color = nothing
    MakieCore.mixin_generic_plot_attributes()...
    MakieCore.mixin_colormap_attributes()...
end

function data_limits(plot::Spy)
    xmin, xmax = minmax(plot.x[]...)
    ymin, ymax = minmax(plot.y[]...)
    return Rect3d(Point3d(xmin, ymin, 0), Vec3d(xmax - xmin, ymax - ymin, 0))
end

function boundingbox(p::Spy, space::Symbol=:data)
    return apply_transform_and_model(p, data_limits(p))
end

function convert_arguments(::Type{<:Spy}, matrix::AbstractMatrix{T}) where T
    Tr = Makie.float_type(T)
    return convert_arguments(Spy, Tr.((0, size(matrix, 1))), Tr.((0, size(matrix, 2))), matrix)
end

function convert_arguments(::Type{<:Spy}, xs, ys, matrix::AbstractMatrix)
    x = to_endpoints(xs, "x")
    y = to_endpoints(ys, "y")
    return (x, y, convert(SparseArrays.SparseMatrixCSC, matrix))
end

needs_tight_limits(::Spy) = true

function Makie.plot!(p::Spy)
    rect = lift(p, p.x, p.y) do x, y
        xe = minmax(x...)
        ye = minmax(y...)
        Rect2((xe[1], ye[1]), (xe[2] - xe[1], ye[2] - ye[1]))
    end
    # TODO FastPixel isn't accepting marker size in data coordinates
    # but instead in pixel - so we need to fix that in GLMakie for consistency
    # and make this nicer when redoing unit support
    markersize = lift(p, p.markersize, rect, p.z) do msize, rect, z
        if msize === automatic
            widths(rect) ./ Vec2(size(z))
        else
            msize
        end
    end
    # TODO correctly align marker
    xycol = lift(p, rect, p.z, markersize) do rect, z, markersize
        x, y, color = SparseArrays.findnz(z)
        mhalf = markersize ./ 2
        points = map(x, y) do x, y
            p01 = (Point2(x, y) .- 1) ./ Point2(size(z))
            return (p01 .* widths(rect)) .+ minimum(rect) .+ mhalf
        end
        points, convert(Vector{Float32}, color)
    end
    color = map(p, p.color, xycol) do color, xycol
        return isnothing(color) ? xycol[2] : color
    end

    scatter!(
        p,
        lift(first, p, xycol);
        color = color,
        markerspace = :data,
        marker = p.marker, markersize = markersize,
        MakieCore.colormap_attributes(p)...,
        MakieCore.generic_plot_attributes(p)...
    )

    lines!(p, rect,
        color = p.framecolor,
        linewidth = p.framesize,
        inspectable = p.inspectable,
        visible = p.framevisible
    )
end
