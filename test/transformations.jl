using Makie: PointTrans, apply_transform
using LinearAlgebra

function xyz_boundingbox(trans, points)
    bb_ref = Base.RefValue(Rect3f())
    foreach(points) do point
        Makie.update_boundingbox!(bb_ref, Makie.apply_transform(trans, point))
    end
    return bb_ref[]
end

@testset "Basic transforms" begin
    function fpoint2(x::Point2)
        return Point2f(x[1] + 10, x[2] - 77)
    end

    function fpoint3(x::Point3)
        return Point3f(x[1] + 10, x[2] - 77, x[3] / 4)
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

    @test apply_transform(t2, p2) == Point2(sqrt(2.0), log(5.0))
    @test apply_transform(t2, p3) == Point3(sqrt(2.0), log(5.0), 4.0)

    @test apply_transform(t3, p3) == Point3(sqrt(2.0), log(5.0), log10(4.0))

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

    @test apply_transform(identity, 1 .. 2) == 1 .. 2
    @test apply_transform(i2, 1 .. 2) == 1 .. 2
    @test apply_transform(i3, 1 .. 2) == 1 .. 2

    pa = Point2f(1, 2)
    pb = Point2f(3, 4)
    r2 = Rect2f(pa, pb .- pa)
    @test apply_transform(t1, r2) == Rect2f(apply_transform(t1, pa), apply_transform(t1, pb) .- apply_transform(t1, pa))
end

@testset "Polar Transform" begin
    function periodic_approx(a::VecTypes{2}, b::VecTypes{2})
        return all(((a .≈ b) .| (abs.(a .- b) .≈ 2.0 * pi)))
    end
    periodic_approx(as, bs) = all(periodic_approx.(as, bs))

    tf = Makie.Polar()
    @test tf.theta_as_x == true
    @test tf.clip_r == true
    @test tf.theta_0 == 0.0
    @test tf.direction == 1
    @test tf.r0 == 0.0

    input = Point2.([0, pi / 3, pi / 2, pi, 2pi, 3pi], 1:6)
    output = [r * Point2(cos(phi), sin(phi)) for (phi, r) in input]
    inv = Point2.(mod.([0, pi / 3, pi / 2, pi, 2pi, 3pi], (0 .. 2pi,)), 1:6)
    @test apply_transform(tf, input) ≈ output
    @test periodic_approx(apply_transform(Makie.inverse_transform(tf), output), inv)

    tf = Makie.Polar(pi / 2, 1, 0, false)
    input = Point2.(1:6, [0, pi / 3, pi / 2, pi, 2pi, 3pi])
    output = [r * Point2(cos(phi + pi / 2), sin(phi + pi / 2)) for (r, phi) in input]
    inv = Point2.(1:6, mod.([0, pi / 3, pi / 2, pi, 2pi, 3pi], Ref(0 .. 2pi)))
    @test apply_transform(tf, input) ≈ output
    @test periodic_approx(apply_transform(Makie.inverse_transform(tf), output), inv)

    tf = Makie.Polar(pi / 2, -1, 0, false)
    output = [r * Point2(cos(-phi - pi / 2), sin(-phi - pi / 2)) for (r, phi) in input]
    @test apply_transform(tf, input) ≈ output
    @test periodic_approx(apply_transform(Makie.inverse_transform(tf), output), inv)

    tf = Makie.Polar(pi / 2, -1, 0.5, false)
    output = [(r - 0.5) * Point2(cos(-phi - pi / 2), sin(-phi - pi / 2)) for (r, phi) in input]
    @test apply_transform(tf, input) ≈ output
    @test periodic_approx(apply_transform(Makie.inverse_transform(tf), output), inv)

    tf = Makie.Polar(0, 1, 0, true)
    input = Point2.([0, pi / 3, pi / 2, pi, 2pi, 3pi], 1:6)
    output = [r * Point2(cos(phi), sin(phi)) for (phi, r) in input]
    inv = Point2.(mod.([0, pi / 3, pi / 2, pi, 2pi, 3pi], (0 .. 2pi,)), 1:6)
    @test apply_transform(tf, input) ≈ output
    @test periodic_approx(apply_transform(Makie.inverse_transform(tf), output), inv)

    tf = Makie.Polar(0, 1, 0, true, false)
    input = Point2.([0, pi / 3, pi / 2, pi, 2pi, 3pi], -6:-1)
    output = [r * Point2(cos(phi), sin(phi)) for (phi, r) in input]
    inv = Point2.(mod.([0, pi / 3, pi / 2, pi, 2pi, 3pi] .+ pi, (0 .. 2pi,)), 6:-1:1)
    @test apply_transform(tf, input) ≈ output
    @test periodic_approx(apply_transform(Makie.inverse_transform(tf), output), inv)
end

