using Makie

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