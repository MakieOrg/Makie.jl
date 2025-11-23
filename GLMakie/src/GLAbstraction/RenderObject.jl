
# Things that influence how data from a renderobject can be rendered
struct RenderInstructions{Pre, Post}
    vertexarray::GLVertexArray # just the vertexarray
    program::GLProgram

    # Can these be part of the RenderStage?
    # i.e. filter by plot type to do pre render setup once, maybe also postrender
    prerender::Pre
    postrender::Post
end

function free(x::RenderInstructions)
    free(x.vertexarray)
    free(x.program)
    return
end

const RENDER_OBJECT_ID_COUNTER = Ref(zero(UInt32))

function pack_bool(id, bool)
    highbit_mask = UInt32(1) << UInt32(31)
    return id + (bool ? highbit_mask : UInt32(0))
end

mutable struct RenderObject{IndexT, InstanceT}
    context # OpenGL context
    id::UInt32
    visible::Bool

    # data of the renderobject
    buffers::Dict{Symbol, GLBuffer}
    indices::IndexT
    instances::InstanceT
    primitive::GLenum

    uniforms::Dict{Symbol, Any}

    variants::Dict{Symbol, RenderInstructions}

    function RenderObject(
            context, visible,
            buffers::Dict{Symbol, GLBuffer},
            indices::IndexT,
            instances::InstanceT,
            primitive::GLenum,
            uniforms::Dict{Symbol, Any},
        ) where {IndexT, InstanceT}
        fxaa = Bool(to_value(get!(uniforms, :fxaa, true)))
        RENDER_OBJECT_ID_COUNTER[] += one(UInt32)
        # Store fxaa in ID, so we can access it in the shader to create a mask
        # for the fxaa render pass
        # In theory, we need to unpack the id again as well,
        # But with this implementation, the fxaa flag can't be changed,
        # and since this is a UUID, it shouldn't matter
        id = pack_bool(RENDER_OBJECT_ID_COUNTER[], fxaa)
        robj = new{IndexT, InstanceT}(
            context, id, to_value(visible),
            buffers, indices, instances, primitive,
            uniforms,
            Dict{Symbol, RenderInstructions}(),
        )
        return robj
    end
end

function process_buffers(context, bufferdict::Dict)
    # get the size of the first array, to assert later, that all have the same size
    indexes = -1
    len = -1
    gl_switch_context!(context)

    buffers = Dict{Symbol, GLBuffer}()
    for (name, buffer) in bufferdict
        if isa(buffer, GLBuffer) && buffer.buffertype == GL_ELEMENT_ARRAY_BUFFER
            indexes = buffer
        elseif Symbol(name) === :indices
            indexes = buffer
        else
            attribute = string(name)
            len == -1 && (len = length(buffer))
            # TODO: use glVertexAttribDivisor to allow multiples of the longest buffer
            if len != length(buffer)
                # We don't know which buffer has the wrong size, so list all of them
                bufferlengths = ""
                for (name, buffer) in bufferdict
                    if isa(buffer, GLBuffer) && buffer.buffertype == GL_ELEMENT_ARRAY_BUFFER
                    elseif Symbol(name) === :indices
                    else
                        bufferlengths *= "\n\t$name has length $(length(buffer))"
                    end
                end
                error(
                    "Buffer $attribute does not have the same length as the other buffers." *
                        bufferlengths
                )
            end
            buffers[name] = buffer
        end
    end

    if indexes == -1
        indexes = len
    end

    return buffers, indexes
end

function RenderObject(context, data::Dict{Symbol, Any})
    gl_switch_context!(context)
    require_context(context)

    # Explicit conversion targets for gl_convert
    targets = get(data, :gl_convert_targets, Dict())
    delete!(data, :gl_convert_targets)

    # Not handled as uniform
    visible = pop!(data, :visible, true)
    @assert !isa(visible, Observable) "No more of this!"

    # Overwriting data with break direct iteration over it
    _keys = collect(keys(data))
    for k in _keys
        v = data[k]
        v isa Observable && error("An Observable? In this economy?")

        if haskey(targets, k)
            # glconvert is designed to convert everything to a fitting opengl datatype, but sometimes
            # the conversion is not unique. (E.g. Array -> Texture, TextureBuffer, GLBuffer, ...)
            # In these cases an explicit conversion target is required
            data[k] = gl_convert(context, targets[k], v)
        else
            k in (:indices, :visible, :ssao, :label, :cycle) && continue

            # structs are decomposed into fields
            #     $k.$fieldname -> v.$fieldname
            if isa_gl_struct(v)
                merge!(data, gl_convert_struct(context, v, k))
                delete!(data, k)

                # try direct conversion
            elseif applicable(gl_convert, context, v)
                try
                    data[k] = gl_convert(context, v)
                catch e
                    @error "gl_convert for key `$k` failed"
                    rethrow(e)
                end

                # Otherwise just let the value pass through
                # TODO: Is this ok/ever not filtered?
            else
                @debug "Passed on $k -> $(typeof(v)) without conversion."
            end
        end
    end

    buffers, indices = process_buffers(
       context,
       filter(((key, value),) -> isa(value, GLBuffer) || key === :indices, data)
    )
    require_context(context)

    # Validate context of things in RenderObject
    if DEBUG[]
        for v in values(data)
            if v isa TextureBuffer
                require_context(v.buffer.context, context)
                require_context(v.texture.context, context)
            elseif v isa GPUArray
                require_context(v.context, context)
            end
        end
    end

    # remove all uniforms not occurring in shader
    # ssao, instances transparency are special for rendering passes. TODO do this more cleanly
    # special = Set([:ssao, :transparency, :instances, :fxaa, :num_clip_planes])
    # for k in setdiff(keys(data), keys(program.nametype))
    #     if !(k in special)
    #         !haskey(buffers, k) && (data[k] isa GPUArray) && free(data[k])
    #         delete!(data, k)
    #     end
    # end
    for k in keys(buffers)
        delete!(data, k)
    end

    # overdraw, transparency, ssao, fxaa, shading
    cleanup = [:indices, :doc_string]
    foreach(key -> pop!(data, key, nothing), cleanup)

    instances = pop!(data, :instances, nothing)
    primitive = pop!(data, :gl_primitive, GL_TRIANGLES)

    robj = RenderObject(context, visible, buffers, indices, instances, primitive, data)

    # automatically integrate object ID, will be discarded if shader doesn't use it
    robj[:objectid] = robj.id

    return robj
