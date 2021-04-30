using SnoopCompile

SnoopCompile.@snoopc ["--project=$(pwd())"] "compiles.log" begin
    using MakieCore
    s = MakieCore.CairoScreen(500, 500)
    x = MakieCore.Scatter(rand(MakieCore.Point2f, 10))
    MakieCore.draw_atomic(s, x)
end
data = SnoopCompile.read("compiles.log")
pc = SnoopCompile.format_userimg(reverse!(data[2]))
SnoopCompile.write(joinpath(@__DIR__, "..", "src", "precompile.jl"), pc)

@time begin
    using MakieCore
    using MakieCore: Point2f
    @time begin
        s = MakieCore.CairoScreen(500, 500)
        x = MakieCore.Scatter(rand(Point2f, 10))
        MakieCore.draw_atomic(s, x)
    end
end

tinf = SnoopCompile.@snoopi_deep begin
    s = MakieCore.Scene(500, 500)
    scat = MakieCore.Scatter(randn(MakieCore.Point2f, 20) ./ 2; strokecolor = :red)
    push!(s, scat)
    MakieCore.colorbuffer(s)
end

# SnoopCompile.write(joinpath(@__DIR__, "..", "src", "precompile.jl"), pc)
fg = flamegraph(tinf)
ProfileView.view(fg)


@time begin
    using MakieCore
    @time begin
        s = MakieCore.Scene(500, 500)
        scat = MakieCore.Scatter(randn(MakieCore.Point2f, 20) ./ 2; strokecolor = :red)
        push!(s, scat)
        MakieCore.colorbuffer(s)
        nothing
    end
end
