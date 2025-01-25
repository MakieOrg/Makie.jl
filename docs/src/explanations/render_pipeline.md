# Render Pipeline

The render pipeline determines in what order plots are rendered and how they get composed into the final image you see.
Currently each backend has its own pipeline which can cause them to behave differently in some cases.
This section aims to summarize how they work and what you can influence to potentially deal with those issues.
Note that this is a fairly in-depth topic that you should usually not need to deal with.
Note as well that we may change pipelines in the future to improve the quality of a backend or the consistency between backends.

## CairoMakie

CairoMakie's pipeline is the simplest out of the backends.
It first draws the backgrounds of each scene with `scene.clear[] == true` recursively, starting with the root scene of the scene tree.
Then it gathers all plots in the scene tree for rendering.
They get sorted based on `Makie.zvalue2d()` which queries `plot.transformation.model` and then rendered if they are visible.
In pseudocode it boils down to:

```julia
function cairo_draw(root_scene)
    draw_background_rec(root_scene)

    all_plots = collect_all_plots_recursively(root_scene)
    for plot in sort!(all_plots, by = Makie.zvalue2d)
        if plot.visible[] && parent_scene(plot).visible[]
            clip_to_parent_scene(plot)
            draw_plot(plot)
        end
    end
end

function draw_background_rec(scene)
    if scene.clear[]
        draw_background(scene)
    end
    foreach(draw_background_rec, scene.children)
end
```

Note that Cairo or more specifically svg and pdf do not support per-pixel z order.
Therefore z order is generally limited to be per-plot.
Some mesh plots additionally sort triangles based on their average depth to improve on this.
This however is limited to each plot, i.e. another plot will either be completely below or above.

## GLMakie

In GLMakie each frame begins by clearing a color buffer, depth buffer and objectid buffer.
Next we go through all scenes in the scene tree recursively and draw their backgrounds to the initial color buffer if `scene.clear[] == true`.
After that rendering is determined by the `Makie.Renderpipeline` that is used by the screen.

### Default RenderPipeline

The default pipeline looks like this:

```@figure
scene = Scene(size = (800, 300), camera = cam2d!)
Makie.pipeline_gui!(scene, Makie.default_pipeline())
center!(scene)
scene
```

It begins with `ZSort` which sorts all plots based on `Makie.zvalue2d`.
Next is the `Render` stage which renders all plots with `plot.transparency[] = false` to the initial color buffer.
Then we get to two Order Independent Transparency Stages.
We render every plot with `plot.transparency[] = true` in `OIT Render`, weighing their colors based on depth and alpha values and then blend them with the opaque color buffer from the first `Render` stage.
The result continues through two anti-aliasing stages `FXAA1` and `FXAA2`.
The first calculates luma (brightness) values and the second uses them to find aliased edges and blur them.
The result moves on to the `Display` stage which copies the color buffer to the screen.

### Plot and Scene Insertion

There are two ways plots and scenes can be added to a GLMakie screen.
The first is by displaying a root scene, i.e. (implicitly) calling `display(fig)` or `display(scene)`.
In this case plots and scenes are added to the screen like in CairoMakie.
In pseudocode we effectively do:

```julia
function add_scene!(screen, scene)
    add_scene!(screen, scene)
    foreach(plot -> add_plot!(screen, plot, scene), scene.plots)
    foreach(scene -> add_scene!(screen, scene), scene.children)
end
```

The second way is to add them interactively, i.e. while the root figure or scene is already being displayed.
Adding a plot to a scene will effectively call the `add_plot!(screen, plot, scene)` function above.
Adding a scene however does not call `add_scene!(screen, scene)`.
It is only added once a plot is added to the new scene.
This is usually not a problem, but can cause differences in clearing order.
Deletion works the same for the plots and scenes - both immediately get removed from the screen.
For scenes all child scenes and child plots get deleted as well.

Note that plot (insertion) order also plays a role in rendering.
When two plots are not separated due to render passes or z order, they will get rendered in the order they were inserted.

### Overdraw Attribute

