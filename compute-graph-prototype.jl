using GLMakie

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
