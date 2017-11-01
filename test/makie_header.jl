using MakiE, GeometryTypes, Colors

scene = Scene(color = :black, resolution = (600, 100))
MakiE.add_mousebuttons(scene)
brush = to_node(Point2f0[])
markersize = to_node(Float32[])

waspressed_t_lastpos = Ref((false, time(), Point2f0(0)))
lift_node(scene, :mouseposition) do mp
    if ispressed(scene, MakiE.Mouse.left)
        waspressed, t, lastpos = waspressed_t_lastpos[]
        elapsed = time() - t
        r = elapsed * 30.0
        dir = normalize(lastpos .- mp)
        N = 10
        points = map(1:N) do i
            mp .+ (rand(Point2f0) .* r)
        end
        append!(brush, points)
        append!(markersize, map(x-> rand() .* 4.0 .+ 0.5, 1:N))
        if !waspressed
            waspressed_t_lastpos[] = (true, time(), mp)
        else
            waspressed_t_lastpos[] = (true, t, mp)
        end
    else
        waspressed_t_lastpos[] = (false, 0, Point2f0(0))
    end
    return
end

c = RGBA(0.95, 0.98, 0.99, 1.0)
aviz = axis(
    linspace(0, 600, 20), linspace(0, 100, 5),
    gridthickness = (0.5, 0.5, 0.5),
    gridcolors = (c, c, c)
)

bv = scatter(
    brush, markersize = markersize,
    color =  :white,
    glowwidth = 0.5,
    glowcolor = (:yellow, 0.8)
)

save("header.png", scene)
