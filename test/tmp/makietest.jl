using Makie

Base.@ccallable function julia_main(ARGS::Vector{String})::Cint
    scene = Scene()
    scatter(scene, rand(50), rand(50), markersize = 0.01)
    a = axis(scene, linspace(0, 1, 4), linspace(0, 1, 4), textsize = 0.1, axisnames = ("", "", ""))
    tf = to_value(a, :tickfont2d)
    a[:tickfont2d] = map(x-> (0.07, x[2:end]...), tf)
    center!(scene)
    Makie.block(scene)
    return 0
end
