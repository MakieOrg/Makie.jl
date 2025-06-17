Package = Symbol(ARGS[1])
macro ctime(x)
    return quote
        tstart = time_ns()
        $(esc(x))
        Float64(time_ns() - tstart)
    end
end
t_using = @ctime @eval using $Package

if Package === :WGLMakie
    import Electron
    # Backwards compatibility for master
    Bonito = isdefined(WGLMakie, :Bonito) ? WGLMakie.Bonito : WGLMakie.JSServe
    Bonito.use_electron_display()
end

set_theme!(size = (800, 600))

GC.gc()
create_time = @ctime fig = scatter(1:4; color = 1:4, colormap = :turbo, markersize = 20, visible = true)
GC.gc()
display_time = @ctime colorbuffer(fig; px_per_unit = 1)

using JSON
using Pkg
using Statistics: median

project_name = basename(dirname(Pkg.project().path))

result = "$(project_name)-benchmark.json"
old = isfile(result) ? JSON.parse(read(result, String)) : [[], [], [], [], []]
@show [t_using, create_time, display_time]
push!.(old[1:3], [t_using, create_time, display_time])

macro simple_median_time(expr)
    time_expr = quote
        local elapsedtime = time_ns()
        $expr
        elapsedtime = time_ns() - elapsedtime
        Float64(elapsedtime)
    end

    return quote
        times = Float64[]
        for i in 1:101
            t = Core.eval(Main, $(QuoteNode(time_expr)))
            if i > 1
                push!(times, t)
            end
        end
        median(times)
    end
end
@time "creating figure" figure_time = @simple_median_time fig = scatter(1:4; color = 1:4, colormap = :turbo, markersize = 20, visible = true)
fig = scatter(1:4; color = 1:4, colormap = :turbo, markersize = 20, visible = true)
@time "colorbuffer" colorbuffer_time = @simple_median_time colorbuffer(fig; px_per_unit = 1)

using Statistics

push!(old[4], figure_time)
push!(old[5], colorbuffer_time)

open(io -> JSON.print(io, old), result, "w")

try
    rm("test.png")
catch e
end
