@reference_test "updating 2d primitives" begin
    fig = Figure()
    t = Observable(1)
    text(fig[1, 1], lift(i -> map(j -> ("$j", Point2f(j * 30, 0)), 1:i), t), axis = (limits = (0, 380, -10, 10),), fontsize = 50)
    scatter(fig[1, 2], lift(i -> Point2f.((1:i) .* 30, 0), t), axis = (limits = (0, 330, -10, 10),), markersize = 50)
    linesegments(fig[2, 1], lift(i -> Point2f.((2:2:4i) .* 30, 0), t), axis = (limits = (30, 650, -10, 10),), linewidth = 20)
    lines(fig[2, 2], lift(i -> Point2f.((2:2:4i) .* 30, 0), t), axis = (limits = (30, 650, -10, 10),), linewidth = 20)

    st = Stepper(fig)

    foreach(1:5) do i
        t[] = i
        Makie.step!(st)
    end

    foreach(5:-1:1) do i
        t[] = i
        Makie.step!(st)
    end
    st
end

@reference_test "updating multiple meshes" begin
    points = Observable(Point3f[(1, 0, 0), (0, 1, 0), (0, 0, 1)])

    meshes = map(p -> Makie.normal_mesh(Sphere(p, 0.2)), points[])
    colors = map(p -> RGBf(normalize(p)...), points[])

    fig, ax, pl = mesh(meshes; color = colors)
    st = Stepper(fig)
    Makie.step!(st)
    on(points) do pts
        Makie.update!(
            pl,
            arg1 = map(p -> Makie.normal_mesh(Sphere(p, 0.2)), points[]),
            color = map(p -> RGBf(normalize(p)...), points[])
        )
        notify(pl[1])
    end

    append!(points[], Point3f[(0, 1, 1), (1, 0, 1), (1, 1, 0)])
    notify(points)
    Makie.step!(st)
end

function generate_plot(N = 3)
    points = Observable(Point2f[])
    color = Observable(RGBAf[])
    fig, ax, pl = scatter(points, color = color, markersize = 1.0, marker = Circle, markerspace = :data, axis = (type = Axis, aspect = DataAspect(), limits = (0.4, N + 0.6, 0.4, N + 0.6)), figure = (size = (800, 800),))
    function update_func(ij)
        push!(points.val, Point2f(Tuple(ij)))
        push!(color.val, RGBAf((Tuple(ij) ./ N)..., 0, 1))
        notify(color)
        return notify(points)
    end
    return fig, CartesianIndices((N, N)), update_func
end

@reference_test "record test" begin
    fig, iter, func = generate_plot(3)
    Record(func, fig, iter)
end

function load_frames(video, dir)
    framedir = joinpath(dir, "frames")
    isdir(framedir) && rm(framedir; recursive = true, force = true)
    mkdir(framedir)
    Makie.extract_frames(video, framedir)
    return map(readdir(framedir; join = true)) do path
        return convert(Matrix{RGB{N0f8}}, load(path))
    end
end

function compare_videos(reference, vpath, dir)
    to_compare = load_frames(vpath, dir)
    n = length(to_compare)
    @test n == length(reference)

    return @test all(1:n) do i
        v = ReferenceTests.compare_images(reference[i], to_compare[i])
        return v < 0.2
    end
end

# To not spam our reference image comparison with lots of frames, we do a manual frame comparison between the formats and only add the mkv reference to the reference image tests
@reference_test "record test formats" begin
    mktempdir() do dir
        fig, iter, func = generate_plot(2)
        record(func, fig, joinpath(dir, "reference.mkv"), iter)
        reference = load_frames(joinpath(dir, "reference.mkv"), dir)
        @testset "$format" for format in ["mp4", "mkv", "webm"]
            path = joinpath(dir, "test.$format")
            fig, iter, func = generate_plot(2)
            record(func, fig, path, iter)
            compare_videos(reference, path, dir)

            fig, iter, func = generate_plot(2)
            vso = Makie.Record(func, fig, iter; format = "mkv")
            path = joinpath(dir, "test.$format")
            save(path, vso)
            compare_videos(reference, path, dir)
        end
        # We reuse ramstepper, to add our array of frames to the reference image comparison
        return Makie.RamStepper(fig, Makie.current_backend().Screen(fig.scene), reference, :png)
    end
