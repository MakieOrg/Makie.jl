using Makie: PointTrans, apply_transform
using LinearAlgebra

function xyz_boundingbox(trans, points)
    bb_ref = Base.RefValue(Rect3f())
    Makie.foreach_transformed(points, Mat4f(I), trans) do point
        Makie.update_boundingbox!(bb_ref, point)
    end
    return bb_ref[]
end

@testset "Basic transforms" begin
    function fpoint2(x::Point2)
        return Point2f(x[1] + 10, x[2] - 77)
    end

    function fpoint3(x::Point3)
        return Point3f(x[1] + 10, x[2] - 77, x[3] /  4)
    end
    trans2 = PointTrans{2}(fpoint2)
    trans3 = PointTrans{3}(fpoint3)
    points2 = [Point2f(0, 0), Point2f(0, 1)]
    bb = xyz_boundingbox(trans2, points2)
    @test bb == Rect(Vec3f(10, -77, 0), Vec3f(0, 1, 0))
    bb = xyz_boundingbox(trans3, points2)
    @test bb == Rect(Vec3f(10, -77, 0), Vec3f(0, 1, 0))

    points3 = [Point3f(0, 0, 4), Point3f(0, 1, -8)]
    bb = xyz_boundingbox(trans2, points3)
    @test bb == Rect(Vec3f(10, -77, -8), Vec3f(0, 1, 12))
    bb = xyz_boundingbox(trans3, points3)
    @test bb == Rect(Vec3f(10, -77, -2.0), Vec3f(0, 1, 3.0))

    @test apply_transform(trans2, points2) == fpoint2.(points2)
    @test apply_transform(trans3, points3) == fpoint3.(points3)

    @test_throws ErrorException PointTrans{2}(x::Int -> x)
    @test_throws ErrorException PointTrans{3}(x::Int -> x)
end

@testset "Tuple and identity transforms" begin
    t1 = sqrt
    t2 = (sqrt, log)
    t3 = (sqrt, log, log10)

    p2 = Point(2.0, 5.0)
    p3 = Point(2.0, 5.0, 4.0)

    @test apply_transform(identity, p2) == p2
    @test apply_transform(identity, p3) == p3

    @test apply_transform(t1, p2) == Point(sqrt(2.0), sqrt(5.0))
    @test apply_transform(t1, p3) == Point(sqrt(2.0), sqrt(5.0), sqrt(4.0))

    @test apply_transform(t2, p2) == Point2f(sqrt(2.0), log(5.0))
    @test apply_transform(t2, p3) == Point3f(sqrt(2.0), log(5.0), 4.0)

    @test apply_transform(t3, p3) == Point3f(sqrt(2.0), log(5.0), log10(4.0))

    i2 = (identity, identity)
    i3 = (identity, identity, identity)
    @test apply_transform(i2, p2) == p2
    @test apply_transform(i3, p3) == p3

    # test that identity gives back exact same arrays without copying
    p2s = Point2f[(1, 2), (3, 4)]
    @test apply_transform(identity, p2s) === p2s
    @test apply_transform(i2, p2s) === p2s
    @test apply_transform(i3, p2s) === p2s

    p3s = Point3f[(1, 2, 3), (3, 4, 5)]
    @test apply_transform(identity, p3s) === p3s
    @test apply_transform(i2, p3s) === p3s
    @test apply_transform(i3, p3s) === p3s

    @test apply_transform(identity, 1) == 1
    @test apply_transform(i2, 1) == 1
    @test apply_transform(i3, 1) == 1

    @test apply_transform(identity, 1..2) == 1..2
    @test apply_transform(i2, 1..2) == 1..2
    @test apply_transform(i3, 1..2) == 1..2

    pa = Point2f(1, 2)
    pb = Point2f(3, 4)
    r2 = Rect2f(pa, pb .- pa)
    @test apply_transform(t1, r2) == Rect2f(apply_transform(t1, pa), apply_transform(t1, pb) .- apply_transform(t1, pa) )
end

