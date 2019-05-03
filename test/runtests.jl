using ShaderAbstractions, LinearAlgebra
using ShaderAbstractions: VertexArray
using Test, Tables

struct WebGL <: ShaderAbstractions.AbstractContext end

import GeometryTypes, AbstractPlotting, GeometryBasics

m = GeometryTypes.GLNormalMesh(GeometryTypes.Sphere(GeometryTypes.Point3f0(0), 1f0))

mvao = VertexArray(m)
instances = VertexArray(positions = rand(GeometryBasics.Point{3, Float32}, 100))
@which Tables.schema(mvao.data.simplices.points)
x = ShaderAbstractions.InstancedProgram(
    WebGL(), read(joinpath(@__DIR__, "..", "assets", "particles.vert"), String),
    mvao,
    instances,
    model = GeometryTypes.Mat4f0(I),
    view = GeometryTypes.Mat4f0(I),
    projectionview = GeometryTypes.Mat4f0(I),

)
x.program.source |> println

using WebSockets, WebIO

node(:h1, "lol") |> display
