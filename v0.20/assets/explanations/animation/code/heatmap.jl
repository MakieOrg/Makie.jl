# This file was generated, do not modify it. # hide
using GLMakie
GLMakie.activate!() # hide

function mandelbrot(x, y)
    z = c = x + y*im
    for i in 1:30.0; abs(z) > 2 && return i; z = z^2 + c; end; 0
end

x = LinRange(-2, 1, 200)
y = LinRange(-1.1, 1.1, 200)
matrix = mandelbrot.(x, y')
fig, ax, hm = heatmap(x, y, matrix)

N = 50
xmin = LinRange(-2.0, -0.72, N)
xmax = LinRange(1, -0.6, N)
ymin = LinRange(-1.1, -0.51, N)
ymax = LinRange(1, -0.42, N)

# we use `record` to show the resulting video in the docs.
# If one doesn't need to record a video, a normal loop works as well.
# Just don't forget to call `display(fig)` before the loop
# and without record, one needs to insert a yield to yield to the render task
record(fig, "heatmap_mandelbrot.mp4", 1:7:N) do i
    _x = LinRange(xmin[i], xmax[i], 200)
    _y = LinRange(ymin[i], ymax[i], 200)
    hm[1] = _x # update x coordinates
    hm[2] = _y # update y coordinates
    hm[3] = mandelbrot.(_x, _y') # update data
    autolimits!(ax) # update limits
    # yield() -> not required with record
end