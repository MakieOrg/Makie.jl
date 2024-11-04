# Conversions and spaces

## Conversion Pipeline

The following graphic sketches out the conversion pipeline of data given to a plot with `space = :data` for GL backends.

```@example
# hideall
using GLMakie, LinearAlgebra
GLMakie.activate!()
Makie.inline!(true)

function myarrows!(scene, ps; kwargs...)
    ends = map(ps) do ps
        output = Int[]
        for i in eachindex(ps)
            isnan(ps[i]) && push!(output, i-1)
        end
        push!(output, length(ps))
        output
    end

    dict = Dict(kwargs)
    endpoints = map((ps, is) -> ps[is], ps, ends)
    dirs = map(
      (ps, is) -> -Makie.quaternion_to_2d_angle.(Makie.to_rotation(normalize.(ps[is] .- ps[is .- 1]))),
      ps, ends)
    cols = map(is -> dict[:color] isa Vector ? dict[:color][is] : dict[:color], ends)

    lines!(scene, ps; kwargs...)
    scatter!(
        scene, endpoints, marker = Makie.BezierUTriangle, color = cols,
        rotation = dirs
    )
end

scene = Scene(size = (1220, 200))
campixel!(scene)

# init space label data
spacing = 80
y0 = 80
ps = Observable(Point2f.(1:8, y0))
# spaces = [":data", "transformed64", "world", "eye", ":clip", "screen"]
spaces = ["plot.args", "plot.converted", "transformed64", "transformed32", "world", "eye", "clip", "screen"]

# plot space labels
p = text!(
    scene, ps, text = spaces, align = (:left, :center),
    fontsize = 20,
    color = [:black, :black, :gray, :gray, :gray, :gray, :gray, :gray]
)

# update space label data & derive arrows
centers = Observable(Point2f[])
text_centers = Observable(Point2f[])
map!(ps, p.plots[1][1]) do gcs
    edge = -spacing + 10
    xvals = Float64[]
    xcenters = Float64[]

    for gc in gcs
        bb = Makie.string_boundingbox(gc, Quaternionf(0,0,0,1))
        left = spacing + edge - minimum(bb)[1]
        push!(xvals, left)
        push!(xcenters, left + 0.5 * widths(bb)[1])
        edge = left + widths(bb)[1]
    end

    text_centers[] = Point2f.(xcenters, y0)
    centers[] = Point2f.(xvals[2:end] .- 0.5spacing, y0)

    return Point2f.(xvals, y0)
end

arrowpos = map(centers) do centers
    half = 0.5 * spacing - 5
    ps = Point2f[]
    lws = Float64[]
    for center in centers
        x, y = center
        push!(ps, Point2f(x-half, y), Point2f(x+half-5, y), Point2f(NaN))
        # push!(ps, Point2f(x-half, y), Point2f(x+half-8, y))
        # push!(ps, Point2f(x+half-10, y), Point2f(x+half, y))
        # push!(lws, 2, 2, 12, 0)
    end
    ps
end

# plot arrows
myarrows!(
    scene, arrowpos, linewidth = 2,
    color = [c for c in [:red, :red, :red, :green, :green, :green, :gray] for _ in 1:3]
)

# transformation labels
transformations = ["convert_arguments", "transform_func", "Float32Convert", "model", "view", "projection", "viewport"]
trans_offset = 25
text!(
    scene, centers, text = transformations, align = (:center, :center),
    offset = (0, trans_offset),
    color = [:black, :orange, :black, :orange, :cyan, :cyan, :gray]
)

# Transformation
bracket_offset = Point2f(0, trans_offset + 15)
trans_bracket_pos = map(centers) do cs
    [cs[2] + bracket_offset, cs[4] + bracket_offset]
end
text!(
  scene, trans_bracket_pos, text = ["Transformation" for _ in 1:2],
  color = :orange, align = (:center, :bottom))

# Camera
cam_bracket_pos = map(centers) do cs
    (cs[5] + bracket_offset, cs[6] + bracket_offset)
end
bracket!(
    scene,
    cam_bracket_pos,
    text = "Camera",
    color = :cyan, textcolor = :cyan
)

# CPU
dx = 10; dy = -20
cpu_bracket_pos = map(text_centers) do ps
    (ps[1] .+ (dx, dy), ps[4] .+ (-dx, dy))
end
bracket!(
    scene,
    cpu_bracket_pos,
    text = "CPU",
    color = :red, textcolor = :red,
    orientation = :down
)

# GPU
gpu_bracket_pos = map(text_centers) do ps
    (ps[4] .+ (dx, dy), ps[7] .+ (-dx, dy))
end
bracket!(
    scene,
    gpu_bracket_pos,
    text = "GPU",
    color = :green, textcolor = :green,
    orientation = :down
)

# Internal
internal_bracket_pos = map(text_centers) do ps
    (ps[7] .+ (dx, dy), ps[8] .+ (-dx, dy))
end
bracket!(
    scene,
    internal_bracket_pos,
    text = "GPU Internal",
    color = :gray, textcolor = :gray,
    orientation = :down
)

# Float32Convert
f32_ps = map(text_centers) do cs
    x1, y1 = cs[2]
    x5, y5 = cs[3]
    x2, y2 = 0.5 * (cs[3] .+ cs[4])
    x3, y3 = cs[6]
    x4, y4 = 0.5 * (cs[4] .+ cs[5])
    Point2f[
        (x1, y1+15), (x1, y1+65), (NaN, NaN),
        (x1+45, y1+83), (x5, y5+83), (x5, y2+25), (x5+45, y2+25), (NaN, NaN),
        (x5-50, y2+25), (x5-10, y2+25), (NaN, NaN),
        (x2+20, y2+40), (x2+20, y2+100), (x3, y3+100), (x3, y3+80), (NaN, NaN),
        (x2+60, y2+25), (x4-15, y4+25)
    ]
end
myarrows!(scene, f32_ps, color = :gray)
text!(
    scene, map(ps -> ps[2], f32_ps), text = "ax.finallimits",
    align = (:center, :bottom), offset = Vec2f(0, 10)
)

scene
```

