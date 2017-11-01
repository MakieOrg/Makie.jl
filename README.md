[![code](https://github.com/SimonDanisch/MakiE.jl/blob/master/docs/header.png?raw=true)](https://github.com/SimonDanisch/MakiE.jl/blob/master/docs/make.jl)

# MakiE

From the japanese word [Maki-e](https://en.wikipedia.org/wiki/Maki-e), which is a technique to sprinkle lacquer with gold and silver powder.
Data is basically the gold and silver of our age, so lets spread it out beautifully on the screen!



[![](https://img.shields.io/badge/docs-stable-blue.svg)](http://www.glvisualize.com/MakiE.jl/stable/)

It's Halloween :)

![output](https://user-images.githubusercontent.com/1010467/32203311-b6624fd6-bde2-11e7-97ca-23cc41c7a475.gif)

IJulia examples:

[![](https://user-images.githubusercontent.com/1010467/32204865-33482ddc-bdec-11e7-9693-b94d999187dc.png)](https://gist.github.com/SimonDanisch/8f5489cffaf6b89c9a3712ba3eb12a84)




Mouse interaction:

[<img src="https://user-images.githubusercontent.com/1010467/31519651-5992ca62-afa3-11e7-8b10-b66e6d6bee42.png" width="489">](https://vimeo.com/237204560 "Mouse Interaction")

Animating a surface:

[<img src="https://user-images.githubusercontent.com/1010467/31519521-fd67907e-afa2-11e7-8c43-5f125780ae26.png" width="489">](https://vimeo.com/237284958 "Surface Plot")


# Installation

This package is not released yet so a bit awkward to set up. Here are the steps:

```julia
Pkg.clone("https://github.com/SimonDanisch/MakiE.jl.git")
Pkg.checkout("GLAbstraction", "sd/makie")
Pkg.checkout("GLVisualize", "sd/makie")

# For UV examples, e.g. earth texture on sphere, or textured cat
Pkg.checkout("MeshIO", "sd/objuv")
Pkg.checkout("GeometryTypes", "sd/sphereuv")
```

Make sure that the check out happens without error. E.e. if you have previously tinkered with GLVisualize, it might happen that you don't check out the `sd/makie` branch correctly.
