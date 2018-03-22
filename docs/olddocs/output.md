# Input Output

Makie overloads the FileIO interface.
So you can just write e.g.:
```Julia
save(scene, "test.png")
save(scene, "test.jpg")
```

There is also the option to save a plot as a Julia File (not implemented yet)

```Julia
save(scene, "test.jl")
```

This will try to reproduce the plotting commands as closely as possible to recreate the current scene.
You can specify if you want to save the defaults explicitly or if you not want to store them, so that
whenever you change defaults and the saved code gets loaded it will take the new defaults.


# VideoStream


```@docs

VideoStream
finish
```

@library_ref[example] "VideoStream"
