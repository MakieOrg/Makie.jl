@reference_test "mesh textured and loaded" begin
    f = Figure(size = (600, 600))

    moon = loadasset("moon.png")
    ax, meshplot = mesh(
        f[1, 1], Sphere(Point3f(0), 1.0f0), color = moon,
        shading = NoShading, axis = (; show_axis = false)
    )
    update_cam!(ax.scene, Vec3f(-2, 2, 2), Vec3f(0))
    cameracontrols(ax).settings.center[] = false # avoid recenter on display

    earth = loadasset("earth.png")
    m = uv_mesh(Tessellation(Sphere(Point3f(0), 1.0f0), 60))
    mesh(f[1, 2], m, color = earth, shading = NoShading)

    catmesh = loadasset("cat.obj")
    mesh(f[2, 1], catmesh, color = loadasset("diffusemap.png"))

    mesh(f[2, 2], loadasset("cat.obj"); color = :black)

    f
end

@reference_test "Orthographic Camera" begin
    function colormesh((geometry, color))
        mesh1 = normal_mesh(geometry)
        npoints = length(GeometryBasics.coordinates(mesh1))
        return GeometryBasics.mesh(mesh1; color = fill(color, npoints))
    end
    # create an array of differently colored boxes in the direction of the 3 axes
    x = Vec3f(0); baselen = 0.2f0; dirlen = 1.0f0
    rectangles = [
        (Rect(Vec3f(x), Vec3f(dirlen, baselen, baselen)), RGBAf(1, 0, 0, 1)),
        (Rect(Vec3f(x), Vec3f(baselen, dirlen, baselen)), RGBAf(0, 1, 0, 1)),
        (Rect(Vec3f(x), Vec3f(baselen, baselen, dirlen)), RGBAf(0, 0, 1, 1)),
    ]

    meshes = map(colormesh, rectangles)
    fig, ax, meshplot = mesh(merge(meshes))
    scene = ax.scene
    cam = cameracontrols(scene)
    cam.settings[:projectiontype][] = Makie.Orthographic
    cam.settings.center[] = false # This would be set by update_cam!()
    cam.upvector[] = (0.0, 0.0, 1.0)
    cam.lookat[] = Vec3f(0.595, 1.5, 0.5)
    cam.eyeposition[] = (cam.lookat[][1], cam.lookat[][2] + 0.61, cam.lookat[][3])
    update_cam!(scene, cam)
    fig
end

@reference_test "simple volumes" begin
    f = Figure()
    r = range(-1, stop = 1, length = 100)
    matr = [(x .^ 2 + y .^ 2 + z .^ 2) for x in r, y in r, z in r]
    volume(f[1, 1], matr .* (matr .> 1.4), algorithm = :iso, isorange = 0.05, isovalue = 1.7, colorrange = (0, 1))

    volume(f[1, 2], RNG.rand(32, 32, 32), algorithm = :mip)

    r = LinRange(-3, 3, 100)   # our value range
    ρ(x, y, z) = exp(-(abs(x))) # function (charge density)
    ax, pl = volume(
        f[2, 1],
        r, r, r,          # coordinates to plot on
        ρ,                # charge density (functions as colorant)
        algorithm = :mip,  # maximum-intensity-projection
        colorrange = (0, 1),
    )
    ax.scene[OldAxis].names[].textcolor = :lightgray # let axis labels be seen on dark background
    ax.scene[OldAxis].ticks[].textcolor = :gray # let axis ticks be seen on dark background
    ax.scene.backgroundcolor[] = to_color(:black)
    ax.scene.clear[] = true

    r = range(-3pi, stop = 3pi, length = 100)
    volume(
        f[2, 2], r, r, r, (x, y, z) -> cos(x) + sin(y) + cos(z),
        colorrange = (0, 1), algorithm = :iso, isorange = 0.1f0, axis = (; show_axis = false)
    )
    volume!(
        r, r, r, (x, y, z) -> cos(x) + sin(y) + cos(z), algorithm = :mip,
        colorrange = (0, 1), transformation = (translation = Vec3f(6pi, 0, 0),)
    )

    f
end

@reference_test "Volume absorption" begin
    f = Figure(size = (600, 300))
    r = range(-5, 5, length = 31)
    data = [cos(x * x + y * y + z * z)^2 for x in r, y in r, z in r]
    absorption = 5.0
    volume(f[1, 1], data, algorithm = :absorption; absorption)
    volume(f[1, 2], 128 .+ 120 .* data, algorithm = :indexedabsorption; absorption)
    volume(f[1, 3], HSV.(180 .* data, 0.8, 0.9), algorithm = :absorptionrgba; absorption)
    f
end

