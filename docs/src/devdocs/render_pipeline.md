# Render Pipeline

The `RenderPipeline` abstracts the steps GLMakie goes through when rendering.
It controls the order in which plots are rendered, which post processors are used and how they connect.
In this section we will explain how the `RenderPipeline` works and can be modified.
Note that this is both an advanced topic and an early implementation.
The pipeline and especially the default steps/stages may change in the future as we figure out how to best organize them.

## Stages

A `Stage` is a step in the render pipeline which represents some action performed during rendering.
Typically this is the execution of a post processing shader which takes some inputs and produces some outputs.
It can also be rendering of plots to some outputs, or something completely CPU side like sorting plots.

As an example, let's say we want to add a color filter like Sepia to the rendering pipeline.
This filter should run at the end of rendering, taking the rendered image as an input and applying a color transformation to each pixel to produce a new output image.
A `Stage` representing this would look like this:

```@example
using Makie
using Makie: N0f8

Makie.Stage(
    :Tint,
    inputs = [:color => Makie.BufferFormat(4, N0f8)],
    outputs = [:color => Makie.BufferFormat(4, N0f8)],
    color_transform = Observable(Makie.Mat3f(
        # sepia filter
        0.393, 0.349, 0.272,
        0.769, 0.686, 0.534,
        0.189, 0.168, 0.131
    ))
)
```

This creates a `Stage` with the name `:Tint`, one input and output buffer each named `:color` and an attribute called `color_transform`.
Any keyword argument other than `inputs`, `outputs` and `samples` will be interpreted as an attribute.
Inputs and outputs can also be passed as arguments, input first, output second.

### BufferFormat

The `BufferFormat` is a type that defines the format of a buffer needed to hold the input or output data of a `Stage`.
In the example above the color input and output both use `BufferFormat(4, N0f8)`.
In OpenGL terms this corresponds to `GL_RGBA8` texture, i.e. a texture with 4 channels carrying 8 bit normalized floats.
In Julia terms this could be understood as representing a `Matrix{RGBA{N0f8}}` or more generally a `Matrix{NTuple{N, N0f8}}`.

`BufferFormat` carry various other settings that apply to textures, such as minification and magnification filters, edge behavior (repeat), mipmap settings and a sample number for msaa.
You can find their default values in the docstring.

When inputs and outputs of different stages are connected, the `BufferFormat` makes sure that the output can actually be used as an input.
I.e. it makes sure that the types compatible and that settings match.
While doing so the format may be upgraded.
For example a `N0f8` may upgrade to `Float16` or an undetermined `magfilter` may be set to a specific option.

## RenderPipeline Object

The `RenderPipeline` holds on to multiple stages and tracks the connections between them.
The stages execute in the order they are added and the connections describe the flow of data between them.

The most basic functional pipeline we can create contains a render and a display stage.
These stages can be created using some default constructors from Makie:

```@example base_pipeline
using Makie
render_stage = Makie.RenderStage()
```

```@example base_pipeline
display_stage = Makie.DisplayStage()
```

To add them to a render pipeline we first create it and then `push!()` the stages to it.
Then we use `connect!()` to connect them.

```@example base_pipeline
pipeline = Makie.RenderPipeline()
push!(pipeline, render_stage)
push!(pipeline, display_stage)
Makie.connect!(pipeline, render_stage, display_stage)
pipeline
```

The `connect!()` function has various different methods.
The one used here connects every output from `render_stage` to every input from `display_stage` with the same name.
`connect!(pipeline, stage1, stage2, name)` can be used to connect just one output and input with matching name and `connect!(pipeline, stage1, name1, stage2, name2)` can be used to connect differently named outputs and inputs.
Note as well that `push!(pipeline, stage)` return the `stage` which can simplify the pipeline setup a bit.

To use our pipeline for rendering we need to pass it to the screen in GLMakie.
This can be done with the `display(fig, render_pipeline = pipeline)` or

```@figure base_pipeline backend=GLMakie
using GLMakie
GLMakie.activate!(render_pipeline = pipeline)
GLMakie.activate!(render_pipeline = pipeline, px_per_unit = 1) # hide

f,a,p = scatter(Circle(Point2f(0), 1.2))
mesh!(a, Circle(Point2f(0), 0.9))
f
```

To return to the default pipeline we need to switch back to it:

```@figure backend=GLMakie
GLMakie.activate!(render_pipeline = Makie.default_pipeline())
GLMakie.activate!(render_pipeline = Makie.default_pipeline(), px_per_unit = 1) # hide

f,a,p = scatter(Circle(Point2f(0), 1.2))
mesh!(a, Circle(Point2f(0), 0.9))
f
```

## Backend Implementation of Stages