@testset "Model Transforms" begin
    t1 = Transformation()

    @testset "defaults" begin
        @test !isassigned(t1.parent)
        @test t1.translation[] == Vec3d(0)
        @test t1.scale[] == Vec3d(1)
        @test t1.rotation[] == Quaternionf(0, 0, 0, 1)
        @test t1.origin[] == Vec3d(0)
        @test t1.transform_func[] == identity
        @test t1.parent_model[] == Mat4d(I)
        @test t1.model[] == Mat4d(I)
    end

    @testset "getters" begin
        @test translation(t1) == t1.translation
        @test Makie.scale(t1) == t1.scale
        @test Makie.rotation(t1) == t1.rotation
        @test Makie.origin(t1) == t1.origin
    end

    function model_from_parts(t)
        Makie.translationmatrix(t.translation[] + t.origin[]) *
            Makie.scalematrix(t.scale[]) *
            Makie.rotationmatrix4(t.rotation[]) *
            Makie.translationmatrix(-t.origin[])
    end

    @testset "Mutation/Transformation functions + model Matrix" begin
        # translate!
        translate!(t1, 1, 2, 3)
        @test t1.translation[] ≈ Vec3d(1, 2, 3)
        @test t1.model[] ≈ model_from_parts(t1)
        translate!(t1, 1)
        @test t1.translation[] ≈ Vec3d(1, 0, 0)
        @test t1.model[] ≈ model_from_parts(t1)
        translate!(t1, Vec3f(0.5, 1.2, 0.9))
        @test t1.translation[] ≈ Vec3f(0.5, 1.2, 0.9)
        @test t1.model[] ≈ model_from_parts(t1)
        translate!(Accum, t1, Vec3f(1))
        @test t1.translation[] ≈ Vec3f(0.5, 1.2, 0.9) + Vec3f(1)
        @test t1.model[] ≈ model_from_parts(t1)

        # rotate!
        q = Quaternionf(0.4, 0.3, 0.5, 0.6)
        Makie.rotate!(t1, q)
        @test t1.rotation[] ≈ q
        @test t1.model[] ≈ model_from_parts(t1)
        Makie.rotate!(t1, pi / 2)
        @test t1.rotation[] ≈ Quaternionf(0, 0, sqrt(0.5), sqrt(0.5))
        @test t1.model[] ≈ model_from_parts(t1)
        Makie.rotate!(t1, Vec3f(1, 1, 0), pi / 3)
        @test t1.rotation[] ≈ Quaternionf(sqrt(0.125), sqrt(0.125), 0, sqrt(0.75))
        @test t1.model[] ≈ model_from_parts(t1)
        Makie.rotate!(Accum, t1, pi / 2)
        combined = Quaternionf(sqrt(0.125), sqrt(0.125), 0, sqrt(0.75)) * Quaternionf(0, 0, sqrt(0.5), sqrt(0.5))
        @test t1.rotation[] ≈ combined atol = 1.0e-5
        @test t1.model[] ≈ model_from_parts(t1)

        # scale!
        scale!(t1, 0.5, 2, 3)
        @test t1.scale[] ≈ Vec3d(0.5, 2, 3)
        @test t1.model[] ≈ model_from_parts(t1)
        scale!(t1, 2)
        @test t1.scale[] ≈ Vec3d(2, 1, 1)
        @test t1.model[] ≈ model_from_parts(t1)

        # origin!
        origin!(t1, 1, 0, 1)
        @test t1.origin[] ≈ Vec3d(1, 0, 1)
        @test t1.model[] ≈ model_from_parts(t1)
        origin!(t1, 0.5)
        @test t1.origin[] ≈ Vec3d(0.5, 0, 0)
        @test t1.model[] ≈ model_from_parts(t1)
        origin!(t1, Vec3(0.5))
        @test t1.origin[] ≈ Vec3d(0.5)
        @test t1.model[] ≈ model_from_parts(t1)
        origin!(Accum, t1, 1, 1)
        @test t1.origin[] ≈ Vec3d(1.5, 1.5, 0.5)
        @test t1.model[] ≈ model_from_parts(t1)
    end

    @testset "Child transform" begin
        t2 = Transformation(t1)

        @test isassigned(t2.parent) && (t2.parent[] == t1)
        @test t2.translation[] == Vec3d(0)
        @test t2.scale[] == Vec3d(1)
        @test t2.rotation[] == Quaternionf(0, 0, 0, 1)
        @test t2.origin[] == Vec3d(0)
        @test t2.transform_func[] == identity
        @test t2.parent_model !== t1.model # not the same object
        @test t2.parent_model[] == t1.model[] # but same value
        @test t2.model[] == t1.model[]

        # transform child
        translate!(t2, 1, 2, 3)
        scale!(t2, 2)
        Makie.rotate!(t2, pi)
        origin!(t2, -1, 0, 1)
        @test t2.model[] ≈ t1.model[] * model_from_parts(t2)

        # transform parent
        translate!(t1, 0)
        scale!(t1, 1)
        Makie.rotate!(t1, 0)
        origin!(t1, 0)
        @test t2.model[] ≈ model_from_parts(t2)
    end

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

@testset "Space dependent transforms" begin
    t1 = sqrt
    t2 = (sqrt, log)
    t3 = (sqrt, log, log10)

    p2 = Point(2.0, 5.0)
    p3 = Point(2.0, 5.0, 4.0)

    spaces_and_desired_transforms = Dict(
        :data => (x, y) -> y, # uses changes
        :clip => (x, y) -> x, # no change
        :relative => (x, y) -> x, # no change
        :pixel => (x, y) -> x, # no transformation
    )
    for (space, desired_transform) in spaces_and_desired_transforms
        @test apply_transform(identity, p2, space) == p2
        @test apply_transform(identity, p3, space) == p3

        @test apply_transform(t1, p2, space) == desired_transform(p2, Point(sqrt(2.0), sqrt(5.0)))
        @test apply_transform(t1, p3, space) == desired_transform(p3, Point(sqrt(2.0), sqrt(5.0), sqrt(4.0)))

        @test apply_transform(t2, p2, space) == desired_transform(p2, Point2(sqrt(2.0), log(5.0)))
        @test apply_transform(t2, p3, space) == desired_transform(p3, Point3(sqrt(2.0), log(5.0), 4.0))

        @test apply_transform(t3, p3, space) == desired_transform(p3, Point3(sqrt(2.0), log(5.0), log10(4.0)))
    end
end
