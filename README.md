# MakiE


[![](https://img.shields.io/badge/docs-stable-blue.svg)](http://www.glvisualize.com/MakiE.jl/stable/)

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
```

Make sure that the check out happens without error. E.e. if you have previously tinkered with GLVisualize, it might happen that you don't check out the `sd/makie` branch correctly.
