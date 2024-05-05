
@reference_test "Image on Geometry (Moon)" begin
    moon = loadasset("moon.png")
    fig, ax, meshplot = mesh(Sphere(Point3f(0), 1f0), color=moon, shading=NoShading, axis = (;show_axis=false))
    update_cam!(ax.scene, Vec3f(-2, 2, 2), Vec3f(0))
    cameracontrols(ax).settings.center[] = false # avoid recenter on display
    fig
end

@reference_test "Image on Geometry (Earth)" begin
    earth = loadasset("earth.png")
    m = uv_mesh(Tesselation(Sphere(Point3f(0), 1f0), 60))
    mesh(m, color=earth, shading=NoShading)
end

@reference_test "Orthographic Camera" begin
    function colormesh((geometry, color))
        mesh1 = normal_mesh(geometry)
        npoints = length(GeometryBasics.coordinates(mesh1))
        return GeometryBasics.pointmeta(mesh1; color=fill(color, npoints))
    end
    # create an array of differently colored boxes in the direction of the 3 axes
    x = Vec3f(0); baselen = 0.2f0; dirlen = 1f0
    rectangles = [
        (Rect(Vec3f(x), Vec3f(dirlen, baselen, baselen)), RGBAf(1, 0, 0, 1)),
        (Rect(Vec3f(x), Vec3f(baselen, dirlen, baselen)), RGBAf(0, 1, 0, 1)),
        (Rect(Vec3f(x), Vec3f(baselen, baselen, dirlen)), RGBAf(0, 0, 1, 1))
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

@reference_test "Volume Function" begin
    volume(RNG.rand(32, 32, 32), algorithm=:mip)
end

@reference_test "Textured Mesh" begin
    catmesh = loadasset("cat.obj")
    mesh(catmesh, color=loadasset("diffusemap.png"))
end

@reference_test "Textured meshscatter" begin
    catmesh = loadasset("cat.obj")
    img = loadasset("diffusemap.png")
    rot = qrotation(Vec3f(1, 0, 0), 0.5pi) * qrotation(Vec3f(0, 1, 0), 0.7pi)
    meshscatter(
        1:3, 1:3, fill(0, 3, 3),
        marker=catmesh, color=img, markersize=1, rotations=rot,
        axis=(type=LScene, show_axis=false)
    )
end

@reference_test "Load Mesh" begin
    mesh(loadasset("cat.obj"); color=:black)
end

@reference_test "Colored Mesh" begin
    x = [0, 1, 2, 0]
    y = [0, 0, 1, 2]
    z = [0, 2, 0, 1]
    color = [:red, :green, :blue, :yellow]
    i = [0, 0, 0, 1]
    j = [1, 2, 3, 2]
    k = [2, 3, 1, 3]
    # indices interpreted as triangles (every 3 sequential indices)
    indices = [1, 2, 3,   1, 3, 4,   1, 4, 2,   2, 3, 4]
    mesh(x, y, z, indices, color=color)
end

@reference_test "Wireframe of a Mesh" begin
    wireframe(loadasset("cat.obj"))
end

@reference_test "Wireframe of Sphere" begin
    wireframe(Sphere(Point3f(0), 1f0))
end

@reference_test "Wireframe of a Surface" begin
    function xy_data(x, y)
        r = sqrt(x^2 + y^2)
        r == 0.0 ? 1f0 : (sin(r) / r)
    end
    N = 30
    lspace = range(-10, stop=10, length=N)
    z = Float32[xy_data(x, y) for x in lspace, y in lspace]
    r = range(0, stop=3, length=N)
    wireframe(r, r, z)
end

@reference_test "Surface with image" begin
    N = 30
    function xy_data(x, y)
        r = sqrt(x^2 + y^2)
        r == 0.0 ? 1f0 : (sin(r) / r)
    end
    xrange = range(-2, stop=2, length=N)
    surf_func(i) = [Float32(xy_data(x * i, y * i)) for x = xrange, y = xrange]
    surface(
        xrange, xrange, surf_func(10),
        color=RNG.rand(RGBAf, 124, 124)
    )
end

@reference_test "Meshscatter Function" begin
    large_sphere = Sphere(Point3f(0), 1f0)
    positions = decompose(Point3f, large_sphere)
    colS = [RGBAf(RNG.rand(), RNG.rand(), RNG.rand(), 1.0) for i = 1:length(positions)]
    sizesS = [RNG.rand(Point3f) .* 0.05f0 for i = 1:length(positions)]
    meshscatter(positions, color=colS, markersize=sizesS)
end

@reference_test "scatter" begin
    scatter(RNG.rand(20), RNG.rand(20), markersize=10)
end

@reference_test "Marker sizes" begin
    colors = Makie.resample(to_colormap(:Spectral), 20)
    scatter(RNG.rand(20), RNG.rand(20), markersize=RNG.rand(20) .* 20, color=colors)
end

@reference_test "Ellipsoid marker sizes" begin # see PR #3722
    pts = Point3f[[0, 0, 0], [1, 0, 0]]
    markersize = Vec3f[[0.5, 0.2, 0.5], [0.5, 0.2, 0.5]]
    rotations = [qrotation(Vec3f(1, 0, 0), 0), qrotation(Vec3f(1, 1, 0), π / 4)]
    meshscatter(pts; markersize, rotations, color=:white, diffuse=Vec3f(-2, 0, 4), specular=Vec3f(4, 0, -2))
end

@reference_test "Record Video" begin
    f(t, v, s) = (sin(v + t) * s, cos(v + t) * s, (cos(v + t) + sin(v)) * s)
    t = Observable(0.0) # create a life signal
    limits = Rect3f(Vec3f(-1.5, -1.5, -3), Vec3f(3, 3, 6))
    fig, ax, p1 = meshscatter(lift(t -> f.(t, range(0, stop=2pi, length=50), 1), t), markersize=0.05)
    p2 = meshscatter!(ax, lift(t -> f.(t * 2.0, range(0, stop=2pi, length=50), 1.5), t), markersize=0.05)

    linepoints = lift(p1[1], p2[1]) do pos1, pos2
        map((a, b) -> (a => b), pos1, pos2)
    end

    linesegments!(ax, linepoints, linestyle=:dot)

    Record(fig, 1:2; framerate=1) do i
        t[] = i / 10
    end
end

@reference_test "3D Contour with 2D contour slices" begin
    function test(x, y, z)
        xy = [x, y, z]
        ((xy') * Matrix(I, 3, 3) * xy) / 20
    end
    x = range(-2pi, stop=2pi, length=100)
    # c[4] == fourth argument of the above plotting command
    fig, ax, c = contour(x, x, x, test, levels=6, alpha=0.3, transparency=true)

    xm, ym, zm = minimum(data_limits(c))
    contour!(ax, x, x, map(v -> v[1, :, :], c[4]), transformation=(:xy, zm), linewidth=2)
    heatmap!(ax, x, x, map(v -> v[:, 1, :], c[4]), transformation=(:xz, ym))
    contourf!(ax, x, x, map(v -> v[:, :, 1], c[4]), transformation=(:yz, xm))
    # reorder plots for transparency
    ax.scene.plots[:] = ax.scene.plots[[1, 3, 4, 5, 2]]
    fig
end

@reference_test "Contour3d" begin
    function xy_data(x, y)
        r = sqrt(x * x + y * y)
        r == 0.0 ? 1f0 : (sin(r) / r)
    end
    r = range(-1, stop=1, length=100)
    contour3d(r, r, (x, y) -> xy_data(10x, 10y), levels=20, linewidth=3)
end

@reference_test "Arrows 3D" begin
    function SphericalToCartesian(r::T, θ::T, ϕ::T) where T <: AbstractArray
        x = @.r * sin(θ) * cos(ϕ)
        y = @.r * sin(θ) * sin(ϕ)
        z = @.r * cos(θ)
        Point3f.(x, y, z)
    end
    n = 100^2 # number of points to generate
    r = ones(n);
    θ = acos.(1 .- 2 .* RNG.rand(n))
    φ = 2π * RNG.rand(n)
    pts = SphericalToCartesian(r, θ, φ)
    arrows(pts, (normalize.(pts) .* 0.1f0), arrowsize=0.02, linecolor=:green, arrowcolor=:darkblue)
end

@reference_test "Image on Surface Sphere" begin
    n = 20
    θ = [0;(0.5:n - 0.5) / n;1]
    φ = [(0:2n - 2) * 2 / (2n - 1);2]
    x = [cospi(φ) * sinpi(θ) for θ in θ, φ in φ]
    y = [sinpi(φ) * sinpi(θ) for θ in θ, φ in φ]
    z = [cospi(θ) for θ in θ, φ in φ]
    pts = vec(Point3f.(x, y, z))
    f, ax, p = surface(x, y, z, color=Makie.logo(), transparency=true)
end

@reference_test "Arrows on Sphere" begin
    n = 20
    f   = (x, y, z) -> x * exp(cos(y) * z)
    ∇f  = (x, y, z) -> Point3f(exp(cos(y) * z), -sin(y) * z * x * exp(cos(y) * z), x * cos(y) * exp(cos(y) * z))
    ∇ˢf = (x, y, z) -> ∇f(x, y, z) - Point3f(x, y, z) * dot(Point3f(x, y, z), ∇f(x, y, z))

    θ = [0;(0.5:n - 0.5) / n;1]
    φ = [(0:2n - 2) * 2 / (2n - 1);2]
    x = [cospi(φ) * sinpi(θ) for θ in θ, φ in φ]
    y = [sinpi(φ) * sinpi(θ) for θ in θ, φ in φ]
    z = [cospi(θ) for θ in θ, φ in φ]

    pts = vec(Point3f.(x, y, z))
    ∇ˢF = vec(∇ˢf.(x, y, z)) .* 0.1f0
    surface(x, y, z)
    arrows!(
        pts, ∇ˢF,
        arrowsize=0.03, linecolor=(:white, 0.6), linewidth=0.03
    )
    current_figure()
end

@reference_test "surface + contour3d" begin
    vx = -1:0.01:1
    vy = -1:0.01:1

    f(x, y) = (sin(x * 10) + cos(y * 10)) / 4
    fig = Figure()
    ax1 = fig[1, 1] = Axis(fig, title = "surface")
    ax2 = fig[1, 2] = Axis(fig, title = "contour3d")
    surface!(ax1, vx, vy, f)
    contour3d!(ax2, vx, vy, (x, y) -> f(x, y), levels=15, linewidth=3)
    fig
end

@reference_test "colorscale (surface)" begin
    x = y = range(-1, 1; length = 20)
    f(x, y) = exp(-(x^2 + y^2)^2)
    fig = Figure()
    surface(fig[1, 1], x, y, f; colorscale = identity)
    surface(fig[1, 2], x, y, f; colorscale = log10)
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
    poly!(Axis3(fig[1, 1]), vertices, indices; color=C[:], colorscale=identity)
    poly!(Axis3(fig[1, 2]), vertices, indices; color=C[:], colorscale=log10)
    fig
end

@reference_test "FEM mesh 3D" begin
    cat = loadasset("cat.obj")
    vertices = decompose(Point3f, cat)
    faces = decompose(TriangleFace{Int}, cat)
    coordinates = [vertices[i][j] for i = 1:length(vertices), j = 1:3]
    connectivity = [faces[i][j] for i = 1:length(faces), j = 1:3]
    mesh(
        coordinates, connectivity,
        color=RNG.rand(length(vertices))
    )
end

@reference_test "OldAxis + Surface" begin
    vx = -1:0.01:1
    vy = -1:0.01:1

    f(x, y) = (sin(x * 10) + cos(y * 10)) / 4
    scene = Scene(size=(500, 500), camera=cam3d!)
    # One way to style the axis is to pass a nested dictionary / named tuple to it.
    psurf = surface!(scene, vx, vy, f)
    axis3d!(scene, frame = (linewidth = 2.0,))
    center!(scene)
    # One can also directly get the axis object and manipulate it
    axis = scene[OldAxis] # get axis

    # You can access nested attributes likes this:
    axis[:names, :axisnames] = ("\\bf{ℜ}[u]", "\\bf{𝕴}[u]", " OK\n\\bf{δ}\n γ")
    tstyle = axis[:names] # or just get the nested attributes and work directly with them

    tstyle[:fontsize] = 10
    tstyle[:textcolor] = (:red, :green, :black)
    tstyle[:font] = "helvetica"

    psurf[:colormap] = :RdYlBu
    wh = widths(scene)
    t = text!(
        campixel(scene),
        "Multipole Representation of first resonances of U-238",
        position=(wh[1] / 2.0, wh[2] - 20.0),
        align=(:center,  :center),
        fontsize=20,
        font="helvetica"
    )
    psurf.converted[3][] = f.(vx .+ 0.5, (vy .+ 0.5)')
    scene
end

@reference_test "Fluctuation 3D" begin
    # define points/edges
    perturbfactor = 4e1
    N = 3; nbfacese = 30; radius = 0.02

    large_sphere = Sphere(Point3f(0), 1f0)
    positions = decompose(Point3f, large_sphere, 30)
    np = length(positions)
    pts = [positions[k][l] for k = 1:length(positions), l = 1:3]
    pts = vcat(pts, 1.1 .* pts + RNG.randn(size(pts)) / perturbfactor) # light position influence ?
    edges = hcat(collect(1:np), collect(1:np) .+ np)
    ne = size(edges, 1); np = size(pts, 1)
    cylinder = Cylinder(Point3f(0), Point3f(0, 0, 1.0), 1f0)
    # define markers meshes
    meshC = normal_mesh(Tesselation(cylinder, nbfacese))
    meshS = normal_mesh(Tesselation(large_sphere, 20))
    # define colors, markersizes and rotations
    pG = [Point3f(pts[k, 1], pts[k, 2], pts[k, 3]) for k = 1:np]
    lengthsC = sqrt.(sum((pts[edges[:,1], :] .- pts[edges[:, 2], :]).^2, dims=2))
    sizesC = [Vec3f(radius, radius, lengthsC[i]) for i = 1:ne]
    sizesC = [Vec3f(1) for i = 1:ne]
    colorsp = [RGBA{Float32}(RNG.rand(), RNG.rand(), RNG.rand(), 1.0) for i = 1:np]
    colorsC = [(colorsp[edges[i, 1]] .+ colorsp[edges[i, 2]]) / 2.0 for i = 1:ne]
    sizesC = [Vec3f(radius, radius, lengthsC[i]) for i = 1:ne]
    Qlist = zeros(ne, 4)
    for k = 1:ne
        ct = Cylinder(
            Point3f(pts[edges[k, 1], 1], pts[edges[k, 1], 2], pts[edges[k, 1], 3]),
            Point3f(pts[edges[k, 2], 1], pts[edges[k, 2], 2], pts[edges[k, 2], 3]),
            1f0
        )
        Q = GeometryBasics.rotation(ct)
        r = 0.5 * sqrt(1 .+ Q[1, 1] .+ Q[2, 2] .+ Q[3, 3]); Qlist[k, 4] = r
        Qlist[k, 1] = (Q[3, 2] .- Q[2, 3]) / (4 .* r)
        Qlist[k, 2] = (Q[1, 3] .- Q[3, 1]) / (4 .* r)
        Qlist[k, 3] = (Q[2, 1] .- Q[1, 2]) / (4 .* r)
    end

    rotationsC = [Vec4f(Qlist[i, 1], Qlist[i, 2], Qlist[i, 3], Qlist[i, 4]) for i = 1:ne]
    # plot
    fig, ax, meshplot = meshscatter(
        pG[edges[:, 1]],
        color=colorsC, marker=meshC,
        markersize=sizesC,  rotations=rotationsC,
    )
    meshscatter!(
        ax, pG,
        color=colorsp, marker=meshS, markersize=radius,
    )
    fig
end

@reference_test "Connected Sphere" begin
    large_sphere = Sphere(Point3f(0), 1f0)
    positions = decompose(Point3f, large_sphere)
    linepos = view(positions, RNG.rand(1:length(positions), 1000))
    fig, ax, lineplot = lines(linepos, linewidth=0.1, color=:black, transparency=true)
    scatter!(
        ax, positions, markersize=10,
        strokewidth=2, strokecolor=:white,
        color=RGBAf(0.9, 0.2, 0.4, 0.3), transparency=true,
    )
    fig
end

@reference_test "image scatter" begin
    scatter(
        1:10, 1:10, RNG.rand(10, 10) .* 10,
        rotations=normalize.(RNG.rand(Quaternionf, 10 * 10)),
        markersize=20,
        # can also be an array of images for each point
        # need to be the same size for best performance, though
        marker=Makie.logo()
    )
end

@reference_test "Simple meshscatter" begin
    large_sphere = Sphere(Point3f(0), 1f0)
    positions = decompose(Point3f, large_sphere)
    meshscatter(positions, color=RGBAf(0.9, 0.2, 0.4, 1), markersize=0.05)
end

@reference_test "Animated surface and wireframe" begin
    function xy_data(x, y)
        r = sqrt(x^2 + y^2)
        r == 0.0 ? 1f0 : (sin(r) / r)
    end

    xrange = range(-2, stop=2, length=50)
    surf_func(i) = [Float32(xy_data(x * i, y * i)) for x = xrange, y = xrange]
    z = surf_func(20)
    fig, ax, surf = surface(xrange, xrange, z)

    wf = wireframe!(ax, xrange, xrange, lift(x -> x .+ 1.0, surf[3]),
        linewidth=2f0, color=lift(x -> to_colormap(x)[5], surf[:colormap])
    )
    Record(fig, range(5, stop=40, length=3); framerate=1) do i
        surf[3] = surf_func(i)
    end
end

@reference_test "Normals of a Cat" begin
    x = loadasset("cat.obj")
    mesh(x, color=:black)
    pos = map(decompose(Point3f, x), GeometryBasics.normals(x)) do p, n
        p => p .+ Point(normalize(n) .* 0.05f0)
    end
    linesegments!(pos, color=:blue)
    current_figure()
end

@reference_test "Sphere Mesh" begin
    mesh(Sphere(Point3f(0), 1f0), color=:blue)
end

@reference_test "Unicode Marker" begin
    scatter(Point3f[(1, 0, 0), (0, 1, 0), (0, 0, 1)], marker=[:x, :circle, :cross],
            markersize=35)
end

@reference_test "Merged color Mesh" begin
    function colormesh((geometry, color))
        mesh1 = normal_mesh(geometry)
        npoints = length(GeometryBasics.coordinates(mesh1))
        return GeometryBasics.pointmeta(mesh1; color=fill(color, npoints))
    end
    # create an array of differently colored boxes in the direction of the 3 axes
    x = Vec3f(0); baselen = 0.2f0; dirlen = 1f0
    rectangles = [
        (Rect(Vec3f(x), Vec3f(dirlen, baselen, baselen)), RGBAf(1, 0, 0, 1)),
        (Rect(Vec3f(x), Vec3f(baselen, dirlen, baselen)), RGBAf(0, 1, 0, 1)),
        (Rect(Vec3f(x), Vec3f(baselen, baselen, dirlen)), RGBAf(0, 0, 1, 1))
    ]

    meshes = map(colormesh, rectangles)
    mesh(merge(meshes))
end

@reference_test "Line GIF" begin
    us = range(0, stop=1, length=100)
    f, ax, p = linesegments(Rect3f(Vec3f(0, -1, 0), Vec3f(1, 2, 2)); color=:black)
    p = lines!(ax, us, sin.(us), zeros(100), linewidth=3, transparency=true, color=:black)
    lineplots = [p]
    Makie.translate!(p, 0, 0, 0)
    colors = to_colormap(:RdYlBu)
    N = 5
    Record(f, 1:N; framerate=1) do i
        t = i/(N/5)
        if length(lineplots) < 20
            p = lines!(
                ax,
                us, sin.(us .+ t), zeros(100),
                color=colors[length(lineplots)],
                linewidth=3
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
    x = range(-2, stop=2, length=N)
    y = x
    z = (-x .* exp.(-x.^2 .- (y').^2)) .* 4
    fig, ax, surfaceplot = surface(x, y, z)
    xm, ym, zm = minimum(data_limits(ax.scene))
    contour!(ax, x, y, z, levels=15, linewidth=2, transformation=(:xy, zm))
    wireframe!(ax, x, y, z, transparency=true, color=(:black, 0.1))
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
        streamplot(f, -1.5..1.5, -1.5..1.5, -1.5..1.5, colormap=:magma, gridsize=(10, 10), arrow_size=0.1, transparency=true)
    end
end

@reference_test "Volume on black background" begin
    r = LinRange(-3, 3, 100);  # our value range

    ρ(x, y, z) = exp(-(abs(x))) # function (charge density)

    fig, ax, pl = volume(
        r, r, r,          # coordinates to plot on
        ρ,                # charge density (functions as colorant)
        algorithm=:mip,  # maximum-intensity-projection
        colorrange=(0, 1),
    )
    ax.scene[OldAxis].names.textcolor = :gray # let axis labels be seen on dark background
    fig.scene.backgroundcolor[] = to_color(:black)
    fig
end

@reference_test "Depth Shift" begin
    # Up to some artifacts from fxaa the left side should be blue and the right red.
    fig = Figure(size = (800, 400))

    prim = Rect3(Point3f(0), Vec3f(1))
    ps  = RNG.rand(Point3f, 10) .+ Point3f(0, 0, 1)
    mat = RNG.rand(4, 4)
    A   = RNG.rand(4,4,4)

    # This generates two sets of plots each on two axis. Both axes have one set
    # without depth_shift (0f0, red) and one at ∓10eps(1f0) (blue, left/right axis).
    # A negative shift should push the plot in the foreground, positive in the background.
    for (i, _shift) in enumerate((-10eps(1f0), 10eps(1f0)))
        ax = LScene(fig[1, i], show_axis = false)

        for (color, shift) in zip((:red, :blue), (0f0, _shift))
            mesh!(ax, prim, color = color, depth_shift = shift)
            lines!(ax, ps, color = color, depth_shift = shift)
            linesegments!(ax, ps .+ Point3f(-1, 1, 0), color = color, depth_shift = shift)
            scatter!(ax, ps, color = color, markersize=10, depth_shift = shift)
            text!(ax, 0, 1, 1.1, text = "Test", color = color, depth_shift = shift)
            surface!(ax, -1..0, 1..2, mat, colormap = [color, color], depth_shift = shift)
            meshscatter!(ax, ps .+ Point3f(-1, 1, 0), color = color, depth_shift = shift)
            # # left side in axis
            heatmap!(ax, 0..1, 0..1, mat, colormap = [color, color], depth_shift = shift)
            # # right side in axis
            image!(ax, -1..0, 1..2, mat, colormap = [color, color], depth_shift = shift)
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
            ps = [Point3f(a, (0.15 + 0.01y)*(2x-1) , 0.2y) for y in 1:8]
            if x == 0
                cs = [RGBAf(1, 0, 0, 0.75), RGBAf(0, 1, 0, 0.5), RGBAf(0, 0, 1, 0.25)]
            elseif x == 1
                cs = [RGBAf(1, x, 0, a), RGBAf(0, 1, x, a), RGBAf(x, 0, 1, a)]
            end
            idxs = [1, 2, 3, 2, 1, 3, 1, 2, 1, 2, 3][i:7+i]
            meshscatter!(
                ax, ps, marker = r,
                color = cs[idxs], transparency = true
            )
        end
    end
    cam = cameracontrols(ax.scene)
    cam.fov[] = 22f0
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
        image!(ax, 0..40, 0..800, [x for x in range(0, 1, length=40), _ in 1:10], space = :pixel)
    end
    fig
end

# TODO: get 3D images working in CairoMakie and test them here too
@reference_test "Heatmap 3D" begin
    heatmap(-2..2, -1..1, RNG.rand(100, 100); axis = (; type = LScene))
end
