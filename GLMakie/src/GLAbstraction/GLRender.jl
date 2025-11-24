function render(list::Tuple)
    for elem in list
        render(elem)
    end
    return
end

function setup_clip_planes(N::Integer)
    for i in 0:min(7, N - 1)
        glEnable(GL_CLIP_DISTANCE0 + UInt32(i))
    end
    for i in max(0, N):7
        glDisable(GL_CLIP_DISTANCE0 + UInt32(i))
    end
    return
end

# Note: context required in renderloop, not per renderobject here

"""
When rendering a specialised list of Renderables, we can do some optimizations
"""
function render(list::Vector{RenderObject{Pre}}) where {Pre}
    error("I'm not dead yet!")
    isempty(list) && return nothing
    first(list).prerender()
    vertexarray = first(list).vertexarray
    program = vertexarray.program
    glUseProgram(program.id)
    bind(vertexarray)
    for renderobject in list
        renderobject.visible || continue # skip invisible
        setup_clip_planes(to_value(get(renderobject.uniforms, :num_clip_planes, 0)))
        # make sure we only bind new programs and vertexarray when it is actually
        # different from the previous one
        if renderobject.vertexarray != vertexarray
            vertexarray = renderobject.vertexarray
            if vertexarray.program != program
                program = renderobject.vertexarray.program
                glUseProgram(program.id)
            end
            bind(vertexarray)
        end
        for (key, value) in program.uniformloc
            if haskey(renderobject.uniforms, key)
                if length(value) == 1
                    gluniform(value[1], renderobject.uniforms[key])
                elseif length(value) == 2
                    gluniform(value[1], value[2], renderobject.uniforms[key])
                else
                    error("Uniform tuple too long: $(length(value))")
                end
            end
        end
        renderobject.postrender(instructions.vertexarray)
    end
    # we need to assume, that we're done here, which is why
    # we need to bind VertexArray to 0.
    # Otherwise, every glBind(::GLBuffer) operation will be recorded into the state
    # of the currently bound vertexarray
    glBindVertexArray(0)
    return
end

"""
Renders a RenderObject
Note, that this function is not optimized at all!
It uses dictionaries and doesn't care about OpenGL call optimizations.
So rewriting this function could get us a lot of performance for scenes with
a lot of objects.
"""
function render(renderobject::RenderObject, instructions = renderobject.variants[:main])
    if renderobject.visible
        instructions.prerender()
        setup_clip_planes(to_value(get(renderobject.uniforms, :num_clip_planes, 0)))
        program = instructions.program
        glUseProgram(program.id)
        for (key, value) in program.uniformloc
            if haskey(renderobject.uniforms, key)
                # uniform_name_type(program, value[1])
                try
                    if length(value) == 1
                        gluniform(value[1], renderobject.uniforms[key])
                    elseif length(value) == 2
                        gluniform(value[1], value[2], renderobject.uniforms[key])
                    else
                        error("Uniform tuple too long: $(length(value))")
                    end
                catch e
                    Base.showerror(stderr, e)
                    @warn error("uniform $key doesn't work with value $(renderobject.uniforms[key])::$(typeof(renderobject.uniforms[key]))") exception = (e, Base.catch_backtrace())
                end
            end
        end
        bind(instructions.vertexarray)
        N_verts = num_vetices(renderobject) # Can we do an early iszero exit condition?
        render(renderobject.primitive, renderobject.indices, renderobject.instances, N_verts)
        instructions.postrender()
        glBindVertexArray(0)
    end
    return
end

# TODO: maybe do this earlier to produce better error?
function vao_boundscheck(target::Integer, current::Integer)
    if target <= current # assuming 0-based OpenGL indices
        msg = IOBuffer()
        print(msg, "BoundsError: OpenGL vertex index $current exceeds the number of vertices $target.\n Occurred with ")
        # show(msg, MIME"text/plain"(), vao)
        error(String(take!(msg)))
    end
    return
end

# multiple index ranges
function render(mode::GLenum, indices::Vector{UnitRange{Int}}, ::Nothing, N_vert)
    for elem in to_value(indices)
        # TODO: Should this exclude last(elem), i.e. shift a:b to (a-1):(b-1)
        #       instead of (a-1):b?
        vao_boundscheck(N_vert, last(elem))
        glDrawArrays(mode, max(first(elem) - 1, 0), length(elem) + 1)
    end
    return nothing
end

# by index range to draw
function render(mode::GLenum, indices::UnitRange{Int}, ::Nothing, nverts)
    ndraw = length(indices)
    ndraw == 0 && return nothing
    offset = first(indices) - 1 # 1 based -> 0 based
    offset < 0 && error("Range of vertex indices must not be < 0, but is $offset")
    vao_boundscheck(nverts, offset + nverts)
    glDrawArrays(mode, offset, ndraw)
    return nothing
end

# by number of triangles
function render(mode::GLenum, indices::Int, ::Nothing, N_verts)
    indices == 0 && return nothing
    glDrawArrays(mode, 0, indices)
    return nothing
end

# using indexbuffer (faces)
function render(mode::GLenum, indices::GLBuffer{T}, ::Nothing, N_verts) where {T <: Union{Integer, AbstractFace}}
    # Note: not discarding draw calls with 0 indices may cause segfaults even if
    # the draw call is later discarded based on on `mode`. See #4782
    N = length(indices) * cardinality(indices)
    N == 0 && return nothing
    if DEBUG[]
        data = gpu_data_no_unbind(indices)
        @assert !isempty(data)
        # raw() to get 0-based value from Faces, does nothing for Int
        N_addressed = GeometryBasics.raw(mapreduce(maximum, max, data))
        vao_boundscheck(N_verts, N_addressed)
    end
    glDrawElements(mode, N, julia2glenum(T), C_NULL)
    return nothing
end

# TODO: Is this reachable?
# undefined indices, default to rendering all vertices
function render(mode::GLenum, indices, ::Nothing, N_verts)
    N_verts == 0 && return nothing
    glDrawArrays(mode, 0, N_verts)
    return nothing
end

# Instanced Versions:

# TODO: Is this reachable?
# TODO: instances::AbstractVector?
function render(mode::GLenum, indices, instances, N_verts)
    render(mode, indices, length(instances), N_verts)
    return nothing
end

# using index buffer
function render(mode::GLenum, indices::GLBuffer{T}, amount::Integer, N_verts) where {T <: Union{Integer, AbstractFace}}
    N = length(indices) * cardinality(indices)
    N * amount == 0 && return nothing
    if DEBUG[]
        data = gpu_data_no_unbind(indices)
        @assert !isempty(data)
        # raw() to get 0-based value from Faces, does nothing for Int
        N_addressed = GeometryBasics.raw(mapreduce(maximum, max, data))
        vao_boundscheck(N_verts, N_addressed)
    end
    glDrawElementsInstanced(mode, N, julia2glenum(T), C_NULL, amount)
    return nothing
end

# based on number of vertices
function renderinstanced(mode::GLenum, indices, amount::Integer, N_verts)
    N_verts * amount == 0 && return nothing
    glDrawElementsInstanced(mode, N_verts, GL_UNSIGNED_INT, C_NULL, amount)
    return nothing
end