end

function Base.show(io::IO, obj::RenderObject)
    print(io, "RenderObject(id = ", obj.id, ", visible = ", obj.visible, ")")
    return io
end

# these collide with other names when using `GLENUM(primitive).name`
const GL_PRIMITIVE_TO_NAME = Dict{GLuint, String}(
    GL_POINTS => "GL_POINTS",
    GL_LINES => "GL_LINES",
    GL_LINE_LOOP => "GL_LINE_LOOP",
    GL_LINE_STRIP => "GL_LINE_STRIP",
    GL_TRIANGLES => "GL_TRIANGLES",
    GL_TRIANGLE_STRIP => "GL_TRIANGLE_STRIP",
    GL_TRIANGLE_FAN => "GL_TRIANGLE_FAN",
    GL_LINES_ADJACENCY => "GL_LINES_ADJACENCY",
    GL_LINE_STRIP_ADJACENCY => "GL_LINE_STRIP_ADJACENCY",
    GL_TRIANGLES_ADJACENCY => "GL_TRIANGLES_ADJACENCY",
    GL_TRIANGLE_STRIP_ADJACENCY => "GL_TRIANGLE_STRIP_ADJACENCY",
)

_print_indices(io::IO, n::Integer) = println(io, "  indices: ", Int64(n))
_print_indices(io::IO, is::AbstractVector{<:Integer}) = println(io, "  indices: ", Int64.(is))
_print_indices(io::IO, fs) = println(io, "  faces: ", fs)

function Base.show(io::IO, ::MIME"text/plain", robj::RenderObject)
    println(io, "RenderObject")
    println(io, "  id: ", robj.id)
    println(io, "  visible: ", robj.visible)
    _print_indices(io, robj.indices)
    isnothing(robj.instances) || println(io, "  instances: ", robj.instances)
    primitive = get(GL_PRIMITIVE_TO_NAME, robj.primitive, GLENUM(robj.primitive).name)
    println(io, "  primitive: ", primitive)
    println(io, "  ", length(robj.buffers), " vertex buffers")
    println(io, "  ", length(robj.uniforms), " uniforms")
    print(io, "  ", length(robj.variants), " variants")
    return io
end

Base.getindex(obj::RenderObject, symbol::Symbol) = obj.uniforms[symbol]
Base.setindex!(obj::RenderObject, value, symbol::Symbol) = obj.uniforms[symbol] = value
Base.haskey(obj::RenderObject, symbol::Symbol) = haskey(obj.uniforms, symbol)

# Probably should look at ALL buffers so that every instruction set renders the
# same number of elements, even if some buffers are temporarily desynced
function num_vetices(robj::RenderObject)
    isempty(robj.buffers) && return -1
    return mapreduce(length, min, values(robj.buffers))
end

################################################################################

"""
Represents standard sets of function applied before rendering
"""
struct StandardPrerender
    overdraw::Observable{Bool}
end

function (sp::StandardPrerender)()
    if sp.overdraw[]
        # Disable depth testing if overdrawing
        glDisable(GL_DEPTH_TEST)
    else
        glEnable(GL_DEPTH_TEST)
        glDepthFunc(GL_LEQUAL)
    end

    # Disable cullface for now, until all rendering code is corrected!
    glDisable(GL_CULL_FACE)
    # glCullFace(GL_BACK)
    return
end

struct EmptyPrerender end
(sp::EmptyPrerender)() = nothing

struct EmptyPostrender end
(sp::EmptyPostrender)() = nothing

export EmptyPrerender

function StandardPrerender(robj::RenderObject)
    overdraw = get(robj.uniforms, :overdraw, false)
    return StandardPrerender(overdraw)
end

# TODO: rework data (used for mustache replacements?)
function RenderInstructions(
        robj::RenderObject, maybe_program;
        pre = StandardPrerender(robj), post = EmptyPostrender()
    )
    # "compile" lazyshader
    data = merge(robj.uniforms, robj.buffers) # TODO: avoid this?
    program = gl_convert(robj.context, to_value(maybe_program), data)
    vertexarray = GLVertexArray(robj.buffers, program, robj.indices)

    if DEBUG[]
        require_context(program.context, context)
        require_context(vertexarray.context, context)
    end

    return RenderInstructions(vertexarray, program, pre, post)
end

function add_instructions!(robj::RenderObject, name::Symbol, program; kwargs...)
    if !haskey(robj.variants, name)
        instructions = RenderInstructions(robj, program; kwargs...)
        robj.variants[name] = instructions
    end
    return
end
