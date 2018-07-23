getnames(check_function::Function) = filter(check_function, uint32(0:65534))

# gets all the names currently boundo to programs
getProgramNames()	  = getnames(glIsProgram)
getShaderNames() 	  = getnames(glIsShader)
getVertexArrayNames() = getnames(glIsVertexArray)

# display info for all active uniforms in a program
function getUniformsInfo(p::Program) 
	program = p.id
	# Get uniforms info (not in named blocks)
	@show activeUnif = glGetProgramiv(program, GL_ACTIVE_UNIFORMS)

	for i=0:activeUnif-1
		@show index = glGetActiveUniformsiv(program, i, GL_UNIFORM_BLOCK_INDEX)
		if (index == -1) 
			@show name 		     = glGetActiveUniformName(program, i)	
			@show uniType 	   	 = glGetActiveUniformsiv(program, i, GL_UNIFORM_TYPE)

			@show uniSize 	   	 = glGetActiveUniformsiv(program, i, GL_UNIFORM_SIZE)
			@show uniArrayStride = glGetActiveUniformsiv(program, i, GL_UNIFORM_ARRAY_STRIDE)

			auxSize = 0
			if (uniArrayStride > 0)
				@show auxSize = uniArrayStride * uniSize
			else
				@show auxSize = spGLSLTypeSize[uniType]
			end
		end
	end
	# Get named blocks info
	@show count = glGetProgramiv(program, GL_ACTIVE_UNIFORM_BLOCKS)

	for i=0:count-1 
		# Get blocks name
		@show name 	 		 = glGetActiveUniformBlockName(program, i)
		@show dataSize 		 = glGetActiveUniformBlockiv(program, i, GL_UNIFORM_BLOCK_DATA_SIZE)

		@show index 	 		 = glGetActiveUniformBlockiv(program, i,  GL_UNIFORM_BLOCK_BINDING)
		@show binding_point 	 = glGetIntegeri_v(GL_UNIFORM_BUFFER_BINDING, index)

		@show activeUnif   	 = glGetActiveUniformBlockiv(program, i, GL_UNIFORM_BLOCK_ACTIVE_UNIFORMS)

		indices = zeros(GLuint, activeUnif)
		glGetActiveUniformBlockiv(program, i, GL_UNIFORM_BLOCK_ACTIVE_UNIFORM_INDICES, indices)
		@show indices	
		for ubindex in indices
			@show name 		   = glGetActiveUniformName(program, ubindex)
			@show uniType 	   = glGetActiveUniformsiv(program, ubindex, GL_UNIFORM_TYPE)
			@show uniOffset    = glGetActiveUniformsiv(program, ubindex, GL_UNIFORM_OFFSET)
			@show uniSize 	   = glGetActiveUniformsiv(program, ubindex, GL_UNIFORM_SIZE)
			@show uniMatStride = glGetActiveUniformsiv(program, ubindex, GL_UNIFORM_MATRIX_STRIDE)
		end
	end
end


# display the values for uniforms in the default block
function getUniformInfo(p::Program, uniName::Symbol) 
	# is it a program ?
	@show program 				  = p.id
	@show loc 	  				  = glGetUniformLocation(program, uniName)
	@show name, typ, uniform_size = glGetActiveUniform(program, loc)
end


# display the values for a uniform in a named block
function getUniformInBlockInfo(p::Program, 
				blockName, 
				uniName) 

	program = p.id

	@show index = glGetUniformBlockIndex(program, blockName)
	if (index == GL_INVALID_INDEX) 
		println("$uniName is not a valid uniform name in block $blockName")
	end
	@show bindIndex 		= glGetActiveUniformBlockiv(program, index, GL_UNIFORM_BLOCK_BINDING)
	@show bufferIndex 		= glGetIntegeri_v(GL_UNIFORM_BUFFER_BINDING, bindIndex)
	@show uniIndex 			= glGetUniformIndices(program, uniName)
	
	@show uniType 			= glGetActiveUniformsiv(program, uniIndex, GL_UNIFORM_TYPE)
	@show uniOffset 		= glGetActiveUniformsiv(program, uniIndex, GL_UNIFORM_OFFSET)
	@show uniSize 			= glGetActiveUniformsiv(program, uniIndex, GL_UNIFORM_SIZE)
	@show uniArrayStride 	= glGetActiveUniformsiv(program, uniIndex, GL_UNIFORM_ARRAY_STRIDE)
	@show uniMatStride 		= glGetActiveUniformsiv(program, uniIndex, GL_UNIFORM_MATRIX_STRIDE)
end


# display information for a program's attributes
function getAttributesInfo(p::Program) 

	program = p.id
	# how many attribs?
	@show activeAttr = glGetProgramiv(program, GL_ACTIVE_ATTRIBUTES)
	# get location and type for each attrib
	for i=0:activeAttr-1
		@show name, typ, siz = glGetActiveAttrib(program,	i)
		@show loc = glGetAttribLocation(program, name)
	end
end


# display program's information
function getProgramInfo(p::Program) 
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
	@show info = glGetProgramiv(program, GL_TRANSFORM_FEEDBACK_VARYINGS)
end


