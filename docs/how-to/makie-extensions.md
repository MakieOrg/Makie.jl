# Makie package extensions

!!! note "For package developers"
    The following is intended for package developers which are also Makie users
    that want to integrate some Makie functionality into their own packages. 

In the following we describe how you can use and extend Makie in your
own package without having a hard dependency on it.
[Package extensions](https://pkgdocs.julialang.org/v1.10/creating-packages/#Conditional-loading-of-code-in-packages-(Extensions))
were introduced in Julia v1.9 to allow one package to extend functionality
of another without the need to add that other package as a dependency.
Many package developers would hesitate to add a dependency on another
large package if it is not essential, but rather would offer
_optional_ functionality if that other large package is also loaded. 
Extensions are therefore soft dependencies, often defining an
additional method for a function from package A for a type of package B,
but this method is only loaded when both A and B are imported.
The extension itself could live in either A or B, extending either
a foreign function, or extending an owned function for a foreign type.
The [documentation of extensions](https://pkgdocs.julialang.org/v1.10/creating-packages/#Conditional-loading-of-code-in-packages-(Extensions))
in Pkg.jl describes the latter situation for extending a function your package owns
for a type another package owns. However, many cases will work the other way around
whereby you want to define a Makie extension for your package, which owns a type
for which you want to define some functionality that lives in Makie.

## Define the Makie extension

First, in the repository of your package `MyPackage.jl`, add the folder `ext`
for extensions and within it a file named `MyPackageMakieExt.jl`
or similar. The naming convention is your package name followed by
the name of the soft dependency (here Makie) followed by "Ext.jl".
This file defines a module with the same name and is structured as

```julia
module MyPackageMakieExt

using MyPackage, Makie

"""Define Makie's `heatmap` for `x::MyType`."""
function Makie.heatmap(x::MyType)
    # your code here how to visualise x
    # likely including a call to a Makie function
    # like heatmap(y) with some data y (e.g. matrix)
    # that Makie can visualise, creating some figure 
    # which presumably should be returned
    # return fig
end

end # module
```

Here the `Makie.` in `Makie.heatmap` is important to extend a function from
Makie and not just define a local `heatmap` function that happens
to have the same name. You can then call `heatmap` within
it as normal because of the line `using Makie` and because `y` (data of type
that Makie can visualise) and `x` (of type `MyType`) have different types.
The above is an example, you have general freedom what to write into this
module `MyPackageMakieExt` it will only be loaded when `using Makie`
(see below in [Testing the extension](@ref)).

Note that we have only extended Makie here, not any of its backends.
While you can do that too to be more specific, the idea here is to
extend functionality for Makie, regardless of which backend is currently active.
So whether you do `using GLMakie` or `using CairoMakie` because it also imports Makie,
it also loads the code above.

## Make Makie a soft dependency

Second, you need to define that Makie is a soft dependency of your
package `MyPackage.jl`. In the `Project.toml` of your package you need to add

```
[weakdeps]
Makie = "ee78f7c6-11fb-53f2-987a-cfe4a2b5a57a"

[extensions]
MyPackageMakieExt = "Makie"

[compat]
Makie = "0.20"
```

Note that `Makie` has been added to `[weakdeps]` not `[deps]`
which would happen if you `add Makie` through the package manager
in the environment of your package. Which is exactly not what we want.
Under `[extensions]` then comes the name of the module you have defined above
on the left, and `"Makie"` the soft dependency on the right.
Also add a compatibility entry under `[compat]` for Makie too,
e.g. here for version 0.20.

## Testing the extension

To test the extension locally is a bit tricky.
If you do `using .MyPackage` locally inside the environment of
your package then with `using Makie` the package manager
will suggest to install Makie as a dependecy. Not what we want
because Makie should not exist in the environment of your package,
it is a soft dependency after all.
The same holds for `using CairoMakie` (or another backend)
which itself also has Makie as dependency.

Given you are developing your own package, one way to
test the Makie extension is to push to a new branch at
`github.com/Me/MyPackage.jl#makie` (use your path) and then
add that branch in your main Julia environment with

```julia
(@v1.10) pkg> add https://github.com/Me/MyPackage.jl#makie
```

(replace with your path). This way you are installing `MyPackage.jl` into
another environment where Makie can, but does not have to be, already installed.
Now the package manager will detect the extension correctly and only load it
when also Makie is imported. You can then test this with

```julia
julia> using MyPackage  # no using/import Makie happened before this line!

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