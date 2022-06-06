Package = Symbol(ARGS[1])
t_using = (tstart = time(); @eval using $Package; time() - tstart)
if Package == :WGLMakie
    using ElectronDisplay
    ElectronDisplay.CONFIG.showable = showable
    ElectronDisplay.CONFIG.single_window = true
    ElectronDisplay.CONFIG.focus = false
end
function test()
    Makie.inline!(false) # needed for cairomakie to return a screen
    screen = display(scatter(1:4; color=1:4, colormap=:turbo, markersize=20, visible=true))
    Makie.colorbuffer(screen)
end
t_plot = (tstart = time(); test(); time() - tstart)
using BenchmarkTools
using BenchmarkTools.JSON
using Pkg

project_name = basename(dirname(Pkg.project().path))

result = "$(project_name)-ttfp-result.json"
old = isfile(result) ? JSON.parse(read(result, String)) : []
push!(old, [t_using, t_plot])
open(io-> JSON.print(io, old), result, "w")

runtime_file = "$(project_name)-runtime-result.json"
# Only benchmark one time!
if !isfile(runtime_file)
    println("Benchmarking runtime")
    b = @benchmark test()
    BenchmarkTools.save(runtime_file, b)
end

try
    rm("test.png")
catch e
end
