"""
Plot the recent history of a time-varying signal as a line plot. Updates
automatically when the signal changes.

## Arguments

* `signal::Union{Real, Point2}` is the signal to track. Can be a scalar value (plotted against
    time) or a `Point2` (plotted directly as x-y coordinates).
"""
@recipe TimeSeries (signal::Real,) begin
    "Number of tracked points."
    history = 100
    documented_attributes(Lines)...
end

argument_dims(::Type{<:TimeSeries}, signal) = (2,)

signal2point(signal::Number, start) = Point2f(time() - start, signal)
signal2point(signal::Point2, start) = signal
signal2point(signal, start) = error(
    """ Signal needs to be of type Number or Point.
    Found: $(typeof(signal))
    """
)

function plot!(plot::TimeSeries)
    # normal plotting code, building on any previously defined recipes
    # or atomic plotting operations, and adding to the combined `plot`:
    points = Observable(fill(Point2f(NaN), plot.history[]))
    buffer_ref = Ref(copy(points[]))
    lines!(plot, Attributes(plot), points)
    start = time()
    on(plot, plot.signal) do x
        current_visible = points[]
        current_buffer = buffer_ref[]
        current_visible[end] = signal2point(x, start)
        circshift!(current_buffer, current_visible, 1)
        points[] = current_buffer
        buffer_ref[] = current_visible
    end
    return plot
end
