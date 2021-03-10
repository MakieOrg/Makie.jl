"""
    arrows(points, directions; kwargs...)
    arrows(x, y, u, v)
    arrows(x::AbstractVector, y::AbstractVector, u::AbstractMatrix, v::AbstractMatrix)
    arrows(x, y, z, u, v, w)

Plots arrows at the specified points with the specified components.
`u` and `v` are interpreted as vector components (`u` being the x
and `v` being the y), and the vectors are plotted with the tails at
`x`, `y`.

If `x, y, u, v` are `<: AbstractVector`, then each 'row' is plotted
as a single vector.

If `u, v` are `<: AbstractMatrix`, then `x` and `y` are interpreted as
specifications for a grid, and `u, v` are plotted as arrows along the
grid.

`arrows` can also work in three dimensions.

## Attributes
$(ATTRIBUTES)
"""
@recipe(Arrows, points, directions) do scene
    theme = Attributes(
        arrowhead = automatic,
        arrowtail = automatic,
        linecolor = :black,
        linewidth = automatic,
        arrowsize = automatic,
        linestyle = nothing,
        # scale = Vec3f0(1), # unused?
        align = :origin,
        normalize = false,
        lengthscale = automatic,
        colormap = :viridis
    )
    # connect arrow + linecolor by default
    get!(theme, :arrowcolor, theme[:linecolor])
    theme
end

# For the matlab/matplotlib users
const quiver = arrows
const quiver! = arrows!
export quiver, quiver!

arrow_head(N, marker) = marker
arrow_head(N, marker::Automatic) = N == 2 ? '▲' : load_asset("meshes/cone.obj")

arrow_tail(N, marker) = marker
arrow_tail(N, marker::Automatic) = N == 2 ? nothing : load_asset("meshes/tube.obj")


convert_arguments(::Type{<: Arrows}, x, y, u, v) = (Point2f0.(x, y), Vec2f0.(u, v))
function convert_arguments(::Type{<: Arrows}, x::AbstractVector, y::AbstractVector, u::AbstractMatrix, v::AbstractMatrix)
    (vec(Point2f0.(x, y')), vec(Vec2f0.(u, v)))
end
convert_arguments(::Type{<: Arrows}, x, y, z, u, v, w) = (Point3f0.(x, y, z), Vec3f0.(u, v, w))

function plot!(arrowplot::Arrows{<: Tuple{AbstractVector{<: Point{N, T}}, V}}) where {N, T, V}
    @extract arrowplot (
        points, directions, colormap, normalize, align,
        arrowtail, linecolor, linestyle, linewidth, lengthscale, 
        arrowhead, arrowsize, arrowcolor
    )
    
    if N == 2
        headstart = lift(points, directions, normalize, align, lengthscale) do points, dirs, n, align, lengthscale
            s = lengthscale === automatic ? 1f0 : Float32(lengthscale)
            map(points, dirs) do p1, dir
                dir = n ? StaticArrays.normalize(dir) : dir
                if align == :head
                    shift = s .* dir
                else
                    shift = Vec2f0(0)
                end
                Point2f0(p1 .- shift) => Point2f0(p1 .- shift .+ (dir .* s))
            end
        end

        linesegments!(
            arrowplot, headstart,
            color = linecolor, colormap = colormap, linestyle = linestyle, 
            linewidth = @lift($linewidth === automatic ? 1f0 : $linewidth)
        )
        scatter!(
            arrowplot,
            lift(x-> last.(x), headstart),
            marker = lift(x-> arrow_head(N, x), arrowhead), 
            markersize = @lift($arrowsize === automatic ? 0.3 : $arrowsize),
            color = arrowcolor, rotations = directions, strokewidth = 0.0, colormap = colormap,
        )
    else
        #                   2d              3d
        # lengthscale:  tail length     tail length
        # linewidth:    tail width      tail width
        # arrowsize:    head size       head size
        # dir:          tail length     tail length
        start = lift(points, directions, align, lengthscale) do points, dirs, align, lengthscale
            s = lengthscale === automatic ? 1f0 : Float32(lengthscale)
            map(points, dirs) do p, dir
                if align == :head
                    shift = Vec3f0(0)
                else
                    shift = -s .* dir
                end
                Point3f0(p .- shift)
            end
        end
        meshscatter!(
            arrowplot,
            start, rotations = directions,
            marker = lift(x -> arrow_tail(3, x), arrowtail),
            markersize = lift(directions, normalize, linewidth, lengthscale) do dirs, n, linewidth, lengthscale
                lw = linewidth === automatic ? 0.05f0 : linewidth
                ls = lengthscale === automatic ? 0.3f0 : lengthscale
                if n
                    Vec3f0(lw, lw, ls)
                else
                    map(dir -> Vec3f0(lw, lw, norm(dir) * ls), dirs)
                end 
            end, 
            color = linecolor, colormap = colormap
        )
        meshscatter!(
            arrowplot,
            start, rotations = directions,
            marker = lift(x -> arrow_head(3, x), arrowhead),
            markersize = lift(arrowsize, typ=Any) do as
                as === automatic ? Vec3f0(0.2, 0.2, 0.3) : as
            end,
            color = arrowcolor, colormap = colormap
        )
    end
end
