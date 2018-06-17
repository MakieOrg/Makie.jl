# the instanced ones assume that there is at least one buffer with the vertextype (=has fields, bit whishy washy) and the others are the instanced things
function attach2vao(buffer::Buffer{T}, attrib_location, instanced=false) where T
    bind(buffer)
    if !is_glsl_primitive(T)
        for i = 1:nfields(T)
            FT = fieldtype(T, i); ET = eltype(FT)
            glVertexAttribPointer(
                attrib_location,
                cardinality(FT), julia2glenum(ET),
                GL_FALSE, sizeof(T), Ptr{Void}(fieldoffset(T, i)) # the fieldoffset is because here we have one buffer having all the attributes
            )
            glEnableVertexAttribArray(attrib_location)
            attrib_location += 1
        end
    else
        FT = T; ET = eltype(FT)
        glVertexAttribPointer(
            attrib_location,
            cardinality(FT), julia2glenum(ET),
            GL_FALSE, 0, C_NULL
        )
        glEnableVertexAttribArray(attrib_location)
        if instanced
            glVertexAttribDivisor(attrib_location, 1)
        end
        attrib_location += 1
    end
    return attrib_location
end

function attach2vao(buffers, attrib_location, kind)
    for b in buffers
        if kind == elements_instanced
            attrib_location = attach2vao(b, attrib_location, true)
        else
            attrib_location = attach2vao(b, attrib_location)
        end
    end
    return attrib_location
end

@enum VaoKind simple elements elements_instanced

struct VertexArray{Vertex, Kind}
    id::GLuint
    buffers::Vector{<:Buffer}
    indices::Union{Buffer, Void}
    nverts::Int32 #total vertices to be drawn in drawcall
    ninst::Int32
    face::GLenum
    context::AbstractContext
    function (::Type{VertexArray{Vertex, Kind}})(id, buffers, indices, nverts, ninst, face) where {Vertex, Kind}
        new{Vertex, Kind}(id, buffers, indices, Int32(nverts), Int32(ninst), face, current_context())
    end
end

function VertexArray(arrays::Tuple, indices::Union{Void, Vector, Buffer}; facelength = 1, attrib_location=0)
    id = glGenVertexArrays()
    glBindVertexArray(id)

    if indices != nothing
        ind_buf = indexbuffer(indices)
        bind(ind_buf)
        kind = elements
    else
        kind = simple
        ind_buf = nothing
    end

    face = eltype(indices) <: Integer ? gl_face_enum(eltype(indices)) : gl_face_enum(facelength)
    ninst  = 1
    nverts = 0
    buffers = map(arrays) do array
        if typeof(array) <: Repeated
            ninst_  = length(array)
            if kind == elements_instanced && ninst_ != ninst
                error("Amount of instances is not equal.")
            end
            ninst = ninst_
            nverts_ = length(array.xs.x)
            kind = elements_instanced
        else
            if kind == elements_instanced
                ninst_ = length(array)
                if ninst_ != ninst
                    error("Amount of instances is not equal.")
                end
                ninst = ninst_
                nverts_ = length(array.xs.x)
            else
                nverts_ = length(array)
                if nverts != 0 && nverts != nverts_
                    error("Amount of vertices is not equal.")
                end
                nverts = nverts_
            end
        end
        convert(Buffer, array)
    end
    #TODO Cleanup
    nverts = ind_buf == nothing ? nverts : length(ind_buf)*cardinality(ind_buf)
    attach2vao(buffers, attrib_location, kind)
    glBindVertexArray(0)

    if length(buffers) == 1
        if !is_glsl_primitive(eltype(buffers[1]))
            vert_type = eltype(buffers[1])
        else
            vert_type = Tuple{eltype(buffers[1])}
        end
    else
        vert_type = Tuple{eltype.((buffers...,))...}
    end

    return VertexArray{vert_type, kind}(id, [buffers...], ind_buf, nverts, ninst, face)
end
VertexArray(buffers...; args...) = VertexArray((buffers...), nothing; args...)
VertexArray(buffers::Tuple; args...) = VertexArray(buffers, nothing; args...)

# TODO
Base.convert(::Type{VertexArray}, x) = VertexArray(x)
Base.convert(::Type{VertexArray}, x::VertexArray) = x

function gl_face_enum(face)
    facelength = typeof(face) <: Integer ? face : length(face)
    if facelength == 1
        return GL_POINTS
    elseif facelength == 2
        return GL_LINES
    elseif facelength == 3
        return GL_TRIANGLES
    elseif facelength == 4
        return GL_QUADS
    end
end

is_struct{T}(::Type{T}) = !(sizeof(T) != 0 && nfields(T) == 0)
# is_glsl_primitive{T <: StaticVector}(::Type{T}) = true
is_glsl_primitive{T <: Union{Float32, Int32}}(::Type{T}) = true
function is_glsl_primitive(T)
    glasserteltype(T)
    true
end

_typeof{T}(::Type{T}) = Type{T}
_typeof{T}(::T) = T

function free!(x::VertexArray)
    if !is_current_context(x.context)
        return x
    end
    id = [x.id]
    for buffer in x.buffers
        free!(buffer)
    end
    if x.indices != nothing
        free!(x.indices)
    end
    try
        glDeleteVertexArrays(1, id)
    catch e
        free_handle_error(e)
    end
    return
end

glitype(vao::VertexArray) = julia2glenum(eltype(vao.indices))
totverts(vao::VertexArray) = vao.indices == nothing ? vao.nverts : length(vao.indices) * cardinality(vao.indices)
Base.length(vao::VertexArray) = vao.nverts
bind(vao::VertexArray) = glBindVertexArray(vao.id)
unbind(vao::VertexArray) = glBindVertexArray(0)

#does this ever work with anything aside from an unsigned int??
draw(vao::VertexArray{V, elements} where V) = glDrawElements(vao.face, vao.nverts, GL_UNSIGNED_INT, C_NULL)

draw(vao::VertexArray{V, elements_instanced} where V) = glDrawElementsInstanced(vao.face, totverts(vao), glitype(vao), C_NULL, vao.ninst)

draw(vao::VertexArray{V, simple} where V) = glDrawArrays(vao.face, 0, totverts(vao))

function Base.show(io::IO, vao::VertexArray)
    fields = filter(x->x != :buffers && x!=:indices, fieldnames(vao))
    for field in fields
        show(io, getfield(vao, field))
        println(io,"")
    end
end

Base.eltype(::Type{VertexArray{ElTypes, Kind}}) where {ElTypes, Kind} = (ElTypes, Kind)
