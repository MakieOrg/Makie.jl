using WGLMakie, AbstractPlotting, WebIO, JSCall
scene = scatter(rand(4))

function test(x)
    if ispressed(x, Mouse.left)
        @show pick(scene, scene.events.mouseposition[])
    end
end
on(test, scene.events.mousebuttons)
