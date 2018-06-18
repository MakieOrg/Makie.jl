const RENDER_OBJECT_ID_COUNTER = Ref(zero(GLushort))

#Renderobject will become a renderable, were first it will be focussed on GL,
#but nothing would stop you to use something else to render it



mutable struct RenderObject <: Composable{DeviceUnit}
    main                 # main object
    uniforms            ::Dict{Symbol, Any}
    vertexarray         ::VertexArray
    id                  ::GLushort
    boundingbox          # workaround for having lazy boundingbox queries, while not using multiple dispatch for boundingbox function (No type hierarchy for RenderObjects)
    function RenderObject(
            main, uniforms::Dict{Symbol, Any}, vertexarray::VertexArray,
            boundingbox
        )
        RENDER_OBJECT_ID_COUNTER[] += one(GLushort)
        new(
            main, uniforms, vertexarray,
            prerenderfunctions, postrenderfunctions,
            RENDER_OBJECT_ID_COUNTER[], boundingbox, program
        )
    end
end

function RenderObject(data::Dict{Symbol, Any}, bbs=Signal(AABB{Float32}(Vec3f0(0), Vec3f0(1))), main=nothing)
    targets = get(data, :gl_convert_targets, Dict())
    delete!(data, :gl_convert_targets)
    passthrough = Dict{Symbol, Any}() # we also save a few non opengl related values in data
    for (k,v) in data # convert everything to OpenGL compatible types
        if haskey(targets, k)
            # glconvert is designed to just convert everything to a fitting opengl datatype, but sometimes exceptions are needed
            # e.g. Texture{T,1} and Buffer{T} are both usable as an native conversion canditate for a Julia's Array{T, 1} type.
            # but in some cases we want a Texture, sometimes a Buffer or TextureBuffer
            data[k] = gl_convert(targets[k], v)
        else
            k in (:indices, :visible) && continue
            if isa_gl_struct(v) # structs are treated differently, since they have to be composed into their fields
                merge!(data, gl_convert_struct(v, k))
            elseif applicable(gl_convert, v) # if can't be converted to an OpenGL datatype,
                data[k] = gl_convert(v)
            else # put it in passthrough
                delete!(data, k)
                passthrough[k] = v
            end
        end
    end
    # handle meshes seperately, since they need expansion
    meshs = filter((key, value) -> isa(value, NativeMesh), data)
    if !isempty(meshs)
        merge!(data, [v.data for (k,v) in meshs]...)
    end

    if haskey(data, :indices) && !isa(data[:indices], Reactive.Signal)
        indices = pop!(data, :indices)
    elseif haskey(data, :faces)
        indices = pop!(data, :faces)
    else
        indices = nothing
    end
    #very ugly and bad
    buffers  = [val for (key,val) in filter((key, value) -> isa(value, Buffer), data)]
    vao = indices == nothing ? VertexArray((buffers...); facelength=3) : VertexArray((buffers...), indices)
    uniforms = filter((key, value) -> !isa(value, Buffer) && key != :indices, data)
    get!(data, :visible, true) # make sure, visibility is set
    merge!(data, passthrough) # in the end, we insert back the non opengl data, to keep things simple
    robj = RenderObject(main, uniforms, vao, bbs)
    # automatically integrate object ID, will be discarded if shader doesn't use it
    robj[:objectid] = robj.id
    robj
end



function RenderObject(
        data::Dict{Symbol}, program, pre,
        bbs = Signal(AABB{Float32}(Vec3f0(0),Vec3f0(1))),
        main = nothing
    )
    RenderObject(convert(Dict{Symbol,Any}, data), program, pre, bbs, main)
end

function Base.show(io::IO, obj::RenderObject)
    println(io, "RenderObject with ID: ", obj.id)
end


Base.getindex(obj::RenderObject, symbol::Symbol)         = obj.uniforms[symbol]
Base.setindex!(obj::RenderObject, value, symbol::Symbol) = (obj.uniforms[symbol] = value)


########### SIGNAL SHENANIGANS####################
const empty_signal = Signal(false)
post_empty() = push!(empty_signal, false)

"""
Function which sets an argument of a Composition/RenderObject.
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
function set_arg!(robj::Composition, sym, value)
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
function set_arg!(robj::RenderObject, sym, to_update::Signal, value::Signal)
    robj[sym] = value
end
function set_arg!(robj::RenderObject, sym, to_update::Signal, value)
    push!(to_update, value)
end

########### SIGNAL SHENANIGANS####################
"""
Represents standard sets of function applied before rendering
"""
function assemble_robj(data, program, bb, primitive, pre_fun, post_fun)
    pre = if pre_fun != nothing
        () -> (GLAbstraction.StandardPrerender(); pre_fun())
    else
        GLAbstraction.StandardPrerender()
    end
    robj = RenderObject(data, program, pre, nothing, bb, nothing)
    robj
end

extract_renderable(context::Vector{RenderObject}) = context
extract_renderable(context::RenderObject) = RenderObject[context]
extract_renderable(context::Vector{T}) where {T <: Composable} = map(extract_renderable, context)
function extract_renderable(context::Composition)
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
function _translate!(c::Composition, m::TOrSignal{Mat4f0})
    for elem in c.children
        _translate!(elem, m)
    end
end

function translate!(c::Composable, vec::TOrSignal{T}) where T <: Vec{3}
     _translate!(c, const_lift(translationmatrix, vec))
end
function _boundingbox(c::RenderObject)
    bb = Reactive.value(c[:boundingbox])
    bb == nothing && return AABB()
    Reactive.value(c[:model]) * bb
end
function _boundingbox(c::Composable)
    robjs = extract_renderable(c)
    isempty(robjs) && return AABB()
    mapreduce(_boundingbox, union, robjs)
end
"""
Copy function for a context. We only need to copy the children
"""
function Base.copy(c::Composition{T}) where T
    new_children = [copy(child) for child in c.children]
    Composition{T}(new_children, c.boundingbox, c.transformation)
end
# """
# If you have an array of OptimizedPrograms, you only need to put PreRender in front.
# """
# type OptimizedProgram{PreRender}
#     program::Program
#     uniforms::FixedDict
#     vertexarray::VertexArray
#     gl_parameters::PreRender
#     renderfunc::Callable
#     visible::Boolean
# end
