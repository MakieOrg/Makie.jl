# Makie package extensions

In the following we described how you can extend Makie in your own package
without having a hard dependency on Makie.jl.
[Package extensions](https://pkgdocs.julialang.org/v1.10/creating-packages/#Conditional-loading-of-code-in-packages-(Extensions)) were introduced
in Julia v1.9 to allow one package to extend functionality of another
without the need to add that other package as a dependency.
These so-called extensions or soft dependencies often define an
additional method for a function from package A for a type of package B,
but this method is only loaded when both A and B are imported.
The documentation of extensions in
[Pkg.jl](https://pkgdocs.julialang.org/v1.10/creating-packages/#Conditional-loading-of-code-in-packages-(Extensions))
describes the situation for extending a function your package owns
for a type another package owns. However, extending Makie externally,
many cases will work the other way around whereby another
packages own the type and would like the extend a function they
do not own, but that lives in Makie.

## Define the Makie extension

First you need to define that Makie is a soft dependency of your
package `MyPackage.jl`. In its repository, add the folder `ext`
for extensions and within it a file named `MyPackageMakieExt.jl`
or similar. This file is then structured as

```julia
module MyPackageMakieExt

using MyPackage, Makie

"""Define Makie's `heatmap` for `x::,MyType`."""
function Makie.heatmap(x::MyType)

    # your code here how to visualise x
    # likely including a call to a Makie function
    # like heatmap(y) with y datatype (e.g. matrix)
    # that Makie can visualise, creating some figure 

    # to see the figure return it
    # return fig
end

end # module
```

Here the `Makie.heatmap` is important to extend a function from
Makie and not just define a local `heatmap` function that happens
to have the same name. You can then call `heatmap` within
it as normal because of the line `using Makie`.

Note that we have only extended Makie here, not any of its
backends. While you can do that too, the idea here is to
extend functionality for Makie, regardless of which
backend is currently active. So whether you do `using GLMakie`
or `using CairoMakie` because it also imports Makie,
it also loads the code above.

## Make Makie a soft dependency

In the `Project.toml` of your package you then need to add

```
[weakdeps]
Makie = "ee78f7c6-11fb-53f2-987a-cfe4a2b5a57a"

[extensions]
MyPackageMakieExt = "Makie"

[compat]
Makie = "0.20"
```

Note that `Makie` has been added to `[weakdeps]` not `[deps]`
which would happen if you `add Makie` in the package manager
in the environment of your package -- but you do not want to
add it as a dependency! Under `[extensions]` then comes the
name of the module you have defined above, which should
have the same name as the file too. You should add a compatibility
entry under `[compat]` for Makie too, here for version 0.20.

## Testing the extensions

This is trickier than it sounds to do locally. If you do
`using .MyPackage` locally and also `using Makie`
(or `using CairoMakie` which also imports Makie) and you
are in the environment of `MyPackage` then the
package manager wants to install Makie as a dependency.
This is because it does exist yet in this environment and also
should not because you only want it as an extension!

Given you are developing your own package, one way to
test the Makie extension is to push to a new branch at
`github.com/Me/MyPackage.jl#makie` or similar and then
add that branch in your main Julia environment with

```julia
(@v1.10) pkg> add https://github.com/Me/MyPackage.jl#makie
```

because you are now installing a package into another
environment it (where Makie is already installed) it detects
the extension correctly. You can then test this with

```julia
julia> using MyPackage

julia> heatmap
ERROR: UndefVarError: `heatmap` not defined
```
So without importing Makie our extension of the `heatmap`
function has not been loaded (good!), but if we do

```julia
julia> using CairoMakie     # or other backend
Precompiling MyPackageMakieExt
  1 dependency successfully precompiled in 12 seconds. 360 already precompiled.
```

This will load the extension and the first time also
precompile it. You can then check that a `heatmap` method
actually exists as defined above with

```julia
julia> methods(heatmap)
# 4 methods for generic function "heatmap" from MakieCore:
 [1] heatmap()
     @ ~/.julia/packages/MakieCore/UAwps/src/recipes.jl:172
 [2] heatmap(x::MyType)
     @ MyPackageMakieExt ~/.julia/packages/MyPackage/kXPNB/ext/MyPackageMakieExt.jl:14
 [3] heatmap(args...; kw...)
     @ ~/.julia/packages/MakieCore/UAwps/src/recipes.jl:175
```

as you can see not just `heatmap` from MakieCore exists but also
the method we have defined in our extension!