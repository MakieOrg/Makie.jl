module RasterPickingTests
using Test, RayMakie, Mantle
using Makie

@testset "raster picking uses the completed visible frame" begin
    for fxaa in (false,true), ppu in (1.0,0.5,2.0)
        scene=Scene(;size=(128,128),camera=campixel!,backgroundcolor=:black)
        front=mesh!(scene,Rect2f(25,25,40,40);color=:red,shading=NoShading)
        translate!(front,0,0,5)
        back=mesh!(scene,Rect2f(10,10,85,85);color=:blue,shading=NoShading)
        dots=scatter!(scene,[Point2f(105,35),Point2f(105,75)];markersize=12,color=:green)
        line=lines!(scene,[Point2f(20,110),Point2f(70,110)];color=:white,linewidth=4)
        transparent=mesh!(scene,Rect2f(30,30,20,20);color=RGBAf(1,0,0,0),shading=NoShading)
        translate!(transparent,0,0,10)
        screen=RayMakie.Screen(scene;device=Mantle.defaultbackend(),visible=false,
            rasterize=true,shadows=false,fxaa,px_per_unit=ppu)
        try
            colorbuffer(screen;px_per_unit=ppu)
            frame=screen.fb_readback_buf.frame
            @test frame.size==round.(Int,(128,128).*ppu)
            @test pick(scene,screen,Vec2d(40,40))[1]===front
            @test pick(scene,screen,Vec2d(15,15))[1]===back
            @test pick(scene,screen,Vec2d(105,35))==(dots,1)
            @test pick(scene,screen,Vec2d(105,75))==(dots,2)
            @test pick(scene,screen,Vec2d(40,110))[1]===line
            @test pick(scene,screen,Vec2d(2,2))==(nothing,0)
            @test pick(scene,screen,Vec2d(-1,0))==(nothing,0)
            @test pick(scene,screen,Vec2d(128,128))==(nothing,0)
            @test pick(scene,screen,Vec2d(NaN,40))==(nothing,0)
            results=pick(scene,screen,Rect2i(34,34,6,6))
            @test all(result->result[1]===front,results)
            @test size(results)==round.(Int,(6,6).*ppu)
            @test Makie.pick_closest(scene,screen,Vec2d(105,35),4)==(dots,1)
            @test first(Makie.pick_sorted(scene,screen,Vec2d(105,35),4))==(dots,1)
            @test_throws ArgumentError pick(scene,screen,Rect2i(125,125,10,10))
            # Picking reads the displayed snapshot, even if a plot changes before
            # its next frame. It neither polls geometry nor triggers a render.
            front.visible[]=false
            @test pick(scene,screen,Vec2d(40,40))[1]===front
            @test screen.fb_readback_buf.frame===frame
            colorbuffer(screen;px_per_unit=ppu)
            @test pick(scene,screen,Vec2d(40,40))[1]===back
            @test !haskey(screen.frame_plans,:editorview)
        finally
            close(screen)
        end
        @test RayMakie.raster_pick_data(screen)===nothing
    end
end
end
