#setup
using Makie

cd(@__DIR__) do
function xy_data(x, y)
    r = sqrt(x*x + y*y)
    r == 0.0 ? 1f0 : (sin(r)/r)
end

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


#cell
img = Makie.logo()
scene1 = image(img)
scene2 = scatter(rand(100), rand(100), markersize = 0.05)
AbstractPlotting.vbox(scene1, scene2)


#cell
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