@reference_test "Volume from inside" begin
    f = Figure(size = (600, 400), backgroundcolor = :black)
    r = -10:10
    data = [1 - (1 + x / 10 + cos(y^2) + cos(z^2)) for x in r, y in r, z in r]
    index_data = round.(Int, 10 .* abs.(data))
    N = maximum(index_data)
    rgba_data = [RGBAf(x / 5, cos(y^2)^2, cos(z^2)^2, 0.5 + 0.5 * sin(x^2 + y^2 + z^2)) for x in r, y in r, z in r]
    add_data = [RGBAf(x, cos(y^2)^2, 0.1 * cos(z^2)^2, 0.1 + 0.1 * sin(x^2 + y^2 + z^2)) for x in r, y in r, z in r]

    volume(
        f[1, 1], -10 .. 10, -10 .. 10, -10 .. 10, data;
        algorithm = :iso, isovalue = 0.5, isorange = 0.1
    )
    volume(f[2, 1], -10 .. 10, -10 .. 10, -10 .. 10, data, algorithm = :absorption)
    volume(f[1, 2], -10 .. 10, -10 .. 10, -10 .. 10, data; algorithm = :mip)
    volume(f[2, 2], -10 .. 10, -10 .. 10, -10 .. 10, rgba_data; algorithm = :absorptionrgba)
    volume(f[1, 3], -10 .. 10, -10 .. 10, -10 .. 10, add_data; algorithm = :additive, alpha = 0.05)
    volume(
        f[2, 3], -10 .. 10, -10 .. 10, -10 .. 10, index_data;
        algorithm = :indexedabsorption, colormap = Makie.resample(to_colormap(:viridis), N)
    )

    for ls in f.content
        cam = cameracontrols(ls)
        cam.settings.center[] = false
        update_cam!(ls.scene, Vec3f(0), Vec3f(20, 1, 1))
    end

    f
end

# Test that volumes don't get clipped when their containing box would (i.e. if
# the back vertices would get clipped)
@reference_test "Volume no-clip" begin
    f = Figure(size = (300, 800))
    r = [sqrt(x * x + y * y + z * z) for x in -5:5, y in -5:5, z in -5:5]

    ax = Axis3(f[1, 1])
    volume!(ax, -5 .. 5, -5 .. 5, -5 .. 5, r, algorithm = :iso, isovalue = 0.9)
    limits!(ax, Rect3f(-1, -1, -1, 2, 2, 2))

    ax = Axis3(f[2, 1])
    contour!(ax, -5 .. 5, -5 .. 5, -5 .. 5, r, levels = [0.5, 0.9, 1.8])
    limits!(ax, Rect3f(-1, -1, -1, 2, 2, 2))

    ax = Axis3(f[3, 1])
    volume!(ax, -5 .. 5, -5 .. 5, -5 .. 5, r, absorption = 0.01, colorrange = (1, 2))
    limits!(ax, Rect3f(-1, -1, -1, 2, 2, 2))

    f
end


@reference_test "Textured meshscatter" begin
    catmesh = loadasset("cat.obj")
    img = loadasset("diffusemap.png")
    rot = qrotation(Vec3f(1, 0, 0), 0.5pi) * qrotation(Vec3f(0, 1, 0), 0.7pi)
    meshscatter(
        1:3, 1:3, fill(0, 3, 3),
        marker = catmesh, color = img, markersize = 1, rotation = rot,
        axis = (type = LScene, show_axis = false)
    )
end

@reference_test "Wireframe of mesh, GeoemtryPrimitive and Surface" begin
    f = Figure()

    wireframe(f[1, 1], Sphere(Point3f(0), 1.0f0))

    function xy_data(x, y)
        r = sqrt(x^2 + y^2)
        r == 0.0 ? 1.0f0 : (sin(r) / r)
    end
    N = 30
    lspace = range(-10, stop = 10, length = N)
    z = Float32[xy_data(x, y) for x in lspace, y in lspace]
    r = range(0, stop = 3, length = N)
    wireframe(f[2, 1], r, r, z)

    wireframe(f[1:2, 2], loadasset("cat.obj"))

    f
end

@reference_test "Surface with image" begin
    N = 30
    function xy_data(x, y)
        r = sqrt(x^2 + y^2)
        r == 0.0 ? 1.0f0 : (sin(r) / r)
    end
    xrange = range(-2, stop = 2, length = N)
    surf_func(i) = [Float32(xy_data(x * i, y * i)) for x in xrange, y in xrange]
    surface(
        xrange, xrange, surf_func(10),
        color = RNG.rand(RGBAf, 124, 124)
    )
end

@reference_test "Meshscatter Function" begin
    large_sphere = Sphere(Point3f(0), 1.0f0)
    positions = decompose(Point3f, large_sphere)
    colS = [RGBAf(RNG.rand(), RNG.rand(), RNG.rand(), 1.0) for i in 1:length(positions)]
    sizesS = [RNG.rand(Point3f) .* 0.05f0 for i in 1:length(positions)]
    meshscatter(positions, color = colS, markersize = sizesS)
end

@reference_test "Basic Shading" begin
    f = Figure(size = (500, 300))

    # see PR #3722
    pts = Point3f[[0, 0, 0], [1, 0, 0]]
    markersize = Vec3f[[0.5, 0.2, 0.5], [0.5, 0.2, 0.5]]
    rotation = [qrotation(Vec3f(1, 0, 0), 0), qrotation(Vec3f(1, 1, 0), π / 4)]
    meshscatter(f[1, 1], pts; markersize, rotation, color = :white, diffuse = Vec3f(-2, 0, 4), specular = Vec3f(4, 0, -2))

    mesh(f[1, 2], Sphere(Point3f(0), 1.0f0), color = :orange, shading = NoShading)

    f
end

