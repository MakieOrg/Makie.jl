"""
clip!(scene, points::Vector{<: Point2})

This function will create a clipping region in the Screen pertaining to the Scene `scene`.
The path must be given as a Vector of Point2.

It is useful to think of the path as a parametrized function; all objects outside the path
will be clipped from the plot.

!!! warning
    Currently, `clip` is only implemented for the `CairoMakie` backend!
"""
@recipe(Clip) do scene
    Attributes(
        space = :data,
    )
end

Makie.conversion_trait(::Type{Clip}) = Makie.PointBased()

function Makie.plot!(plot::Clip)
    # This is a fallback implementation; each backend should override this
    # like CairoMakie does!
    lines!(plot, plot[1]; visible = true, linewidth = 5, color = :red, inspectable = false, xautolimit = false, yautolimit = false)
end
