
function subscenes()
    img = loadasset("doge.png")
    scene = Scene(resolution = (500, 500))
    
    is = image(img)
    center!(scene)
    subscene = Scene(scene, Signal(SimpleRectangle(0, 0, 200, 200)))
    scatter(subscene, rand(100) * 200, rand(100) * 200, markersize = 4)
    center!(scene)
    scene

end

function contour_function()
    scene = Scene(resolution = (500, 500))
    r = linspace(-10, 10, 512)
    z = ((x, y)-> sin(x) + cos(y)).(r, r')
    contour(r, r, z, levels = 5, color = ColorBrewer.palette("RdYlBu", 5))
    center!(scene)

end

function contour_simple()
    scene = Scene(resolution = (500, 500))
    y = linspace(-0.997669, 0.997669, 23)
    contour(linspace(-0.99, 0.99, 23), y, rand(23, 23), levels = 10)
    center!(scene)

end

function heatmap_1()
    scene = Scene(resolution = (500, 500))
    heatmap(rand(32, 32))
    center!(scene)

end

function animated_scatter()
    scene = Scene(resolution = (500, 500))
    r = [(rand(7, 2) .- 0.5) .* 25 for i = 1:200]
    axis(linspace(-25, 25, 4), linspace(-25, 25, 4))
    scatter(r[1][:, 1], r[1][:, 2], markersize = 1)
    center!(scene)
    io = VideoStream(scene, "C:\\Users\\sdani\\.julia\\v0.6\\Makie\\docs\\media\\animated_scatter")
    @inbounds for i in 2:length(r)
        scene[:scatter][:positions] = Point2f0.(view(r[i], :, 1), view(r[i], :, 2))
        recordframe!(io)
    end
    io

end

function text_annotation()
    scene = Scene(resolution = (500, 500))
    text(
        ". This is an annotation!",
        position = (300, 200),
        align = (:center,  :center),
        textsize = 60,
        font = "URW Chancery L"
    )
    scene

end

function text_rotation()
    scene = Scene(resolution = (500, 500))
    pos = (500, 500)
    rot = to_node(0.0pi)
    posis = Point2f0[]
    for r in linspace(0, 2pi, 20)
        p = pos .+ (sin(r)*100.0, cos(r) * 100)
        push!(posis, p)
        t = text("test",
            position = p,
            textsize = 50,
            rotation = 1.5pi - r,
            align = (:center, :center)
        )
    end
    scatter(posis, markersize = 10)
    center!(scene)

end

function sample_7()
    scene = Scene(resolution = (500, 500))
    sv = scatter(rand(Point3f0, 100))
    similar(sv, rand(10), rand(10), rand(10), color = :black, markersize = 0.4)
    center!(scene)

end

function fluctuation_3d()
    scene = Scene(resolution = (500, 500))
    # define points/edges
    perturbfactor = 4e1
    N = 3; nbfacese = 30; radius = 0.02
    large_sphere = HyperSphere(Point3f0(0), 1f0)
    positions = decompose(Point3f0, large_sphere, 30)
    np = length(positions)
    pts = [positions[k][l] for k = 1:length(positions), l = 1:3]
    pts = vcat(pts, 1.1 * pts + randn(size(pts)) / perturbfactor) # light position influence ?
    edges = hcat(collect(1:np), collect(1:np) + np)
    ne = size(edges, 1); np = size(pts, 1)
    # define markers meshes
    meshC = GLNormalMesh(
        Cylinder{3, Float32}(
            Point3f0(0., 0., 0.),
            Point3f0(0., 0, 1.),
            Float32(1)
        ), nbfacese
    )
    meshS = GLNormalMesh(large_sphere, 20)
    # define colors, markersizes and rotations
    pG = [Point3f0(pts[k, 1], pts[k, 2], pts[k, 3]) for k = 1:np]
    lengthsC = sqrt.(sum((pts[edges[:,1], :] .- pts[edges[:, 2], :]) .^ 2, 2))
    sizesC = [Vec3f0(radius, radius, lengthsC[i]) for i = 1:ne]
    sizesC = [Vec3f0(1., 1., 1.) for i = 1:ne]
    colorsp = [Colors.RGBA{Float32}(rand(), rand(), rand(), 1.) for i = 1:np]
    colorsC = [(colorsp[edges[i, 1]] + colorsp[edges[i, 2]]) / 2. for i = 1:ne]
    sizesC = [Vec3f0(radius, radius, lengthsC[i]) for i = 1:ne]
    Qlist = zeros(ne, 4)
    for k = 1:ne
        ct = Cylinder{3, Float32}(
            Point3f0(pts[edges[k, 1], 1], pts[edges[k, 1], 2], pts[edges[k, 1], 3]),
            Point3f0(pts[edges[k, 2], 1], pts[edges[k, 2], 2], pts[edges[k, 2], 3]),
            Float32(1)
        )
        Q = rotation(ct)
        r = 0.5 * sqrt(1 + Q[1, 1] + Q[2, 2] + Q[3, 3]); Qlist[k, 4] = r
        Qlist[k, 1] = (Q[3, 2] - Q[2, 3]) / (4 * r)
        Qlist[k, 2] = (Q[1, 3] - Q[3, 1]) / (4 * r)
        Qlist[k, 3] = (Q[2, 1] - Q[1, 2]) / (4 * r)
    end
    rotationsC = [Vec4f0(Qlist[i, 1], Qlist[i, 2], Qlist[i, 3], Qlist[i, 4]) for i = 1:ne]
    # plot
    hm = meshscatter(
        pG[edges[:, 1]], color = colorsC, marker = meshC,
        markersize = sizesC,  rotations = rotationsC
    )
    hp = meshscatter(pG, color = colorsp, marker = meshS, markersize = radius)

    r = linspace(-1.3, 1.3, 4); axis(r, r, r)
    center!(scene)

end

function connected_sphere()
    scene = Scene(resolution = (500, 500))
    large_sphere = HyperSphere(Point3f0(0), 1f0)
    positions = decompose(Point3f0, large_sphere)
    linepos = view(positions, rand(1:length(positions), 1000))
    lines(linepos, linewidth = 0.1, color = :black)
    scatter(positions, strokewidth = 0.02, strokecolor = :white, color = RGBA(0.9, 0.2, 0.4, 0.6))
    r = linspace(-1.5, 1.5, 5)
    axis(r, r, r)
    scene

end

function simple_meshscatter()
    scene = Scene(resolution = (500, 500))
    large_sphere = HyperSphere(Point3f0(0), 1f0)
    positions = decompose(Point3f0, large_sphere)
    meshscatter(positions, color = RGBA(0.9, 0.2, 0.4, 1))
    scene

end

function animated_surface_and_wireframe()
    scene = Scene(resolution = (500, 500))

    function xy_data(x, y)
        r = sqrt(x^x + y^y)
        r == 0.0 ? 1f0 : (sin(r)/r)
    end

    r = linspace(-2, 2, 40)
    surf_func(i) = [Float32(xy_data(x*i, y*i)) for x = r, y = r]
    z = surf_func(20)
    surf = surface(r, r, z)

    wf = wireframe(r, r, surf[:z] .+ 1.0,
        linewidth = 2f0, color = lift_node(x-> x[5], surf[:colormap])
    )
    xy = linspace(-2.1, 2.1, 4)
    axis(xy, xy, linspace(0, 2, 4))
    center!(scene)

    io = VideoStream(scene, "C:\\Users\\sdani\\.julia\\v0.6\\Makie\\docs\\media\\animated_surface_and_wireframe")
    for i in linspace(0, 60, 100)
        surf[:z] = surf_func(i)
        recordframe!(io)
    end
    scene

end

function normals_of_a_cat()
    scene = Scene(resolution = (500, 500))
    x = loadasset("cat.obj")
    mesh(x.vertices, x.faces, color = :black)
    pos = map(x.vertices, x.normals) do p, n
        p => p .+ (normalize(n) .* 0.05f0)
    end
    linesegment(pos)
    scene

end

function sphere_mesh()
    scene = Scene(resolution = (500, 500))
    mesh(Sphere(Point3f0(0), 1f0))
    center!(scene)
    scene

end

function stars()
    scene = Scene(resolution = (500, 500), color = :black)
    stars = 100_000
    scatter((rand(Point3f0, stars) .- 0.5) .* 10,
        glowwidth = 0.005, glow_color = :white, color = RGBA(0.8, 0.9, 0.95, 0.4),
        markersize = rand(linspace(0.0001, 0.01, 100), stars)
    )
    scene

end

function unicode_marker()
    scene = Scene(resolution = (500, 500))
    scatter(Point3f0[(1,0,0), (0,1,0), (0,0,1)], marker = [:x, :circle, :cross])
    axis(scene, linspace(0, 1, 4), linspace(0, 1, 4), linspace(0, 1, 4))
    center!(scene);

end

function line_gif()
    scene = Scene(resolution = (500, 500))
    lineplots = []
    axis(linspace(-0.1, 1.1, 4), linspace(-2, 2, 4), linspace(0, 2, 4))
    center!(scene)
    us = linspace(0, 1, 100)

    mktempdir() do path
        io = VideoStream(scene, "C:\\Users\\sdani\\.julia\\v0.6\\Makie\\docs\\media\\line_gif")
        for i = 1:100
            if length(lineplots) < 20
                push!(lineplots, lines(us, sin.(us .+ time()), zeros(100)))
            else
                lineplots = circshift(lineplots, 1)
                lp = first(lineplots)
                lp[:positions] = Point3f0.(us, sin.(us .+ time()), zeros(100))
                lp[:offset] = Vec3f0(0)
            end
            for lp in lineplots
                z = to_value(lp, :offset)[3]
                lp[:offset] = Vec3f0(0, 0, z + 0.1)
            end
            recordframe!(io)
        end
        finish(io, "gif")
    end

end

function complex_axis()
    scene = Scene(resolution = (500, 500))
    vx = -1:0.01:1;
    vy = -1:0.01:1;

    f(x, y) = (sin(x*10) + cos(y*10)) / 4
    psurf = surface(vx, vy, f)

    a = axis(linspace(extrema(vx)..., 4), linspace(extrema(vy)..., 4), linspace(-1, 1, 4))
    center!(scene, 0)

    a[:axisnames] = ("\\bf{ℜ}[u]", "\\bf{𝕴}[u]", " OK\n\\bf{δ}\n γ")
    a[:axisnames_size] = (0.15, 0.15, 0.15)
    a[:axisnames_color] = (:black, :black, :black)
    a[:axisnames_font] = "Palatino"

    # available_gradients() print gradients
    psurf[:colormap] = :RdYlBu
    wh = widths(scene)
    t = text(
        "Multipole Representation of first resonances of U-238",
        position = (wh[1] / 2.0, wh[2] - 20.0),
        align = (:center,  :center),
        textsize = 20,
        font = "Palatino",
        camera = :pixel
    )
    c = lines(Circle(Point2f0(0.1, 0.5), 0.1f0), color = :red, offset = Vec3f0(0, 0, 1))
    #update surface
    psurf[:z] = f.(vx .+ 0.5, (vy .+ 0.5)')
    scene

end

function volume_function()
    scene = Scene(resolution = (500, 500))
    volume(rand(32, 32, 32), algorithm = :iso)
    center!(scene)

end

function heatmap_function()
    scene = Scene(resolution = (500, 500))
    heatmap(rand(32, 32))
    center!(scene)

end

function textured_mesh()
    scene = Scene(resolution = (500, 500))
    cat = load(assetpath("cat.obj"), GLNormalUVMesh)
    mesh(cat, color = loadasset("diffusemap.tga"))
    center!(scene)

end

function load_mesh()
    scene = Scene(resolution = (500, 500))
    mesh(loadasset("cat.obj"))
    r = linspace(-0.1, 1, 4)
    center!(scene)
    scene

end

function colored_mesh()
    scene = Scene(resolution = (500, 500));
    x = [0, 1, 2, 0]
    y = [0, 0, 1, 2]
    z = [0, 2, 0, 1]
    color = [:red, :green, :blue, :yellow]
    i = [0, 0, 0, 1]
    j = [1, 2, 3, 2]
    k = [2, 3, 1, 3]

    indices = [1, 2, 3, 1, 3, 4, 1, 4, 2, 2, 3, 4]
    mesh(x, y, z, indices, color = color)
    r = linspace(-0.5, 2.5, 4)
    axis(r, r, r)
    center!(scene)

end

function wireframe_of_a_mesh()
    scene = Scene(resolution = (500, 500))
    wireframe(GLVisualize.loadasset("cat.obj"))
    center!(scene)

end

function wireframe_of_sphere()
    scene = Scene(resolution = (500, 500))
    wireframe(Sphere(Point3f0(0), 1f0))
    center!(scene)

end

function wireframe_of_a_surface()
    scene = Scene(resolution = (500, 500))
    surf = wireframe(range, range, z)
    center!(scene)

end

function surface_function()
    scene = Scene(resolution = (500, 500))
    N = 32
    function xy_data(x, y)
        r = sqrt(x^x + y^y)
        r == 0.0 ? 1f0 : (sin(r)/r)
    end
    lspace = linspace(-10, 10, 32)
    z = Float32[xy_data(x, y) for x in lspace, y in lspace]
    range = linspace(0, 3, N)
    surf = surface(range, range, z, colormap = :Spectral)
    center!(scene)

end

function surface_with_image()
    scene = Scene(resolution = (500, 500))

    N = 60

    function xy_data(x, y)
        r = sqrt(x^x + y^y)
        r == 0.0 ? 1f0 : (sin(r)/r)
    end

    r = linspace(-2, 2, 40)
    surf_func(i) = [Float32(xy_data(x*i, y*i)) for x = r, y = r]
    surface(
        r, r, surf_func(10),
        color = loadasset("doge.png")
    )
    center!(scene)
    scene

end

function line_function()
    scene = Scene(resolution = (500, 500))
    x = linspace(0, 3pi)
    lines(x, sin.(x))
    center!(scene)

end

function meshscatter_function()
    scene = Scene(resolution = (500, 500))
    large_sphere = HyperSphere(Point3f0(0), 1f0)
    positions = decompose(Point3f0, large_sphere)
    colS = [RGB(rand(), rand(), rand()) for i = 1:length(positions)]
    sizesS = [rand(Point3f0) .* 0.5f0 for i = 1:length(positions)]
    meshscatter(positions, color = colS, markersize = sizesS)
    center!(scene)

end

function scatter_function()
    scene = Scene(resolution = (500, 500))
    scatter(rand(20), rand(20))
    center!(scene)

end

function interaction()
    scene = Scene(resolution = (500, 500))

    f(t, v, s) = (sin(v + t) * s, cos(v + t) * s)

    p1 = scatter(lift_node(t-> f.(t, linspace(0, 2pi, 50), 1), scene[:time]))
    p2 = scatter(lift_node(t-> f.(t * 2.0, linspace(0, 2pi, 50), 1.5), scene[:time]))
    center!(scene)
    # you can now reference to life attributes from the above plots:

    lines = lift_node(p1[:positions], p2[:positions]) do pos1, pos2
        map((a, b)-> (a, b), pos1, pos2)
    end

    linesegment(lines)

    center!(scene)
    io = VideoStream(scene, "C:\\Users\\sdani\\.julia\\v0.6\\Makie\\docs\\media\\interaction")
    # record a video
    for i = 1:300
        recordframe!(io)
    end
    io

end

function legend_1()
    scene = Scene(resolution = (500, 500))
    plots = map([:dot, :dash, :dashdot], [2, 3, 4]) do ls, lw
        linesegment(linspace(1, 5, 100), rand(100), rand(100), linestyle = ls, linewidth = lw)
    end

    push!(plots, scatter(linspace(1, 5, 100), rand(100), rand(100)))

    center!(scene)

    # plot a legend for the plots with an array of names
    l = legend(plots, ["attribute $i" for i in 1:4])

    ann = VideoAnnotation(scene, "C:\\Users\\sdani\\.julia\\v0.6\\Makie\\docs\\media\\legend_1", "Themes")

    io = ann
    recordstep!(io, "Interact with Legend:")
    # Change some attributes interactively
    l[:position] = (0.4, 0.7)
    recordstep!(io, "Change Position")
    l[:backgroundcolor] = RGBA(0.95, 0.95, 0.95)
    recordstep!(io, "Change Background")
    l[:strokecolor] = RGB(0.8, 0.8, 0.8)
    recordstep!(io, "Change Stroke Color")
    l[:gap] = 30
    recordstep!(io, "Change Gaps")
    l[:textsize] = 19
    recordstep!(io, "Change Textsize")
    l[:linepattern] = Point2f0[(0,-0.2), (0.5, 0.2), (0.5, 0.2), (1.0, -0.2)]
    recordstep!(io, "Change Line Pattern")
    l[:scatterpattern] = decompose(Point2f0, Circle(Point2f0(0.5, 0), 0.3f0), 9)
    recordstep!(io, "Change Scatter Pattern")
    l[:markersize] = 2f0
    recordstep!(io, "Change Marker Size")
    io

end

function color_legend()
    scene = Scene(resolution = (500, 500))
    cmap = collect(linspace(to_color(:red), to_color(:blue), 20))
    l = legend(cmap, 1:4)
    ann = VideoAnnotation(scene, "C:\\Users\\sdani\\.julia\\v0.6\\Makie\\docs\\media\\color_legend", "Color Map Legend:")
    recordstep!(io, "Color Map Legend:", 3)
    l[:position] = (1.0, 1.0)
    recordstep!(io, "Change Position")
    l[:textcolor] = :blue
    l[:strokecolor] = :black
    recordstep!(io, "Change Colors")
    l[:strokewidth] = 1
    l[:textsize] = 15
    l[:textgap] = 5
    recordstep!(io, "Change everything!")
    ann

end

function videostream()
    scene = Scene(resolution = (500, 500))

    f(t, v, s) = (sin(v + t) * s, cos(v + t) * s, (cos(v + t) + sin(v)) * s)
    t = to_node(time()) # create a life signal
    p1 = meshscatter(lift_node(t-> f.(t, linspace(0, 2pi, 50), 1), t))
    p2 = meshscatter(lift_node(t-> f.(t * 2.0, linspace(0, 2pi, 50), 1.5), t))
    center!(scene)

    # you can now reference to life attributes from the above plots:
    lines = lift_node(p1[:positions], p2[:positions]) do pos1, pos2
        map((a, b)-> (a, b), pos1, pos2)
    end

    linesegment(lines, linestyle = :dot)

    center!(scene)
    # record a video
    io = VideoStream(scene, "C:\\Users\\sdani\\.julia\\v0.6\\Makie\\docs\\media\\videostream")
    for i = 1:300
        push!(t, time())
        recordframe!(io)
    end
    finish(io, "mp4") # could also be gif, webm or mkv

end



using GeometryTypes





function axis_2d()
    scene = Scene(resolution = (500, 500))
    aviz = axis(linspace(0, 2, 4), linspace(0, 2, 4))
    center!(scene)

    scene = Scene(resolution = (500, 500))
    aviz = axis(linspace(0, 2, 4), linspace(0, 2, 4), linspace(0, 2, 4))
    center!(scene)

    aviz[:gridcolors] = (:gray, :gray, :gray)
    aviz[:axiscolors] = (:red, :black, :black)
    aviz[:showticks] = (true, true, false)

    # To simplify the example, we take the already existing GeometryTypes.Circle type, which
    # can already be decomposed into positions
    function Makie.to_positions(backend, x::Circle)
        # Convert to a type to_positions can handle.
        # Everything that usually works in e.g. scatter/lines should be allowed here.
        positions = decompose(Point2f0, x, 50)
        # Pass your position data to to_positions,
        # just in case the backend has some extra converts
        # that are not visible in the user facing API.
        Makie.to_positions(backend, positions)
    end
    scene = Scene(resolution = (500, 500))
    p1 = lines(Circle(Point2f0(0), 5f0))
    p2 = scatter(Circle(Point2f0(0), 6f0))
    center!(scene)

    p2[:positions] = Circle(Point2f0(0), 7f0)
    center!(scene)

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
    # Update the entire surface node with this
    scene[:scatter] = theme
    # Or permananently (to be more precise: just for this session) change the theme for scatter
    scene[:theme, :scatter] = theme
    scatter(lift_node(x-> x .+ (Point3f0(0, 0, 1),), pos)) # will now use new theme
    scene

    function custom_theme(scene)
        @theme theme = begin
            linewidth = to_float(3)
            colormap = to_colormap(:RdPu)
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

end
