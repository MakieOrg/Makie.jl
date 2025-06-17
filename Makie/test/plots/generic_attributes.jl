@testset "Generic Attributes" begin
    scene = Scene()
    p = scatter!(scene, rand(10))
    @test scene.theme.inspectable[]
    @test p.inspectable[]

    scene = Scene(inspectable = false)
    p = scatter!(scene, rand(10))
    @test !scene.theme.inspectable[]
    @test !p.inspectable[]
end
