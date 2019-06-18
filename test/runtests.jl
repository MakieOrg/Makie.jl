using WGLMakie, AbstractPlotting, WebIO, JSCall
scene = contour(rand(Float32, 4, 4, 4)) |> display
jsm = WGLMakie.three_scene(scene)
jsm.RedFormat |> JSCall.jlvalue
open(joinpath(@__DIR__, "index.html"), "w") do io
    show(io, WebIO.WEBIO_APPLICATION_MIME(), WGLMakie.three_scene(scene))
end
typeof(x)
mini = (0, 1)
maxi = (1, 2)

jscam = jsm.THREE.new.OrthographicCamera(
    mini[1], maxi[1], maxi[2], mini[2], -10_000, 10_000
)
AbstractPlotting.to_align((:left, :bottom))
