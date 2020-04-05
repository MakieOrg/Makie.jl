
function assemble_robj(data, program, bb, primitive, pre_fun, post_fun)
    transp = get(data, :transparency, Node(false))
    overdraw = get(data, :overdraw, Node(false))
    pre = if pre_fun != nothing
        _pre_fun = GLAbstraction.StandardPrerender(transp, overdraw)
        function ()
            _pre_fun()
            pre_fun()
        end
    else
        GLAbstraction.StandardPrerender(transp, overdraw)
    end
    robj = RenderObject(data, program, pre, nothing, bb, nothing)
    post = if haskey(data, :instances)
        GLAbstraction.StandardPostrenderInstanced(data[:instances], robj.vertexarray, primitive)
    else
        GLAbstraction.StandardPostrender(robj.vertexarray, primitive)
    end
    robj.postrenderfunction = if post_fun != nothing
        () -> begin
            post()
            post_fun()
        end
    else
        post
    end
    robj
end

function assemble_shader(data)
    shader = data[:shader]
    delete!(data, :shader)
    glp = get(data, :gl_primitive, GL_TRIANGLES)
    return assemble_robj(
        data, shader, FRect3D(), glp,
        get(data, :prerender, nothing),
        get(data, :postrender, nothing)
    )
end

points2f0(positions::Vector{T}, range::AbstractRange) where {T} = Point2f0[Point2f0(range[i], positions[i]) for i=1:length(range)]

"""
Converts index arrays to the OpenGL equivalent.
"""
to_index_buffer(x::GLBuffer) = x
to_index_buffer(x::TOrSignal{Int}) = x
to_index_buffer(x::VecOrSignal{UnitRange{Int}}) = x
to_index_buffer(x::TOrSignal{UnitRange{Int}}) = x
"""
For integers, we transform it to 0 based indices
"""
to_index_buffer(x::AbstractVector{I}) where {I <: Integer} = indexbuffer(Cuint.(x .- 1))
function to_index_buffer(x::Node{<: AbstractVector{I}}) where I <: Integer
    indexbuffer(lift(x-> Cuint.(x .- 1), x))
end

"""
If already GLuint, we assume its 0 based (bad heuristic, should better be solved with some Index type)
"""
function to_index_buffer(x::VectorTypes{I}) where I <: Union{GLuint, LineFace{GLIndex}}
    indexbuffer(x)
end

to_index_buffer(x) = error(
    "Not a valid index type: $(typeof(x)).
    Please choose from Int, Vector{UnitRange{Int}}, Vector{Int} or a signal of either of them"
)
