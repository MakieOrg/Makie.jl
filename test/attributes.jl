
mutable struct Scatter <: AttributeFields
    color::RGBA{Float32}
    markersize::Float64
end

using Test

function test(a::Attributes)
    x = a.color
    a.color = RGBA(0.0f0, 0.0f0, red(x), 1.0f0)
    return x
end

@testset "inference" begin
    attr = Attributes(Scatter(RGBA(1.0f0, 1.0f0, 1.0f0, 1.0f0), 1.0))
    @inferred test(attr)
    @inferred observe(attr, Key(:color))
end

@testset "updates" begin
    attr = Attributes(Scatter(RGBA(1.0f0, 1.0f0, 1.0f0, 1.0f0), 1.0))
    updated = Observable(0)
    callback = on_update(attr, :color) do color
        updated[] += 1
        return
    end
    attr.color = :red
    attr.markersize = 2.0
    @test updated[] == 1
    update!(attr; color = :green, markersize = 2.0)
    @test updated[] == 2
    remove_callback!(attr, callback)
    attr.color = :red
    attr.markersize = 2.0
    @test updated[] == 2

    updated[] = 0
    callback2 = on_update(attr, :color, :markersize) do color, markersize
        updated[] += 1
        return
    end
    attr.color = :red
    attr.markersize = 2.0
    @test updated[] == 2
    update!(attr; color = :green, markersize = 2.0)
    @test updated[] == 3

    remove_callback!(attr, callback2)
    attr.color = :red
    attr.markersize = 2.0
    update!(attr; color = :green, markersize = 2.0)
    @test updated[] == 3
end
