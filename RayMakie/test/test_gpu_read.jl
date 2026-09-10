"""
A scatter attribute is either ONE value for every vertex or one per vertex, and
`gpu_read` has to tell them apart from the argument alone.

It could not, and the failure was silent. The methods were

    gpu_read(::Type{T}, xs::AbstractVector, idx) = T(xs[idx])
    gpu_read(::Type{T}, x::T, idx)               = x

and `Tuple{Type{T}, T, Any}` is not more specific than
`Tuple{Type{T}, AbstractVector, Any}` — `T` is not constrained to be a vector,
so neither signature implies the other. They are AMBIGUOUS, and Julia resolved
the ambiguity to the array method for every uniform that is itself a vector,
which a `Vec` is: a uniform `Vec4f(0.1,0.2,0.3,1)` read at index 2 answered
`Vec4f(0.2, 0.2, 0.2, 0.2)`.

So a scatter with one colour drew vertex 1 in `(r,r,r,r)`, vertex 2 in
`(g,g,g,g)`, and from vertex 5 on read past the end of a four-component vector.
The same held for markersize, rotation, marker offset and the SDF uv box. No
error, no warning: a picture that is simply wrong. It also broke COMPILATION of
the scatter vertex stage, because indexing an immutable vector at a runtime
index forces the argument tuple into memory, and the copy that produced ran off
the end of the argument's own alloca (`OpLoad %uchar` on a struct pointer, in
`spirv-val`).

The fix is to dispatch the uniform on `StaticVector`, which IS strictly more
specific than `AbstractVector`. Every shape is pinned here.
"""

using Test, RayMakie, GeometryBasics
using RayMakie: gpu_read

@testset "gpu_read tells a uniform from a per-vertex array" begin
    @testset "a uniform vector is itself, at every index" begin
        c = Vec4f(0.1, 0.2, 0.3, 1.0)
        # Fails before the fix: answered Vec4f(0.1,0.1,0.1,0.1) at idx 1 and
        # Vec4f(0.2,0.2,0.2,0.2) at idx 2.
        @test gpu_read(c, 1) === c
        @test gpu_read(c, 2) === c
        # Past the length of the vector, which is where it went out of bounds.
        @test gpu_read(c, 5) === c
        @test gpu_read(c, 4096) === c
    end

    @testset "every uniform vector shape" begin
        @test gpu_read(Point3f(1, 2, 3), 7) === Point3f(1, 2, 3)
        @test gpu_read(Vec2f(4, 5), 7) === Vec2f(4, 5)
        @test gpu_read(Vec3f(1, 2, 3), 7) === Vec3f(1, 2, 3)
    end

    @testset "a uniform scalar is itself" begin
        @test gpu_read(2.5f0, 3) === 2.5f0
        @test gpu_read(Int32(7), 3) === Int32(7)
    end

    @testset "a per-vertex array is indexed" begin
        ps = [Point3f(1, 2, 3), Point3f(4, 5, 6)]
        @test gpu_read(ps, 1) === Point3f(1, 2, 3)
        @test gpu_read(ps, 2) === Point3f(4, 5, 6)
        cs = [Vec4f(1, 0, 0, 1), Vec4f(0, 1, 0, 1)]
        @test gpu_read(cs, 2) === Vec4f(0, 1, 0, 1)
    end

    @testset "a per-vertex array of scalars is NOT a uniform" begin
        # The discriminator is `StaticVector`, not "has a Number element type":
        # a per-vertex markersize is a `Vector{Float32}` and must still index.
        ws = Float32[10, 20, 30]
        @test gpu_read(ws, 1) === 10f0
        @test gpu_read(ws, 3) === 30f0
    end
end
