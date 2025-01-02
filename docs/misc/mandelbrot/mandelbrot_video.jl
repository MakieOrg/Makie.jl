function mandelbrot(x, y)
    z = c = x + y * im
    for i in 1:100.0
        abs(z) > 2 && return i; z = z^2 + c
    end
    return 0
end

x = Observable(range(-2, 1, length = 400))
y = Observable(range(-1, 1, length = 300))

fig, ax, img = heatmap(
    x, y, mandelbrot, colormap = Reverse(:deep),
    figure = (size = (400, 300),)
)
hidedecorations!(ax)

record(fig, "mandelbrot.mp4", 1:200) do frame
    x.val = x[] .+ ((-0.562 .- x[]) .* 0.05)
    y[] = y[] .+ ((0.645 .- y[]) .* 0.05)
    autolimits!(ax)
end
