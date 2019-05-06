using ShaderAbstractions, LinearAlgebra
using ShaderAbstractions: VertexArray, Buffer
using Test, Tables, Observables
using AbstractPlotting
using WGLMakie
import GeometryTypes: GLNormalMesh

scene = meshscatter(rand(Point3f0, 10), rotations = rand(Quaternionf0, 10))

struct WebGL <: ShaderAbstractions.AbstractContext end

import GeometryTypes, AbstractPlotting, GeometryBasics


lasset(path) = read(joinpath(dirname(pathof(WGLMakie)), "..", "assets", path), String)

function wgl_convert(value, key1, key2)
    convert_attribute(value, key1, key2)
end

function wgl_convert(value::AbstractMatrix, ::key"colormap", key2)
    ShaderAbstractions.Sampler(value)
end

function lift_convert(key, value, plot)
    val = lift(value) do value
         wgl_convert(value, AbstractPlotting.Key{key}(), AbstractPlotting.Key{AbstractPlotting.plotkey(plot)}())
     end
     if key == :colormap && val[] isa AbstractArray
         return ShaderAbstractions.Sampler(val)
     else
         val
     end
end
ShaderAbstractions.type_string(context::ShaderAbstractions.AbstractContext, t::Type{<: AbstractPlotting.Quaternionf0}) = "vec4"


function create_shader(scene::Scene, plot::MeshScatter)
    vshader = lasset("particles.vert")
    # Potentially per instance attributes
    per_instance_keys = (:position, :rotations, :markersize, :color, :intensity)
    per_instance = filter(plot.attributes.attributes) do (k, v)
        k in per_instance_keys && !(isscalar(v[]))
    end
    per_instance[:position] = plot[1]

    for (k, v) in per_instance
        per_instance[k] = Buffer(v)
    end

    uniforms = filter(plot.attributes.attributes) do (k, v)
        (!haskey(per_instance, k)) && isscalar(v[])
    end

    uniform_dict = Dict{Symbol, Any}()
    for (k,v) in uniforms
        k in (:shading, :overdraw, :fxaa, :visible, :transformation, :alpha, :linewidth, :transparency, :marker) && continue
        uniform_dict[k] = lift_convert(k, v, plot)
    end
    color = uniform_dict[:color][]
    if color isa Colorant || color isa AbstractVector{<: Colorant}
        delete!(uniform_dict, :colormap)
    end
    instance = VertexArray(map(GLNormalMesh, plot.marker))
    if !GeometryBasics.hascolumn(instance, :texturecoordinate)
        uniform_dict[:texturecoordinate] = Vec2f0(0)
    end
    for key in (:view, :projection, :resolution, :eyeposition, :projectionview)
        uniform_dict[key] = getfield(scene.camera, key)
    end
    p = ShaderAbstractions.InstancedProgram(
        WebGL(), vshader,
        instance,
        VertexArray(; per_instance...)
        ; uniform_dict...
    )
end
using Colors
write("test.vert", create_shader(scene, scene[end]).program.source)
