using Pkg

pkg"dev Makie https://github.com/JuliaPlots/MakieGallery.jl"

#pkg"test MakieGallery"
using MakieGallery, GLMakie

include(joinpath(dirname(pathof(MakieGallery)), "..", "test", "runtests.jl"))
