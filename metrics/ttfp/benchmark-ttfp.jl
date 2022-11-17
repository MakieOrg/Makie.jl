Package = Symbol(ARGS[1])
macro ctime(x)
    return quote
        tstart = time_ns()
        $(esc(x))
        Float64(time_ns() - tstart)
    end
end
t_using = @ctime @eval using $Package

function get_colorbuffer(fig)
    # We need to handle old versions of Makie
    if isdefined(Makie, :CURRENT_BACKEND) # new version after display refactor
        return Makie.colorbuffer(fig) # easy :)
    else
        Makie.inline!(false)
        screen = display(fig; visible=false)
        return Makie.colorbuffer(screen)
    end
end

if Package == :WGLMakie
    using ElectronDisplay
    using WGLMakie.JSServe
    JSServe.configure_server!(listen_port=rand(8000:9000))
    ElectronDisplay.CONFIG.showable = showable
    ElectronDisplay.CONFIG.single_window = true
    ElectronDisplay.CONFIG.focus = false
end

create_time = @ctime fig = scatter(1:4; color=1:4, colormap=:turbo, markersize=20, visible=true)
display_time = @ctime get_colorbuffer(fig)

using BenchmarkTools
using BenchmarkTools.JSON
using Pkg

project_name = basename(dirname(Pkg.project().path))

result = "$(project_name)-benchmark.json"
old = isfile(result) ? JSON.parse(read(result, String)) : [[], [], [], [], []]
@show [t_using, create_time, display_time]
push!.(old[1:3], [t_using, create_time, display_time])

b1 = @benchmark fig = scatter(1:4; color=1:4, colormap=:turbo, markersize=20, visible=true)

b2 = @benchmark get_colorbuffer(fig)

using Statistics

push!(old[4], mean(b1.times))
push!(old[5], mean(b2.times))

open(io-> JSON.print(io, old), result, "w")

try
    rm("test.png")
catch e
end
