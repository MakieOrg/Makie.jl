module RPRMakie

using Makie
using RadeonProRender
using GeometryBasics
using Colors
using FileIO

const RPR = RadeonProRender
using Makie: colorbuffer

const NUM_ITERATIONS = Ref(200)
const RENDER_RESOURCE = Ref(RPR.RPR_CREATION_FLAGS_ENABLE_GPU0)
const RENDER_PLUGIN = Ref(RPR.Tahoe)

include("scene.jl")
include("lines.jl")
include("meshes.jl")
include("volume.jl")

"""
    RPRMakie.activate!(;
        iterations=200,
        resource=RPR.RPR_CREATION_FLAGS_ENABLE_GPU0,
        plugin=RPR.Tahoe)

- iterations: Iterations of light simulations. The more iterations, the less noisy the picture becomes, but higher numbers take much longer. For e.g. `iterations=10` one should expect rendering to take a couple of seconds but it will produce pretty noisy output. 200 is a good middle ground taking around ~30s on an old nvidia 1060. For highest quality output, numbers above 500 are required.
- resource: GPU or CPU to use. Multiple GPUs and CPUs can be used together by using `&` (e.g. `RPR.RPR_CREATION_FLAGS_ENABLE_GPU0 & RPR.RPR_CREATION_FLAGS_ENABLE_CPU`)
- plugin:
    * `RPR.Tahoe`, the legacy RadeonProRender backend. It's the most stable, but doesn't have all new features (e.g. the `RPR.MatX` material), and may be slower than others
    * `RPR.Northstar`, the new rewritten backend, faster and optimized for many iterations. Single iterations are much slower, so less usable for interactive display. Sometimes, Northstar just produces black, jiggly objects. It's not clear yet, if that's just a bug, or the result of using an unsupported/deprecated feature. Switch to `Tahoe` if that happens.
    * `RPR.Hybrid`: Vulkan backend, fit for real time rendering, using AMDs and NVIDIAs new hardware accelerated ray tracing. Doesn't work reliably yet and only works with `RPR.Uber` material.
    * `RPR.HybridPro`: The same as Hybrid, but works only for Radeon GPUs, using AMDs own hardware acceleration API.

"""
function activate!(; iterations=200, resource=RENDER_RESOURCE[], plugin=RENDER_PLUGIN[])
    NUM_ITERATIONS[] = iterations
    RENDER_RESOURCE[] = resource
    RENDER_PLUGIN[] = plugin
    b = RPRBackend()
    Makie.register_backend!(b)
    Makie.current_backend[] = b
    Makie.inline!(true)
    return
end

function __init__()
    activate!()
    return
end

for name in names(Makie; all=true)
    if Base.isexported(Makie, name)
        @eval using Makie: $(name)
        @eval export $(name)
    end
end

export RPRScreen, RPR, colorbuffer

end
