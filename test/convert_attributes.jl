using Makie: Mat, convert_attribute, uv_transform, automatic

@testset "uv_transform" begin
    key = Makie.key"uv_transform"()

    # defaults matching previous Makie versions
    @test convert_attribute(automatic, key, Makie.key"meshscatter"()) ==  Mat{2, 3, Float32}(0, 1, -1, 0, 1, 0)
    @test convert_attribute(automatic, key, Makie.key"mesh"()) ==  Mat{2, 3, Float32}(0, 1, -1, 0, 1, 0)
    @test convert_attribute(automatic, key, Makie.key"surface"()) === nothing
    @test convert_attribute(automatic, key, Makie.key"image"()) == Mat{2, 3, Float32}(1, 0, 0, -1, 0, 1)

    # General Pipeline
    # Each should work as a value or as a vector element
    for wrap in (identity, x -> [x])
        M = Mat{2, 3, Float32}(1,2,3,4,5,6)
        @test convert_attribute(wrap(M), key) == wrap(M)
        
        M3 = Mat3f(1,2,0, 3,4,0, 5,6,0)
        @test convert_attribute(wrap(M3), key) == wrap(M)

        @test convert_attribute(wrap(Vec2f(2,3)), key) == wrap(Mat{2, 3, Float32}(2,0,0,3,0,0))
        @test convert_attribute(wrap((Vec2f(-1,-2), Vec2f(2,3))), key) == 
            wrap(Mat{2, 3, Float32}(2,0,0,3,-1,-2))
        @test convert_attribute(wrap(I), key) == wrap(Mat{2, 3, Float32}(1,0,0,1,0,0))
        @test convert_attribute(wrap(1.0), key) == 
            wrap(Mat{2, 3, Float32}(cos(1.0),sin(1.0),-sin(1.0),cos(1.0),0,0))

        T = Makie.translationmatrix(Vec3f(-1, -2, 0))
        S = Makie.scalematrix(Vec3f(3, 4, 0))
        R = Makie.rotationmatrix_z(1.8f0)
        M = (T * S * R)[Vec(1,2), Vec(1,2,4)]
        @test convert_attribute(wrap((Vec2f(-1,-2), Vec2f(3,4), 1.8)), key) ≈ wrap(M)

        @test convert_attribute(wrap(:rotr90), key)  == wrap(Mat{2, 3, Float32}(0, -1, 1, 0, 0, 1))
        @test convert_attribute(wrap(:rotl90), key)  == wrap(Mat{2, 3, Float32}(0, 1, -1, 0, 1, 0))
        @test convert_attribute(wrap(:swap_xy), key) == wrap(Mat{2, 3, Float32}(0, 1, 1, 0, 0, 0))
        @test convert_attribute(wrap(:flip_x), key)  == wrap(Mat{2, 3, Float32}(-1, 0, 0, 1, 1, 0))
        @test convert_attribute(wrap(:flip_y), key)  == wrap(Mat{2, 3, Float32}(1, 0, 0, -1, 0, 1))
        @test convert_attribute(wrap(:flip_xy), key) == wrap(Mat{2, 3, Float32}(-1, 0, 0, -1, 1, 1))
    end
    
    @test convert_attribute(nothing, key) === nothing
    
    # Not meant to be used via convert_attribute, util for uv_transform
    @test uv_transform(:meshscatter)[Vec(1,2), Vec(1,2,3)] == convert_attribute(automatic, key, Makie.key"meshscatter"())
    @test uv_transform(:mesh)[Vec(1,2), Vec(1,2,3)]        == convert_attribute(automatic, key, Makie.key"mesh"())
    @test uv_transform(:image)[Vec(1,2), Vec(1,2,3)]       == convert_attribute(automatic, key, Makie.key"image"())
    @test uv_transform(:surface) == Mat3f(I)
end