@testset "Projection math" begin
    @test eltype(Makie.rotationmatrix_x(1)) == Float64
    @test eltype(Makie.rotationmatrix_x(1f0)) == Float32
end

@testset "transformation matrix decomposition" begin
    v1 = normalize(2f0 .* rand(Vec3f) .- 1.0)
    v2 = normalize(2f0 .* rand(Vec3f) .- 1.0)
    rot = Makie.rotation_between(v1, v2)
    trans = 10.0 .* (2.0 .* rand(Vec3f) .- 1.0)
    scale = 10.0 .* rand(Vec3f) # avoid negative because decomposition puts negative into rotation

    M = Makie.translationmatrix(trans) *
        Makie.scalematrix(scale) *
        Makie.rotationmatrix4(rot)

    t, s, r = Makie.decompose_translation_scale_rotation_matrix(M)
    @test t ≈ trans
    @test s ≈ scale
    @test r ≈ rot

    M2 = Makie.translationmatrix(t) *
         Makie.scalematrix(s) *
         Makie.rotationmatrix4(r)

    @test M ≈ M2
end