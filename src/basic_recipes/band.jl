"""
    band(x, ylower, yupper; kwargs...)
    band(lower, upper; kwargs...)
    band(x, lowerupper; kwargs...)

Plots a band from `ylower` to `yupper` along `x`. The form `band(lower, upper)` plots a [ruled surface](https://en.wikipedia.org/wiki/Ruled_surface)
between the points in `lower` and `upper`.
Both bounds can be passed together as `lowerupper`, a vector of intervals.
"""
@recipe Band (lowerpoints, upperpoints) begin
    MakieCore.documented_attributes(Mesh)...
    shading = NoShading
end

function convert_arguments(::Type{<: Band}, x, ylower, yupper)
    return (Point2{float_type(x, ylower)}.(x, ylower), Point2{float_type(x, yupper)}.(x, yupper))
end

convert_arguments(P::Type{<: Band}, x::AbstractVector{<:Number}, y::AbstractVector{<:Interval}) =
    convert_arguments(P, x, leftendpoint.(y), rightendpoint.(y))

function band_connect(n)
    ns = 1:n-1
    ns2 = n+1:2n-1
    return [GLTriangleFace.(ns, ns .+ 1, ns2); GLTriangleFace.(ns .+ 1, ns2 .+ 1, ns2)]
end

function Makie.plot!(plot::Band)
    @extract plot (lowerpoints, upperpoints)
    nanpoint(::Type{<:Point3}) = Point3(NaN)
    nanpoint(::Type{<:Point2}) = Point2(NaN)
    coordinates = lift(plot, lowerpoints, upperpoints) do lowerpoints, upperpoints
        n = length(lowerpoints)
        @assert n == length(upperpoints) "length of lower band is not equal to length of upper band!"
        concat = [lowerpoints; upperpoints]
        # if either x, upper or lower is NaN, all of them should be NaN to cut out a whole band segment and not just a triangle
        for i in 1:n
            if isnan(lowerpoints[i]) || isnan(upperpoints[i])
                concat[i] = nanpoint(eltype(concat))
                concat[n + i] = nanpoint(eltype(concat))
            end
        end
        return concat
    end
    connectivity = lift(x -> band_connect(length(x)), plot, plot[1])

    meshcolor = Observable{RGBColors}()

    lift!(plot, meshcolor, plot.color) do c
        if c isa AbstractArray
            # if the same number of colors is given as there are
            # points on one side of the band, the colors are mirrored to the other
            # side to make an even band
            if length(c) == length(lowerpoints[])
                return repeat(to_color(c), 2)::RGBColors
            # if there's one color for each band vertex, the colors are used directly
            elseif length(c) == 2 * length(lowerpoints[])
                return to_color(c)::RGBColors
            else
                error("Wrong number of colors. Must be $(length(lowerpoints[])) or double.")
            end
        else
            return to_color(c)::RGBAf
        end
    end
    attr = Attributes(plot)
    attr[:color] = meshcolor
    mesh!(plot, attr, coordinates, connectivity)
    
    return plot
end

function fill_view(x, y1, y2, where::Nothing)
    x, y1, y2
end
function fill_view(x, y1, y2, where::Function)
    fill_view(x, y1, y2, where.(x, y1, y2))
end
function fill_view(x, y1, y2, bools::AbstractVector{<: Union{Integer, Bool}})
    view(x, bools), view(y1, bools), view(y2, bools)
end

"""
    fill_between!(scenelike, x, y1, y2; where = nothing, kw_args...)

fill the section between 2 lines with the condition `where`
"""
function fill_between!(scenelike, x, y1, y2; where = nothing, kw_args...)
    xv, ylow, yhigh = fill_view(x, y1, y2, where)
    band!(scenelike, xv, ylow, yhigh; kw_args...)
end

export fill_between!
