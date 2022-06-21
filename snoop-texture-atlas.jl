using SnoopCompileCore, Makie
tinf = @snoopi_deep begin
    Makie.get_texture_atlas()
end
using SnoopCompile, ProfileView; ProfileView.view(flamegraph(tinf))
