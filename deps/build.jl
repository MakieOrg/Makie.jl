install_tips = """
OpenGL/GLFW wasn't loaded correctly or couldn't be initialized. 
This likely means, you don't have an OpenGL capable Graphic Card,
or you don't have an OpenGL 3.3 capable video driver installed.
If you're on a headless server, you still need to install x-server and
proper graphics drivers.
If you don't have a GPU, there is also a Cairo software backend
for Makie which you can use:
https://github.com/JuliaPlots/CairoMakie.jl.
Please check the below error and open an issue at:
https://github.com/JuliaPlots/GLMakie.jl.
After you fixed your OpenGL install, please run `]build GLMakie`!
Otherwise, GLMakie would still load, but would be disabled as a 
default backend for Makie.
"""
try
    using GLFW
catch e
    open("deps.jl", "w") do io
        println(io, "const WORKING_OPENGL = false")
    end
    # it would be nice to check if this is a GLFW error, but if GLFW doesn't actually load
    # we can't easily use GLFW.GLFWError. Well, GLFW error is the most likely, and
    # we will print the error, to inform the user what happens, so I think this should be fine!
    println(stderr,"Load error for GLFW")
    error(install_tips)
end

try
    using ModernGL
    # Create a windowed mode window and its OpenGL context
    window = GLFW.Window(resolution = (10, 10), major = 3, minor = 3, visible = false, focus = false)
    glversion = unsafe_string(glGetString(GL_VERSION))
    m = match(r"(\d+)\.(\d+)(.\d+)?\s", glversion)
    # I don't really trust that all vendors have a version that matches
    # the above regex, so let's make no match non fatal!
    if m === nothing
        @warn("Unknown OpenGL version format: $glversion. You need to verify if it's above OpenGL 3.3 yourself!")
    else
        v = VersionNumber(parse(Int, m[1]), parse(Int, m[2]))
        if !(v >= v"3.3")
            open("deps.jl", "w") do io
                println(io, "const WORKING_OPENGL = false")
            end
            println(stderr, "Your OpenGL version is too low! Update your driver or GPU! Version found: $v, version required: 3.3")
            error(install_tips)
        end
    end

    open("deps.jl", "w") do io
        println(io, "const WORKING_OPENGL = true")
    end
catch e
    open("deps.jl", "w") do io
        println(io, "const WORKING_OPENGL = false")
    end
    # it would be nice to check if this is a GLFW error, but if GLFW doesn't actually load
    # we can't easily use GLFW.GLFWError. Well, GLFW error is the most likely, and
    # we will print the error, to inform the user what happens, so I think this should be fine!
    println(stderr, "Initialization error of GLFW")
    error(install_tips)
end
