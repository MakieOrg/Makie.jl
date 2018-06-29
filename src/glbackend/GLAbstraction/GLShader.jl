# Different shader string literals- usage: e.g. frag" my shader code"
macro frag_str(source::AbstractString)
    quote
        ($source, GL_FRAGMENT_SHADER)
    end
end
macro vert_str(source::AbstractString)
    quote
        ($source, GL_VERTEX_SHADER)
    end
end
macro geom_str(source::AbstractString)
    quote
        ($source, GL_GEOMETRY_SHADER)
    end
end
macro comp_str(source::AbstractString)
    quote
        ($source, GL_COMPUTE_SHADER)
    end
end

function getinfolog(obj::GLuint)
    # Return the info log for obj, whether it be a shader or a program.
    isShader    = glIsShader(obj)
    getiv       = isShader == GL_TRUE ? glGetShaderiv : glGetProgramiv
    get_log     = isShader == GL_TRUE ? glGetShaderInfoLog : glGetProgramInfoLog

    # Get the maximum possible length for the descriptive error message
    maxlength = GLint[0]
    getiv(obj, GL_INFO_LOG_LENGTH, maxlength)
    maxlength = first(maxlength)
    # Return the text of the message if there is any
    if maxlength > 0
        buffer = zeros(GLchar, maxlength)
        sizei = GLsizei[0]
        get_log(obj, maxlength, sizei, buffer)
        length = first(sizei)
        return unsafe_string(pointer(buffer), length)
    else
        return "success"
    end
end

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

abstract type AbstractLazyShader end
struct LazyShader <: AbstractLazyShader
    paths::Tuple
    kw_args::Dict{Symbol, Any}
    function LazyShader(paths...; kw_args...)
        args = Dict{Symbol, Any}(kw_args)
        get!(args, :view, Dict{String, String}())
        new(paths, args)
    end
end



# caching templated shaders is a pain -.-

# cache for template keys per file
# path --> template keys
const _template_cache = Dict{String, Vector{String}}()
# path --> Dict{template_replacements --> Shader)
const _shader_cache = Dict{String, Dict{Any, Shader}}()


function empty_shader_cache!()
    empty!(_template_cache)
    empty!(_shader_cache)
    empty!(_program_cache)
end

# TODO remove this silly constructor
function compile_shader(source::Vector{UInt8}, typ, name)
    shaderid = createshader(typ)
    glShaderSource(shaderid, source)
    glCompileShader(shaderid)
    if !GLAbstraction.iscompiled(shaderid)
        GLAbstraction.print_with_lines(String(source))
        warn("shader $(name) didn't compile. \n$(GLAbstraction.getinfolog(shaderid))")
    end
    Shader(name, source, typ, shaderid)
end

function compile_shader(path, source_str::AbstractString)
    typ = GLAbstraction.shadertype(query(path))
    source = Vector{UInt8}(source_str)
    name = Symbol(path)
    compile_shader(source, typ, name)
end

function createshader(shadertype::GLenum)
    shaderid = glCreateShader(shadertype)
    @assert shaderid > 0 "opengl context is not active or shader type not accepted. Shadertype: $(GLENUM(shadertype).name)"
    shaderid::GLuint
end

function get_shader!(path, template_replacement, view, attributes)
    # this should always be in here, since we already have the template keys
    shader_dict = _shader_cache[path]
    get!(shader_dict, template_replacement) do
        template_source = readstring(path)
        source = mustache_replace(template_replacement, template_source)
        compile_shader(path, source)::Shader
    end::Shader
end
function get_template!(path, view, attributes)
    get!(_template_cache, path) do
        _, ext = splitext(path)

        typ = shadertype(ext)
        template_source = readstring(path)
        source, replacements = template2source(
            template_source, view, attributes
        )
        s = compile_shader(path, source)
        template_keys = collect(keys(replacements))
        template_replacements = collect(values(replacements))
        # can't yet be in here, since we didn't even have template keys
        _shader_cache[path] = Dict(template_replacements => s)

        template_keys
    end
end

