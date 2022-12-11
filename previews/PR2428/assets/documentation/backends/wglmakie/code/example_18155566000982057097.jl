# This file was generated, do not modify it. # hide
__result = begin # hide
    using WGLMakie
using JSServe, Markdown
Page(exportable=true, offline=true)
WGLMakie.activate!()
scatter(1:4, color=1:4)
end # hide
println("~~~") # hide
show(stdout, MIME"text/html"(), __result) # hide
println("~~~") # hide
nothing # hide