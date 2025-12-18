# Blocks

`Blocks` are objects which can be added to a `Figure` or `Scene` and have their location and size controlled by a `GridLayout`. In of itself, a `Block` is an abstract type.
A `Figure` has its own internal `GridLayout` and therefore offers simplified syntax for adding blocks to it.
If you want to work with a bare `Scene`, you can attach a `GridLayout` to its pixel area.

!!! note
    A layout only controls an object's position or bounding box.
    A `Block` can be controlled by the GridLayout of a Figure but not be added as a visual to the Figure.
    A `Block` can also be added to a Scene without being inside any GridLayout, if you specify the bounding box yourself.

## Adding to a `Figure`

Here's one way to add a `Block`, in this case an `Axis`, to a Figure.

```@figure
f = Figure()
ax = Axis(f[1, 1])
f
```

## Specifying a boundingbox directly

Sometimes you just want to place a `Block` in a specific location, without it being controlled by a dynamic layout.
You can do this by setting the `bbox` parameter, which is usually controlled by the layout, manually.
The boundingbox should be a 2D `Rect`, and can also be an Observable if you plan to change it dynamically.
The function `BBox` creates an `Rect2f`, but instead of passing origin and widths, you pass left, right, bottom and top boundaries directly.

Here's an example where two axes are placed manually:

```@figure
f = Figure()
Axis(f, bbox = BBox(50, 200, 50, 300), title = "Axis 1")
Axis(f, bbox = BBox(250, 550, 100, 350), title = "Axis 2")
f
```

## Deleting blocks

To remove blocks from their layout and the figure or scene, use `delete!(block)`.

## Blocks as Complex Recipes

As of Makie 0.25, blocks have been expanded to function as a container for other blocks.
This means a block can describe a layout of multiple Axis objects, Legends, Colorbars, etc.
Plots can also be added to any axis used within the block.

### Creating Complex Recipe Blocks

Defining such a block is quite similar to defining plot [Recipes](@ref):

```@example DualView
using CairoMakie

"""
Creates two `Axis` blocks side by side, showing the same data, once with a
scatter plot and once with a lines plot.
"""
@Block DualView (positions, ) begin
    @attributes begin
        "Color for scatter plot"
        scatter_color = :blue
        "Color for line plot"
        line_color = :red
    end
end

Makie.conversion_trait(::Type{<:DualView}) = PointBased()
```

This will create a `DualView <: Block` struct, containing `scatter_color` and `line_color` as attributes.
The docstring above the macro will be added to struct with "DualView <: Block" as the first line.
The docstrings above the attributes will be processed as attribute docs, which can be checked with `?DualView.attribute_name`.
All of the docstrings are optional.

Similar to plot recipes, block recipes also include argument conversions.
These are specified with `convert_arguments` methods or a `conversion_trait`, see [Type recipes](@ref).
The `positions` specified in the macro sets the name of the converted arguments.
Unlike plot recipes however, there are no automatically generated names.
You will either have to define the names in macro (as done here) or handle it explicitly in a later step.

After setting up the block object we now need to define what it does.
For this we define a `initialize_block!` method similar to how plot recipes define a `plot!` method:

```@example DualView
function Makie.initialize_block!(block::DualView)
    ax = Axis(block[1, 1])
    scatter!(ax, block.positions; color = block.scatter_color)
    lines(block[1, 2], block.positions; color = block.line_color)
    return
end
```

As you can see blocks can be added the same way as they would to a figure.
Doing so will add them to the layout of the `DualView`.
Plots can then be added to any axis added to the parent block.
Much like plot recipe, all the attributes and arguments can be accessed from the parent block.
Any attributes that are not set will default like usual.

!!! note
    The `@Block` macro also allows defining fields by creating an attribute-like entry outside the `@attributes` block.

!!! note
    Argument conversions can be skipped by implementing `Makie.initialize_block!(block, args...; kwargs...)` instead.

### Using Complex Recipe Blocks

With the definitions above we can create a `DualView` either with an implicitly created figure, or by adding them to an existing figure:

```@figure DualView
fig, dv1 = DualView(sin.(range(0, 2pi, 100)))
dv2 = DualView(fig[2, 1], cos.(range(0, 2pi, 100)))
fig
```

The blocks created by `DualView` are tracked as part of the layout in `dv.layout` and as a flattened list in `dv.blocks`.
This follows the same tree-like structure as `plot.plots`, meaning that only the blocks directly added to the `DualView` are tracked here.
For example, if we were to create a `QuadView` consisting of two `DualViews`, `quadview.layout` and `quadview.blocks` would contain two `DualViews` but no `Axis`.

Blocks can be added to a parent block in the same way they are added in `initialize_block!`:

```@figure DualView
Label(dv1[0, 1:2], "sin")
Label(dv2[0, 1:2], "cos")
fig
```

And plots can be added to the axes inside parent block as well:

```@figure DualView
hlines!(dv1[1, 2], [-1, 1], color = :black)
hlines!(dv2.blocks[2], [-1, 1], color = :black)
fig
```

## Creating self-contained Blocks

Not every block is defined as a layout of other blocks.
Some also define their visuals and functionality directly, by adding plots to a scene and reacting to events.
In analogy to plots we will call these primitive blocks.
They are also created with the `@Block` macro, though they typically use them slightly differently.

```julia
@Block MyBlock <: OptionalType begin
    scene::Scene
    @attributes begin
        color = :black
        linewidth = 4
    end
end
```

The first difference is the inclusion of the optional parent type `OptionalType`.
Including this can be useful to share functionality between blocks.
In Makie this is only used for axes with the `AbstractAxis <: Block` type.
Functionality like plotting to an axis or deleting plots from axis is implemented this way.

!!! note
    The optional type must inherit from `Block`.

The second difference is that converted argument names are not given.
This is because primitive blocks usually don't accept any arguments.
And those that do, like `Legend(fig[1, 1], axis)`, typically don't have arguments fitting for the conversion pipeline.
Instead these arguments are handled explicitly by implementing an `initialize_block!` method that accepts and handles them.

The third difference is the inclusion of entries like `scene::Scene` outside the `@attributes` block.
These are added as fields to the struct `@Block` creates.
Non-reactive things that should exist outside the `attributes` ComputeGraph should be added here.
For example extra scenes, a `MouseEventHandle`, `axis.interactions` or tasks.

!!! note
    The `AbstractAxis` interface relies on `block.scene` being the scene reserved for user plots.

With the struct created the next task is to implement `initialize_block!`.
This typically involves adding plots to `block.blockscene` and computing whatever is necessary for them.
That includes reacting to events.
If the block macro defines extra fields they should also be set here.

```julia
function Makie.initialize_block!(block::MyBlock)
    blockscene = block.blockscene
    computedbbox_obs = block.layoutobservables.computedbbox

    Makie.add_input!(block.attributes, :computedbbox, computedbbox_obs)
    map!(block, [:computedbbox, :linewidth], :inner_bbox) do bb, linewidth
        return Rect2f(minimum(bb) .+ 0.5linewidth, widths(bb) .- linewidth)
    end

    lines!(blockscene, block.inner_bbox, color = block.color, linewidth = block.linewidth)

    viewport_obs = map(Makie.round_to_IRect2D, computedbbox_obs)
    block.scene = Scene(blockscene, viewport_obs)

    # ...
end
```