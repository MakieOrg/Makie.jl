# Output

Makie overloads the `FileIO` interface, so it is simple to save plots as images or videos.


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
st = Stepper(scene, @outputfile)
```

and save the scene content & increment the stepper by using:
```julia
step!(st)
```

@example_database("Stepper demo")


## Animated plots

It is also possible to output animated plots as videos (note that this requires [`ffmpeg`](https://ffmpeg.org/) to be installed and properly configured on your computer (test this by running `ffmpeg -version` from a terminal window).)

```@docs
record
```

For recording of videos (either as .mp4 or .gif), you can do:
```julia
record(scene, "video.mp4", itr) do i
    func(i) # or some other animation in scene
end
```

where `itr` is an iterator and `scene` is the scene handle.

It is also possible to `record` to gifs:
```julia
record(scene, "video.gif", itr) do i
    func(i) # or some other animation in scene
end
```

In both cases, the returned value is a path pointing to the location of the recorded file.


### Example usage

@example_database("Record Video")

For more info, consult the [Examples index](@ref).
