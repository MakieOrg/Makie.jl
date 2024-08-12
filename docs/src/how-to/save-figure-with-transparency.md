# How to save a figure with transparency

## Using CairoMakie

In CairoMakie, set the background color to `:transparent` (converts to `RGBAf(0, 0, 0, 0)`) to get a fully transparent background.
In the following examples, I use a partially transparent blue because a transparent background is indistinguishable from the usual white on a white page.

```@figure
f = Figure(backgroundcolor = (:blue, 0.4))
Axis(f[1, 1], backgroundcolor = (:tomato, 0.5))
f
```

## Using GLMakie

For technical reasons, GLMakie's color buffer does not have an alpha component:

```@figure backend=GLMakie
f = Figure(backgroundcolor = (:blue, 0.4))
Axis(f[1, 1], backgroundcolor = (:tomato, 0.5))
f
```

With the following trick you can still save an image with transparent background.
It works by setting two different background colors and calculating the foreground color with alpha from the difference.

```@example
using GLMakie
GLMakie.activate!() # hide
Makie.inline!(true) # hide

function calculate_rgba(rgb1, rgb2, rgba_bg)::RGBAf
    rgb1 == rgb2 && return RGBAf(rgb1.r, rgb1.g, rgb1.b, 1)
    c1 = Float64.((rgb1.r, rgb1.g, rgb1.b))
    c2 = Float64.((rgb2.r, rgb2.g, rgb2.b))
    alphas_fg = 1 .+ c1 .- c2
    alpha_fg = clamp(sum(alphas_fg) / 3, 0, 1)
    alpha_fg == 0 && return rgba_bg
    rgb_fg = clamp.((c1 ./ alpha_fg), 0, 1)
    rgb_bg = Float64.((rgba_bg.r, rgba_bg.g, rgba_bg.b))
    alpha_final = alpha_fg + (1 - alpha_fg) * rgba_bg.alpha
    rgb_final = @. 1 / alpha_final * (alpha_fg * rgb_fg + (1 - alpha_fg) * rgba_bg.alpha * rgb_bg)
    return RGBAf(rgb_final..., alpha_final)
end

function alpha_colorbuffer(figure)
    scene = figure.scene
    bg = scene.backgroundcolor[]
    scene.backgroundcolor[] = RGBAf(0, 0, 0, 1)
    b1 = copy(colorbuffer(scene))
    scene.backgroundcolor[] = RGBAf(1, 1, 1, 1)
    b2 = colorbuffer(scene)
    scene.backgroundcolor[] = bg
    return map(b1, b2) do b1, b2
        calculate_rgba(b1, b2, bg)
    end
end

f = Figure(backgroundcolor = (:blue, 0.4))
Axis(f[1, 1], backgroundcolor = (:tomato, 0.5))
f

save("transparent.png", alpha_colorbuffer(f))
nothing # hide
```

![transparent](./transparent.png)