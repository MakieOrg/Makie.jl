using Pkg

pkg"add Makie#gl-makie https://github.com/JuliaPlots/MakieGallery.jl#gl-makie"

#pkg"test MakieGallery"
using MakieGallery, GLMakie

include(joinpath(dirname(pathof(MakieGallery)), "..", "test", "runtests.jl"))
