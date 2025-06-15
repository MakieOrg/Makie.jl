getnames(check_function::Function) = filter(check_function, uint32(0:65534))

# gets all the names currently boundo to programs
getProgramNames() = getnames(glIsProgram)
getShaderNames() = getnames(glIsShader)
getVertexArrayNames() = getnames(glIsVertexArray)

# display info for all active uniforms in a program
function getUniformsInfo(p::GLProgram)
    program = p.id
    # Get uniforms info (not in named blocks)
    @show activeUnif = glGetProgramiv(program, GL_ACTIVE_UNIFORMS)
    bufSize = 16
    name = zeros(UInt8, bufSize)
    buflen = Ref{GLsizei}(0)
    size = Ref{GLint}(0)
    type = Ref{GLenum}()

    for i in 0:(activeUnif - 1)
        glGetActiveUniform(program, i, bufSize, buflen, size, type, name)
        println(String(name), " ", buflen[], " ", size[], " ", GLENUM(type[]).name)
    end
    return
end

function uniform_name_type(p::GLProgram, location)
    bufSize = 32
    name = zeros(UInt8, bufSize)
    buflen = Ref{GLsizei}(0)
    size = Ref{GLint}(0)
    type = Ref{GLenum}()
    glGetActiveUniform(p.id, location, bufSize, buflen, size, type, name)
    return println(String(name), " ", buflen[], " ", size[], " ", GLENUM(type[]).name)
end

# display the values for uniforms in the default block
function getUniformInfo(p::GLProgram, uniName::Symbol)
    # is it a program ?
    @show program = p.id
    @show loc = glGetUniformLocation(program, uniName)
    return @show name, typ, uniform_size = glGetActiveUniform(program, loc)
end


# display the values for a uniform in a named block
function getUniformInBlockInfo(p::GLProgram, blockName, uniName)
    program = p.id

    @show index = glGetUniformBlockIndex(program, blockName)
    if (index == GL_INVALID_INDEX)
        println("$uniName is not a valid uniform name in block $blockName")
    end
    @show bindIndex = glGetActiveUniformBlockiv(program, index, GL_UNIFORM_BLOCK_BINDING)
    @show bufferIndex = glGetIntegeri_v(GL_UNIFORM_BUFFER_BINDING, bindIndex)
    @show uniIndex = glGetUniformIndices(program, uniName)

    @show uniType = glGetActiveUniformsiv(program, uniIndex, GL_UNIFORM_TYPE)
    @show uniOffset = glGetActiveUniformsiv(program, uniIndex, GL_UNIFORM_OFFSET)
    @show uniSize = glGetActiveUniformsiv(program, uniIndex, GL_UNIFORM_SIZE)
    @show uniArrayStride = glGetActiveUniformsiv(program, uniIndex, GL_UNIFORM_ARRAY_STRIDE)
    return @show uniMatStride = glGetActiveUniformsiv(program, uniIndex, GL_UNIFORM_MATRIX_STRIDE)
end


# display information for a program's attributes
function getAttributesInfo(p::GLProgram)

    program = p.id
    # how many attribs?
    @show activeAttr = glGetProgramiv(program, GL_ACTIVE_ATTRIBUTES)
    # get location and type for each attrib
    for i in 0:(activeAttr - 1)
        @show name, typ, size = glGetActiveAttrib(program, i)
        @show loc = glGetAttribLocation(program, name)
    end
    return
end


# display program's information
function getProgramInfo(p::GLProgram)
    # check if name is really a program
    @show program = p.id
    # Get the shader's name
    @show shaders = glGetAttachedShaders(program)
    for shader in shaders
        @show info = GLENUM(convert(GLenum, glGetShaderiv(shader, GL_SHADER_TYPE))).name
    end
    # Get program info
    @show info = glGetProgramiv(program, GL_PROGRAM_SEPARABLE)
    @show info = glGetProgramiv(program, GL_PROGRAM_BINARY_RETRIEVABLE_HINT)
    @show info = glGetProgramiv(program, GL_LINK_STATUS)
    @show info = glGetProgramiv(program, GL_VALIDATE_STATUS)
    @show info = glGetProgramiv(program, GL_DELETE_STATUS)
    @show info = glGetProgramiv(program, GL_ACTIVE_ATTRIBUTES)
    @show info = glGetProgramiv(program, GL_ACTIVE_UNIFORMS)
    @show info = glGetProgramiv(program, GL_ACTIVE_UNIFORM_BLOCKS)
    @show info = glGetProgramiv(program, GL_ACTIVE_ATOMIC_COUNTER_BUFFERS)
    @show info = glGetProgramiv(program, GL_TRANSFORM_FEEDBACK_BUFFER_MODE)
    return @show info = glGetProgramiv(program, GL_TRANSFORM_FEEDBACK_VARYINGS)
end

const FAILED_FREE_COUNTER = Threads.Atomic{Int}(0)
function verify_free(obj::T, name = T) where {T}
    return if obj.id != 0
        FAILED_FREE_COUNTER[] += 1
        Core.println(Core.stderr, "Error: $name with id $(obj.id) has not been freed.")
    end
end
