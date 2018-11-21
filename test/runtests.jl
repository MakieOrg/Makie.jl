using Pkg

pkg"add Makie#sd-glmakie https://github.com/JuliaPlots/MakieGallery.jl"

#pkg"test MakieGallery"
using MakieGallery, GLMakie

include(joinpath(dirname(pathof(MakieGallery)), "..", "test", "runtests.jl"))
