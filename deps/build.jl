install_tips = """
OpenGL/GLFW wasn't installed correctly. This likely means,
you don't have an OpenGL capable Graphic Card,
you don't have the newest video driver installed,
or the GLFW build failed. If you're on linux and `]build` GLFW failed,
try manually adding `sudo apt-get install libglfw3` and then `]build GLMakie`.
If you're on a headless server, you still need to install x-server and
proper GPU drivers. You can take inspiration from this article
on how to get Makie running on a headless system:
https://nextjournal.com/sdanisch/makie-1.0
If you don't have a GPU, there is also a Cairo software backend
for Makie which you can use:
https://github.com/JuliaPlots/CairoMakie.jl.
Please check the below error and open an issue at:
https://github.com/JuliaPlots/GLMakie.jl.
After you fixed your OpenGL install, please run `]build GLMakie` again!
GLMakie will still load, but will be disabled as a default backend for Makie
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
    println(stderr, "init error of GLFW")
    error(install_tips)
end
