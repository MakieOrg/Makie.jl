# Layouting

Every object contains a boundingbox and a box indicating where the object should be placed.
By default, those boxes are the same. But if you want to move, stretch, scale an object, you can edit the latter.
This can be a manual process, or an automatic one.
E.g. there are several functions which try to automatically find a layout for certain objects.

# Automatic interface

```Julia
layout!(object1, object2, objectN...) 1D grid (alternatively use a vector)
layout!(Matrix{Objects}(...)) # 2d Grid
layout!(Array{Objects, 3}(...))

# TODO port layouting options from Plots.jl

```


# Manual interface

```Julia

scale!(object, 1f0) # ND version with same scalar for all dimensions
scale!(object, (1f0, 2f0)) # 2d
scale!(object, (1f0, 2f0, 3f0)) # 3d

rotate!(object, axis::Vec, amount_degree)

move!(object, amount) # for amount it's the same as with scale!

# boundingbox can be any rect type, e.g. a 3D or 2D HyperRectangle
# with the effect of exactly fitting `object` into `boundingbox`
move!(object, boundingbox)
```
