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

function iscompiled(shader::GLuint)
    success = GLint[0]
    glGetShaderiv(shader, GL_COMPILE_STATUS, success)
    return first(success) == GL_TRUE
end
islinked(program::GLuint) = glGetProgramiv(program, GL_LINK_STATUS) == GL_TRUE

function createshader(shadertype::GLenum)
    shaderid = glCreateShader(shadertype)
    @assert shaderid > 0 "opengl context is not active or shader type not accepted. Shadertype: $(GLENUM(shadertype).name)"
    shaderid::GLuint
end
function createprogram()
    program = glCreateProgram()
    @assert program > 0 "couldn't create program. Most likely, opengl context is not active"
    program::GLuint
end

shadertype(s::Shader) = s.typ
function shadertype(ext::AbstractString)
    ext == ".comp" && return GL_COMPUTE_SHADER
    ext == ".vert" && return GL_VERTEX_SHADER
    ext == ".frag" && return GL_FRAGMENT_SHADER
    ext == ".geom" && return GL_GEOMETRY_SHADER
    error("$ext not a valid shader extension")
end

function uniformlocations(nametypedict::Dict{Symbol, GLenum}, program)
    result = Dict{Symbol, Tuple}()
    texturetarget = -1 # start -1, as texture samplers start at 0
    for (name, typ) in nametypedict
        loc = get_uniform_location(program, name)
        if istexturesampler(typ)
            texturetarget += 1
            result[name] = (loc, texturetarget)
        else
            result[name] = (loc,)
        end
    end
    return result
end

struct ShaderCache
    # path --> template keys
    # cache for template keys per file
    template_cache::Dict{String, Vector{String}}
    # path --> Dict{template_replacements --> Shader)
    shader_cache::Dict{String, Dict{Any, Shader}}
    program_cache::Dict{Any, GLProgram}
end

function ShaderCache()
    ShaderCache(
        Dict{String, Vector{String}}(),
        Dict{String, Dict{Any, Shader}}(),
        Dict{Any, GLProgram}()
    )
end


abstract type AbstractLazyShader end
struct LazyShader <: AbstractLazyShader
    shader_cache::ShaderCache
    paths::Tuple
    kw_args::Dict{Symbol, Any}
    function LazyShader(cache::ShaderCache, paths...; kw_args...)
        args = Dict{Symbol, Any}(kw_args)
        get!(args, :view, Dict{String, String}())
        new(cache, paths, args)
    end
end

gl_convert(shader::GLProgram, data) = shader


# TODO remove this silly constructor
function compile_shader(source::Vector{UInt8}, typ, name)
    shaderid = createshader(typ)
    glShaderSource(shaderid, source)
    glCompileShader(shaderid)
    if !GLAbstraction.iscompiled(shaderid)
        GLAbstraction.print_with_lines(String(source))
        @warn("shader $(name) didn't compile. \n$(GLAbstraction.getinfolog(shaderid))")
    end
    Shader(name, source, typ, shaderid)
end

function compile_shader(path, source_str::AbstractString)
    typ = shadertype(splitext(path)[2])
    source = Vector{UInt8}(source_str)
    name = Symbol(path)
    compile_shader(source, typ, name)
end

function get_shader!(cache::ShaderCache, path, template_replacement)
    # this should always be in here, since we already have the template keys
    shader_dict = cache.shader_cache[path]
    get!(shader_dict, template_replacement) do
        template_source = read(path, String)
        source = mustache_replace(template_replacement, template_source)
        compile_shader(path, source)
    end::Shader
end

function get_template!(cache::ShaderCache, path, view, attributes)
    get!(cache.template_cache, path) do
        _, ext = splitext(path)

        typ = shadertype(ext)
        template_source = read(path, String)
        source, replacements = template2source(
            template_source, view, attributes
        )
        s = compile_shader(path, source)
        template_keys = collect(keys(replacements))
        template_replacements = collect(values(replacements))
        # can't yet be in here, since we didn't even have template keys
        cache.shader_cache[path] = Dict(template_replacements => s)

        template_keys
    end
end


function compile_program(shaders, fragdatalocation)
    # Remove old shaders
    program = createprogram()
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
    if !GLAbstraction.islinked(program)
        error(
            "program $program not linked. Error in: \n",
            join(map(x-> string(x.name), shaders), " or "), "\n", getinfolog(program)
        )
    end
    # Can be deleted, as they will still be linked to Program and released after program gets released
    #foreach(glDeleteShader, shader_ids)
    # generate the link locations
    nametypedict = uniform_name_type(program)
    uniformlocationdict = uniformlocations(nametypedict, program)
    GLProgram(program, shaders, nametypedict, uniformlocationdict)
end

function get_view(kw_dict)
    _view = kw_dict[:view]
    extension = Sys.isapple() ? "" : "#extension GL_ARB_draw_instanced : enable\n"
    _view["GLSL_EXTENSION"] = extension*get(_view, "GLSL_EXTENSIONS", "")
    _view["GLSL_VERSION"] = glsl_version_string()
    _view
end

gl_convert(lazyshader::AbstractLazyShader, data) = error("gl_convert shader")
function gl_convert(lazyshader::LazyShader, data)
    gl_convert(lazyshader.shader_cache, lazyshader, data)
end
function gl_convert(cache::ShaderCache, lazyshader::AbstractLazyShader, data)
    kw_dict = lazyshader.kw_args
    paths = lazyshader.paths
    if all(x-> isa(x, Shader), paths)
        fragdatalocation = get(kw_dict, :fragdatalocation, Tuple{Int, String}[])
        return compile_program([paths...], fragdatalocation)
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
        return compile_program([shaders...], fragdatalocation)
    end
    if !all(x-> isa(x, String), paths)
        error("Please supply only paths or tuples of (source, typ) for Lazy Shader
            Found: $paths"
        )
    end
    template_keys = Vector{Vector{String}}(undef, length(paths))
    replacements = Vector{Vector{String}}(undef, length(paths))
    for (i, path) in enumerate(paths)
        template = get_template!(cache, path, v, data)
        template_keys[i] = template
        replacements[i] = String[mustache2replacement(t, v, data) for t in template]
    end
    program = get!(cache.program_cache, (paths, replacements)) do
        # when we're here, this means there were uncached shaders, meaning we definitely have
        # to compile a new program
        shaders = Vector{Shader}(undef, length(paths))
        for (i, path) in enumerate(paths)
            tr = Dict(zip(template_keys[i], replacements[i]))
            shaders[i] = get_shader!(cache, path, tr)
        end
        compile_program(shaders, fragdatalocation)
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
    len = lastindex(string)
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
        keystring = replace(mustache_key, postfix => "")
        keysym = Symbol(keystring)
        if haskey(attributes, keysym)
            val = attributes[keysym]
            if !isa(val, AbstractString)
                if postfix == "_type"
                    return toglsltype_string(val)::String
                else  postfix == "_calculation"
                    return glsl_variable_access(keystring, val)
                end
            end
        end
    end
    return ""
    # error("No match found: $(mustache_key)")
end

# Takes a shader template and renders the template and returns shader source
template2source(source::Vector{UInt8}, view, attributes::Dict{Symbol, Any}) = template2source(String(source), attributes, view)
function template2source(source::AbstractString, view, attributes::Dict{Symbol, Any})
    replacements = Dict{String, String}()
    source = mustache_replace(source) do mustache_key
        r = mustache2replacement(mustache_key, view, attributes)
        replacements[mustache_key] = r
        return r
    end
    return source, replacements
end
