The OpenGL backend for [Makie](https://github.com/MakieOrg/Makie.jl)

Read the docs for Makie and its backends [here](http://makie.juliaplots.org/dev)

## Issues
Please file all issues in [Makie.jl](https://github.com/MakieOrg/Makie.jl/issues/new), and mention GLMakie in the issue text!


## Troubleshooting OpenGL

If you get any error loading GLMakie, it likely means, you don't have an OpenGL capable Graphic Card, or you don't have an OpenGL 3.3 capable video driver installed.
Note, that most GPUs, even 8 year old integrated ones, support OpenGL 3.3.

On Linux, you can find out your OpenGL version with:
`glxinfo | grep "OpenGL version"`

If you're using an AMD or Intel gpu on linux, you may run into [GLFW#198](https://github.com/JuliaGL/GLFW.jl/issues/198).

If you're on a headless server, you still need to install x-server and
proper graphics drivers.

You can find instructions to set that up in:

https://nextjournal.com/sdanisch/GLMakie-nogpu
And for a headless github action:

https://github.com/MakieOrg/Makie.jl/blob/master/.github/workflows/glmakie.yaml
If none of these work for you, there is also a Cairo and WebGL backend
for Makie which you can use:

https://github.com/MakieOrg/Makie.jl/tree/master/CairoMakie.

https://github.com/MakieOrg/Makie.jl/tree/master/WGLMakie.

If you get an error pointing to [GLFW.jl](https://github.com/JuliaGL/GLFW.jl), please look into the existing [GLFW issues](https://github.com/JuliaGL/GLFW.jl/issues), and also google for those errors. This is then very likely something that needs fixing in the  [glfw c library](https://github.com/glfw/glfw) or in the GPU drivers.


## WSL setup or X-forwarding

From: https://github.com/Microsoft/WSL/issues/2855#issuecomment-358861903

WSL runs OpenGL alright, but it is not a supported scenario.
From a clean Ubuntu install from the store do:

```
sudo apt install ubuntu-desktop mesa-utils
export DISPLAY=localhost:0
glxgears
```

On the Windows side:

1) install [VcXsrv](https://sourceforge.net/projects/vcxsrv/)
2) choose multiple windows -> display 0 -> start no client -> disable native opengl

Troubleshooting:

1.)  install: `sudo apt-get install -y xorg-dev mesa-utils xvfb libgl1 freeglut3-dev libxrandr-dev libxinerama-dev libxcursor-dev libxi-dev libxext-dev`

2.) WSL has some problems with passing through localhost, so one may need to use: `export DISPLAY=192.168.178.31:0`, with the local ip of the pcs network adapter, which runs VcXsrv

3.) One may need `mv /opt/julia-1.5.2/lib/julia/libstdc++.so.6 /opt/julia-1.5.2/lib/julia/libcpp.backup`, another form of [GLFW#198](https://github.com/JuliaGL/GLFW.jl/issues/198)
