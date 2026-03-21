# This file was generated, do not modify it. # hide
__result = begin # hide
    N = 60
function xy_data(x, y)
    r = sqrt(x^2 + y^2)
    r == 0.0 ? 1f0 : (sin(r)/r)
end
l = range(-10, stop = 10, length = N)
z = Float32[xy_data(x, y) for x in l, y in l]
surface(
    -1..1, -1..1, z,
    colormap = :Spectral
)
end # hide
println("~~~") # hide
show(stdout, MIME"text/html"(), __result) # hide
println("~~~") # hide
nothing # hide