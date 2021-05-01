# Profiling inference
using SnoopCompile, MakieCore, ProfileView

tinf = SnoopCompile.@snoopi_deep begin
    s = MakieCore.Scene(500, 500)
    scat = MakieCore.Scatter(randn(MakieCore.Point2f, 20)./2; strokecolor=:red)
    push!(s, scat)
    MakieCore.colorbuffer(s)
end

fg = flamegraph(tinf)
ProfileView.view(fg)
staleinstances(tinf) # still need to dive into this!
flat = flatten(tinf) # flat[end-10:end-1] to get top 10 offenders


# Generating precompiles
using MakieCore, SnoopCompile
SnoopCompile.@snoopc ["--project=$(pwd())"] "compiles.log" begin
    using MakieCore
    s = MakieCore.Scene(500, 500)
    scat = MakieCore.Scatter(randn(MakieCore.Point2f, 20)./2; strokecolor=:red)
    push!(s, scat)
    MakieCore.colorbuffer(s)
    nothing
end
data = SnoopCompile.read("compiles.log")
pc = SnoopCompile.format_userimg(reverse!(data[2]))
SnoopCompile.write(joinpath(@__DIR__, "..", "src", "precompile.jl"), pc)


# Measuring ttfp
@time begin
    using MakieCore
    @time begin
        s = MakieCore.Scene(500, 500)
        scat = MakieCore.Scatter(randn(MakieCore.Point2f, 20)./2; strokecolor=:red)
        push!(s, scat)
        MakieCore.colorbuffer(s)
        nothing
    end
end
