function RenderObject(
        data::Dict{Symbol}, program, pre,
        bbs = Node(FRect3D(Vec3f0(0),Vec3f0(1))),
        main = nothing
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

const empty_signal = Node(false)
post_empty() = push!(empty_signal, false)

"""
Function which sets an argument of a Context/RenderObject.
If multiple RenderObjects are supplied, it'll try to set the same argument in all
of them.
"""
function set_arg!(robj::RenderObject, sym, value)
    current_val = robj[sym]
    set_arg!(robj, sym, current_val, value)
    # GLVisualize relies on reactives event system no for rendering
    # so if a change should be visible there must be an event to indicate change
    post_empty()
    nothing
end
function set_arg!(robj::Context, sym, value)
    set_arg!(robj.children, sym, value)
    nothing
end
function set_arg!(robj::Vector, sym, value)
    for elem in robj
        set_arg!(elem, sym, value)
    end
    nothing
end

function set_arg!(robj::RenderObject, sym, to_update::GPUArray, value)
    update!(to_update, value)
end
function set_arg!(robj::RenderObject, sym, to_update, value)
    robj[sym] = value
end
function set_arg!(robj::RenderObject, sym, to_update::Node, value::Node)
    robj[sym] = value
end
function set_arg!(robj::RenderObject, sym, to_update::Node, value)
    push!(to_update, value)
end


"""
Represents standard sets of function applied before rendering
"""
struct StandardPrerender
    transparency::Node{Bool}
    overdraw::Node{Bool}
end

function (sp::StandardPrerender)()
    if sp.overdraw[]
        # Disable depth testing if overdrawing
        glDisable(GL_DEPTH_TEST)
    else
        glEnable(GL_DEPTH_TEST)
        glDepthFunc(GL_LEQUAL)
    end
    # Disable depth write for transparent objects
    glDepthMask(sp.transparency[] ? GL_FALSE : GL_TRUE)
    # Disable cullface for now, untill all rendering code is corrected!
    glDisable(GL_CULL_FACE)
    # glCullFace(GL_BACK)
    enabletransparency()
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

function instanced_renderobject(data, program, bb = Node(FRect3D(Vec3f0(0), Vec3f0(1))), primitive::GLenum=GL_TRIANGLES, main=nothing)
    pre = StandardPrerender()
    robj = RenderObject(convert(Dict{Symbol,Any}, data), program, pre, nothing, bb, main)
    robj.postrenderfunction = StandardPostrenderInstanced(main, robj.vertexarray, primitive)
    robj
end

function std_renderobject(data, program, bb = Node(FRect3D(Vec3f0(0), Vec3f0(1))), primitive=GL_TRIANGLES, main=nothing)
    pre = StandardPrerender()
    robj = RenderObject(convert(Dict{Symbol,Any}, data), program, pre, nothing, bb, main)
    robj.postrenderfunction = StandardPostrender(robj.vertexarray, primitive)
    robj
end

prerendertype(::Type{RenderObject{Pre}}) where {Pre} = Pre
prerendertype(::RenderObject{Pre}) where {Pre} = Pre

extract_renderable(context::Vector{RenderObject}) = context
extract_renderable(context::RenderObject) = RenderObject[context]
extract_renderable(context::Vector{T}) where {T <: Composable} = map(extract_renderable, context)
function extract_renderable(context::Context)
    result = extract_renderable(context.children[1])
    for elem in context.children[2:end]
        push!(result, extract_renderable(elem)...)
    end
    result
end
transformation(c::RenderObject) = c[:model]
function transformation(c::RenderObject, model)
    c[:model] = const_lift(*, model, c[:model])
end
function transform!(c::RenderObject, model)
    c[:model] = const_lift(*, model, c[:model])
end

function _translate!(c::RenderObject, trans::TOrSignal{Mat4f0})
    c[:model] = const_lift(*, trans, c[:model])
end
function _translate!(c::Context, m::TOrSignal{Mat4f0})
    for elem in c.children
        _translate!(elem, m)
    end
end

function translate!(c::Composable, vec::TOrSignal{T}) where T <: Vec{3}
     _translate!(c, const_lift(translationmatrix, vec))
end
function _boundingbox(c::RenderObject)
    bb = to_value(c[:boundingbox])
    bb == nothing && return FRect3D()
    to_value(c[:model]) * bb
end
function _boundingbox(c::Composable)
    robjs = extract_renderable(c)
    isempty(robjs) && return FRect3D()
    mapreduce(_boundingbox, union, robjs)
end
"""
Copy function for a context. We only need to copy the children
"""
function Base.copy(c::Context{T}) where T
    new_children = [copy(child) for child in c.children]
    Context{T}(new_children, c.boundingbox, c.transformation)
end


"""
Copy function for a RenderObject. We only copy the uniform dict
"""
function Base.copy(robj::RenderObject{Pre}) where Pre
    uniforms = Dict{Symbol, Any}([(k,v) for (k,v) in robj.uniforms])
    robj = RenderObject{Pre}(
        robj.main,
        uniforms,
        robj.vertexarray,
        robj.prerenderfunction,
        robj.postrenderfunction,
        robj.boundingbox,
    )
    Context(robj)
end

# """
# If you have an array of OptimizedPrograms, you only need to put PreRender in front.
# """
# type OptimizedProgram{PreRender}
#     program::GLProgram
#     uniforms::FixedDict
#     vertexarray::GLVertexArray
#     gl_parameters::PreRender
#     renderfunc::Callable
#     visible::Boolean
# end
