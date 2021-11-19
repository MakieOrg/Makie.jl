module RPRMakie

using Makie
using RadeonProRender
using GeometryBasics
using Colors
using FileIO

const RPR = RadeonProRender
const NUM_ITERATIONS = Ref(200)

include("scene.jl")
include("lines.jl")
include("meshes.jl")
include("volume.jl")

function activate!(; iterations=200)
    NUM_ITERATIONS[] = iterations
    b = RPRBackend()
    Makie.register_backend!(b)
    Makie.current_backend[] = b
    Makie.inline!(true)
end

function __init__()
    activate!()
end

for name in names(Makie, all=true)
    if Base.isexported(Makie, name)
        @eval using Makie: $(name)
        @eval export $(name)
    end
end

end