end

@reference_test "deletion" begin
    f = Figure()
    l = Legend(f[1, 1], [LineElement(color = :red)], ["Line"])
    s = display(f)
    @test f.scene.current_screens[1] === s
    @test f.scene.children[1].current_screens[1] === s
    @test f.scene.children[1].children[1].current_screens[1] === s
    delete!(l)
    @test f.scene.current_screens[1] === s
    ## legend should be gone
    ax = Axis(f[1, 1])
    scatter!(ax, 1:4, markersize = 200, color = 1:4)
    f
end

@reference_test "deletion and observable args" begin
    obs = Observable(1:5)
    f, ax, pl = scatter(obs; markersize = 150)
    s = display(f)
    # So, for GLMakie it will be 2, since we register an additional listener for
    # State changes for the on demand renderloop
    @test length(obs.listeners) in (1, 2)
    delete!(ax, pl)
    @test length(obs.listeners) == 0
    # ugh, hard to synchronize this with WGLMakie, so, we need to sleep for now to make sure the change makes it to the browser
    # TODO, add synchronization primitive?
    sleep(1)
    f
end

@reference_test "interactive colorscale - mesh" begin
    brain = load(assetpath("brain.stl"))
    color = [abs(tri[1][2]) for tri in brain for i in 1:3]
    f, ax, m = mesh(brain; color, colorscale = identity)
    mesh(f[1, 2], brain; color, colorscale = log10)
    st = Stepper(f)
    Makie.step!(st)
    m.colorscale = log10
    Makie.step!(st)
end

@reference_test "interactive colorscale - heatmap" begin
    data = exp.(abs.(RNG.randn(20, 20)))
    f, ax, hm = heatmap(data, colorscale = log10, axis = (; title = "log10"))
    Colorbar(f[1, 2], hm)
    ax2, hm2 = heatmap(f[1, 3], data, colorscale = log10, axis = (; title = "log10"))
    st = Stepper(f)
    Makie.step!(st)

    hm2.colorscale = identity
    ax2.title = "identity"
    Makie.step!(st)

    hm.colorscale = identity
    ax.title = "identity"
    Makie.step!(st)
end

@reference_test "interactive colorscale - hexbin" begin
    x = RNG.randn(1_000)
    y = RNG.randn(1_000)
    f = Figure()
    hexbin(f[1, 1], x, y; axis = (aspect = DataAspect(), title = "identity"))
    ax, hb = hexbin(f[1, 2], x, y; colorscale = log, axis = (aspect = DataAspect(), title = "log"))
    Colorbar(f[1, end + 1], hb)
    st = Stepper(f)
    Makie.step!(st)
    hb.colorscale = identity
    ax.title = "identity"
    Makie.step!(st)
end

@reference_test "event ticks in record" begin
    # Checks whether record calculates and triggers event.tick by drawing a
    # Point at y = 1 for each frame where it does. The animation is irrelevant
    # here, so we can just check the final image.
    # The first point maybe at 0 depending on when the backend sets up it's
    # reference time
    ps = Observable(Point2f[])
    f, a, p = scatter(ps)
    xlims!(a, 0, 61)
    ylims!(a, -0.1, 1.1)
    Record(f, 1:60, framerate = 30) do i
        push!(ps.val, Point2f(i, f.scene.events.tick[].delta_time > 1.0e-6))
        notify(ps)
        f.scene.events.tick[] = Makie.Tick(Makie.UnknownTickState, 0, 0.0, 0.0)
    end
    f
end

# TODO
# We never really supported move_to! and GLMakie actually has didn't even move the plots in the reference image on master.
# We can now implement move_to! with the compute graph more easily, but it will require some more work.
# Until then, it's not a regression to disable this test.

