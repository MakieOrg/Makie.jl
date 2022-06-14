Package = Symbol(ARGS[1])
macro ctime(x)
    return quote
        tstart = time_ns()
        $(esc(x))
        Float64(time_ns() - tstart)
    end
end
t_using = @ctime @eval using $Package
Makie.inline!(false) # needed for cairomakie to return a screen


if Package == :WGLMakie
    using ElectronDisplay
    ElectronDisplay.CONFIG.showable = showable
    ElectronDisplay.CONFIG.single_window = true
    ElectronDisplay.CONFIG.focus = false
end

create_time = @ctime fig = scatter(1:4; color=1:4, colormap=:turbo, markersize=20, visible=true)
display_time = @ctime Makie.colorbuffer(display(fig))

using BenchmarkTools
using BenchmarkTools.JSON
using Pkg

project_name = basename(dirname(Pkg.project().path))

result = "$(project_name)-benchmark.json"
old = isfile(result) ? JSON.parse(read(result, String)) : [[], [], [], [], []]
@show [t_using, create_time, display_time]
push!.(old[1:3], [t_using, create_time, display_time])

b1 = @benchmark fig = scatter(1:4; color=1:4, colormap=:turbo, markersize=20, visible=true)
b2 = @benchmark Makie.colorbuffer(display(fig))
append!(old[4], b1.times)
append!(old[5], b2.times)

open(io-> JSON.print(io, old), result, "w")

try
    rm("test.png")
catch e
end
