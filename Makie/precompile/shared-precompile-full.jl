# Extended precompile workload, included in addition to shared-precompile.jl
# when the Makie preference `precompile_workload_level = "full"` is set.
# Covers the long tail of common recipes at the cost of longer package
# precompilation. Everything here must run headless (no backend window).

@compile hist(randn(100))

@compile density(randn(100))

@compile band(1:10, fill(0.0, 10), rand(10))

@compile boxplot(fill(1, 50), rand(50))

@compile errorbars(1:10, rand(10), rand(10) .* 0.1)

@compile rangebars(1:10, rand(10), rand(10) .+ 1)

@compile stairs(rand(10))

@compile stem(rand(10))

@compile begin
    f, a, p = lines(rand(10))
    vlines!(a, [0.5])
    hlines!(a, [0.5])
    ablines!(a, 0.0, 1.0)
    f
end

@compile pie(rand(4))

@compile series(rand(3, 10))

@compile arrows2d(rand(Point2f, 10), rand(Vec2f, 10))

@compile tricontourf(rand(20), rand(20), rand(20))

@compile contourf(rand(20, 20))

@compile waterfall(rand(10))

@compile crossbar(fill(1, 10), rand(10), rand(10) .- 1, rand(10) .+ 1)

@compile bracket(1.0, 1.0, 2.0, 2.0)

@compile streamplot((x, y) -> Point2f(y, -x), -1 .. 1, -1 .. 1)

@compile begin
    f, a, p = heatmap(rand(10, 10))
    Colorbar(f[1, 2], p)
    f
end
