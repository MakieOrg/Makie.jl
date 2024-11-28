using ComputePipeline, Chairmarks
using Makie

using GLMakie
using CairoMakie
scatter(1:4, color=1:4)


@profview [Scatter((1:10,), Dict{Symbol,Any}()) for i in 1:10000]
@b Scatter((1:10,), Dict{Symbol,Any}())

@b scatter(1:4; color=1:4, colormap=:turbo, markersize=20, visible=true)

using GLMakie
using CairoMakie

scatter(1:4; color=1:4, colormap=:turbo, markersize=20, visible=true)


function test(x)
    s = 0.0
    for (k, i) in x
        s += i
    end
    return s
end
using Random
a = Dict(randstring(10) => rand() for i in 1:10000)
b = Dict(Symbol(k) => v for (k, v) in a)
a |> first
@b a["ha7SToDtH5"]
@b b[:ha7SToDtH5]

begin
    s = Scene()
    pl = linesegments!(s, -1:0.1:1, -1:0.1:1)
    scren = display(s)
end

robj = pl.gl_renderobject[]

lines( -1:0.1:1, -1:0.1:1)

begin
    s = Scene()
    pl = lines!(s, -1:0.1:1, -1:0.1:1)
    scren = display(s)
end
robj = scren.renderlist[end][3]
for (k, v) in robj.uniforms
    println(k, " => ", (to_value(v)))
end

f, ax, pl = lines(rand(10), rand(10); color=rand(10), linewidth=10);

pl.color[]
using Makie
@profview [scatter(1:4; color=1:4, colormap=:turbo, markersize=20, visible=true) for i in 1:100]
