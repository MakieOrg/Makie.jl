using ShaderAbstractions, LinearAlgebra
using ShaderAbstractions: VertexArray
using Test

struct WebGL <: ShaderAbstractions.AbstractContext end

import GeometryTypes, AbstractPlotting, GeometryBasics

m = GeometryTypes.GLNormalMesh(GeometryTypes.Sphere(GeometryTypes.Point3f0(0), 1f0))

mvao = VertexArray(m)
instances = VertexArray(positions = rand(GeometryBasics.Point{3, Float32}, 100))

x = ShaderAbstractions.InstancedProgram(
    WebGL(), read(joinpath(@__DIR__, "..", "assets", "particles.vert"), String),
    mvao,
    instances,
    model = GeometryTypes.Mat4f0(I),
    view = GeometryTypes.Mat4f0(I),
    projection = GeometryTypes.Mat4f0(I),

)
x.program.source |> println
