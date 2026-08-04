@testset "pointer events carry their position" begin
    scene = Scene()
    comm = WGLMakie.Observable{Any}(nothing)
    WGLMakie.connect_scene_events!(WGLMakie.Screen(), scene, comm)

    observed = Tuple{Makie.MouseButtonEvent, Tuple{Float64, Float64}}[]
    on(events(scene).mousebutton) do event
        push!(observed, (event, events(scene).mouseposition[]))
    end

    comm[] = Dict("pointerdown" => [123.0, 456.0, 1])
    @test Bonito.wait_for(() -> length(observed) == 1; timeout = 2) == :success
    @test observed[1] == (Makie.MouseButtonEvent(Makie.Mouse.left, Makie.Mouse.press), (123.0, 456.0))

    comm[] = Dict("pointerup" => [321.0, 654.0, 0])
    @test Bonito.wait_for(() -> length(observed) == 2; timeout = 2) == :success
    @test observed[2] == (Makie.MouseButtonEvent(Makie.Mouse.left, Makie.Mouse.release), (321.0, 654.0))

    # Browser sessions created with a previous WGLMakie bundle may still emit
    # the legacy button-only messages until their page is reloaded.
    comm[] = Dict("mousedown" => 1)
    @test Bonito.wait_for(() -> length(observed) == 3; timeout = 2) == :success
    @test observed[3] == (Makie.MouseButtonEvent(Makie.Mouse.left, Makie.Mouse.press), (321.0, 654.0))

    comm[] = Dict("mouseup" => 0)
    @test Bonito.wait_for(() -> length(observed) == 4; timeout = 2) == :success
    @test observed[4] == (Makie.MouseButtonEvent(Makie.Mouse.left, Makie.Mouse.release), (321.0, 654.0))
end
