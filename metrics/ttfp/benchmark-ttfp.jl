Package = Symbol(ARGS[1])
macro ctime(x)
    return quote
        tstart = time_ns()
        $(esc(x))
        Float64(time_ns() - tstart)
    end
end
t_using = @ctime @eval using $Package

set_theme!(size=(800, 600))

create_time = @ctime fig = scatter(1:4; color=1:4, colormap=:turbo, markersize=20, visible=true)
display_time = @ctime colorbuffer(fig; px_per_unit=1)

using JSON
using Pkg
using Statistics: median

project_name = basename(dirname(Pkg.project().path))

result = "$(project_name)-benchmark.json"
old = isfile(result) ? JSON.parse(read(result, String)) : [[], [], [], [], []]
@show [t_using, create_time, display_time]
push!.(old[1:3], [t_using, create_time, display_time])

function simple_median_time(f, n=100)
    function time_f()
        local elapsedtime = time_ns()
        f()
        elapsedtime = time_ns() - elapsedtime
        return Float64(elapsedtime)
    end
    times = Float64[]
    for i in 1:n
        t = time_f()
        push!(times, t)
    end
    return median(times)
end

test_figure(n) = simple_median_time(n) do
    return scatter(1:4; color=1:4, colormap=:turbo, markersize=20, visible=true)
end

function test_colorbuffer(n)
    fig = scatter(1:4; color=1:4, colormap=:turbo, markersize=20, visible=true)
    return simple_median_time(n) do
        return colorbuffer(fig; px_per_unit=1)
    end
end

@time "first run figure" test_figure(1)
@time "creating figure" figure_time = test_figure(100)

@time "first run colorbuffer" test_colorbuffer(2)
@time "first run colorbuffer" test_colorbuffer(2) # second call will compile additional functions like `delete!(screen)`
@time "colorbuffer" colorbuffer_time = test_colorbuffer(100)

using Statistics

push!(old[4], figure_time)
push!(old[5], colorbuffer_time)

open(io-> JSON.print(io, old), result, "w")

try
    rm("test.png")
catch e
end
