"""
Plots a band between lower and upper bounds.

## Arguments

* `xs, ys_lower, ys_upper` Plots a band from `ys_lower` to `ys_upper` along `xs`. `xs` is an `AbstractVector{<:Real}` containing x-values, and `ys_lower`, `ys_upper` are `AbstractVector{<:Real}` containing the lower and upper y-limits of the band. These are interpreted as x-limits if `direction = :y`.
* `xs, lowerupper` Plots a band where `lowerupper` is an `AbstractVector{<:Interval}` containing the lower and upper limits of the band as intervals. These are interpreted as x-limits if `direction = :y`.
* `lower, upper` Plots a [ruled surface](https://en.wikipedia.org/wiki/Ruled_surface) between the points in `lower` and `upper`. Both are `AbstractVector{<:Point{D, <:Real}}` containing the (x, y) or (x, y, z) coordinates of the lower and upper limits of the band respectively. Setting `direction = :y` will swap x and y in the 2D case.
"""
@recipe Band (lowerpoints, upperpoints) begin
    documented_attributes(Mesh)...
    "The direction of the band. If set to `:y`, x and y coordinates will be flipped, resulting in a vertical band. This setting applies only to 2D bands."
    direction = :x
    "Sets the color of the lines at the lower and upper limits of the band"
    strokecolor = @inherit patchstrokecolor
    "Sets the colormap that is sampled for numeric `strokecolor`s."
    strokecolormap = @inherit colormap
    "Sets the width of the lines at the lower and upper limits of the band"
    strokewidth = @inherit patchstrokewidth
    shading = NoShading
end

function convert_arguments(::Type{<:Band}, x, ylower, yupper)
    return (Point2{float_type(x, ylower)}.(x, ylower), Point2{float_type(x, yupper)}.(x, yupper))
end

function convert_arguments(P::Type{<:Band}, x::AbstractVector{<:Number}, y::AbstractVector{<:Interval})
    return convert_arguments(P, x, leftendpoint.(y), rightendpoint.(y))
end

function band_connect(n)
    ns = 1:(n - 1)
    ns2 = (n + 1):(2n - 1)
    return [GLTriangleFace.(ns, ns .+ 1, ns2); GLTriangleFace.(ns .+ 1, ns2 .+ 1, ns2)]
end

function plot!(plot::Band)
    nanpoint(::Type{<:Point3}) = Point3(NaN)
    nanpoint(::Type{<:Point2}) = Point2(NaN)
    map!(plot, [:lowerpoints, :upperpoints, :direction], :coordinates) do lowerpoints, upperpoints, direction
        n = length(lowerpoints)
        @assert n == length(upperpoints) "length of lower band is not equal to length of upper band!"
        concat = [lowerpoints; upperpoints]
        direction in (:x, :y) || error("Invalid band direction $(repr(direction)). Allowed values are :x and :y.")
        if direction === :y && eltype(concat) <: Point2
            concat .= reverse.(concat)
        end
        # if either x, upper or lower is NaN, all of them should be NaN to cut out a whole band segment and not just a triangle
        for i in 1:n
            if isnan(lowerpoints[i]) || isnan(upperpoints[i])
                concat[i] = nanpoint(eltype(concat))
                concat[n + i] = nanpoint(eltype(concat))
            end
        end
        return concat
    end

    map!(plot, [:lowerpoints], :connectivity) do lowerpoints
        return band_connect(length(lowerpoints))
    end

    map!(plot, [:lowerpoints, :color], :colors) do lowerpoints, c
        if c isa AbstractVector
            # if the same number of colors is given as there are
            # points on one side of the band, the colors are mirrored to the other
            # side to make an even band
            if length(c) == length(lowerpoints)
                return repeat(to_color(c), 2)
                # if there's one color for each band vertex, the colors are used directly
            elseif length(c) == 2 * length(lowerpoints)
                return to_color(c)
            else
                error("Wrong number of colors. Must be $(length(lowerpoints)) or double.")
            end
        else
            return c
        end
    end

    mesh!(plot, plot.attributes, plot.coordinates, plot.connectivity, color = plot.colors)

    map!(plot, :strokecolor, :linecolor) do strokecolor
        if strokecolor isa AbstractVector
            return vcat(strokecolor, strokecolor[1:1], strokecolor)
        else
            return strokecolor
        end
    end

    map!(plot, [:lowerpoints, :upperpoints, :direction], :merged_points) do lower, upper, direction
        ps = copy(lower)
        push!(ps, eltype(ps)(NaN))
        append!(ps, upper)
        if direction === :y
            ps .= reverse.(ps)
        end
        return ps
    end

    lines!(
        plot, plot.attributes, plot.merged_points,
        linewidth = plot.strokewidth, color = plot.linecolor,
        fxaa = false
    )

    return
end

function fill_view(x, y1, y2, where::Nothing)
    return x, y1, y2
end
function fill_view(x, y1, y2, where::Function)
    return fill_view(x, y1, y2, where.(x, y1, y2))
end
function fill_view(x, y1, y2, bools::AbstractVector{<:Union{Integer, Bool}})
    return view(x, bools), view(y1, bools), view(y2, bools)
end

"""
    fill_between!(scenelike, x, y1, y2; where = nothing, kw_args...)

fill the section between 2 lines with the condition `where`
"""
function fill_between!(scenelike, x, y1, y2; where = nothing, kw_args...)
    xv, ylow, yhigh = fill_view(x, y1, y2, where)
    return band!(scenelike, xv, ylow, yhigh; kw_args...)
end

export fill_between!

# attribute_examples for Band has been moved to documentation/plots/band.md
# under the "## Attributes" section and is now loaded automatically.
