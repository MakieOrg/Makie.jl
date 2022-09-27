using ReferenceTests
using LinearAlgebra
using ReferenceTests: @reference_test

@reference_test "updating 2d primitives" begin
    fig = Figure()
    t = Observable(1)
    text(fig[1, 1], lift(i-> map(j-> ("$j", Point2f(j*30, 0)), 1:i), t), axis=(limits=(0, 380, -10, 10),), textsize=50)
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