For GLMakie to be able to use a `Stage` it needs to have a backend implementation.
This implementation includes:
- A struct inheriting from `GLMakie.AbstractRenderStep` representing the stage. For post processors this can usually be a `GLMakie.RenderPass` which contains a framebuffer and render object.
- A `GLMakie.construct` method which sets up the render step. This can be either:
  - `GLMakie.construct(::Val{name}, screen, stage)` where `name` is the name of the respective stage.
  - `GLMakie.construct(::Val{name}, screen, framebuffer, inputs, stage)` where the `framebuffer` includes all the outputs of the stage and `inputs` all the stage inputs.
- A `GLMakie.run_step!(screen, _, step)` method which executes the step. (`_` is currently unused.)

Explaining everything that goes into these methods in detail is beyond the scope of section.
Instead we return to the color tinting example and briefly explain what that implementation would look like.

```@figure backend=GLMakie
using Makie: N0f8

function GLMakie.construct(::Val{:Tint}, screen, framebuffer, inputs, stage)
    # Create the shader that applies the color transformation.
    # For the vertex shader we can reuse "fullscreen.vert". It renders two
    # triangles covering the full screen and produces uv coordinates for full-
    # screen texture access

    # For the fragment shader we add a new shader here, which reads a color
    # from an input texture, applies the color transformation and writes the
    # result to the color buffer in `framebuffer`.
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

    # Create a GLMakie Shader that will get compiled during its first use
    shader = GLMakie.LazyShader(
        screen.shader_cache,
        GLMakie.loadshader("postprocessing/fullscreen.vert"),
        GLMakie.ShaderSource(frag_shader, :frag)
    )

    # Uniforms (and vertex buffers) are passed to a RenderObject via a
    # Dict{Symbol, Any}. The Symbols represent the uniform names and the values
    # inform the representation in the shader. E.g. a Float32 will be passed
    # as a float uniform, a Texture as a OpenGL texture/sampler and a GLBuffer
    # as a vertex buffer.

    # We need two uniforms here, the color buffer representing the :color input
    # of the stage and the color transform we have as an attribute. The former
    # is already part of `inputs`, which can be expanded to include other
    # uniforms. So we just add the color transform to it:
    inputs[:color_transform] = stage.attributes[:color_transform]

    # We then create a RenderObject:
    robj = GLMakie.RenderObject(
        inputs, # Dict{Symbol, Any} containing uniforms, vertex buffers and indices
        shader, # the shader (program) to use
        GLMakie.PostprocessPrerender(), # setup function "prerender"
        nothing, # render function "postrender"
        screen.glscreen # OpenGL context of the RenderObject
    )

    # Rendering of a RenderObject happens in 3 steps:
    # 1. the prerender function runs
    # 2. uniforms, buffers and the shader program are bound and get updated
    # 3. the postrender function runs

    # The PostprocessPrerender() is a callable struct that disables depth tests,
    # blending and face culling.
    # The postrender function
    robj.postrenderfunction = () -> GLMakie.draw_fullscreen(robj.vertexarray.id)
    # binds the vertexarray and draws two triangles.

    # With the finalized renderobject we create a renderpass. This just holds on
    # to the framebuffer and render object
    return GLMakie.RenderPass{:Tint}(framebuffer, robj)
end

# This runs as a step in the render loop for each frame
function GLMakie.run_step(screen, _, step::GLMakie.RenderPass{:Tint})
    # bind all color buffers in the framebuffer (here one color output)
    GLMakie.set_draw_buffers(step.framebuffer)
    # Set the draw region to the full size of the framebuffer
    wh = size(step.framebuffer)
    GLMakie.glViewport(0, 0, wh[1], wh[2])
    # render the render object
    GLMakie.GLAbstraction.render(step.robj)
    return
end

tint_stage = Makie.Stage(
    :Tint,
    inputs = [:color => Makie.BufferFormat(4, N0f8)],
    outputs = [:color => Makie.BufferFormat(4, N0f8)],
    color_transform = Observable(Makie.Mat3f(
        # sepia filter
        0.393, 0.349, 0.272,
        0.769, 0.686, 0.534,
        0.189, 0.168, 0.131
    ))
)

pipeline = Makie.RenderPipeline()
render_stage = push!(pipeline, Makie.RenderStage())
push!(pipeline, tint_stage)
display_stage = push!(pipeline, Makie.DisplayStage())
Makie.connect!(pipeline, render_stage, tint_stage)
Makie.connect!(pipeline, tint_stage, display_stage)
Makie.connect!(pipeline, render_stage, display_stage, :objectid)
Makie.connect!(pipeline, render_stage, display_stage, :depth)

GLMakie.activate!(render_pipeline = pipeline)
GLMakie.activate!(render_pipeline = pipeline, px_per_unit = 1) # hide

image(rotr90(Makie.loadasset("cow.png")))
```

```
# julia:reset-render-pipeline # not working here
GLMakie.activate!(pipelien = Makie.default_pipeline()) # hide
GLMakie.closeall() # hide
```