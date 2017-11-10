using MakiE, FileIO, GLFW, GeometryTypes, Reactive

img = load(homedir()*"/Desktop/matcha.png")
scene = Scene()
is = image(img)
center!(scene)
subscene = Scene(scene, Signal(SimpleRectangle(0, 0, 200, 200)))
scatter(subscene, rand(100) * 200, rand(100) * 200, markersize = 4)


img = load(homedir()*"/Desktop/matcha.png")
scene = Scene()
image(img);

using MakiE
scene = Scene()
volume(rand(32, 32, 32), algorithm = :iso)
center!(scene)

using MakiE
scene = Scene()
heatmap(rand(32, 32))
center!(scene)

using MakiE, GeometryTypes
scene = Scene()
r = linspace(-10, 10, 512)
z = ((x, y)-> sin(x) + cos(y)).(r, r')
MakiE.contour(r, r, z, levels = 5, color = ColorBrewer.palette("RdYlBu", 5))
center!(scene)

using MakiE, GeometryTypes, Colors, MacroTools
scene = Scene()
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
    markersize = to_markersize(0.01)
    strokecolor = to_color(:white)
    strokewidth = to_float(0.01)
end

# this pushes all the values from theme to the plot

push!(pscat, theme)
pscat[:glow_color] = to_node(RGBA(0, 0, 0, 0.4), x->to_color((), x))


function custom_theme(scene)
    @theme theme = begin
        linewidth = to_float(3)
        colormap = to_colormap(:RdYlGn)#to_colormap(:RdPu)
        scatter = begin
            marker = to_spritemarker(Circle)
            markersize = to_float(0.03)
            strokecolor = to_color(:white)
            strokewidth = to_float(0.01)
            glowcolor = to_color(RGBA(0, 0, 0, 0.4))
            glowwidth = to_float(0.1)
        end
    end
    # update theme values
    scene[:theme] = theme
end
# apply it to the scene
custom_theme(scene)

# From now everything will be plotted with new theme
psurf = surface(vx, 1:0.1:2, psurf[:z])
center!(scene)

scene = Scene()
sv = scatter(rand(Point3f0, 100))
similar(sv, rand(10), rand(10), rand(10), color = :black, markersize = 0.4)


using MakiE, GeometryTypes, GLVisualize
scene = Scene()
x = map([:dot, :dash, :dashdot], [2, 3, 4]) do ls, lw
    linesegment(linspace(1, 5, 100), rand(100), rand(100), linestyle = ls, linewidth = lw)
end
push!(x, scatter(linspace(1, 5, 100), rand(100), rand(100)))
center!(scene)
l = MakiE.legend(x, ["attribute $i" for i in 1:4])

l[:position] = (0.089, 0.75)
l[:gap] = 20
l[:textgap] = 20
l[:padding] = 20
l[:scatterpattern]


scene = Scene(resolution = (500, 500))
large_sphere = HyperSphere(Point3f0(0), 1f0)
positions = decompose(Point3f0, large_sphere)
colS = [Colors.RGBA{Float32}(rand(), rand(), rand(), 1.) for i = 1:length(positions)]
sizesS = [rand(Vec3f0) .* 0.5f0 for i = 1:length(positions)]
meshscatter(positions, color = colS, markersize = sizesS)

scene = Scene()
y = [
    -0.997669
    -0.979084
    -0.942261
    -0.887885
    -0.81697
    -0.730836
    -0.631088
    -0.519584
    -0.398401
    -0.269797
    -0.136167
    0.0
    0.136167
    0.269797
    0.398401
    0.519584
    0.631088
    0.730836
    0.81697
    0.887885
    0.942261
    0.979084
    0.997669
]
contour(linspace(-0.99, 0.99, 23), y, rand(23, 23), levels = 10)
center!(scene)

using FileIO, MakiE, GeometryTypes, MakiE
lakemesh = load(Pkg.dir("DiffEqProblemLibrary", "src", "premade_meshes.jld"))["lakemesh"]
scene = Scene()

function MakiE.to_mesh(b, m::typeof(lakemesh))
    vertices = map(1:size(m.node, 1)) do i
        Point3f0(ntuple(j-> m.node[i, j], Val{2})..., 0)
    end
    triangles = map(1:size(m.elem, 1)) do i
        GLTriangle(Int.(ntuple(j-> m.elem[i, j], Val{3})))
    end
    GLNormalMesh(vertices, triangles)
end

wireframe(lakemesh)
m = mesh(lakemesh)
center!(scene)
