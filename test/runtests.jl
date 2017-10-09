using MakiE, GeometryTypes

# write your own tests here
scene = Scene()

f(x,y) = x^2+y^2 < 1e-3 ? 0 : x*y/(x^2+y^2)
rad = 1
rv = linspace(0, rad, 5)
θv = linspace(0, 2π, 12)
xv = Float32[r*cos(θ) for r=rv, θ=θv]
yv = Float32[r*sin(θ) for r=rv, θ=θv]
zv = Float32[f(r*cos(θ),r*sin(θ)) for r = rv, θ = θv]


x = wireframe(xv, yv, zv)
scatter(vec(xv), vec(yv), vec(zv), markersize = 0.1)

mini, maxi = extrema(Point3f0.(xv, yv, zv))
ranges = Tuple(map(mini, maxi) do a, b
    linspace(a, b, 5)
end)
a = axis(MakiE.to_node(ranges))
