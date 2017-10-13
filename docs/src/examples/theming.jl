using MakiE, GeometryTypes, Colors, MacroTools

scene = Scene()

vx = -10:0.1:10;
vy = -8:0.1:8;
x = [i for i in vx, j in vy];
y = [j for i in vx, j in vy];
z = @. (x * y * (x^2 - y^2) ./ (x^2 + y^2 + eps())) / 5.0

psurf = surface(x, y, z)
Pmax = Point3f0(-10, -8, -6)
Pmin = -Pmax
pscat = scatter(
    map(x-> (x .* (Pmax .- Pmin)) .+ Pmin, rand(Point3f0, 1000)),
)

MakiE.@theme theme = begin
    colormap = MakiE.to_colormap(:RdPu)
end
# this pushes all the values from theme to the plot
# This will unlink the values from the current theme
push!(psurf, theme)
# Or update the entire scatter node with this
scene[:surface1] = theme

# Or permananently (to be more precise: just for this session) change the theme for scatter
scene[:theme, :surface] = theme

# Make a completely new theme
function my_sweet_theme(scene)
    MakiE.@theme theme = begin
        linewidth = 2::Float32
        colormap = MakiE.to_colormap(:BuGn)
        scatter = begin
            marker = MakiE.to_spritemarker(Circle)
            markersize = 0.5::Float32
            strokecolor = MakiE.to_color(:white)
            strokewidth = 0.1::Float32
            glowcolor = MakiE.to_color(RGBA(0, 0, 0, 0.4))
            glowwidth = 0.2::Float32
        end
    end
    # update theme values
    scene[:theme] = theme
end
# apply it to the scene
my_sweet_theme(scene)

psurf = surface(x, y, z .+ 6)
