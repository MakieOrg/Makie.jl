"""
    band(x, ylower, yupper; kwargs...)
    band(lower, upper; kwargs...)

Plots a band from `ylower` to `yupper` along `x`. The form `band(lower, upper)` plots a [ruled surface](https://en.wikipedia.org/wiki/Ruled_surface)
between the points in `lower` and `upper`.

## Attributes
$(ATTRIBUTES)
"""
@recipe(Band, lowerpoints, upperpoints) do scene
    attr = Attributes(;
        default_theme(scene, Mesh)...,
        colorrange = automatic,
    )
    attr[:shading][] = false
    attr
end

convert_arguments(::Type{<: Band}, x, ylower, yupper) = (Point2f.(x, ylower), Point2f.(x, yupper))

function band_connect(n)
    ns = 1:n-1
    ns2 = n+1:2n-1
    [GLTriangleFace.(ns, ns .+ 1, ns2); GLTriangleFace.(ns .+ 1, ns2 .+ 1, ns2)]
end

function Makie.plot!(plot::PlotObject, ::Band)
    @extract plot (lowerpoints, upperpoints)
    @lift(@assert length($lowerpoints) == length($upperpoints) "length of lower band is not equal to length of upper band!")
    coordinates = @lift([$lowerpoints; $upperpoints])
    connectivity = lift(x -> band_connect(length(x)), plot[1])

    meshcolor = Observable{RGBColors}()

    map!(meshcolor, plot.color) do c
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
