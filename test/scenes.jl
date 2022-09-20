@testset "Scenes" begin
    scene = Scene()
    @test propertynames(scene) == fieldnames(Scene)
    @testset "getproperty(scene, :$field)" for field in fieldnames(Scene)
            @test getproperty(scene, field) !== missing # well, just don't error
        end
    end
end
