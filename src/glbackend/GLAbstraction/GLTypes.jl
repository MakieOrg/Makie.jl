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
    id::Symbol
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
set_context!(x) = (context[] = x)

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

struct Shader
    name::Symbol
    source::Vector{UInt8}
    typ::GLenum
    id::GLuint
    context::AbstractContext
    function Shader(name, source, typ, id)
        new(name, source, typ, id, current_context())
    end
end
function Shader(name, source::Vector{UInt8}, typ)
    compile_shader(source, typ, name)
end
name(s::Shader) = s.name

import Base: ==

function (==)(a::Shader, b::Shader)
    a.source == b.source && a.typ == b.typ && a.id == b.id && a.context == b.context
end

function Base.hash(s::Shader, h::UInt64)
    hash((s.source, s.typ, s.id, s.context), h)
end


function Base.show(io::IO, shader::Shader)
    println(io, GLENUM(shader.typ).name, " shader: $(shader.name))")
    println(io, "source:")
    print_with_lines(io, String(shader.source))
end

######## NEW
islinked(program::GLuint) = glGetProgramiv(program, GL_LINK_STATUS) == GL_TRUE

abstract type AbstractProgram end
mutable struct Program <: AbstractProgram
    id          ::GLuint
    shaders     ::Vector{Shader}
    nametype    ::Dict{Symbol, GLenum}
    uniformloc  ::Dict{Symbol, Tuple}
    context     ::AbstractContext
    function Program(shaders::Vector{Shader}, fragdatalocation::Vector{Tuple{Int, String}})
        # Remove old shaders
        exists_context()
        program = glCreateProgram()::GLuint
        glUseProgram(program)
        #attach new ones
        foreach(shaders) do shader
            glAttachShader(program, shader.id)
        end

        #Bind frag data
        for (location, name) in fragdatalocation
            glBindFragDataLocation(program, location, ascii(name))
        end

        #link program
        glLinkProgram(program)
        if !islinked(program)
            for shader in shaders
                write(STDOUT, shader.source)
                println("---------------------------")
            end
            error(
                "program $program not linked. Error in: \n",
                join(map(x-> string(x.name), shaders), " or "), "\n", getinfolog(program)
            )
        end

        # generate the link locations
        nametypedict = uniform_nametype(program)
        uniformlocationdict = uniformlocations(nametypedict, program)
        new(program, shaders, nametypedict, uniformlocationdict, current_context())
    end
end

function Program(sh_string_typ...)
    shaders = Shader[]
    for (source, typ) in sh_string_typ
        push!(shaders, Shader(gensym(), typ, Vector{UInt8}(source)))
    end
    Program(shaders, Tuple{Int, String}[])
end


bind(program::Program) = glUseProgram(program.id)
unbind(program::AbstractProgram) = glUseProgram(0)

mutable struct LazyProgram <: AbstractProgram
    sources::Vector
    data::Dict
    compiled_program::Union{Program, Void}
end
LazyProgram(sources...; data...) = LazyProgram(Vector(sources), Dict(data), nothing)

function Program(lazy_program::LazyProgram)
    fragdatalocation = get(lazy_program.data, :fragdatalocation, Tuple{Int, String}[])
    shaders = haskey(lazy_program.data, :arguments) ? Shader.(lazy_program.sources, Ref(lazy_program.data[:arguments])) : Shader.()
    return Program([shaders...], fragdatalocation)
end
function bind(program::LazyProgram)
    iscompiled_orcompile!(program)
    bind(program.compiled_program)
end

function iscompiled_orcompile!(program::LazyProgram)
    if program.compiled_program == nothing
        program.compiled_program = Program(program)
    end
end

##########
# freeing

# OpenGL has the annoying habit of reusing id's when creating a new context
# We need to make sure to only free the current one
function free(x::Program)
    if !is_current_context(x.context)
        return # don't free from other context
    end
    try
        glDeleteProgram(x.id)
    catch e
        free_handle_error(e)
    end
    return
end

function free_handle_error(e)
    #ignore, since freeing is not needed if context is not available
    isa(e, ContextNotAvailable) && return
    rethrow(e)
end
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

include("buffer.jl")
include("texture.jl")

########################################################################

include("vertexarray.jl")

##################################################################################


include("GLRenderObject.jl")




##########################################################################
