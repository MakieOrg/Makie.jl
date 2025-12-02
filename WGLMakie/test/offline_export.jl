using Bonito, WGLMakie, Makie

function handler(session, request)
    return scatter(1:4, color = 1:4)
end

dir = joinpath(@__DIR__, "exported")
isdir(dir) || mkdir(dir)
Bonito.export_standalone(handler, dir)
# Then serve it with e.g. LiveServer
using LiveServer

LiveServer.serve(dir = dir)
