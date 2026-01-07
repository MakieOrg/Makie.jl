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
    Makes the marker size smaller to create a gap between the markers.
    The unit of this is in data space.
    """
    marker_gap = 0
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
    mixin_generic_plot_attributes()...
    mixin_colormap_attributes()...
end

function data_limits(plot::Spy)
    return Rect3d(plot.data_limits[])
end

function boundingbox(p::Spy, space::Symbol = :data)
    return apply_transform_and_model(p, data_limits(p))
end

function convert_arguments(::Type{<:Spy}, matrix::AbstractMatrix{T}) where {T}
    Tr = Makie.float_type(T)
    return convert_arguments(Spy, Tr.((0, size(matrix, 1))), Tr.((0, size(matrix, 2))), matrix)
end

function convert_arguments(::Type{<:Spy}, xs, ys, matrix::AbstractMatrix)
    x = to_endpoints(xs, "x", "Spy")
    y = to_endpoints(ys, "y", "Spy")
    return (x, y, convert(SparseArrays.SparseMatrixCSC, matrix))
end

needs_tight_limits(::Spy) = true

function Makie.plot!(p::Spy)
    map!(p, [:x, :y], :data_limits) do x, y
        xe = minmax(x...)
        ye = minmax(y...)
        Rect2((xe[1], ye[1]), (xe[2] - xe[1], ye[2] - ye[1]))
    end
    # TODO FastPixel isn't accepting marker size in data coordinates
    # but instead in pixel - so we need to fix that in GLMakie for consistency
    # and make this nicer when redoing unit support
    map!(p, [:markersize, :data_limits, :z, :marker_gap], :spy_markersize) do markersize, rect, z, gap
        if markersize === automatic
            return Vec2f((widths(rect) ./ Vec2(size(z))) .- gap)
        else
            return Vec2f(markersize)
        end
    end

    map!(p, [:z, :spy_markersize, :color, :data_limits], [:positions, :spy_color, :index_map]) do z, markersize, color, rect
        x, y, scolor = SparseArrays.findnz(z)
        index_map = Dict(enumerate(zip(x, y)))
        mhalf = markersize ./ 2
        points = map(x, y) do x, y
            p01 = (Point2(x, y) .- 1) ./ Point2(size(z))
            return (p01 .* widths(rect)) .+ minimum(rect) .+ mhalf
        end
        _color = isnothing(color) ? convert(Vector{Float32}, scolor) : color
        return points, _color, index_map
    end

    scatter!(
        p, p.positions;
        color = p.spy_color,
        markerspace = :data,
        marker = p.marker, markersize = p.spy_markersize,
        colormap_attributes(p)...,
        generic_plot_attributes(p)...
    )

    lines!(
        p, p.data_limits;
        color = p.framecolor,
        linewidth = p.framesize,
        visible = p.framevisible,
        inspectable = false
    )

    return p
end
