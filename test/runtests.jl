using MakieCore

@time begin
    using MakieCore, GeometryBasics
    @time begin
        s = MakieCore.CairoScreen(500, 500)
        x = MakieCore.Scatter(rand(Point2f0, 10))
        MakieCore.draw_atomic(s, x)
    end
end
