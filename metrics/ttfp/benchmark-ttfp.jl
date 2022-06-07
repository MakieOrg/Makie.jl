Package = Symbol(ARGS[1])
Package = :CairoMakie
macro ctime(x)
    return quote
        tstart = time_ns()
        $(esc(x))
        (time_ns() - tstart) / 1e9
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

result = "$(project_name)-ttfp-result.json"
old = isfile(result) ? JSON.parse(read(result, String)) : [[], [], []]
@show [t_using, create_time, display_time]
push!.(old, [t_using, create_time, display_time])
open(io-> JSON.print(io, old), result, "w")

runtime_file = "$(project_name)-runtime-result.json"
# Only benchmark one time!

function runtime_bench()
    fig = scatter(1:4; color=1:4, colormap=:turbo, markersize=20, visible=true)
    Makie.colorbuffer(display(fig))
end

if !isfile(runtime_file)
    println("Benchmarking runtime")
    b1 = @benchmark fig = scatter(1:4; color=1:4, colormap=:turbo, markersize=20, visible=true)
    b2 = @benchmark Makie.colorbuffer(display(fig))
    BenchmarkTools.save(runtime_file, b1, b2)
end

try
    rm("test.png")
catch e
end
