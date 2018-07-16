############################################################################
const TOrSignal{T} = Union{Signal{T}, T}

const ArrayOrSignal{T, N} = TOrSignal{Array{T, N}}
const VecOrSignal{T} = ArrayOrSignal{T, 1}
const MatOrSignal{T} = ArrayOrSignal{T, 2}
const VolumeOrSignal{T} = ArrayOrSignal{T, 3}

const ArrayTypes{T, N} = Union{GPUArray{T, N}, ArrayOrSignal{T,N}}
const VecTypes{T} = ArrayTypes{T, 1}
const MatTypes{T} = ArrayTypes{T, 2}
const VolumeTypes{T} = ArrayTypes{T, 3}

@enum Projection PERSPECTIVE ORTHOGRAPHIC
@enum MouseButton MOUSE_LEFT MOUSE_MIDDLE MOUSE_RIGHT

# const GLContext = Symbol

"""
Returns the cardinality of a type. falls back to length
"""
cardinality(x) = length(x)
cardinality(x::Number) = 1
cardinality(x::Type{T}) where {T <: Number} = 1


#Context and current_context should be overloaded by users of the library! They are standard Symbols
abstract type AbstractContext end

struct DummyContext <: AbstractContext
    id::Any
end

#=
We need to track the current OpenGL context.
Since we can't do this via pointer identity  (OpenGL may reuse the same pointers)
We go for this slightly ugly version.
In the future, this should probably be part of GLWindow.
=#
const context = Base.RefValue{AbstractContext}(DummyContext(:none))

new_context() = (context[] = DummyContext(gensym()))
current_context() = context[]
is_current_context(x) = x == context[]
clear_context!() = (context[] = DummyContext(:none))
set_context!(x::DummyContext) = (context[] = x)
function native_context_active(x)
    error("Not implemented for $(typeof(x))")
end

function is_context_active(x::DummyContext)
    is_current_context(x) &&
    native_context_active(x.id)
end

function native_switch_context!(x)
    error("Not implemented for $(typeof(x))")
end

Base.Symbol(c::DummyContext) = c.id
Base.convert(::Type{Symbol}, c::DummyContext) = c.id

function exists_context()
    if current_context().id == :none
        error("Couldn't find valid OpenGL Context. OpenGL Context active?")
    end
end

#These have to get overloaded for the pipeline to work!
swapbuffers(c::AbstractContext) = return
Base.clear!(c::AbstractContext) = return


####################NEW
########################################################################################
# OpenGL Arrays


const GLArrayEltypes = Union{StaticVector, Real, Colorant}
"""
Transform julia datatypes to opengl enum type
"""
julia2glenum(x::Type{T}) where {T <: FixedPoint} = julia2glenum(FixedPointNumbers.rawtype(x))
julia2glenum(x::Type{OffsetInteger{O, T}}) where {O, T} = julia2glenum(T)
julia2glenum(x::Union{Type{T}, T}) where {T <: Union{StaticVector, Colorant}} = julia2glenum(eltype(x))
julia2glenum(x::Type{GLubyte})  = GL_UNSIGNED_BYTE
julia2glenum(x::Type{GLbyte})   = GL_BYTE
julia2glenum(x::Type{GLuint})   = GL_UNSIGNED_INT
julia2glenum(x::Type{GLushort}) = GL_UNSIGNED_SHORT
julia2glenum(x::Type{GLshort})  = GL_SHORT
julia2glenum(x::Type{GLint})    = GL_INT
julia2glenum(x::Type{GLfloat})  = GL_FLOAT
julia2glenum(x::Type{GLdouble}) = GL_DOUBLE
julia2glenum(x::Type{Float16})  = GL_HALF_FLOAT
function julia2glenum(::Type{T}) where T
    glasserteltype(T)
    julia2glenum(eltype(T))
end
