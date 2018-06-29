using Makie
new_theme = Theme(
    linewidth = 3,
    colormap = :RdYlGn,
    color = :red,
    scatter = Theme(
        marker = '⊝',
        markersize = 0.03,
        strokecolor = :black,
        strokewidth = 0.1,
    ),
)
AbstractPlotting.set_theme!(new_theme)
scene2 = scatter(rand(100), rand(100))
new_theme[:color] = :blue
new_theme[:scatter, :marker] = '◍'
new_theme[:scatter, :markersize] = 0.05
new_theme[:scatter, :strokewidth] = 0.1
new_theme[:scatter, :strokecolor] = :green
scene2 = scatter(rand(100), rand(100))
scene2[end][:marker] = 'π'



scene3 = AbstractPlotting.vbox(scene1, scene2)
boundingbox(scene2)

scene3
scene3.children[2].plots[2].transformation.model[]
scene = Scene(resolution = (500, 500))
vx = -1:0.1:1;
vy = -1:0.1:1;

f(x, y) = (sin(x*10) + cos(y*10)) / 4
psurf = surface(vx, vy, f)

pos = lift_node(psurf[:x], psurf[:y], psurf[:z]) do x, y, z
    vec(Point3f0.(x, y', z .+ 0.5))
end
pscat = scatter(pos)
plines = lines(view(pos, 1:2:length(pos)))
center!(scene)
@theme theme = begin
    markersize = to_markersize2d(0.01)
    strokecolor = to_color(:white)
    strokewidth = to_float(0.01)
end
# this pushes all the values from theme to the plot
push!(pscat, theme)
pscat[:glow_color] = to_node(RGBA(0, 0, 0, 0.4), x->to_color((), x))
# apply it to the scene
custom_theme(scene)
# From now everything will be plotted with new theme
psurf = surface(vx, 1:0.1:2, psurf[:z])
center!(scene)



#cell
scene = Scene(resolution = (500, 500))

x = map([:dot, :dash, :dashdot], [2, 3, 4]) do ls, lw
    linesegment(linspace(1, 5, 100), rand(100), rand(100), linestyle = ls, linewidth = lw)
end
push!(x, scatter(linspace(1, 5, 100), rand(100), rand(100)))
center!(scene)
l = Makie.legend(x, ["attribute $i" for i in 1:4])
l[:position] = (0, 1)
l[:backgroundcolor] = RGBA(0.95, 0.95, 0.95)
l[:strokecolor] = RGB(0.8, 0.8, 0.8)
l[:gap] = 30
l[:textsize] = 19
l[:linepattern] = Point2f0[(0,-0.2), (0.5, 0.2), (0.5, 0.2), (1.0, -0.2)]
l[:scatterpattern] = decompose(Point2f0, Circle(Point2f0(0.5, 0), 0.3f0), 9)
l[:markersize] = 2f0
scene

#cell
scene = Scene(resolution = (500, 500))
cmap = collect(linspace(to_color(:red), to_color(:blue), 20))
l = Makie.legend(cmap, 1:4)
l[:position] = (1.0,1.0)
l[:textcolor] = :blue
l[:strokecolor] = :black
l[:strokewidth] = 1
l[:textsize] = 15
l[:textgap] = 5
scene



#cell
using Makie, GeometryTypes, ColorTypes
scene = Scene();
scatter([Point2f0(1.0f0,1.0f0),Point2f0(1.0f0,0.0f0)])
center!(scene);
text_overlay!(scene, "test", position = Point2f0(1.0f0,1.0f0), textsize=200,color= RGBA(0.0f0,0.0f0,0.0f0,1.0f0))
text_overlay!(scene, "test", position = Point2f0(1.0f0,0.0f0), textsize=200,color= RGBA(0.0f0,0.0f0,0.0f0,1.0f0))

scene = Scene();
scatter([Point2f0(1.0f0,1.0f0),Point2f0(1.0f0,0.0f0)])
center!(scene);

text_overlay!(scene,:scatter, "test", "test", textsize=200,color= RGBA(0.0f0,0.0f0,0.0f0,1.0f0))

scene = Scene();
scatter([Point2f0(1.0f0,1.0f0),Point2f0(1.0f0,0.0f0)])
center!(scene);
text_overlay!(scene, :scatter, 1=>"test1", 2=>"test2", textsize=200,color= RGBA(0.0f0,0.0f0,0.0f0,1.0f0))

#cell


# needs to be in a function for ∇ˢf to be fast and inferable
function test(scene)
    n = 20
    f   = (x,y,z) -> x*exp(cos(y)*z)
    ∇f  = (x,y,z) -> Point3f0(exp(cos(y)*z), -sin(y)*z*x*exp(cos(y)*z), x*cos(y)*exp(cos(y)*z))
    ∇ˢf = (x,y,z) -> ∇f(x,y,z) - Point3f0(x,y,z)*dot(Point3f0(x,y,z), ∇f(x,y,z))
    θ = [0;(0.5:n-0.5)/n;1]
    φ = [(0:2n-2)*2/(2n-1);2]
    x = [cospi(φ)*sinpi(θ) for θ in θ, φ in φ]
    y = [sinpi(φ)*sinpi(θ) for θ in θ, φ in φ]
    z = [cospi(θ) for θ in θ, φ in φ]

    pts = vec(Point3f0.(x, y, z))
    lns = Makie.streamlines!(scene, pts, ∇ˢf)
    # those can be changed interactively:
    lns[:color] = :black
    lns[:h] = 0.06
    lns[:linewidth] = 1.0
    lns
end


using Makie
main = Scene()
cam3d!(main)
main
plots = [
    heatmap(0..1, 0..1, rand(100, 100)),
    meshscatter(rand(10), rand(10), rand(10)),
    scatter(rand(10), rand(10)),
    mesh(Makie.loadasset("cat.obj")),
    volume(0..1, 0..1, 0..1, rand(32, 32, 32)),
]

for p in plots
    push!(main, p)
    translate!(p, rand()*3, rand()*3, rand()*3)
end


using Makie, GeometryTypes
scene = Scene()
ui = Scene(scene, lift(x-> IRect(0, 0, widths(x)[1], 100), pixelarea(scene)))
plots = Scene(scene, lift(x-> IRect(0, 100, widths(x) .- Vec(0, 100)), pixelarea(scene)))
campixel!(ui)
s1 = slider!(ui, 1:10, raw = true)[end]
s2 = slider!(ui, 1:10, raw = true)[end]
s3 = slider!(ui, linspace(0, 1, 100), raw = true)[end]
AbstractPlotting.vbox(s1, s2, s3)
heatmap!(plots, rand(100, 100))
scene

@inline function collide(p, bounds)
    mini = p .<= minimum(bounds)
    any(mini) && return true, normalize(Point3f0(mini))
    maxi = p .>= maximum(bounds)
    any(maxi) && return true, normalize(-Point3f0(maxi))
    false, p
end

@inline function particle_inner(posj, posi, vel)
    d = posj - posi
    distsq = dot(d, d) + 1f0
    vel .+ (reverse(d)/distsq)
end

function solve_particles!(
        positions::AbstractVector{P}, velocity::AbstractVector, bounds, dt::T = T(0.01)
    ) where P <: Point{N, T} where {N, T}
    @inbounds for i in eachindex(positions)
        vel = velocity[i]
        posi = positions[i]
        for j in eachindex(positions)
            posj = positions[j]
            d = posj .- posi
            distsq = dot(d, d) + T(1)
            vel = vel .+ (d ./ distsq)
            any(x-> abs(x) > T(0.8), vel) && break # restrict velocity
        end
        col, normal = collide(posi, bounds)
        if col
            vel = -2f0 * (dot(vel, normal) * normal + vel)
        end
        velocity[i] = vel
        positions[i] = posi .+ dt*vel
    end
    return
end


startpositions(N::Integer, radius::T, n) where T = startpositions(Val{N}(), radius, n)
function startpositions(::Val{N}, radius::T, n) where {N, T}
    sphere = HyperSphere(Point{N, T}(0), T(radius))
    n = N == 3 ? floor(Int, sqrt(n)) : n # n must be n^2 for 3D Sphere
    pos = decompose(Point{N, T}, sphere, n)
    map!(pos, pos) do p
        p .+ ((rand(Point{N, T}) .- 0.5) .* radius * T(0.1))
    end
end
using GeometryTypes
FRect3D = HyperRectangle
bounds = FRect3D(Vec3f0(-1), Vec3f0(2))
N = 3; T = Float32; n = 10^5
positions = startpositions(N, T(0.5), n)
velocities = rand(Point3f0, length(positions))

using Makie
scene = scatter(positions, markersize = 0.006, color = norm.(velocities))
particles = scene[end]
linesegments!(scene, bounds)
display(Makie.global_gl_screen(), scene)

@async while isopen(scene)
    @time solve_particles!(positions, velocities, bounds)
    particles[1] = positions
    sleep(1/60)
end
# keep_runnin[] = true
scene
velocities
solve_particles2!(positions, velocities, bounds, 0.1f0)

Profile.print()
any.(x-> abs(x) > T(0.8), velocities)


using Makie
import RDatasets
singers = RDatasets.dataset("lattice","singer")

keys = unique(singers[:VoicePart])
map(typeof, singers[:VoicePart])
findfirst
first(keys) == first(singers[:VoicePart])
findfirst(keys, first(singers[:VoicePart]))

x = map(x-> findfirst(keys, x), singers[:VoicePart])

box(x, singers[:Height])


scene = Scene()
cam2d!(scene)
axis2d!(scene, ((-3, 4), (3, 8)))
center!(scene)
scene
@which AbstractPlotting.plots_from_camera(scene)
@which boundingbox()
