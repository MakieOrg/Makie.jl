"""
Plot the history of a time-varying signal as a line plot.

The signal is tracked over time, displaying the most recent `history` points.
Updates automatically when the signal observable changes.

## Arguments

* `signal::Union{Number, Point2}` is the signal to track. Can be a scalar value (plotted against time) or a `Point2` (plotted directly as x-y coordinates).
"""
@recipe TimeSeries (signal,) begin
    "Number of tracked points."
    history = 100
    documented_attributes(Lines)...
end

signal2point(signal::Number, start) = Point2f(time() - start, signal)
signal2point(signal::Point2, start) = signal
signal2point(signal, start) = error(
    """ Signal needs to be of type Number or Point.
    Found: $(typeof(signal))
    """
)


function Makie.plot!(plot::TimeSeries)
    # normal plotting code, building on any previously defined recipes
    # or atomic plotting operations, and adding to the combined `plot`:
    points = Observable(fill(Point2f(NaN), plot.history[]))
    buffer = copy(points[])
    lines!(plot, Attributes(plot), points)
    start = time()
    on(plot, plot.signal) do x
        points[][end] = signal2point(x, start)
        circshift!(buffer, points[], 1)
        buff_ref = buffer
        buffer = points[]
        points[] = buff_ref
    end
    return plot
end
