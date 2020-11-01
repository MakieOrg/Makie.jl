# Devdocs

## Testing

The main repo to test is AbstractPlotting/test/ReferenceTests; all backends use this to do integration tests with AbstractPlotting.  
There are several environment variables which govern the behaviour of the test suite.

## Logistical issues

### Precompilation

Makie goes with the design of backends overloading the functions like `scatter(::Backend, args...)`,
which means they can be loaded in by Julia's normal code loading mechanisms, and should be precompile-safe.
Makie also tries to be statically compilable, but this isn't as straightforward as one could think.
So far it seems that all kind of globals are not save for static compilation and generated functions seem to also make problems.
I'm slowly removing problematic constructs from the dependencies and try to get static compilation as quick as possible.

!!! note "The state of static compilability in Makie"
Currently, `Makie` is statically compilable.

### TODOs / Up for grabs

Check out [this project](https://github.com/orgs/JuliaPlots/projects/1) for planned features and additions to Makie, as well as backlogged documentation issues.

### Adding Cameras

If you're planning to add a new camera type, you will also have to edit the `apply_camera!` function, to accept your camera type.
