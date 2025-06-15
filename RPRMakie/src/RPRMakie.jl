module RPRMakie

using Makie
using RadeonProRender
using GeometryBasics
using Colors
using FileIO
using Makie: colorbuffer

const RPR = RadeonProRender

"""
* `iterations = 200`: Iterations of light simulations. The more iterations, the less noisy the picture becomes, but higher numbers take much longer. For e.g. `iterations=10` one should expect rendering to take a couple of seconds but it will produce pretty noisy output. 200 is a good middle ground taking around ~30s on an old nvidia 1060. For highest quality output, numbers above 500 are required.
* `resource = RPR.RPR_CREATION_FLAGS_ENABLE_GPU0`: GPU or CPU to use. Multiple GPUs and CPUs can be used together by using `&` (e.g. `RPR.RPR_CREATION_FLAGS_ENABLE_GPU0 & RPR.RPR_CREATION_FLAGS_ENABLE_CPU`).
* `plugin = RPR.Tahoe`:
    * `RPR.Tahoe`, the legacy RadeonProRender backend. It's the most stable, but doesn't have all new features (e.g. the `RPR.MatX` material), and may be slower than others
    * `RPR.Northstar`, the new rewritten backend, faster and optimized for many iterations. Single iterations are much slower, so less usable for interactive display. Sometimes, Northstar just produces black, jiggly objects. It's not clear yet, if that's just a bug, or the result of using an unsupported/deprecated feature. Switch to `Tahoe` if that happens.
    * `RPR.Hybrid`: Vulkan backend, fit for real time rendering, using AMDs and NVIDIAs new hardware accelerated ray tracing. Doesn't work reliably yet and only works with `RPR.Uber` material.
    * `RPR.HybridPro`: The same as Hybrid, but works only for Radeon GPUs, using AMDs own hardware acceleration API.
"""
struct ScreenConfig
    iterations::Int
    max_recursion::Int
    resource::Int32
    plugin::RPR.PluginType
end

function ScreenConfig(iterations::Int, max_recursion::Int, render_resource, render_plugin)
    return ScreenConfig(
        iterations,
        max_recursion,
        Int32(render_resource isa Makie.Automatic ? RPR.RPR_CREATION_FLAGS_ENABLE_GPU0 : render_resource),
        render_plugin isa Makie.Automatic ? RPR.Northstar : render_plugin
    )
end


include("scene.jl")
include("lines.jl")
include("meshes.jl")
include("volume.jl")

Makie.apply_screen_config!(screen::RPRMakie.Screen, ::RPRMakie.ScreenConfig, args...) = screen
Base.empty!(::RPRMakie.Screen) = nothing

"""
    RPRMakie.activate!(; screen_config...)


Sets RPRMakie as the currently active backend and also allows to quickly set the `screen_config`.
Note, that the `screen_config` can also be set permanently via `Makie.set_theme!(RPRMakie=(screen_config...,))`.

# Arguments one can pass via `screen_config`:

$(Base.doc(ScreenConfig))
"""
function activate!(; screen_config...)
    Makie.set_screen_config!(RPRMakie, screen_config)
    Makie.set_active_backend!(RPRMakie)
    return
end

function __init__()
    activate!()
    return
end

for name in names(Makie; all = true)
    if Base.isexported(Makie, name)
        @eval using Makie: $(name)
        @eval export $(name)
    end
end

export RPR, colorbuffer

end
