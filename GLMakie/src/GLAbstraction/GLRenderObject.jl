function Base.show(io::IO, obj::RenderObject)
    return print(io, "RenderObject(id = ", obj.id, ", visible = ", obj.visible, ")")
end

Base.getindex(obj::RenderObject, symbol::Symbol) = obj.uniforms[symbol]
Base.setindex!(obj::RenderObject, value, symbol::Symbol) = obj.uniforms[symbol] = value
Base.haskey(obj::RenderObject, symbol::Symbol) = haskey(obj.uniforms, symbol)

Base.getindex(obj::RenderObject, symbol::Symbol, x::Function) = getindex(obj, Val(symbol), x)
Base.getindex(obj::RenderObject, ::Val{:prerender}, x::Function) = obj.prerenderfunctions[x]
Base.getindex(obj::RenderObject, ::Val{:postrender}, x::Function) = obj.postrenderfunctions[x]

Base.setindex!(obj::RenderObject, value, symbol::Symbol, x::Function) = setindex!(obj, value, Val(symbol), x)
Base.setindex!(obj::RenderObject, value, ::Val{:prerender}, x::Function) = obj.prerenderfunctions[x] = value
Base.setindex!(obj::RenderObject, value, ::Val{:postrender}, x::Function) = obj.postrenderfunctions[x] = value

"""
Represents standard sets of function applied before rendering
"""
struct StandardPrerender
    transparency::Observable{Bool}
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
    return glDisable(GL_CULL_FACE)
    # glCullFace(GL_BACK)
end

struct StandardPostrender
    vao::GLVertexArray
    primitive::GLenum
end

function (sp::StandardPostrender)()
    return render(sp.vao, sp.primitive)
end

struct StandardPostrenderInstanced
    n_instances::Observable{Int}
    vao::GLVertexArray
    primitive::GLenum
end

function (sp::StandardPostrenderInstanced)()
    return renderinstanced(sp.vao, sp.n_instances[], sp.primitive)
end

struct EmptyPrerender end

(sp::EmptyPrerender)() = nothing

export EmptyPrerender
export prerendertype

prerendertype(::Type{RenderObject{Pre}}) where {Pre} = Pre
prerendertype(::RenderObject{Pre}) where {Pre} = Pre