function get_view(kw_dict)
    _view = kw_dict[:view]
    extension = is_apple() ? "" : "#extension GL_ARB_draw_instanced : enable\n"
    _view["GLSL_EXTENSION"] = extension*get(_view, "GLSL_EXTENSIONS", "")
    _view["GLSL_VERSION"] = glsl_version_string()
    _view
end

#TODO shadercleanup: LazyShader is really a lazyprogram....
function gl_convert(lazyshader::AbstractLazyShader, data)
    kw_dict = lazyshader.kw_args
    paths = lazyshader.paths
    if all(x-> isa(x, Shader), paths)
        fragdatalocation = get(kw_dict, :fragdatalocation, Tuple{Int, String}[])
        return Program([paths...], fragdatalocation)
    end
    v = get_view(kw_dict)
    fragdatalocation = get(kw_dict, :fragdatalocation, Tuple{Int, String}[])
    # Tuple(Source, ShaderType)
    if all(paths) do x
            isa(x, Tuple) && length(x) == 2 &&
            isa(first(x), String) &&
            isa(last(x), GLenum)
        end
        # we don't cache view & templates for shader strings!
        shaders = map(paths) do source_typ
            source, typ = source_typ
            src, _ = template2source(source, v, data)
            compile_shader(Vector{UInt8}(src), typ, :from_string)
        end
        return Program([shaders...], fragdatalocation)
    end
    if !all(x-> isa(x, String), paths)
        error("Please supply only paths or tuples of (source, typ) for Lazy Shader
            Found: $paths"
        )
    end
    template_keys = Vector{Vector{String}}(length(paths))
    replacements = Vector{Vector{String}}(length(paths))
    for (i, path) in enumerate(paths)
        template = get_template!(path, v, data)
        template_keys[i] = template
        replacements[i] = String[mustache2replacement(t, v, data) for t in template]
    end
    program = get!(_program_cache, (paths, replacements)) do
        # when we're here, this means there were uncached shaders, meaning we definitely have
        # to compile a new program
        shaders = Vector{Shader}(length(paths))
        for (i, path) in enumerate(paths)
            tr = Dict(zip(template_keys[i], replacements[i]))
            shaders[i] = get_shader!(path, tr, v, data)
        end
        Program([shaders...], fragdatalocation)
    end
end

function insert_from_view(io, replace_view::Function, keyword::AbstractString)
    print(io, replace_view(keyword))
    nothing
end

function insert_from_view(io, replace_view::Dict, keyword::AbstractString)
    if haskey(replace_view, keyword)
        print(io, replace_view[keyword])
    end
    nothing
end
"""
Replaces
{{keyword}} with the key in `replace_view`, or replace_view(key)
in a string
"""
function mustache_replace(replace_view::Union{Dict, Function}, string)
    io = IOBuffer()
    replace_started = false
    open_mustaches = 0
    closed_mustaches = 0
    i = 0
    replace_begin = i
    last_char = SubString(string, 1, 1)
    len = endof(string)
    while i <= len
        i = nextind(string, i)
        i > len && break
        char = string[i]
        if replace_started
            # ignore, or wait for }
            if char == '}'
                closed_mustaches += 1
                if closed_mustaches == 2 # we found a complete mustache!
                    insert_from_view(io, replace_view, SubString(string, replace_begin+1, i-2))
                    open_mustaches = 0
                    closed_mustaches = 0
                    replace_started = false
                end
            else
                closed_mustaches = 0
                continue
            end
        elseif char == '{'
            open_mustaches += 1
            if open_mustaches == 2
                replace_begin = i
                replace_started = true
            end
        else
            if open_mustaches == 1
                print(io, last_char)
            end
            print(io, char) # just copy all the rest
            open_mustaches = 0
            closed_mustaches = 0
        end
        last_char = char
    end
    String(take!(io))
end


function mustache2replacement(mustache_key, view, attributes)
    haskey(view, mustache_key) && return view[mustache_key]
    for postfix in ("_type", "_calculation")
        keystring = replace(mustache_key, postfix, "")
        keysym = Symbol(keystring)
        if haskey(attributes, keysym)
            val = attributes[keysym]
            if !isa(val, AbstractString)
                return if postfix == "_type"
                    toglsltype_string(val)::String
                else  postfix == "_calculation"
                    glsl_variable_access(keystring, val)::String
                end
            end
        end
    end
    "" # no match found, leave empty!
