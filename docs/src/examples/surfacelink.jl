#julia
using Makie
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
range = range(0, stop=3, length=N)
surf = surface(range, range, z, colormap = :Spectral)
wf = wireframe(range, range, surf[:z] .+ 1.0,
    linewidth = 2f0, color = lift_node(x-> x[5], surf[:colormap])
)
axis(range(0, stop=3, length=4), range(0, stop=3, length=4), range(0, stop=3, length=4))
center!(scene)

wf[:linewidth] = 1
surf[:colormap] = :YlGnBu
io = VideoStream(scene)
for i in range(0, stop=60, length=200)
    surf[:z] = surf_func(i)
    recordframe!(io)
end
io
