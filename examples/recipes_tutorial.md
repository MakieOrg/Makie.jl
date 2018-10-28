1) Simple Transform
"""
Convert from one type to another plottable type in general
"""
convert_arguments(args...) -> converted args

example:

convert_arguments(x::Circle) = (decompose(Point2f, x),)

2) Transform + add Attributes


Example:
function transform_arguments(x::Vector{<: Complex}; kw_args...)
  (
    x = imag.(x),
    y = real.(y),
    axis = (labels = ("imaginary part", "real part"))
  )
end



3) Type Recipe

Works on specific type, gets invoked via `plot`

function plot!(empty_plot::Plot(MyType))
  plot!(empty_plot, ...) # fill it with plots
end

4) Named Recipe

Works for multiple types, needs own name for disambiguation.
Gets invoked via `name`

5) High level Recipe

can create multiple axes & subscenes etc