@testset "Polar Transform" begin
    tf = Makie.Polar()
    @test tf.theta_as_x == true
    @test tf.clip_r == true
    @test tf.theta_0 == 0.0
    @test tf.direction == 1
    @test tf.r0 == 0.0

    input = Point2f.([0, pi/3, pi/2, pi, 2pi, 3pi], 1:6)
    output = [r * Point2f(cos(phi), sin(phi)) for (phi, r) in input]
    inv = Point2f.(mod.([0, pi/3, pi/2, pi, 2pi, 3pi], (0..2pi,)), 1:6)
    @test apply_transform(tf, input) ≈ output
    @test apply_transform(Makie.inverse_transform(tf), output) ≈ inv

    tf = Makie.Polar(pi/2, 1, 0, false)
    input = Point2f.(1:6, [0, pi/3, pi/2, pi, 2pi, 3pi])
    output = [r * Point2f(cos(phi+pi/2), sin(phi+pi/2)) for (r, phi) in input]
    inv = Point2f.(1:6, mod.([0, pi/3, pi/2, pi, 2pi, 3pi], (0..2pi,)))
    @test apply_transform(tf, input) ≈ output
    @test apply_transform(Makie.inverse_transform(tf), output) ≈ inv

    tf = Makie.Polar(pi/2, -1, 0, false)
    output = [r * Point2f(cos(-phi-pi/2), sin(-phi-pi/2)) for (r, phi) in input]
    @test apply_transform(tf, input) ≈ output
    @test apply_transform(Makie.inverse_transform(tf), output) ≈ inv

    tf = Makie.Polar(pi/2, -1, 0.5, false)
    output = [(r - 0.5) * Point2f(cos(-phi-pi/2), sin(-phi-pi/2)) for (r, phi) in input]
    @test apply_transform(tf, input) ≈ output
    @test apply_transform(Makie.inverse_transform(tf), output) ≈ inv

    tf = Makie.Polar(0, 1, 0, true)
    input = Point2f.([0, pi/3, pi/2, pi, 2pi, 3pi], 1:6)
    output = [r * Point2f(cos(phi), sin(phi)) for (phi, r) in input]
    inv = Point2f.(mod.([0, pi/3, pi/2, pi, 2pi, 3pi], (0..2pi,)), 1:6)
    @test apply_transform(tf, input) ≈ output
    @test apply_transform(Makie.inverse_transform(tf), output) ≈ inv

    tf = Makie.Polar(0, 1, 0, true, false)
    input = Point2f.([0, pi/3, pi/2, pi, 2pi, 3pi], -6:-1)
    output = [r * Point2f(cos(phi), sin(phi)) for (phi, r) in input]
    inv = Point2f.(mod.([0, pi/3, pi/2, pi, 2pi, 3pi] .+ pi, (0..2pi,)), 6:-1:1)
    @test apply_transform(tf, input) ≈ output
    @test apply_transform(Makie.inverse_transform(tf), output) ≈ inv
end

@testset "Coordinate Systems" begin
    funcs = [Makie.is_data_space, Makie.is_pixel_space, Makie.is_relative_space, Makie.is_clip_space]
    spaces = [:data, :pixel, :relative, :clip]
    for (i, f) in enumerate(funcs)
        for j in 1:4
            @test f(spaces[j]) == (i == j)
        end
    end

    scene = Scene(cam = cam3d!)
    scatter!(scene, [Point3f(-10), Point3f(10)])
    for space in vcat(spaces...)
        @test Makie.clip_to_space(scene.camera, space) * Makie.space_to_clip(scene.camera, space) ≈ Mat4f(I)
    end
end

@testset "Bounding box utilities" begin

    box = Rect2f(0,0,1,1)

    @test Makie.rotatedrect(box, π) == Rect2f(-1, -1, 1, 1)

    @test Makie.rotatedrect(box, π/2) == Rect2f(0, -1, 1, 1)

    @test all(Makie.rotatedrect(box, π/4).origin .≈ Rect2f(0, -1/(√2f0), √2f0, √2f0).origin)
    @test all(Makie.rotatedrect(box, π/4).widths .≈ Rect2f(0, -1/(√2f0), √2f0, √2f0).widths)

end

@testset "Space dependent transforms" begin
    t1 = sqrt
    t2 = (sqrt, log)
    t3 = (sqrt, log, log10)

    p2 = Point(2.0, 5.0)
    p3 = Point(2.0, 5.0, 4.0)

    spaces_and_desired_transforms = Dict(
        :data => (x,y) -> y, # uses changes
        :clip => (x,y) -> x, # no change
        :relative => (x,y) -> x, # no change
        :pixel => (x,y) -> x, # no transformation
    )
    for (space, desired_transform) in spaces_and_desired_transforms
        @test apply_transform(identity, p2, space) == p2
        @test apply_transform(identity, p3, space) == p3

        @test apply_transform(t1, p2, space) == desired_transform(p2, Point(sqrt(2.0), sqrt(5.0)))
        @test apply_transform(t1, p3, space) == desired_transform(p3, Point(sqrt(2.0), sqrt(5.0), sqrt(4.0)))

        @test apply_transform(t2, p2, space) == desired_transform(p2, Point2f(sqrt(2.0), log(5.0)))
        @test apply_transform(t2, p3, space) == desired_transform(p3, Point3f(sqrt(2.0), log(5.0), 4.0))

        @test apply_transform(t3, p3, space) == desired_transform(p3, Point3f(sqrt(2.0), log(5.0), log10(4.0)))
    end
end
