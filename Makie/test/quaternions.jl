struct Degree{T} <: Number
    θ::T
end
Base.:/(θ::Degree, x::Number) = Degree(θ.θ / x)
Base.sin(θ::Degree) = sin(θ.θ * π/180)
Base.cos(θ::Degree) = cos(θ.θ * π/180)

@testset "Quaternions" begin

    qx = qrotation(Vec(1, 0, 0), pi / 4)
    @test qx * qx ≈ qrotation(Vec(1.0, 0.0, 0.0), pi / 2)
    @test Base.power_by_squaring(qx, 2) ≈ qrotation(Vec(1.0, 0.0, 0.0), pi / 2)
    theta = pi / 8
    qx = qrotation(Vec(1.0, 0.0, 0.0), theta)
    c = cos(theta); s = sin(theta)
    Rx = [1 0 0; 0 c -s; 0 s c]

    @test Mat3f(qx) ≈ Rx
    theta = pi / 6
    qy = qrotation(Vec(0.0, 1.0, 0.0), theta)
    c = cos(theta); s = sin(theta)
    Ry = [c 0 s; 0 1 0; -s 0 c]
    @test Mat3f(qy) ≈ Ry
    theta = 4pi / 3
    qz = qrotation(Vec(0.0, 0.0, 1.0), theta)
    c = cos(theta); s = sin(theta)
    Rz = [c -s 0; s c 0; 0 0 1]
    @test Mat3f(qz) ≈ Rz

    @test Mat3f(qx * qy * qz) ≈ Rx * Ry * Rz
    @test Mat3f(qy * qx * qz) ≈ Ry * Rx * Rz
    @test Mat3f(qz * qx * qy) ≈ Rz * Rx * Ry

    a, b = qrotation(Vec(0.0, 0.0, 1.0), deg2rad(0)), qrotation(Vec(0.0, 0.0, 1.0), deg2rad(180))
    # @test slerp(a, b, 0.0) ≈ a
    # @test slerp(a, b, 1.0) ≈ b
    # @test slerp(a, b, 0.5) ≈ qrotation([0, 0, 1], deg2rad(90))
    #
    # @test angle(qrotation(Vec(1.0, 0.0, 0.0), 0)) ≈ 0
    # @test angle(qrotation([0, 1, 0], pi / 4)) ≈ pi / 4
    # @test angle(qrotation([0, 0, 1], pi / 2)) ≈ pi / 2
    #
    # let # test numerical stability of angle
    #     ax = RNG.randn(3)
    #     for θ in [1e-9, π - 1e-9]
    #         q = qrotation(ax, θ)
    #         @test angle(q) ≈ θ
    #     end
    # end

    # Test `to_rotation` with other subtypes of `Number` than `AbstractFloat`
    # such as `Base.Irrational` and Unitful's `90u"°"`
    v = Vec(0.0, 0.0, 1.0)
    # `π` is not an `AbstractFloat` but it is a `Number`
    @test to_rotation(π) == to_rotation(1.0π)
    @test to_rotation((v, π)) == to_rotation((v, 1.0π))
    @test to_rotation(Degree(90)) == to_rotation(π/2)
    @test to_rotation((v, Degree(90))) == to_rotation((v, π/2))
end
