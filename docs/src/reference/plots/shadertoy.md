# shadertoy

```@shortdocs; canonical=false
shadertoy
```


## Examples

```@example
using GLMakie
GLMakie.activate!() # hide
# Define the shader as a string
plasma_shader = """
// A colorful plasma animation
// Demonstrates time, coordinates and color manipulation

vec4 mainImage(in vec2 fragCoord) {
    // Normalized pixel coordinates (from -1 to 1)
    vec2 uv = fragCoord.xy / iResolution.xy * 2.0 - 1.0;
    uv.x *= iResolution.x / iResolution.y;  // Correct for aspect ratio

    // Create a plasma effect using sine waves
    float time = iGlobalTime * 0.5;
    float v1 = sin(uv.x * 3.0 + time);
    float v2 = sin(uv.y * 2.0 - time * 1.3);
    float v3 = sin(uv.x * 0.7 + uv.y * 0.8 + time * 0.7);
    float v4 = sin(length(uv) * 2.5 - time);

    // Combine waves
    float plasma = (v1 + v2 + v3 + v4) * 0.25;

    // Create a color palette
    vec3 color = vec3(0.0);
    color.r = cos(plasma * 3.14159 + time) * 0.5 + 0.5;
    color.g = sin(plasma * 3.14159 * 1.3 + time * 0.9) * 0.5 + 0.5;
    color.b = cos(plasma * 3.14159 * 0.8 - time * 1.2) * 0.5 + 0.5;

    // Add some noise from the texture for detail
    vec2 noiseCoord = (uv * 0.5 + 0.5) * 3.0;  // Scale for texture coordinates
    vec4 noise = texture(iChannel0, noiseCoord);
    color = mix(color, noise.rgb, 0.1);  // Subtle noise blend

    // Output the color
    return vec4(color, color.r + color.b);
}
"""
noise_img = rand(RGBf, 256, 256)
f, ax, pl = barplot(-0.8..0.8, rand(10), fillto=-1, color=rand(10))
shadertoy!(ax,
    plasma_shader;
    uniforms=Dict{Symbol, Any}(
        :iChannel0 => GLMakie.Sampler(noise_img; x_repeat=:repeat, minfilter=:linear)
    )
)
record(identity, f, "plasma_animation.mp4", 1:1000; framerate=30)
nothing # hide
```

```@raw html
<video autoplay loop muted playsinline controls src="./plasma_animation.mp4" />
```

## Attributes

```@attrdocs
ShaderToy
```
