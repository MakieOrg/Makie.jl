using Makie, GLMakie, Makie.Colors

# Create an empty Pipeline
pipeline = Makie.RenderPipeline()

# Add stages in order
render1 = push!(pipeline, Makie.RenderStage(transparency = false))
render2 = push!(pipeline, Makie.TransparentRenderStage())
oit = push!(pipeline, Makie.OITStage())
fxaa = push!(pipeline, Makie.FXAAStage()) # includes FXAA1 & FXAA2 with color_luma connection

# Our new stage takes a 32bit color and produces a new 32 bit color
color_tint = Makie.Stage(:Tint3,
    # BufferFormat defaults to 4x N0f8, i.e. 32Bit color
    inputs = [:color => Makie.BufferFormat()],
    outputs = [:color => Makie.BufferFormat()],
    oklab2oklmsp_mat = Observable(Makie.Mat3f(Colors.M_OKLMSP2OKLAB_INV)),
    oklms2xyz_mat = Observable(Makie.Mat3f(Colors.M_XYZ2OKLMS_INV)),
    xyz2rgb_mat = Observable(Makie.Mat3f(Colors.M_RGB2XYZ))
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

function GLMakie.construct(::Val{:Tint3}, screen, framebuffer, inputs, parent)
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
    uniform mat3 oklab2oklmsp_mat;   // from Stage attributes
    uniform mat3 oklms2xyz_mat;   // from Stage attributes
    uniform mat3 xyz2rgb_mat;   // from Stage attributes

    vec3 linear_from_oklab(vec3 oklab)
    {
        const mat3 m1 = mat3(+1.000000000, +1.000000000, +1.000000000,
                            +0.396337777, -0.105561346, -0.089484178,
                            +0.215803757, -0.063854173, -1.291485548);
                        
        const mat3 m2 = mat3(+4.076724529, -1.268143773, -0.004111989,
                            -3.307216883, +2.609332323, -0.703476310,
                            +0.230759054, -0.341134429, +1.706862569);
        vec3 lms = m1 * oklab;
        
        return m2 * (lms * lms * lms);
    }


    void main(void) {
        vec4 c = texture(color_buffer, frag_uv).rgba;
        // convert from linear rgb to oklab using the original function
        // of Björn Ottosson
        vec3 rgb = linear_from_oklab(c.rgb);
        // go from linear rgb to srgb via a gamma correction
        // vec3 rgb_s = pow(rgb, vec3(1.0/2.2) );
        fragment_color = vec4(rgb, c.a);
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
    inputs[:oklab2oklmsp_mat] = parent.attributes[:oklab2oklmsp_mat]
    inputs[:oklms2xyz_mat] = parent.attributes[:oklms2xyz_mat]
    inputs[:xyz2rgb_mat] = parent.attributes[:xyz2rgb_mat]

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
    return GLMakie.RenderPass{:Tint3}(framebuffer, robj)
end

function GLMakie.run_step(screen, glscene, step::GLMakie.RenderPass{:Tint3})
    wh = size(step.framebuffer)
    # This binds all color buffers in the framebuffer (i.e. our one color output)
    GLMakie.set_draw_buffers(step.framebuffer)
    GLMakie.glViewport(0, 0, wh[1], wh[2])
    GLMakie.GLAbstraction.render(step.robj)
    return
end
GLMakie.closeall()
GLMakie.activate!(render_pipeline = Makie.default_pipeline())
GLMakie.closeall()
GLMakie.activate!(render_pipeline = pipeline)

f, a, p = scatter(rand(1000), rand(1000); color = rand(1000))

colorbuffer(f) |> save("colorbuffer.png")

function oklab_from_linear(linear::RGB)
    im1 = Makie.GeometryBasics.Mat3(0.4121656120, 0.2118591070, 0.0883097947,
                          0.5362752080, 0.6807189584, 0.2818474174,
                          0.0514575653, 0.1074065790, 0.6302613616);
                       
    im2 = Makie.GeometryBasics.Mat3(+0.2104542553, +1.9779984951, +0.0259040371,
                          +0.7936177850, -2.4285922050, +0.7827717662,
                          -0.0040720468, +0.4505937099, -0.8086757660);
    linear = Makie.GeometryBasics.Vec3(linear.r, linear.g, linear.b)
    lms = im1 * linear;
            
    return im2 * (sign.(lms) .* abs.(lms) .^ (1.0/3.0));
end

function remap_to_oklab(c::Colors.Color)
    o = oklab_from_linear(RGB(c))
    Colors.RGB(o...)
end

function remap_to_oklab(c::Colors.TransparentColor)
    o = oklab_from_linear(RGB(c))
    Colors.RGBA(o..., Colors.alpha(c))
end

remap_to_oklab(c) = remap_to_oklab(convert(Colors.RGBA{Float64}, c))

function rgb_from_oklab(c::RGB)
    oklab = [c.r, c.g, c.b]
    m1 = Makie.GeometryBasics.Mat3(+1.000000000, +1.000000000, +1.000000000,
                         +0.396337777, -0.105561346, -0.089484178,
                         +0.215803757, -0.063854173, -1.291485548);
                       
    m2 = Makie.GeometryBasics.Mat3(+4.076724529, -1.268143773, -0.004111989,
                         -3.307216883, +2.609332323, -0.703476310,
                         +0.230759054, -0.341134429, +1.706862569);
    lms = m1 * oklab;
    
    return m2 * (lms .* lms .* lms);
end

theme_oklab() = Theme(
    ; backgroundcolor = RGBAf(1, 0, 0, 1), # for some reason the color conversion wants this to be red
    color = remap_to_oklab(colorant"black"),
    gridcolor = remap_to_oklab(colorant"black"),
    spinecolor = remap_to_oklab(colorant"black"),
    textcolor = remap_to_oklab(colorant"black"),
    Axis = (; 
        backgroundcolor = RGBAf(1, 0, 0, 1), # for some reason the color conversion wants this to be red
        xgridcolor = remap_to_oklab(RGBAf(colorant"black", 0.12)),
        ygridcolor = remap_to_oklab(RGBAf(colorant"black", 0.12)),
        xspinecolor = remap_to_oklab(RGBAf(colorant"black", 0.12)),
        yspinecolor = remap_to_oklab(RGBAf(colorant"black", 0.12)),
    )
)

f, a, p = with_theme(theme_oklab()) do
    scatter(rand(1000), rand(1000); color = rand(1000), colormap = remap_to_oklab.(Makie.ColorSchemes.viridis))
end

colorbuffer(f) |> save("colorbuffer_viridis.png")


f = with_theme(theme_oklab()) do
    N = 100_000
    α = 0.01
    f, a, p = scatter(randn(N) .+ 1, randn(N); color = remap_to_oklab(RGBAf(colorant"red", α)))
    scatter!(a, randn(N) .- 1, randn(N); color = remap_to_oklab(RGBAf(colorant"blue", α)))
    f
end


colorbuffer(f) |> save("colorbuffer_oklab_scatter.png")

f = with_theme(theme_oklab()) do
    volume(rand(10, 10, 10); colormap = remap_to_oklab.(Makie.ColorSchemes.viridis))
end