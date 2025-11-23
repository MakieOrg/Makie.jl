"""
Represents an OpenGL vertex array type.
Can be created from a dict of buffers and an opengl Program.
Keys with the name `indices` will get special treatment and will be used as
the indexbuffer.
"""
mutable struct GLVertexArray
    context::GLContext
    id::GLuint
    buffer::Vector{Symbol} # probably unnecessary, actively used buffers
end

function GLVertexArray(bufferdict::Dict{Symbol, GLBuffer}, program::GLProgram, indices)
    gl_switch_context!(program.context)

    id = glGenVertexArrays()
    glBindVertexArray(id)

    indices isa GLBuffer && bind(indices)

    N_attrib = max(0, get_attribute_count(program.id))
    buffers = fill(:unknown, N_attrib)
    messages = String[]
    for (name, buffer) in bufferdict
        attribute = string(name)
        bind(buffer)
        attribLocation = get_attribute_location(program.id, attribute)
        if attribLocation != -1
            glVertexAttribPointer(attribLocation, cardinality(buffer), julia2glenum(eltype(buffer)), GL_FALSE, 0, C_NULL)
            glEnableVertexAttribArray(attribLocation)
            buffers[attribLocation+1] = name
        else
            push!(messages, "could not bind attribute $(attribute)")
        end
    end

    glBindVertexArray(0)

    obj = GLVertexArray(program.context, id, buffers)
    DEBUG[] && finalizer(verify_free, obj)

    println.(Ref(stdout), messages)
    flush(stdout)
    gl_switch_context!(program.context)

    return obj
end

using ShaderAbstractions: Buffer

# TODO: do this earlier (::GLTriangleFace) if it's ever used
# function GLVertexArray(program::GLProgram, buffers::Buffer, triangles::AbstractVector{<:GLTriangleFace})
#     gl_switch_context!(program.context)
#     # get the size of the first array, to assert later, that all have the same size
#     id = glGenVertexArrays()
#     glBindVertexArray(id)
#     for property_name in propertynames(buffers)
#         array = getproperty(buffers, property_name)
#         attribute = string(property_name)
#         # TODO: use glVertexAttribDivisor to allow multiples of the longest buffer
#         buffer = GLBuffer(program.context, array)
#         bind(buffer)
#         attribLocation = get_attribute_location(program.id, attribute)
#         if attribLocation == -1
#             error("could not bind attribute $(attribute)")
#         end
#         glVertexAttribPointer(attribLocation, cardinality(buffer), julia2glenum(eltype(buffer)), GL_FALSE, 0, C_NULL)
#         glEnableVertexAttribArray(attribLocation)
#         buffers[attribute] = buffer
#     end
#     glBindVertexArray(0)
#     indices = indexbuffer(triangles)
#     obj = GLVertexArray{typeof(indexes)}(program, id, len, buffers, indices)
#     DEBUG[] && finalizer(verify_free, obj)
#     return obj
# end

function bind(va::GLVertexArray)
    if va.id == 0
        error("Binding freed VertexArray")
    end
    return glBindVertexArray(va.id)
end

Base.show(io::IO, vao::GLVertexArray) = print(io, "GLVertexArray $(vao.id)")
function Base.show(io::IO, ::MIME"text/plain", vao::GLVertexArray)
    # show(io, vao.program)
    println(io, "GLVertexArray $(vao.id):")
    print(io, "used buffers: ", vao.buffers)
    return
end
