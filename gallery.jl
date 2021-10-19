
using HTTP
using CSV
using DataFrames
using GLMakie
using LinearAlgebra
GLMakie.inline!(false)
url = "https://raw.githubusercontent.com/plotly/datasets/master/vortex.csv"
df = CSV.File(HTTP.get(url).body)|> DataFrame;

uvw = Vec3f0.(df.u, df.v, df.w)
len = norm.(uvw)

arrows(df.x, df.y, df.z, df.u, df.v, df.w, linewidth=0, color=len, arrowsize = Vec3f0(0.5, 0.5, 1)) |> display


# surface parameterization  (u, v)----> (f(u,v), g(u,v), h(u,v)):
f = (u, v) -> cos(v)*(6 - (5/4 +sin(3*u))*sin(u-3*v))
g = (u, v) -> sin(v)*(6 - (5/4 +sin(3*u))*sin(u-3*v))
h = (u, v) -> -cos(u-3*v) * (5/4 +sin(3*u));

u = range(0, stop=2π, length=150)
v = range(0, stop=2π, length=150)

tr = surface(f.(u,v'),
             g.(u,v'),
             h.(u,v'),
             ambient=Vec3f(0.5),
             diffuse=Vec3f(1),
             specular=0.5,
             colormap=:balance) |> display