The `overdraw` attribute does not affect when a plot gets rendered in terms of render order or render passes.
Instead it affects depth testing.
A plot with `overdraw = true` ignores depth values when drawing and does not write out its own depth values.
This means that such a plot will draw over everything that has been render, but not stop later plots from drawing over it.

### SSAO RenderPipeline

Screen Space Ambient Occlusion is an optional post-processing effect you can turn on in GLMakie.
It modifies the render loop to include 3 more stages - one Render stage and two SSAO stages:

```@figure
scene = Scene(size = (1000, 300), camera = cam2d!)
Makie.pipeline_gui!(scene, Makie.default_pipeline(ssao = true))
center!(scene)
scene
```

The `Render` stage includes options for filtering plots based on their values for `ssao`, `fxaa` and `transparency`.
The single Render in the default pipeline only filtered based on `transparency == false`.
Now we also filter based on `ssao`.
The first Render stage requires `ssao == true && transparency == false`, the second `ssao = false && transparency = false`.
OIT Render requires `transparency == true`, so that all combinations are covered.
`fxaa` is handled per-pixel in the FXAA stages in this pipeline, but can also be handled per plot.

After the first Render Stage there are two SSAO stages.
The first calculates an occlusion factor based on the surrounding geometry using position and normal data recorded in the render stage.
The second smooths the occlusion factor and applies it to the recorded colors.
The next Render stage then continues to add to those colors before merging with OIT and applying FXAA.

### Custom RenderPipeline

It is possible to define your own pipeline and render stages though the latter requires knowledge of some GLMakie internals and OpenGL.
Explaining those is outside the scope of this section.
Instead we provide a small example you can use as a starting point.
You may also want to look at "GLMakie/src/postprocessing.jl" and "GLMakie/assets/postprocessors" to reference the existing implementations of pipeline stages.

As an example we will create a stage that applies a Sepia effect to our figure.
Lets begin by setting up a pipeline that includes the stage.

```@example RenderPipeline
# Create an empty Pipeline
pipeline = Makie.RenderPipeline()

# Add stages in order
render1 = push!(pipeline, Makie.RenderStage(transparency = false))
render2 = push!(pipeline, Makie.TransparentRenderStage())
oit = push!(pipeline, Makie.OITStage())
fxaa = push!(pipeline, Makie.FXAAStage()) # includes FXAA1 & FXAA2 with color_luma connection

# Our new stage takes a 32bit color and produces a new 32 bit color
color_tint = Makie.Stage(:Tint,
    # BufferFormat defaults to 4x N0f8, i.e. 32Bit color
    inputs = [:color => Makie.BufferFormat()],
    outputs = [:color => Makie.BufferFormat()],
    color_transform = Observable(Makie.Mat3f(
        # sepia filter
        0.393, 0.349, 0.272,
        0.769, 0.686, 0.534,
        0.189, 0.168, 0.131
    ))
)
push!(pipeline, color_tint)
display_stage = push!(pipeline, Makie.DisplayStage())

# Connect stages
connect!(pipeline, render1, fxaa) # connect everything from render1 to FXAA1, FXAA2
connect!(pipeline, render2, oit)  # everything from OIT Render -> OIT
connect!(pipeline, :objectid)     # connect all :objectid inputs and outputs
connect!(pipeline, oit, fxaa, :color)  # OIT color output -> fxaa color input
connect!(pipeline, fxaa, color_tint, :color)  # fxaa color output -> color tint input
connect!(pipeline, color_tint, display_stage, :color)  # color tint -> display
```

Note that you can also create connections with `Makie.pipeline_gui!(ax, pipeline)`.

When passing this pipeline to GLMakie, it will determine all the necessary buffers it needs to allocate.
Each stage will get a framebuffer based on the connected outputs of the pipeline and an `inputs` Dict based on the connected inputs of the pipeline.
The names match the names of the pipeline stage with a `_buffer` postfix.
What we now need to do is define a constructor for a `<: GLMakie.AbstractRenderStep` object which represents the stage in the `GLRenderPipeline`, and a `run_step()` method that executes the stage.