@reference_test "Record Video" begin
    f(t, v, s) = (sin(v + t) * s, cos(v + t) * s, (cos(v + t) + sin(v)) * s)
    t = Observable(0.0) # create a life signal
    limits = Rect3f(Vec3f(-1.5, -1.5, -3), Vec3f(3, 3, 6))
    fig, ax, p1 = meshscatter(lift(t -> f.(t, range(0, stop = 2pi, length = 50), 1), t), markersize = 0.05)
    p2 = meshscatter!(ax, lift(t -> f.(t * 2.0, range(0, stop = 2pi, length = 50), 1.5), t), markersize = 0.05)

    linepoints = lift(p1[1], p2[1]) do pos1, pos2
        map((a, b) -> (a => b), pos1, pos2)
    end

    linesegments!(ax, linepoints, linestyle = :dot)

    Record(fig, 1:2; framerate = 1) do i
        t[] = i / 10
    end
end

@reference_test "3D Contour with 2D contour slices" begin
    function test(x, y, z)
        xy = [x, y, z]
        ((xy') * Matrix(I, 3, 3) * xy) / 20
    end
    x = range(-2pi, stop = 2pi, length = 100)
    # c[4] == fourth argument of the above plotting command
    fig = Figure(size = (400, 700))
    ax, c = contour(fig[1, 1], x, x, x, test, levels = 6, alpha = 0.03, colormap = [:white, :black], transparency = true)

    xm, ym, zm = minimum(data_limits(c))
    contour!(ax, x, x, map(v -> v[1, :, :], c[4]), transformation = (:xy, zm), linewidth = 2)
    heatmap!(ax, x, x, map(v -> v[:, 1, :], c[4]), transformation = (:xz, ym))
    contourf!(ax, x, x, map(v -> v[:, :, 1], c[4]), transformation = (:yz, xm))
    # reorder plots for transparency
    ax.scene.plots[:] = ax.scene.plots[[1, 3, 4, 5, 2]]

    contour(
        fig[2, 1], x, x, x, (x, y, z) -> sqrt(x * x + y * y) / (10 + z * z),
        levels = [0.01, 0.1, 0.2, 0.5, 1.0],
        colorrange = (0.1, 0.5), # this should clip 0.01 and 1.0
    )

    fig
end

@reference_test "Contour3d" begin
    function xy_data(x, y)
        r = sqrt(x * x + y * y)
        r == 0.0 ? 1.0f0 : (sin(r) / r)
    end
    r = range(-1, stop = 1, length = 100)
    contour3d(r, r, (x, y) -> xy_data(10x, 10y), levels = 20, linewidth = 3)
end

@reference_test "Arrows 3D" begin
    function SphericalToCartesian(r::T, θ::T, ϕ::T) where {T <: AbstractArray}
        x = @.r * sin(θ) * cos(ϕ)
        y = @.r * sin(θ) * sin(ϕ)
        z = @.r * cos(θ)
        Point3f.(x, y, z)
    end
    n = 100^2 # number of points to generate
    r = ones(n)
    θ = acos.(1 .- 2 .* RNG.rand(n))
    φ = 2π * RNG.rand(n)
    pts = SphericalToCartesian(r, θ, φ)
    arrows(pts, (normalize.(pts) .* 0.1f0), arrowsize = 0.02, linecolor = :green, arrowcolor = :darkblue)
end

@reference_test "Arrows 3D marker_transform" begin
    f = Figure()
    a = Axis3(f[1, 1])
    r = range(-1, 1, length = 5)
    arrows!(a, Point3f[(1, 0, 0), (0, 0, 0)], Point3f[(0, 0, 0.1), (1, 0, 0)], color = :gray)
    arrows!(a, Point3f[(-1, 1, 0), (0, 0, 0)], Point3f[(0, 0, 0.1), (-1, 1, 0)], color = :lightblue)
    arrows!(a, Point3f[(1, -1, 0), (0, 0, 0)], Point3f[(0, 0, 0.1), (1, -1, 0)], color = :yellow)
    mesh!(a, Rect2f(-1, -1, 2, 2), color = (:red, 0.5), transparency = true)
    f
end


@reference_test "Image on Surface Sphere" begin
    n = 20
    θ = [0;(0.5:(n - 0.5)) / n;1]
    φ = [(0:(2n - 2)) * 2 / (2n - 1);2]
    x = [cospi(φ) * sinpi(θ) for θ in θ, φ in φ]
    y = [sinpi(φ) * sinpi(θ) for θ in θ, φ in φ]
    z = [cospi(θ) for θ in θ, φ in φ]
    pts = vec(Point3f.(x, y, z))
    f, ax, p = surface(x, y, z, color = Makie.logo(), transparency = true)
end

@reference_test "Arrows on Sphere" begin
    n = 20
    f = (x, y, z) -> x * exp(cos(y) * z)
    ∇f = (x, y, z) -> Point3f(exp(cos(y) * z), -sin(y) * z * x * exp(cos(y) * z), x * cos(y) * exp(cos(y) * z))
    ∇ˢf = (x, y, z) -> ∇f(x, y, z) - Point3f(x, y, z) * dot(Point3f(x, y, z), ∇f(x, y, z))

    θ = [0;(0.5:(n - 0.5)) / n;1]
    φ = [(0:(2n - 2)) * 2 / (2n - 1);2]
    x = [cospi(φ) * sinpi(θ) for θ in θ, φ in φ]
    y = [sinpi(φ) * sinpi(θ) for θ in θ, φ in φ]
    z = [cospi(θ) for θ in θ, φ in φ]

    pts = vec(Point3f.(x, y, z))
    ∇ˢF = vec(∇ˢf.(x, y, z)) .* 0.1f0
    surface(x, y, z)
    arrows!(
        pts, ∇ˢF,
        arrowsize = 0.03, linecolor = (:white, 0.6), linewidth = 0.03
    )
    current_figure()
end

@reference_test "surface + contour3d" begin
    vx = -1:0.01:1
    vy = -1:0.01:1

    foo(x, y) = (sin(x * 10) + cos(y * 10)) / 4
    fig = Figure()
    ax1 = fig[1, 1] = Axis(fig, title = "surface")
    ax2 = fig[1, 2] = Axis(fig, title = "contour3d")
    surface!(ax1, vx, vy, foo)
    contour3d!(ax2, vx, vy, (x, y) -> foo(x, y), levels = 15, linewidth = 3)
    fig
end

@reference_test "colorscale (surface)" begin
    x = y = range(-1, 1; length = 20)
    foo(x, y) = exp(-(x^2 + y^2)^2)
    fig = Figure()
    surface(fig[1, 1], x, y, foo; colorscale = identity)
    surface(fig[1, 2], x, y, foo; colorscale = log10)
    fig
end

@reference_test "colorscale (poly)" begin
    X = [0.0 1 1 2; 1 1 2 2; 0 0 1 1]
    Y = [1.0 1 1 1; 1 0 1 0; 0 0 0 0]
    Z = [1.0 1 1 1; 1 0 1 0; 0 0 0 0]
    C = [0.5 1.0 1.0 0.5; 1.0 0.5 0.5 0.1667; 0.333 0.333 0.5 0.5] .^ 3

    vertices = connect(reshape([X[:] Y[:] Z[:]]', :), Point3f)
    indices = connect(1:length(X), TriangleFace)

    fig = Figure()
    poly!(Axis3(fig[1, 1]), vertices, indices; color = C[:], colorscale = identity)
    poly!(Axis3(fig[1, 2]), vertices, indices; color = C[:], colorscale = log10)
    fig
end

@reference_test "OldAxis + Surface" begin
    vx = -1:0.01:1
    vy = -1:0.01:1

    fff(x, y) = (sin(x * 10) + cos(y * 10)) / 4
    scene = Scene(size = (500, 500), camera = cam3d!)
    # One way to style the axis is to pass a nested dictionary / named tuple to it.
    psurf = surface!(scene, vx, vy, fff)
    axis3d!(scene, frame = (linewidth = 2.0,))
    center!(scene)
    # One can also directly get the axis object and manipulate it
    axis = scene[OldAxis] # get axis

    # You can access nested attributes likes this:
    axis[:names, :axisnames] = ("\\bf{ℜ}[u]", "\\bf{𝕴}[u]", " OK\n\\bf{δ}\n γ")
    tstyle = axis[:names][] # or just get the nested attributes and work directly with them

    tstyle[:fontsize] = 10
    tstyle[:textcolor] = (:red, :green, :black)
    tstyle[:font] = "helvetica"

    psurf[:colormap] = :RdYlBu
    wh = widths(scene)
    t = text!(
        campixel(scene),
        "Multipole Representation of first resonances of U-238",
        position = (wh[1] / 2.0, wh[2] - 20.0),
        align = (:center, :center),
        fontsize = 20,
        font = "helvetica"
    )
    psurf.arg3 = fff.(vx .+ 0.5, (vy .+ 0.5)')
    scene
end

@reference_test "Fluctuation 3D" begin
    # define points/edges
    perturbfactor = 4.0e1
    N = 3; nbfacese = 30; radius = 0.02

    large_sphere = Sphere(Point3f(0), 1.0f0)
    positions = decompose(Point3f, Tessellation(large_sphere, 30))
    np = length(positions)
    pts = [positions[k][l] for k in 1:length(positions), l in 1:3]
    pts = vcat(pts, 1.1 .* pts + RNG.randn(size(pts)) / perturbfactor) # light position influence ?
    edges = hcat(collect(1:np), collect(1:np) .+ np)
    ne = size(edges, 1); np = size(pts, 1)
    cylinder = Cylinder(Point3f(0), Point3f(0, 0, 1.0), 1.0f0)
    # define markers meshes
    meshC = normal_mesh(Tessellation(cylinder, nbfacese))
    meshS = normal_mesh(Tessellation(large_sphere, 20))
    # define colors, markersizes and rotations
    pG = [Point3f(pts[k, 1], pts[k, 2], pts[k, 3]) for k in 1:np]
    lengthsC = sqrt.(sum((pts[edges[:, 1], :] .- pts[edges[:, 2], :]) .^ 2, dims = 2))
    sizesC = [Vec3f(radius, radius, lengthsC[i]) for i in 1:ne]
    sizesC = [Vec3f(1) for i in 1:ne]
    colorsp = [RGBA{Float32}(RNG.rand(), RNG.rand(), RNG.rand(), 1.0) for i in 1:np]
    colorsC = [(colorsp[edges[i, 1]] .+ colorsp[edges[i, 2]]) / 2.0 for i in 1:ne]
    sizesC = [Vec3f(radius, radius, lengthsC[i]) for i in 1:ne]
    Qlist = zeros(ne, 4)
    for k in 1:ne
        ct = Cylinder(
            Point3f(pts[edges[k, 1], 1], pts[edges[k, 1], 2], pts[edges[k, 1], 3]),
            Point3f(pts[edges[k, 2], 1], pts[edges[k, 2], 2], pts[edges[k, 2], 3]),
            1.0f0
        )
        Q = GeometryBasics.rotation(ct)
        r = 0.5 * sqrt(1 .+ Q[1, 1] .+ Q[2, 2] .+ Q[3, 3]); Qlist[k, 4] = r
        Qlist[k, 1] = (Q[3, 2] .- Q[2, 3]) / (4 .* r)
        Qlist[k, 2] = (Q[1, 3] .- Q[3, 1]) / (4 .* r)
        Qlist[k, 3] = (Q[2, 1] .- Q[1, 2]) / (4 .* r)
    end

    rotationsC = [Vec4f(Qlist[i, 1], Qlist[i, 2], Qlist[i, 3], Qlist[i, 4]) for i in 1:ne]
    # plot
    fig, ax, meshplot = meshscatter(
        pG[edges[:, 1]],
        color = colorsC, marker = meshC,
        markersize = sizesC, rotation = rotationsC,
    )
    meshscatter!(
        ax, pG,
        color = colorsp, marker = meshS, markersize = radius,
    )
    fig
end

@reference_test "Connected Sphere" begin
    large_sphere = Sphere(Point3f(0), 1.0f0)
    positions = decompose(Point3f, large_sphere)
    linepos = view(positions, RNG.rand(1:length(positions), 1000))
    fig, ax, lineplot = lines(linepos, linewidth = 0.1, color = :black, transparency = true)
    scatter!(
        ax, positions, markersize = 10,
        strokewidth = 2, strokecolor = :white,
        color = RGBAf(0.9, 0.2, 0.4, 0.3), transparency = true,
    )
    fig
end

@reference_test "image scatter" begin
    scatter(
        1:10, 1:10, RNG.rand(10, 10) .* 10,
        rotation = normalize.(RNG.rand(Quaternionf, 10 * 10)),
        markersize = 20,
        # can also be an array of images for each point
        # need to be the same size for best performance, though
        marker = Makie.logo()
    )
end

@reference_test "Simple meshscatter" begin
    large_sphere = Sphere(Point3f(0), 1.0f0)
    positions = decompose(Point3f, large_sphere)
    meshscatter(positions, color = RGBAf(0.9, 0.2, 0.4, 1), markersize = 0.05)
end

@reference_test "Animated surface and wireframe" begin
    function xy_data(x, y)
        r = sqrt(x^2 + y^2)
        r == 0.0 ? 1.0f0 : (sin(r) / r)
    end

    xrange = range(-2, stop = 2, length = 50)
    surf_func(i) = [Float32(xy_data(x * i, y * i)) for x in xrange, y in xrange]
    z = surf_func(20)
    fig, ax, surf = surface(xrange, xrange, z)

    wf = wireframe!(
        ax, xrange, xrange, lift(x -> x .+ 1.0, surf[3]),
        linewidth = 2.0f0, color = lift(x -> to_colormap(x)[5], surf[:colormap])
    )
    Record(fig, range(5, stop = 40, length = 3); framerate = 1) do i
        surf[3] = surf_func(i)
    end
end

@reference_test "Normals of a Cat" begin
    x = GeometryBasics.expand_faceviews(loadasset("cat.obj"))
    f, a, p = mesh(x, color = :black)
    pos = map(decompose(Point3f, x), GeometryBasics.normals(x)) do p, n
        p => p .+ Point(normalize(n) .* 0.05f0)
    end
    linesegments!(pos, color = :blue)
    Makie.update_state_before_display!(f)
    f
end

@reference_test "Sphere Mesh" begin
    mesh(Sphere(Point3f(0), 1.0f0), color = :blue)
end

@reference_test "Unicode Marker" begin
    scatter(
        Point3f[(1, 0, 0), (0, 1, 0), (0, 0, 1)], marker = [:x, :circle, :cross],
        markersize = 35
    )
end

@reference_test "Merged color Mesh" begin
    function colormesh((geometry, color))
        mesh1 = normal_mesh(geometry)
        npoints = length(GeometryBasics.coordinates(mesh1))
        return GeometryBasics.mesh(mesh1; color = fill(color, npoints))
    end
    # create an array of differently colored boxes in the direction of the 3 axes
    x = Vec3f(0); baselen = 0.2f0; dirlen = 1.0f0
    rectangles = [
        (Rect(Vec3f(x), Vec3f(dirlen, baselen, baselen)), RGBAf(1, 0, 0, 1)),
        (Rect(Vec3f(x), Vec3f(baselen, dirlen, baselen)), RGBAf(0, 1, 0, 1)),
        (Rect(Vec3f(x), Vec3f(baselen, baselen, dirlen)), RGBAf(0, 0, 1, 1)),
    ]

    meshes = map(colormesh, rectangles)
    mesh(merge(meshes))
end

@reference_test "Line GIF" begin
    us = range(0, stop = 1, length = 100)
    f, ax, p = linesegments(Rect3f(Vec3f(0, -1, 0), Vec3f(1, 2, 2)); color = :black)
    p = lines!(ax, us, sin.(us), zeros(100), linewidth = 3, transparency = true, color = :black)
    lineplots = [p]
    Makie.translate!(p, 0, 0, 0)
    colors = to_colormap(:RdYlBu)
    N = 5
    Record(f, 1:N; framerate = 1) do i
        t = i / (N / 5)
        if length(lineplots) < 20
            p = lines!(
                ax,
                us, sin.(us .+ t), zeros(100),
                color = colors[length(lineplots)],
                linewidth = 3
            )
            pushfirst!(lineplots, p)
            translate!(p, 0, 0, 0)
        else
            lineplots = circshift(lineplots, 1)
            lp = first(lineplots)
            lp[2] = sin.(us .+ t)
            translate!(lp, 0, 0, 0)
        end
        for lp in Iterators.drop(lineplots, 1)
            z = translation(lp)[][3]
            translate!(lp, 0, 0, z + 0.1)
        end
    end
end

@reference_test "Surface + wireframe + contour" begin
    N = 51
    x = range(-2, stop = 2, length = N)
    y = x
    z = (-x .* exp.(-x .^ 2 .- (y') .^ 2)) .* 4
    fig, ax, surfaceplot = surface(x, y, z)
    xm, ym, zm = minimum(data_limits(ax.scene))
    contour!(ax, x, y, z, levels = 15, linewidth = 2, transformation = (:xy, zm))
    wireframe!(ax, x, y, z, transparency = true, color = (:black, 0.1))
    center!(ax.scene) # center the Scene on the display
    fig
end

let
    struct FitzhughNagumo{T}
        ϵ::T
        s::T
        γ::T
        β::T
    end

    @reference_test "Streamplot 3D" begin
        P = FitzhughNagumo(0.1, 0.0, 1.5, 0.8)
        f(x, P::FitzhughNagumo) = Point3f(
            (x[1] - x[2] - x[1]^3 + P.s) / P.ϵ,
            P.γ * x[2] - x[2] + P.β,
            P.γ * x[1] - x[3] - P.β,
        )
        f(x) = f(x, P)
        streamplot(f, -1.5 .. 1.5, -1.5 .. 1.5, -1.5 .. 1.5, colormap = :magma, gridsize = (10, 10), arrow_size = 0.1, transparency = true)
    end
end

@reference_test "Depth Shift" begin
    # Up to some artifacts from fxaa the left side should be blue and the right red.
    fig = Figure(size = (800, 400))

    prim = Rect3(Point3f(0), Vec3f(1))
    ps = RNG.rand(Point3f, 10) .+ Point3f(0, 0, 1)
    mat = RNG.rand(4, 4)
    A = RNG.rand(4, 4, 4)

    # This generates two sets of plots each on two axis. Both axes have one set
    # without depth_shift (0f0, red) and one at ∓10eps(1f0) (blue, left/right axis).
    # A negative shift should push the plot in the foreground, positive in the background.
    for (i, _shift) in enumerate((-10eps(1.0f0), 10eps(1.0f0)))
        ax = LScene(fig[1, i], show_axis = false)

        for (color, shift) in zip((:red, :blue), (0.0f0, _shift))
            mesh!(ax, prim, color = color, depth_shift = shift)
            lines!(ax, ps, color = color, depth_shift = shift)
            linesegments!(ax, ps .+ Point3f(-1, 1, 0), color = color, depth_shift = shift)
            scatter!(ax, ps, color = color, markersize = 10, depth_shift = shift)
            text!(ax, 0, 1, 1.1, text = "Test", color = color, depth_shift = shift)
            surface!(ax, -1 .. 0, 1 .. 2, mat, colormap = [color, color], depth_shift = shift)
            meshscatter!(ax, ps .+ Point3f(-1, 1, 0), color = color, depth_shift = shift)
            # # left side in axis
            heatmap!(ax, 0 .. 1, 0 .. 1, mat, colormap = [color, color], depth_shift = shift)
            # # right side in axis
            image!(ax, -1 .. 0, 1 .. 2, mat, colormap = [color, color], depth_shift = shift)
            p = volume!(ax, A, colormap = [:white, color], depth_shift = shift)
            translate!(p, -1, 0, 0)
            scale!(p, 0.25, 0.25, 0.25)
        end

        center!(ax.scene)
    end
    fig
end


@reference_test "Order Independent Transparency" begin
    # top row (yellow, cyan, magenta) contains stacks with the same alpha value
    # bottom row (red, green, blue) contains stacks with varying alpha values
    fig = Figure()
    ax = LScene(fig[1, 1])
    r = Rect2f(-1, -1, 2, 2)
    for x in (0, 1)
        for (i, a) in enumerate((0.25, 0.5, 0.75, 1.0))
            ps = [Point3f(a, (0.15 + 0.01y) * (2x - 1), 0.2y) for y in 1:8]
            if x == 0
                cs = [RGBAf(1, 0, 0, 0.75), RGBAf(0, 1, 0, 0.5), RGBAf(0, 0, 1, 0.25)]
            elseif x == 1
                cs = [RGBAf(1, x, 0, a), RGBAf(0, 1, x, a), RGBAf(x, 0, 1, a)]
            end
            idxs = [1, 2, 3, 2, 1, 3, 1, 2, 1, 2, 3][i:(7 + i)]
            meshscatter!(
                ax, ps, marker = r,
                color = cs[idxs], transparency = true
            )
        end
    end
    cam = cameracontrols(ax.scene)
    cam.fov[] = 22.0f0
    update_cam!(ax.scene, cam, Vec3f(0.625, 0, 3.5), Vec3f(0.625, 0, 0), Vec3f(0, 1, 0))
    cameracontrols(ax).settings.center[] = false # avoid recenter on display
    fig
end


@reference_test "space 3D" begin
    fig = Figure()
    for ax in [LScene(fig[1, 1]), Axis3(fig[1, 2])]
        mesh!(ax, Rect3(Point3f(-10), Vec3f(20)), color = :orange)
        mesh!(ax, Rect2f(0.8, 0.1, 0.1, 0.8), space = :relative, color = :blue, shading = NoShading)
        linesegments!(ax, Rect2f(-0.5, -0.5, 1, 1), space = :clip, color = :cyan, linewidth = 5)
        text!(ax, 0, 0.52, text = "Clip Space", align = (:center, :bottom), space = :clip)
        image!(ax, 0 .. 40, 0 .. 800, [x for x in range(0, 1, length = 40), _ in 1:10], space = :pixel)
    end
    fig
end

# TODO: get 3D images working in CairoMakie and test them here too
@reference_test "Heatmap 3D" begin
    heatmap(-2 .. 2, -1 .. 1, RNG.rand(100, 100); axis = (; type = LScene))
end

# Clip Planes
@reference_test "Clip planes - general" begin
    # Test
    # - inheritance of clip planes from scene and parent plot (wireframe)
    # - test clipping of linesegments, mesh, surface, scatter, image, heatmap
    f = Figure()
    a = LScene(f[1, 1])
    a.scene.theme[:clip_planes][] = Makie.planes(Rect3f(Point3f(-0.75), Vec3f(1.5)))
    linesegments!(
        a, Rect3f(Point3f(-0.75), Vec3f(1.5)), clip_planes = Plane3f[],
        fxaa = true, transparency = false, linewidth = 3
    )

    p = mesh!(Sphere(Point3f(0, 0, 1), 1.0f0), transparency = false, color = :orange, backlight = 1.0)
    wireframe!(p[1][], fxaa = true, color = :cyan)
    r = range(-pi, pi, length = 101)
    surface!(-pi .. pi, -pi .. pi, [sin(-x - y) for x in r, y in r], transparency = false)
    scatter!(-1.4:0.1:2, 2:-0.1:-1.4, color = :red)
    p = heatmap!(-2 .. 2, -2 .. 2, [sin(x + y) for x in r, y in r], colormap = [:purple, :pink])
    translate!(p, 0, 0, -0.666)
    p = image!(-2 .. 2, -2 .. 2, [cos(x + y) for x in r, y in r], colormap = [:red, :orange])
    translate!(p, 0, 0, -0.333)
    text!(-1:0.2:1, 1:-0.2:-1, text = ["█" for i in -1:0.2:1], color = :purple)
    f
end

@reference_test "Clip planes - lines" begin
    # red vs green matters here, not light vs dark
    plane = Plane3f(normalize(Vec3f(1)), 0)

    f, a, p = mesh(
        Makie.to_mesh(plane, scale = 1.5), color = (:black, 0.5),
        transparency = true, visible = true
    )

    cam3d!(a.scene, center = false)

    attr = (color = :red, linewidth = 5, fxaa = true)
    linesegments!(a, Rect3f(Point3f(-1), Vec3f(2)); attr...)
    lines!(a, [Point3f(cos(x), sin(x), 0) for x in range(0, 2pi, length = 101)]; attr...)
    lines!(a, [Point3f(cos(x), sin(x), 0) for x in 1:4:80]; attr...)
    lines!(a, [Point3f(-1), Point3f(1)]; attr...)

    attr = (color = RGBf(0, 1, 0), overdraw = true, clip_planes = [plane], linewidth = 5, fxaa = true)
    linesegments!(a, Rect3f(Point3f(-1), Vec3f(2)), ; attr...)
    lines!(a, [Point3f(cos(x), sin(x), 0) for x in range(0, 2pi, length = 101)]; attr...)
    lines!(a, [Point3f(cos(x), sin(x), 0) for x in 1:4:80]; attr...)
    lines!(a, [Point3f(-1), Point3f(1)]; attr...)

    lines!(a, [Point3f(1, -1, 0), Point3f(-1, 1, 0)], color = :black, overdraw = true)

    update_cam!(a.scene, Vec3f(1.5, 4, 2), Vec3f(0))
    f
end

@reference_test "Clip planes - voxel" begin
    f = Figure()
    a = LScene(f[1, 1])
    a.scene.theme[:clip_planes][] = [Plane3f(Vec3f(-2, -1, -0.5), 0.1), Plane3f(Vec3f(-0.5, -1, -2), 0.1)]
    r = -10:10
    p = voxels!(a, [cos(sin(x + y) + z) for x in r, y in r, z in r])
    f
end

@reference_test "Clip planes - volume" begin
    f = Figure(size = (600, 400), backgroundcolor = :black)
    r = -10:10
    data = [1 - (1 + cos(x^2) + cos(y^2) + cos(z^2)) for x in r, y in r, z in r]
    index_data = round.(Int, 10 .* abs.(data))
    N = maximum(index_data)
    density_data = 0.005 .* abs.(data)
    rgba_data = [RGBAf(cos(x^2)^2, cos(y^2)^2, cos(z^2)^2, 0.5 + 0.5 * sin(x^2 + y^2 + z^2)) for x in r, y in r, z in r]

    clip_planes = [Plane3f(Vec3f(-1), 0.0)]
    attr = (clip_planes = clip_planes, axis = (show_axis = false,))

    volume(
        f[1, 1], -10 .. 10, -10 .. 10, -10 .. 10, data; attr...,
        algorithm = :iso, isovalue = 1.0, isorange = 0.1
    )
    volume(
        f[2, 1], -10 .. 10, -10 .. 10, -10 .. 10, data; attr...,
        algorithm = :absorption
    )

    volume(
        f[1, 2], -10 .. 10, -10 .. 10, -10 .. 10, data; attr...,
        algorithm = :mip
    )
    volume(
        f[2, 2], -10 .. 10, -10 .. 10, -10 .. 10, rgba_data; attr...,
        algorithm = :absorptionrgba
    )

    # TODO: doesn't work as intended anymore?
    volume(
        f[1, 3], -10 .. 10, -10 .. 10, -10 .. 10, rgba_data; attr...,
        algorithm = :additive, alpha = 0.01
    )
    volume(
        f[2, 3], -10 .. 10, -10 .. 10, -10 .. 10, index_data; attr...,
        algorithm = :indexedabsorption, colormap = Makie.resample(to_colormap(:viridis), N)
    )

    f
end

@reference_test "Clip planes - only data space" begin
    f = Figure()
    a = LScene(f[1, 1])
    a.scene.theme[:clip_planes][] = [Plane3f(Vec3f(-1, 0, 0), 0), Plane3f(Vec3f(-1, 0, 0), -100)]

    # verify that clipping is working
    wireframe!(a, Rect3f(Point3f(-1), Vec3f(2)), color = :green, linewidth = 5)

    # verify that space != :data is excluded
    lines!(a, -1 .. 1, sin, space = :clip, color = :gray, linewidth = 5)
    linesegments!(a, [100, 200, 300, 400], [100, 100, 100, 100], space = :pixel, color = :gray, linewidth = 5)
    scatter!(a, [0.2, 0.8], [0.4, 0.6], space = :relative, color = :gray, markersize = 20)
    f
end

@reference_test "Surface interpolate attribute" begin
    f, ls1, pl = surface(Makie.peaks(20); interpolate = true, axis = (; show_axis = false))
    ls2, pl = surface(f[1, 2], Makie.peaks(20); interpolate = false, axis = (; show_axis = false))
    f
end

@reference_test "volumeslices" begin
    r = range(-1, 1, length = 10)
    data = RNG.rand(10, 10, 10)

    fig = Figure()
    volumeslices(fig[1, 1], r, r, r, data)
    a, p = volumeslices(
        fig[1, 2], r, r, r, data, bbox_visible = false, colormap = :RdBu,
        colorrange = (0.2, 0.8), lowclip = :black, highclip = :green
    )
    p.update_xz[](3)
    p.update_yz[](4)
    p.update_xy[](10)
    fig
end

@reference_test "MetaMesh (Sponza)" begin
    m = load(Makie.assetpath("sponza/sponza.obj"), uvtype = Vec2f)
    f, a, p = mesh(m)
    cameracontrols(a).settings.center[] = false
    cameracontrols(a).settings.fixed_axis[] = false # irrelevant here
    update_cam!(a.scene, Vec3f(-15, 7, 1), Vec3f(3, 5, 0), Vec3f(0, 1, 0))
    f
end

@reference_test "Mesh with 3d volume texture" begin
    triangles = GLTriangleFace[(1, 2, 3), (3, 4, 1)]
    uv3_mesh(p) = GeometryBasics.Mesh(p, triangles; uv = Vec3f.(p))
    r = -5:0.1:5
    data = [1 - (1 + cos(x) + cos(y^2) + cos(z)) for x in r, y in r, z in r]
    # Define the positions
    positions = [Point3f(0.5, 0, 0), Point3f(0.5, 1, 0), Point3f(0.5, 1, 1), Point3f(0.5, 0, 1)]
    # Pass the volume plot to the color
    f, ax, pl = mesh(uv3_mesh(positions), color = data, shading = NoShading, axis = (; show_axis = false))
    positions = [Point3f(0.0, 0.5, 0), Point3f(1.0, 0.5, 0), Point3f(1, 0.5, 1), Point3f(0.0, 0.5, 1)]
    mesh!(ax, uv3_mesh(positions); color = data, shading = NoShading)
    f
end

@reference_test "Transformed 3D Arrows" begin
    ps = [Point2f(i, 2^i) for i in 1:10]
    vs = [Vec2f(1, 100) for _ in 1:10]
    f, a, p = arrows3d(ps, vs, markerscale = 1, tiplength = 30, color = log10.(norm.(ps)), colormap = :RdBu)
    arrows3d(f[1, 2], ps, vs, markerscale = 1, color = log10.(norm.(ps)), axis = (yscale = log10,))

    ps = coordinates(Rect3f(-1, -1, -1, 2, 2, 2))
    a, p = arrows3d(f[2, 1], ps, ps)
    meshscatter!(a, Point3f(0), markersize = 1, marker = Rect3f(-0.5, -0.5, -0.5, 1, 1, 1))
    translate!(p, 0, 0, 1)

    a, p = arrows3d(f[2, 2], ps, ps)
    meshscatter!(a, Point3f(0), markersize = 1, marker = Rect3f(-0.5, -0.5, -0.5, 1, 1, 1))
    scale!(p, 1.0 / sqrt(2), 1.0 / sqrt(2), 1.0 / sqrt(2))
    Makie.rotate!(p, Vec3f(0, 0, 1), pi / 4)

    startpoints = Makie.apply_transform_and_model(p, ps)
    endpoints = Makie.apply_transform_and_model(p, ps + ps)
    meshscatter!(a, startpoints, color = :red)
    meshscatter!(a, endpoints, color = :red)

    f
end
