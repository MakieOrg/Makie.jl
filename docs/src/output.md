# Output

Makie overloads the `FileIO` interface, so it is simple to save Scenes as images.

## Static plots

To save a `scene` as an image, you can just write e.g.:

```julia
Makie.save("plot.png", scene)
Makie.save("plot.jpg", scene)
```

where `scene` is the scene handle.

In the backend, `ImageMagick` is used for the image format conversions.

## Stepper plots

A `Stepper` is a scene type that simplifies the cumulative plotting, modifying of an existing scene, and saving of scenes.
These are great for showing off progressive changes in plots, such as demonstrating the effects of theming or changing data.

You can initialize a `Stepper` by doing:

```julia
st = Stepper(scene, @replace_with_a_path)
```

and save the scene content & increment the stepper by using:

```julia
step!(st)
```

```julia
function stepper_demo()
    scene = Scene()
    pos = (50, 50)
    steps = ["Step 1", "Step 2", "Step 3"]
    colors = AbstractPlotting.ColorBrewer.palette("Set1", length(steps))
    lines!(scene, Rect(0,0,500,500), linewidth = 0.0001)
    # initialize the stepper and give it an output destination
    st = Stepper(scene, @replace_with_a_path)

    for i = 1:length(steps)
        text!(
            scene,
            steps[i],
            position = pos,
            align = (:left, :bottom),
            textsize = 100,
            font = "Blackchancery",
            color = colors[i],
            scale_plot = false
        )
        pos = pos .+ 100
        step!(st) # saves the step and increments the step by one
    end
    return st
end
stepper_demo()
```

For more info, consult the [Example Gallery](http://juliaplots.org/MakieReferenceImages/gallery/index.html).