### Argument Conversions

When calling a plot function, e.g. `scatter!(axis_or_scene, args...)` a new plot object is constructed.
The plot object keeps track of the original input arguments converted to Observables in `plot.args`.
Those input arguments are then converted via `convert_arguments` and stored in `plot.converted`.
Generally speaking these methods either dispatch on the plot type or the result of `conversion_trait(PlotType, args...)`, i.e. `convert_arguments(type_or_trait, args...)`.
They are expected to generalize and simplify the structure of data given to a plot while leaving the numeric type as either a Float32 or Float64 as appropriate.

The full conversion pipeline is run in `Makie.conversion_pipeline` which also applies `dim converts` and checks if the conversion was successful.

### Transformation Objects

The remaining transformed versions of data are not accessible, but rather abstract representations which the data goes through.
As such they are named based on the coordinate space they are in and grayed out.
Note as well that these representations are only relevant to primitive plots like lines or mesh.
Ignoring `Float32Convert` for now, the next two transformations are summarized under the `Transformation` object present in `plot.transformation` and `scene.transformation`.

The first transformation is `transformation.transform_func`, which holds a function which is applied to a `Vector{Point{N, T}}` element by element.
It is meant to resolve transformations that cannot be represented as a matrix operations, for example moving data into a logarithmic space or into Polar coordinates.
They are implemented using the `apply_transform(func, data)` methods.
Generally we also expect transform function to be (partially) invertible and their inverse to be returned by `inverse_transform(func)`.

The second transformation is `transformation.model`, which combines `translate!(plot, ...)`, `scale!(plot, ...)` and `rotate!(plot, ...)` into a matrix.
The order of operations here is fixed - rotations apply first, then scaling and finally translations.
As a matrix operation they can and are handled on the GPU.

### Float32Convert

Nested between `transform_func` and `model` is the application of `scene.float32convert`.
Its job is to bring the transformed data into a range acceptable for `Float32`, which is used on the GPU.

Currently only `Axis` actually defines this transformation.
When calling `plot!(axis, ...)` it takes a snapshot of the limits of the plot using `data_limits(plot)` and updates its internal limits.
These are combined with other sources to generate `axis.finallimits`.
When setting the camera matrices `axis.finallimits` gets transformed by `transform_func` and processed by `scene.float32convert` to generate a valid Float32 range for the camera.
This processing will update the `Float32Convert` if needed.

With respect to the conversion pipeline the `Float32Convert` is a linear function applied to transformed data using `f32_convert(scene, data)`.
After the transformation, data strictly uses Float32 as a numeric type.

Note that since the `Float32Convert` is based on and transforms the limits used to create the camera (matrices), it should technically act between `model` and `view`.
In fact, this order is used for CairoMakie and some CPU projection code.
For the GPU however, we want to avoid applying `model` on the CPU.
To do that we calculate a new model matrix using `new_model = patch_model(scene, model)`, which acts after `Float32Convert`.

### Camera

Next in our conversion pipeline are the camera matrices tracked in `scene.camera`.
Their job is to transform plot data to a normalized "clip" space.
While not consistently followed, the `view` matrix is supposed to adjust the coordinate system to that of the viewer and the `projection` matrix is supposed to apply scaling and perspective projection if applicable.
The viewers position and orientation is set by either the the camera controller of the scene or the parent Block.



## Coordinate spaces

Currently `Makie` defines 4 coordinate spaces: :data, :clip, :relative and :pixel.
The example above shows the conversion pipeline for `space = :data`.

For `space = :clip` we consider `plot.converted` to be in clip space, meaning that `transform_func`, `model`, `view` and `projection` can be skipped, and `Float32Convert` only does a cast to Float32.
The x and y direction correspond to right and up, with z increasing towards the viewer.
All coordinates are limited to a -1 .. 1 range.

The other two spaces each include one matrix transformation to clip space.
For `space = :relative` this simply rescales the x and y dimension to a 0 .. 1 range.
And for `space = :pixel` the `camera.pixel_space` matrix is used to set the x and y range the size of the scene and the z range to -10_000 .. 10_000, with z facing away from the viewer.
