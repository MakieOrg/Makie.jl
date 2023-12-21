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

using BenchmarkTools
using BenchmarkTools.JSON
using Pkg

project_name = basename(dirname(Pkg.project().path))

result = "$(project_name)-benchmark.json"
old = isfile(result) ? JSON.parse(read(result, String)) : [[], [], [], [], []]
@show [t_using, create_time, display_time]
push!.(old[1:3], [t_using, create_time, display_time])

b1 = @benchmark fig = scatter(1:4; color=1:4, colormap=:turbo, markersize=20, visible=true)
b2 = @benchmark colorbuffer(fig; px_per_unit=1)

using Statistics

push!(old[4], mean(b1.times))
push!(old[5], mean(b2.times))

open(io-> JSON.print(io, old), result, "w")

try
    rm("test.png")
catch e
end
