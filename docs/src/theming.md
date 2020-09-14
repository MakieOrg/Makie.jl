# Config file

A configuration file can be used to save theming options. This makes
it easier to have a common style for multiple plots without explicitly giving
the desired options each time.

A config file must return an `Attributes` object. For example, if the contents of
`theme.jl` is the following:
```julia
Attributes(
    font = "Chilanka",
    backgroundcolor = :gray,
    color = :blue,
    linestyle = :dot,
    linewidth = 3
)
```
you can use it with Makie by `include`ing it before making any plots
```julia
theme = include("theme.jl")
theme isa Attributes && set_theme!(theme)
```

There are other things that you can configure in this file before returning the Attributes, though.  

## Resolution setting

You can set the default resolution, at which Scenes will be displayed, by adding the statement:
```julia
reasonable_resolution() = (800, 800)
```
before the attributes' declaration.

You can also configure your primary resolution, by:
```julia
primary_resolution() = (1920, 1080)
```
