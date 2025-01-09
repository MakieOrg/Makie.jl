# TODO: test more
# Note: zoom_pan.jl includes more tests for this
@testset "Axis Interactions" begin
    f = Figure(size = (400, 400))
    a = Axis(f[1, 1])
    e = events(f)

    names = (:rectanglezoom, :dragpan, :limitreset, :scrollzoom)
    @test keys(a.interactions) == Set(names)

    types = (Makie.RectangleZoom, Makie.DragPan, Makie.LimitReset, Makie.ScrollZoom)
    for (name, type) in zip(names, types)
        @test a.interactions[name][1] == true
        @test a.interactions[name][2] isa type
    end

    blocked = Observable(true)
    on(x -> blocked[] = false, e.scroll, priority = typemin(Int))

    @assert !is_mouseinside(a.scene)
    e.scroll[] = (0.0, 0.0)
    @test !blocked[]
    blocked[] = true
    e.scroll[] = (0.0, 1.0)
    @test !blocked[]

    blocked[] = true
    e.mouseposition[] = (200, 200)
    e.scroll[] = (0.0, 0.0)
    @test blocked[] # TODO: should it block?
    blocked[] = true
    e.scroll[] = (0.0, 1.0)
    @test blocked[]

    deactivate_interaction!.((a,), names)

    blocked[] = true
    e.scroll[] = (0.0, 0.0)
    @test !blocked[]
    blocked[] = true
    e.scroll[] = (0.0, 1.0)
    @test !blocked[]
end