# @reference_test "Moving plots with move_to" begin
#     f, ax, pl1 = scatter(5:-1:1; markersize=20, axis=(; title="Axis 1"))
#     pl2 = poly!(ax, Rect2f(10, 10, 100, 100); color=:green, space=:pixel)
#     pl3 = scatter!(ax, 1:5; color=Float64[1:5;], markersize=0.5, colorrange=(1, 5), lowclip=:black,
#                    highclip=:red, markerspace=:data)
#     pl4 = poly!(ax, Rect2f(0, 0, 1, 1); color=(:green, 0.5), strokewidth=2, strokecolor=:black)
#     f
#     img1 = copy(colorbuffer(f; px_per_unit=1))
#     plots = [pl1, pl2, pl3, pl4]

#     # TODO what memory leak to check here?

#     # get_listener_lengths() = map(plots) do x
#     #     arg_l = length(x[1].listeners)
#     #     attr_l = length(x.color.listeners)
#     #     return [arg_l, attr_l]
#     # end
#     # listener_lengths_1 = get_listener_lengths()

#     ax2 = Axis(f[1, 2]; title="Axis 2")
#     ls = LScene(f[2, :]; show_axis=false)
#     scene = Makie.camrelative(ls.scene)

#     Makie.move_to!(pl2, ax2.scene)
#     Makie.move_to!(pl3, ax2.scene)
#     Makie.move_to!(pl4, scene)
#     # Make sure updating still works for color
#     pl3.color = [-1, 2, 3, 4, 7]
#     pl3.colormap = :inferno
#     pl3.markersize = 1

#     # @test listener_lengths_1 == get_listener_lengths()

#     img2 = copy(colorbuffer(f; px_per_unit=1))
#     @test length(ax.scene.plots) == 1
#     @test ax.scene.plots[1] === pl1
#     @test length(ax2.scene.plots) == 2
#     @test pl2 in ax2.scene.plots
#     @test pl3 in ax2.scene.plots
#     @test pl4 in scene.plots
#     @test length(scene) == 1

#     # Move everything back
#     pl3.color = Float64[1:5;]
#     pl3.colormap = :viridis
#     pl3.markersize = 0.5
#     Makie.move_to!(pl1, ax.scene)
#     Makie.move_to!(pl2, ax.scene)
#     Makie.move_to!(pl3, ax.scene)
#     Makie.move_to!(pl4, ax.scene)
#     # Make it easier to see similarity to first plot, by removing new scenes
#     delete!(ls)
#     delete!(ax2)
#     trim!(f.layout)

#     img3 = copy(colorbuffer(f; px_per_unit=1))

#     # @test listener_lengths_1 == get_listener_lengths()

#     imgs = hcat(rotr90.((img1, img2, img3))...)
#     s = Scene(; size=size(imgs))
#     image!(s, imgs; space=:pixel)
#     s
# end

@reference_test "updating surface size" begin
    X = Observable(-5:5)
    Y = Observable(-5:5)
    Z = Observable([0.01 * x * x * y * y for x in X.val, y in Y.val])

    f = Figure(size = (800, 400))
    surface(f[1, 1], X, Y, Z)
    surface(f[1, 2], map(collect, X), map(collect, Y), Z)
    surface(
        f[1, 3],
        map((X, Y) -> [x for x in X, y in Y], X, Y),
        map((X, Y) -> [y for x in X, y in Y], X, Y), Z
    )
    f
    st = Stepper(f)
    Makie.step!(st)

    X.val = -5:0
    Z.val = Z.val[1:6, :]
    notify(X)
    notify(Z)
    Makie.step!(st)

    X.val = -5:5
    Z.val = [0.01 * x * x * y * y for x in X.val, y in Y.val]
    notify(X)
    notify(Z)
    Makie.step!(st)
end

@reference_test "meshscatter update" begin
    f, a, p = meshscatter([Point3f(0)])
    st = Stepper(f)
    Makie.step!(st)

    p.marker = Rect3f(0, 0, 0, 1, 1, 1)
    p.color = :red
    p.markersize = Vec3f(0.2, 0.1, 0.05)
    p.rotation = Vec3f(1, 1, -1)
    p.alpha = 0.5
    p.arg1 = [Point3f(-0.1, -0.05, 0), Point3f(0.1, 0, 0), Point3f(0, 0.15, 0)]
    Makie.step!(st)
end
