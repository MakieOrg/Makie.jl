@testset "clipped plots defer uploads and resume with current data" begin
    root = Scene(size=(120,120), camera=campixel!, backgroundcolor=:black)
    container = Scene(root; visible=true, viewport=Observable(Rect2i(0,0,120,120)))
    area = Observable(Rect2i(160,20,80,80))
    child = Scene(container; visible=true, viewport=area, camera=campixel!)
    plot = scatter!(child, [Point2f(40,40)]; color=:red, markersize=40, strokewidth=0)
    screen = display(GLMakie.Screen(visible=false, start_renderloop=false), root)
    try
        node = plot.attributes[:gl_renderobject]
        calls = Ref(0)
        object = node[]
        for (name, instruction) in object.variants
            object.variants[name] = GLMakie.GLAbstraction.RenderInstructions(
                instruction.vertexarray, instruction.program,
                () -> (calls[] += 1; instruction.prerender()), instruction.postrender)
        end
        plot.color = :green
        image = copy(colorbuffer(screen))
        @test calls[] == 0
        @test Makie.ComputePipeline.isdirty(node)
        @test maximum(c -> maximum((c.r,c.g,c.b)), image) < 0.05
        area[] = Rect2i(20,20,80,80)
        image = copy(colorbuffer(screen))
        @test calls[] > 0
        centre = CartesianIndex(size(image) .÷ 2) # also covers HiDPI screens
        @test !Makie.ComputePipeline.isdirty(node)
        @test image[centre].g > 0.4 && image[centre].r < 0.05
        container.visible[] = false
        calls[] = 0
        plot.color = :blue
        image = copy(colorbuffer(screen))
        @test calls[] == 0
        @test child.visible[]
        @test Makie.ComputePipeline.isdirty(node)
        @test maximum(c -> maximum((c.r,c.g,c.b)), image) < 0.05
        container.visible[] = true
        image = copy(colorbuffer(screen))
        @test !Makie.ComputePipeline.isdirty(node)
        @test image[centre].b > 0.9 && image[centre].g < 0.05
    finally
        close(screen)
        Makie.free(root)
    end
end

@testset "depth sorting follows changed plot transforms and scene deletion" begin
    root = Scene(size=(120,120), camera=campixel!, backgroundcolor=:black)
    child = Scene(root; viewport=Observable(Rect2i(0,0,120,120)), camera=campixel!)
    red = poly!(root, Rect2f(20,20,80,80); color=:red, overdraw=true, fxaa=false)
    blue = poly!(child, Rect2f(20,20,80,80); color=:blue, overdraw=true, fxaa=false)
    translate!(red, 0, 0, 1.1)
    translate!(blue, 0, 0, 1.2)
    screen = display(GLMakie.Screen(visible=false, start_renderloop=false), root)
    try
        image = copy(colorbuffer(screen))
        centre = CartesianIndex(size(image) .÷ 2)
        @test image[centre].b > .9 && image[centre].r < .05
        translate!(red, 0, 0, 1.3)
        image = copy(colorbuffer(screen))
        @test image[centre].r > .9 && image[centre].b < .05
        delete!(child, blue)
        delete!(screen, child)
        image = copy(colorbuffer(screen))
        @test image[centre].r > .9 && image[centre].b < .05
    finally
        close(screen)
        Makie.free(root)
    end
end
