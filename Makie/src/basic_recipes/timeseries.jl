"""
    timeseries(x::Observable{{Union{Number, Point2}}})

Plots a sampled signal.

Usage:
```julia
signal = Observable(1.0)
scene = timeseries(signal)
display(scene)
# @async is optional, but helps to continue evaluating more code
@async while !Makie.isclosed(scene)
    # acquire data from e.g. a sensor:
    data = rand()
    # update the signal
    signal[] = data
    # sleep/ wait for new data/ whatever...
    # It's important to yield here though, otherwise nothing will be rendered
    sleep(1/30)
end

```
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
