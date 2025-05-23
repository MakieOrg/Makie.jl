
# GLMakie {#GLMakie}

[GLMakie](https://github.com/MakieOrg/Makie.jl/tree/master/GLMakie) is the native, desktop-based backend, and is the most feature-complete. It requires an OpenGL enabled graphics card with OpenGL version 3.3 or higher.

## Activation and screen config {#Activation-and-screen-config}

Activate the backend by calling `GLMakie.activate!()`:
<details class='jldocstring custom-block' open>
<summary><a id='GLMakie.activate!' href='#GLMakie.activate!'><span class="jlbinding">GLMakie.activate!</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
GLMakie.activate!(; screen_config...)
```


Sets GLMakie as the currently active backend and also optionally modifies the screen configuration using `screen_config` keyword arguments. Note that the `screen_config` can also be set permanently via `Makie.set_theme!(GLMakie=(screen_config...,))`.

**Arguments one can pass via `screen_config`:**

**Renderloop**
- `renderloop = GLMakie.renderloop`: Sets a function `renderloop(::GLMakie.Screen)` which starts a renderloop for the screen.
  

::: warning Warning

The keyword arguments below are not effective if `renderloop` isn&#39;t set to `GLMakie.renderloop`, unless implemented in a custom renderloop function:

:::
- `pause_renderloop = false`: If `true`, creates a screen with a paused renderloop. The renderloop can be started with `GLMakie.start_renderloop!(screen)` and paused again with `GLMakie.pause_renderloop!(screen)`.
  
- `vsync = false`: Whether to enable vsync for the window.
  
- `render_on_demand = true`: If `true`, the scene will only be rendered if something has changed in it.
  
- `framerate = 30.0`: Sets the currently rendered frames per second.
  
- `px_per_unit = automatic`: Sets the ratio between the number of rendered pixels and the `Makie` resolution. It defaults to the value of `scalefactor` but may be any positive real number.
  

**GLFW window attributes**
- `float = false`: Whether the window should float above other windows.
  
- `focus_on_show = false`: If `true`, focuses the window when newly opened.
  
- `decorated = true`: Whether or not to show window decorations.
  
- `title::String = "Makie"`: Sets the window title.
  
- `fullscreen = false`: Whether to start the window in fullscreen mode.
  
- `debugging = false`: If `true`, starts the GLFW.Window/OpenGL context with debug output.
  
- `monitor::Union{Nothing, GLFW.Monitor} = nothing`: Sets the monitor on which the window should be opened. If set to `nothing`, GLFW will decide which monitor to use.
  
- `visible = true`: Whether or not the window should be visible when first created.
  
- `scalefactor = automatic`: Sets the window scaling factor, such as `2.0` on HiDPI/Retina displays. It is set automatically based on the display, but may be any positive real number.
  

**Rendering constants &amp; Postprocessor**
- `oit = false`: Whether to enable order independent transparency for the window.
  
- `fxaa = true`: Whether to enable fxaa (anti-aliasing) for the window.
  
- `ssao = true`: Whether to enable screen space ambient occlusion, which simulates natural shadowing at inner edges and crevices.
  
- `transparency_weight_scale = 1000f0`: Adjusts a factor in the rendering shaders for order independent transparency.   This should be the same for all of them (within one rendering pipeline) otherwise depth &quot;order&quot; will be broken.
  
- `max_lights = 64`: The maximum number of lights with `shading = MultiLightShading`
  
- `max_light_parameters = 5 * N_lights`: The maximum number of light parameters that can be uploaded. These include everything other than the light color (i.e. position, direction, attenuation, angles) in terms of scalar floats.
  


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/f5fbbfb4328fb1bb82ddf663ef4cba4b04da2f84/GLMakie/src/screen.jl#L127-L136" target="_blank" rel="noreferrer">source</a></Badge>

</details>


#### Window Scaling {#Window-Scaling}

The sizes of figures are given in display-independent &quot;logical&quot; dimensions, and the GLMakie backend will scale the size of the displayed window on HiDPI/Retina displays automatically. For example, the default `size = (800, 600)` will be shown in a 1600 × 1200 window on a HiDPI display which is configured with a 200% scaling factor.

The scaling factor may be overridden by displaying the figure with a different `scalefactor` value:

```julia
fig = Figure(size = (800, 600))
# ...
display(fig, scalefactor = 1.5)
```


If the scale factor is not changed from its default automatic configuration, the window will be resized to maintain its apparent size when moved across displays with different scaling factors on Windows and OSX. (Independent scaling factors are not supported by X11, and at this time the underlying GLFW library is not compiled with Wayland support.)

#### Resolution Scaling {#Resolution-Scaling}

Related to the window scaling factor, the mapping from figure sizes and positions to pixels can be scaled to achieve HiDPI/Retina resolution renderings. The resolution scaling defaults to the same factor as the window scaling, but it may be independently overridden with the `px_per_unit` argument when showing a figure:

```julia
fig = Figure(size = (800, 600))
# ...
display(fig, px_per_unit = 2)
```


The resolution scale factor may also be changed when saving pngs:

```julia
save("hires.png", fig, px_per_unit = 2)    # 1600 × 1200 px png
save("lores.png", fig, px_per_unit = 0.5)  #  400 × 300 px png
```


If a script may run in interactive environments where the native screen DPI can vary, you may want to explicitly set `px_per_unit = 1` when saving figures to ensure consistency of results.

#### Multiple Windows {#Multiple-Windows}

GLMakie has experimental support for displaying multiple independent figures (or scenes). To open a new window, use `display(GLMakie.Screen(), figure_or_scene)`. To close all windows, use `GLMakie.closeall()`.

## Embedding {#Embedding}

There&#39;s experimental support for embedding GLMakie by creating a custom &#39;window&#39; type (analogous to the GLFW OS-level window) and grabbing GLMakie&#39;s framebuffers to display in your own GUI. Here&#39;s a high-level overview of what you&#39;d need to do:
1. Create a `MyWindow` type, which might represent a widget in your chosen GUI framework. Pass an instance of this type to `GLMakie.Screen(; window=my_window, start_renderloop=false)` to get a `Screen{MyWindow}` object without the renderloop running in the background (optional, depends on your application). This is the main object you&#39;ll need to work with.
  
2. Define method specializations for the `MyWindow` type. Here&#39;s a non-exhaustive list:
  - `Base.isopen(::MyWindow)`
    
  - `ShaderAbstractions.native_switch_context!(::MyWindow)` (switch to the OpenGL context of the window)
    
  - `ShaderAbstractions.native_context_alive(::MyWindow)` (check if the window OpenGL context is still valid)
    
  - `GLMakie.framebuffer_size(::MyWindow)` (get the size of the windows framebuffer)
    
  - `GLMakie.destroy!(::MyWindow)` (&#39;destroy&#39; the window, this should be a no-op unless you want GLMakie to really close the window)
    
  - `GLMakie.connect_screen(::Scene, Screen{MyWindow})` (connect input signals for e.g. the keyboard and mouse; you may want to implement the individual connection methods instead).
    
  The actual implementation of all these depends entirely on how you want to embed GLMakie.
  
3. A `Figure` can now be displayed in the new screen by calling `display(screen, f)`. If you&#39;re not using GLMakie&#39;s own renderloop you&#39;ll need to take care of calling `GLMakie.render_frame(screen)` whenever necessary (you can use `GLMakie.requires_update(screen)`).
  
4. `display(screen, f)` will only draw the figure to a framebuffer. You can get the color texture attachment of the framebuffer with `screen.framebuffer.buffers[:color]`, and display that color texture as an image in your chosen GUI framework.
  
5. If interactivity is desired, you will need to pass input events from the keyboard and mouse to the events in `Makie.get_scene(f).events` ([The Events struct](/explanations/events#The-Events-struct)).
  

## Forcing Dedicated GPU Use In Linux {#Forcing-Dedicated-GPU-Use-In-Linux}

Normally the dedicated GPU is used for rendering. If instead an integrated GPU is used, one can tell Julia to use the dedicated GPU while launching julia as `$ sudo DRI_PRIME=1 julia` in the bash terminal. To have it permanently used, add the line `export DRI_PRIME=1` in  your `.bashrc` or `.zshrc` file.

## Troubleshooting OpenGL {#Troubleshooting-OpenGL}

If you get any error loading GLMakie, it likely means you don&#39;t have an OpenGL capable graphics card, or you don&#39;t have an OpenGL 3.3 capable driver installed. Note that most GPUs, even 8 year old integrated ones, support OpenGL 3.3.

On Linux, you can find out your OpenGL version with: `glxinfo | grep "OpenGL version"`

If you&#39;re using an AMD or Intel gpu on linux, you may run into [GLFW#198](https://github.com/JuliaGL/GLFW.jl/issues/198).

If you&#39;re on a headless server, you still need to install x-server and proper graphics drivers.

You can find a demo on how to set that up in this [nextjournal article](https://nextjournal.com/sdanisch/GLMakie-nogpu).

GLMakie&#39;s CI has no GPU, so you can also look at [.github/workflows/glmakie.yaml](https://github.com/MakieOrg/Makie.jl/blob/master/.github/workflows/glmakie.yaml) for a working setup.

If none of these work for you, take a look at the other backends, which all work without a GPU.

If you get an error pointing to [GLFW.jl](https://github.com/JuliaGL/GLFW.jl), please look into the existing [GLFW issues](https://github.com/JuliaGL/GLFW.jl/issues), and also google for those errors. This is then very likely something that needs fixing in the  [glfw c library](https://github.com/glfw/glfw) or in the GPU drivers.

::: warning Warning

GLMakie is not thread-safe! Makie functions to display in GLMakie or updates to `Observable` displayed in GLMakie windows from other threads may not work as expected or cause a segmentation fault.

:::

## WSL setup or X-forwarding {#WSL-setup-or-X-forwarding}

From: [Microsoft/WSL/issues/2855](https://github.com/Microsoft/WSL/issues/2855#issuecomment-358861903)

WSL runs OpenGL alright, but it is not a supported scenario. From a clean Ubuntu install from the store do:

```
sudo apt install ubuntu-desktop mesa-utils
export DISPLAY=localhost:0
glxgears
```


On the Windows side:
1. install [VcXsrv](https://sourceforge.net/projects/vcxsrv/)
  
2. choose multiple windows -&gt; display 0 -&gt; start no client -&gt; disable native opengl
  

Troubleshooting:
1. install:
  
  ```sh
  sudo apt-get install -y xorg-dev mesa-utils xvfb libgl1 freeglut3-dev libxrandr-dev libxinerama-dev libxcursor-dev libxi-dev libxext-dev
  ```
  
  
2. WSL has some problems with passing through localhost, so one may need to use: `export DISPLAY=192.168.178.31:0`, with the local ip of the pcs network adapter, which runs VcXsrv
  
3. One may need `mv /opt/julia-1.5.2/lib/julia/libstdc++.so.6 /opt/julia-1.5.2/lib/julia/libcpp.backup`, another form of [GLFW#198](https://github.com/JuliaGL/GLFW.jl/issues/198)
  

## GLMakie does not show Figure or crashes on full screen mode on macOS {#GLMakie-does-not-show-Figure-or-crashes-on-full-screen-mode-on-macOS}

MacOS gives a warning if a graphical user interface (GUI) is not started from an AppBundle and this exception can crash the Julia process that initiated the GUI.  This warning only occurs if macOS Settings-&gt;Desktop &amp; Dock-&gt;Menu Bar-&gt;Automatically hide and show the menu bar is not set to Never. Therefore make sure this setting is set to `Never` to enable the use of GLMakie on macOS.