end

# Takes a shader template and renders the template and returns shader source
template2source(source::Vector{UInt8}, view, attributes::Dict{Symbol, Any}) = template2source(String(source), attributes, view)
function template2source(source::AbstractString, view, attributes::Dict{Symbol, Any})
    replacements = Dict{String, String}()
    source = mustache_replace(source) do mustache_key
        r = mustache2replacement(mustache_key, view, attributes)
        replacements[mustache_key] = r
        r
    end
    source, replacements
end

function glsl_version_string()
    glsl = split(unsafe_string(glGetString(GL_SHADING_LANGUAGE_VERSION)), ['.', ' '])
    if length(glsl) >= 2
        glsl = VersionNumber(parse(Int, glsl[1]), parse(Int, glsl[2]))
        glsl.major == 1 && glsl.minor <= 2 && error("OpenGL shading Language version too low. Try updating graphic driver!")
        glsl_version = string(glsl.major) * rpad(string(glsl.minor),2,"0")
        return "#version $(glsl_version)\n"
    else
        error("could not parse GLSL version: $glsl")
    end
end
function iscompiled(shader::GLuint)
    success = GLint[0]
    glGetShaderiv(shader, GL_COMPILE_STATUS, success)
    return first(success) == GL_TRUE
end

#Note: fragdatalocation sets to which buffer one should write. That is, it links
#      a word inside the shader to a certain framebuffer.
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
        nametypedict = uniform_name_type(program)
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

islinked(program::GLuint) = glGetProgramiv(program, GL_LINK_STATUS) == GL_TRUE

function createprogram()
    program = glCreateProgram()
    @assert program > 0 "couldn't create program. Most likely, opengl context is not active"
    program::GLuint
end

shadertype(s::Shader) = s.typ
function shadertype(f::File{format"GLSLShader"})
    shadertype(file_extension(f))
end
function shadertype(ext::AbstractString)
    ext == ".comp" && return GL_COMPUTE_SHADER
    ext == ".vert" && return GL_VERTEX_SHADER
    ext == ".frag" && return GL_FRAGMENT_SHADER
    ext == ".geom" && return GL_GEOMETRY_SHADER
    error("$ext not a valid extension for $f")
end

#Implement File IO interface
function load(f::File{format"GLSLShader"})
    fname = filename(f)
    source = open(readstring, fname)
    compile_shader(fname, source)
end
function save(f::File{format"GLSLShader"}, data::Shader)
    s = open(f, "w")
    write(s, data.source)
    close(s)
end

function uniformlocations(nametypedict::Dict{Symbol, GLenum}, program)
    result = Dict{Symbol, Tuple}()
    texturetarget = -1 # start -1, as texture samplers start at 0
    for (name, typ) in nametypedict
        loc = get_uniform_location(program, name)
        str_name = string(name)
        if istexturesampler(typ)
            texturetarget += 1
            result[name] = (loc, texturetarget)
        else
            result[name] = (loc,)
        end
    end
    return result
end

const _program_cache = Dict{Any, Program}()

#TODO: shadercleanup: is this necessary?
gl_convert(shader::Program, data) = shader


# function compile_program(shaders, fragdatalocation)
#     # Remove old shaders
#     program = createprogram()
#     glUseProgram(program)
#     #attach new ones
#     foreach(shaders) do shader
#         glAttachShader(program, shader.id)
#     end
#
#     #Bind frag data
#     for (location, name) in fragdatalocation
#         glBindFragDataLocation(program, location, ascii(name))
#     end
#
#     #link program
#     glLinkProgram(program)
#     if !GLAbstraction.islinked(program)
#         error(
#             "program $program not linked. Error in: \n",
#             join(map(x-> string(x.name), shaders), " or "), "\n", getinfolog(program)
#         )
#     end
#     # Can be deleted, as they will still be linked to Program and released after program gets released
#     #foreach(glDeleteShader, shader_ids)
#     # generate the link locations
#     nametypedict = uniform_name_type(program)
#     uniformlocationdict = uniformlocations(nametypedict, program)
#     Program(program, shaders, nametypedict, uniformlocationdict)
# end
