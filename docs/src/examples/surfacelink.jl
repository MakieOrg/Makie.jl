#julia
using MakiE
scene = Scene()
N = 32
function xy_data(x,y,i, N)
    x = ((x/N)-0.5f0)*i
    y = ((y/N)-0.5f0)*i
    r = sqrt(x*x + y*y)
    res = Float32(sin(r)/r)
    isnan(res) ? 1f0 : res
end

surf_func(i) = [Float32(xy_data(x, y, i, 32)) + 0.5 for x=1:32, y=1:32]

z = surf_func(20)
range = linspace(0, 3, N)
surf = surface(range, range, z, colormap = :Spectral)
wf = wireframe(range, range, surf[:z] .+ 1.0,
    linewidth = 2f0, color = lift_node(x-> x[5], surf[:colormap])
)
axis(linspace(0, 3, 4), linspace(0, 3, 4), linspace(0, 3, 4))
center!(scene)

wf[:linewidth] = 1
surf[:colormap] = :YlGnBu
io = VideoStream(scene)
for i in linspace(0, 60, 200)
    surf[:z] = surf_func(i)
    recordframe!(io)
end
io
