using ImageMagick, Test
using CairoMakie, AbstractPlotting, MakieGallery
CairoMakie.activate!(type = "png")
        
AbstractPlotting.format2mime(::Type{AbstractPlotting.FileIO.format"PDF"})  = MIME("application/pdf")

include("saving.jl") # test saving params

database = MakieGallery.load_database()
filter!(database) do entry
    "2d" in entry.tags &&
    "Text rotation" != entry.title &&
    "fem polygon 2d" != lowercase(entry.title) &&
    "Hbox" != entry.title &&
    lowercase(entry.title) != "arrows on hemisphere" &&
    lowercase(entry.title) != "cobweb plot" &&
    lowercase(entry.title) != "streamplot animation" &&
    !("heatmap" in entry.tags) && # why though, they worked -.-
    !("image" in entry.tags)
end

empty!(MakieGallery.plotting_backends)
push!(MakieGallery.plotting_backends, "AbstractPlotting", "CairoMakie")
tested_diff_path = joinpath(@__DIR__, "tested_different")
test_record_path = joinpath(@__DIR__, "test_recordings")
rm(tested_diff_path, force = true, recursive = true)
mkpath(tested_diff_path)
rm(test_record_path, force = true, recursive = true)
mkpath(test_record_path)

MakieGallery.record_examples(test_record_path)
MakieGallery.run_comparison(test_record_path, tested_diff_path)
