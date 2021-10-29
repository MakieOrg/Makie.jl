function RenderObject(
        data::Dict{Symbol}, program, pre,
        bbs=Observable(Rect3f(Vec3f(0), Vec3f(1))),
        main=nothing
    )
    RenderObject(convert(Dict{Symbol,Any}, data), program, pre, bbs, main)
end

function Base.show(io::IO, obj::RenderObject)
    println(io, "RenderObject with ID: ", obj.id)
end


Base.getindex(obj::RenderObject, symbol::Symbol)         = obj.uniforms[symbol]
Base.setindex!(obj::RenderObject, value, symbol::Symbol) = obj.uniforms[symbol] = value

Base.getindex(obj::RenderObject, symbol::Symbol, x::Function)     = getindex(obj, Val(symbol), x)
Base.getindex(obj::RenderObject, ::Val{:prerender}, x::Function)  = obj.prerenderfunctions[x]
Base.getindex(obj::RenderObject, ::Val{:postrender}, x::Function) = obj.postrenderfunctions[x]

Base.setindex!(obj::RenderObject, value, symbol::Symbol, x::Function)     = setindex!(obj, value, Val(symbol), x)
Base.setindex!(obj::RenderObject, value, ::Val{:prerender}, x::Function)  = obj.prerenderfunctions[x] = value
Base.setindex!(obj::RenderObject, value, ::Val{:postrender}, x::Function) = obj.postrenderfunctions[x] = value

const empty_signal = Observable(false)
post_empty() = push!(empty_signal, false)


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

    # Disable cullface for now, untill all rendering code is corrected!
    glDisable(GL_CULL_FACE)
    # glCullFace(GL_BACK)

    # # Disable depth write for transparent objects
    # glDepthMask(sp.transparency[] ? GL_FALSE : GL_TRUE)
    # enabletransparency()

    if sp.transparency[]
        sp.overdraw[] && @warn("overdraw may break transparency?")

        glDepthMask(GL_FALSE)

        # Blending
        glEnable(GL_BLEND)
        glBlendEquation(GL_FUNC_ADD)

        # 0 contains weight * color.rgba, should do sum
        # destination <- 1 * source + 1 * destination
        glBlendFunci(0, GL_ONE, GL_ONE)
        
        # 1 is objectid, do nothing
        glDisablei(1, GL_BLEND)
        
        # 2 is color.a, should do product
        # destination <- 0 * source + (1 - source) * destination
        glBlendFunci(2, GL_ZERO, GL_ONE_MINUS_SRC_COLOR)

    else
        glDepthMask(GL_TRUE)
        glDisable(GL_BLEND)
    end
end

struct StandardPostrender
    vao::GLVertexArray
    primitive::GLenum
end
function (sp::StandardPostrender)()
    render(sp.vao, sp.primitive)
end
struct StandardPostrenderInstanced{T}
    main::T
    vao::GLVertexArray
    primitive::GLenum
end
function (sp::StandardPostrenderInstanced)()
    renderinstanced(sp.vao, to_value(sp.main), sp.primitive)
end

struct EmptyPrerender
end
function (sp::EmptyPrerender)()
end
export EmptyPrerender
export prerendertype

function instanced_renderobject(data, program, bb=Observable(Rect3f(Vec3f(0), Vec3f(1))), primitive::GLenum=GL_TRIANGLES, main=nothing)
    pre = StandardPrerender()
    robj = RenderObject(convert(Dict{Symbol,Any}, data), program, pre, nothing, bb, main)
    robj.postrenderfunction = StandardPostrenderInstanced(main, robj.vertexarray, primitive)
    robj
end

function std_renderobject(data, program, bb=Observable(Rect3f(Vec3f(0), Vec3f(1))), primitive=GL_TRIANGLES, main=nothing)
    pre = StandardPrerender()
    robj = RenderObject(convert(Dict{Symbol,Any}, data), program, pre, nothing, bb, main)
    robj.postrenderfunction = StandardPostrender(robj.vertexarray, primitive)
    robj
end

prerendertype(::Type{RenderObject{Pre}}) where {Pre} = Pre
prerendertype(::RenderObject{Pre}) where {Pre} = Pre
