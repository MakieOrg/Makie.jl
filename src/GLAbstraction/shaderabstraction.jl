
struct GLContext{T} <: ShaderAbstraction.AbstractContext
    context::T
    opengl_version::VersionNumber
    glsl_version::VersionNumber
    # Use a unique id, since we can't track this via pointer identity
    # (OpenGL may reuse the same pointers)
    unique_id::UInt64
end

let counter = Threads.Atomic{UInt64}(0)
    global unique_context_counter
    function unique_context_counter()
        # dont start at zero, so we can keep zero special
        counter[] = counter[] + 1
        return counter[]
    end
end

function GLContext(::Nothing)
    return GLContext(nothing, v"0.0.0", v"0.0.0", UInt64(0))
end
