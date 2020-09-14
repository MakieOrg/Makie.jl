# Troubleshooting

## Installation issues

Here, we assume you are running Julia on the vanilla system image - no PackageCompiler goodness.  If you are using `PackageCompiler`, check out the page on compilation.

### No `Scene` displayed or GLMakie fails to build

If `Makie` builds, but when a plotting, no `Scene` is displayed, as in:

```julia
julia> using Makie

julia> lines([0,1], [0,1])
Scene (960px, 540px):
events:
    window_area: GeometryTypes.HyperRectangle{2,Int64}([0, 0], [0, 0])
    window_dpi: 100.0
    window_open: false
    mousebuttons: Set(AbstractPlotting.Mouse.Button[])
    mouseposition: (0.0, 0.0)
    mousedrag: notpressed
    scroll: (0.0, 0.0)
    keyboardbuttons: Set(AbstractPlotting.Keyboard.Button[])
    unicode_input: Char[]
    dropped_files: String[]
    hasfocus: false
    entered_window: false
plots:
   *Axis2D{...}
   *Lines{...}
subscenes:
   *scene(960px, 540px)
```

then, your backend may not have built correctly.  By default, Makie will try to use GLMakie as a backend, but if it does not build correctly for whatever reason, then scenes will not be displayed.
Ensure that your graphics card supports OpenGL; if it does not (old models, or relatively old integrated graphics cards), then you may want to consider CairoMakie.

# Plotting issues

## Dimension too large

In general, plotting functions tend to plot whatever's given to them as a single texture.  This can lead to GL errors, or OpenGL failing silently.  To circumvent this, one can 'tile' the plots (i.e., assemble them piece-by-piece) to decrease the individual texture size.

### 2d plots (heatmaps, images, etc.)

```julia
heatmap(rand(Float32, 24900, 26620))
```
may either fail with an error
```julia
   Error showing value of type Scene:
ERROR: glTexImage 2D: width too large. Width: 24900
[...]
```
or fail silently:

![untiled heatmap](https://user-images.githubusercontent.com/32143268/55675737-96357280-5894-11e9-9170-1ffd21f544cc.png)

Tiling the plot, as shown below, yields a correct image.

```julia
sc = Scene()
data = rand(Float32, 24900, 26620)
heatmap!(sc, 1:size(data, 1)÷2, 1:size(data, 2)÷2, data[1:end÷2, 1:end÷2])
heatmap!(sc, (size(data, 1)÷2 + 1):size(data, 1), 1:size(data, 2)÷2, data[(end÷2 + 1):end, 1:end÷2])
heatmap!(sc, 1:size(data, 1)÷2, (size(data, 2)÷2 + 1):size(data, 2), data[1:end÷2, (end÷2 + 1):end])
heatmap!(sc, (size(data, 1)÷2 + 1):size(data, 1), (size(data, 2)÷2 + 1):size(data, 2),
         data[(end÷2 + 1):end, (end÷2 + 1):end])
```
![tiled heatmap](https://user-images.githubusercontent.com/32143268/61105143-a3b35780-a496-11e9-83d1-bebe549aa593.png)

### 3d plots (volumes)

The approach here is similar to that for the 2d plots, except that here there is a helpful function that gives the maximum texture size.
You can check the maximum texture size with:
```julia
using Makie, GLMakie, ModernGL
# simple plot to open a window (needs to be open for opengl)
display(scatter(rand(10)))
glGetIntegerv(GL_MAX_3D_TEXTURE_SIZE)
```
and then just split the volume:
```julia
vol = rand(506, 720, 1440)
ranges = (1:256, 1:256, 1:256)
scene = volume(ranges..., vol[ranges...])
for i in 1:3
    global ranges
    ranges = ntuple(3) do j
        s = j == i ? last(ranges[j]) : 1
        e = j == i ? size(vol, j) : last(ranges[j])
        s:e
    end
    volume!(ranges..., vol[ranges...])
end
scene
```

## General issues

### My font doesn't work!

If `Makie` can't find your font, you can do two things:

1) Check that the name matches and that the font is in one of the directories in:

    - `using FreeTypeAbstraction; FreeTypeAbstraction.valid_fontpaths`

2) You can add a custom font path via the environment variable:

    - `ENV["FREETYPE_ABSTRACTION_FONT_PATH"] = "/path/to/your/fonts"`

3) Specify the path to the font; instead of `font = "Noto"`, you could write `joindir(homedir(), "Noto.ttf")` or something.
