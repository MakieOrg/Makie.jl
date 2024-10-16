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

set_theme!(size=(800, 600))

create_time = @ctime fig = scatter(1:4; color=1:4, colormap=:turbo, markersize=20, visible=true)
display_time = @ctime colorbuffer(fig; px_per_unit=1)

using JSON
using Pkg

project_name = basename(dirname(Pkg.project().path))

result = "$(project_name)-benchmark.json"
old = isfile(result) ? JSON.parse(read(result, String)) : [[], [], [], [], []]
@show [t_using, create_time, display_time]
push!.(old[1:3], [t_using, create_time, display_time])

macro simple_time(expr)
    time_expr = quote
        t1 = time_ns()
        $expr
        t2 = time_ns()
        Float64(t2 - t1)
    end

    quote
        times = Float64[]
        for i in 1:101
            t = Core.eval(Main, $(QuoteNode(time_expr)))
            i > 1 && push!(times, t)
        end
        times
    end
end
@time "creating figure" figure_times = @simple_time fig = scatter(1:4; color=1:4, colormap=:turbo, markersize=20, visible=true)
fig = scatter(1:4; color=1:4, colormap=:turbo, markersize=20, visible=true)
@time "colorbuffer" colorbuffer_times = @simple_time colorbuffer(fig; px_per_unit=1)

using Statistics

append!(old[4], figure_times)
append!(old[5], colorbuffer_times)

open(io-> JSON.print(io, old), result, "w")

try
    rm("test.png")
catch e
end