```@example RenderPipeline
using GLMakie

function GLMakie.construct(::Val{:Tint}, screen, framebuffer, inputs, parent)
    # Create the shader that applies the Sepia effect.
    # For the vertex shader we can reuse "fullscreen.vert", which sets up frag_uv.
    # For the fragment shader we add a new shader here, which reads a color
    # from an input texture, applies a transformation and writes it to the
    # output color buffer.
    frag_shader = """
    {{GLSL_VERSION}}

    in vec2 frag_uv;
    out vec4 fragment_color;

    uniform sampler2D color_buffer; // \$(name of input)_buffer
    uniform mat3 color_transform;   // from Stage attributes

    void main(void) {
        vec4 c = texture(color_buffer, frag_uv).rgba;
        fragment_color = vec4(color_transform * c.rgb, c.a);
    }
    """

    # Create a GLMakie Shader that will get compiled later
    shader = GLMakie.LazyShader(
        screen.shader_cache,
        GLMakie.loadshader("postprocessing/fullscreen.vert"),
        GLMakie.ShaderSource(frag_shader, :frag)
    )

    # `inputs` are unique to each stage, so we can directly pass them as inputs
    # of the RenderObject. On top of the `color_buffer` generated from the
    # stage input we add a `color_transform` which connects to the color_transform
    # in our stage:
    inputs[:color_transform] = parent.attributes[:color_transform]

    # We then create a RenderObject:
    robj = GLMakie.RenderObject(
        inputs, # will lower to uniforms (and vertex attributes/vertex shader inputs)
        shader, # will be compiled to a shader program
        GLMakie.PostprocessPrerender(), # turn of depth testing, blending and culling before rendering
        nothing, # postrender function - set later
        screen.glscreen # OpenGL context of the RenderObject
    )
    # postrenderfunction is the "nothing" from before
    # this produces a draw call with two triangles representing th full framebuffer
    robj.postrenderfunction = () -> GLMakie.draw_fullscreen(robj.vertexarray.id)

    # Finally we create a "RenderPass" which simply contains the render object and framebuffer
    return GLMakie.RenderPass{:Tint}(framebuffer, robj)
end

function GLMakie.run_step(screen, glscene, step::GLMakie.RenderPass{:Tint})
    wh = size(step.framebuffer)
    # This binds all color buffers in the framebuffer (i.e. our one color output)
    GLMakie.set_draw_buffers(step.framebuffer)
    GLMakie.glViewport(0, 0, wh[1], wh[2])
    GLMakie.GLAbstraction.render(step.robj)
    return
end
```

With that done we can now use our new pipeline for rendering:

```@figure RenderPipeline backend=GLMakie
using FileIO

GLMakie.activate!(render_pipeline = pipeline)
cow = load(Makie.assetpath("cow.png"))
f,a,p = image(rotr90(cow))
```

## WGLMakie

WGLMakie does not (yet) support the RenderPipeline.
Instead it relies on Three.js for rendering and adjusts a few settings.
It sets `antialias = true` for all plots, ignoring `fxaa` attributes.
It keeps `sortObjects = true` which enables sorting of plots with transparency.
The `transparency` attribute only affects depth writes.
The renderloop boils down to:

```julia
function render_scene(scene)
    if !scene.visible; return end
    set_region(scene.viewport)
    if scene.clear; clear(color, depth) end
    foreach(render, scene.plots)
    foreach(render_scene, scene.children)
end
```

Note that unlike CairoMakie and GLMakie, WGLMakie renders scene by scene.
I.e. if a child scene clears, nothing from the parent scene will be visible in that area.

### Plot & Scene Insertion

WGLMakie follows the same plot and scene insertion logic as GLMakie.
This includes a new scene only getting added when a plot gets added to it.
The main difference to GLMakie is that plots and scenes get serialized so they can be transferred to JavaScript instead of getting added to a screen directly.

```julia
function serialize_scene(scene)
    return Dict(
        :plots => map(plot -> serialize_plot(scene, plot), scene.plots)
        :children => map(serialize_scene, scene.children),
        # scene data...
    )
end
```