# This file was generated, do not modify it. # hide
__result = begin # hide
    using WGLMakie
WGLMakie.activate!()
# Set the default resolution to something that fits the Documenter theme
set_theme!(resolution=(800, 400))
scatter(1:4, color=1:4)
end # hide
println("~~~") # hide
show(stdout, MIME"text/html"(), __result) # hide
println("~~~") # hide
nothing # hide