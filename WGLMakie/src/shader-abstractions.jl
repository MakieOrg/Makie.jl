import ShaderAbstractions as SA

# Use highp precision to avoid float overflows in uniforms (e.g. preprojection
# matrices for 3D scatter plots can produce values exceeding the f16 range that
# `mediump` uses on some drivers, leading to Inf values and missing geometry).
const SHADER_PRECISION_HEADER = """
#version 300 es
precision highp int;
precision highp float;
precision highp sampler2D;
precision highp sampler3D;
precision highp isampler2D;
precision highp isampler3D;
precision highp usampler2D;
precision highp usampler3D;
"""

to_vertex_dict(dict::Dict) = dict

to_face_buffer(xx::Vector{UInt32}) = xx
function to_face_buffer(xx)
    return collect(reinterpret(UInt32, xx))
end

function to_vertex_dict(mesh::AbstractGeometry)
    va = Dict{Symbol, AbstractVector}()
    for (k, v) in pairs(GeometryBasics.vertex_attributes(mesh))
        va[k] = v
    end
    va[:faces] = to_face_buffer(decompose(GLTriangleFace, mesh))
    return va
end


function serialize_named_buffer(va::Dict)
    result = Dict{Symbol, Any}()
    for (name, buff) in va
        name == :faces && continue
        result[name] = serialize_buffer_attribute(buff)
    end
    return result
end

function create_shader(vertex_attr, uniforms, vertshader, fragshader)
    context = WebGL()
    vertex_dict = to_vertex_dict(vertex_attr)
    # For vertex_attributes with varying names we set a backup in uniforms
    # Which needs to be removed, when they actually come from the mesh/vertex_attributes
    for (name, element) in vertex_dict
        delete!(uniforms, name)
    end
    # remove faces from vertex attributes
    uniform_block = sprint() do io
        println(io, "\n// Uniforms: ")
        for (name, v) in uniforms
            endswith(string(name), "_getter") && continue
            t_str = try
                SA.type_string(context, v)
            catch e
                @error("Type $(typeof(v)) isn't supported for uniform: $(name)")
                rethrow(e)
            end
            println(io, "uniform ", t_str, " $name;")
            getkey = Symbol(string(name, "_", "getter"))
            if !haskey(uniforms, getkey)
                SA.getter_function(io, v, t_str, name)
            end
        end
        # emit getter after uniforms
        for (name, v) in uniforms
            getkey = Symbol(string(name, "_", "getter"))
            if haskey(uniforms, getkey)
                println(io, uniforms[getkey])
            end
        end

        println(io)
    end
    src = sprint() do io
        println(io, "// vertex inputs: ")
        for (name, element) in vertex_dict
            name == :faces && continue
            SA.input_element(context, SA.Vertex(), io, element, name, uniforms)
        end
        println(io, uniform_block)
        println(io)
        println(io, vertshader)
    end
    vert = SHADER_PRECISION_HEADER * src
    frag = SHADER_PRECISION_HEADER * "\nout vec4 fragment_color;\n" * uniform_block * fragshader
    up(x) = replace(x, "#version 300 es" => "")
    filter!(((name, _),) -> !endswith(string(name), "_getter"), uniforms)
    return Dict(
        :vertexarrays => serialize_named_buffer(vertex_dict),
        :faces => to_face_buffer(vertex_dict[:faces]),
        :uniforms => serialize_uniforms(uniforms),
        :vertex_source => up(vert),
        :fragment_source => up(frag),
    )
end

function create_instanced_shader(per_instance, vertexbuffers, uniforms, vertshader, fragshader)
    instance_attributes = sprint() do io
        println(io, "\n// Per instance attributes: ")
        for (name, element) in per_instance
            SA.input_element(WebGL(), SA.Vertex(), io, element, name, uniforms)
        end
        println(io)
    end
    data = create_shader(vertexbuffers, uniforms, instance_attributes * vertshader, fragshader)
    data[:instance_attributes] = serialize_named_buffer(per_instance)
    return data
end
