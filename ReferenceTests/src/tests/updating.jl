@reference_test "updating 2d primitives" begin
    fig = Figure()
    t = Observable(1)
    text(fig[1, 1], lift(i-> map(j-> ("$j", Point2f(j*30, 0)), 1:i), t), axis=(limits=(0, 380, -10, 10),), fontsize=50)
    scatter(fig[1, 2], lift(i-> Point2f.((1:i).*30, 0), t), axis=(limits=(0, 330, -10, 10),), markersize=50)
    linesegments(fig[2, 1], lift(i-> Point2f.((2:2:4i).*30, 0), t), axis=(limits=(30, 650, -10, 10),), linewidth=20)
    lines(fig[2, 2], lift(i-> Point2f.((2:2:4i).*30, 0), t), axis=(limits=(30, 650, -10, 10),), linewidth=20)

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
    points = Observable(Point3f[(1,0,0), (0,1,0), (0,0,1)])

    meshes = map(p->Makie.normal_mesh(Sphere(p, 0.2)), points[])
    colors = map(p->RGBf(normalize(p)...), points[])

    fig, ax, pl = mesh(meshes; color = colors)
    st = Stepper(fig)
    Makie.step!(st)
    on(points) do pts
        pl[1].val = map(p->Makie.normal_mesh(Sphere(p, 0.2)), points[])
        pl.color.val = map(p->RGBf(normalize(p)...), points[])
        notify(pl[1])
    end

    append!(points[], Point3f[(0,1,1), (1,0,1), (1,1,0)])
    notify(points)
    Makie.step!(st)
end

function generate_plot(N = 3)
    points = Observable(Point2f[])
    color = Observable(RGBAf[])
    fig, ax, pl = scatter(points, color=color, markersize=1.0, marker=Circle, markerspace=:data, axis=(type=Axis, aspect=DataAspect(), limits=(0.4, N + 0.6, 0.4, N + 0.6),), figure=(resolution=(800, 800),))
    function update_func(ij)
        push!(points.val, Point2f(Tuple(ij)))
        push!(color.val, RGBAf((Tuple(ij)./N)..., 0, 1))
        notify(color)
        notify(points)
    end
    return fig, CartesianIndices((N, N)), update_func
end

@reference_test "record test" begin
    fig, iter, func = generate_plot(3)
    Record(func, fig, iter)
end

function load_frames(video, dir)
    framedir = joinpath(dir, "frames")
    isdir(framedir) && rm(framedir; recursive=true, force=true)
    mkdir(framedir)
    Makie.extract_frames(video, framedir)
    return map(readdir(framedir; join=true)) do path
        return convert(Matrix{RGB{N0f8}}, load(path))
    end
end

function compare_videos(reference, vpath, dir)
    to_compare = load_frames(vpath, dir)
    n = length(to_compare)
    @test n == length(reference)

    @test all(1:n) do i
        v = ReferenceTests.compare_media(reference[i], to_compare[i])
        return v < 0.02
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
            vso = Makie.Record(func, fig, iter; format="mkv")
            path = joinpath(dir, "test.$format")
            save(path, vso)
            compare_videos(reference, path, dir)
        end
        # We re-use ramstepper, to add our array of frames to the reference image comparison
        return Makie.RamStepper(fig, Makie.current_backend().Screen(fig.scene), reference, :png)
    end
end
