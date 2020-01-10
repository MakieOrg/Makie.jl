using ElectronDisplay
ElectronDisplay.CONFIG.showable = showable
ElectronDisplay.CONFIG.single_window = false
using WGLMakie, AbstractPlotting, JSServe, Test

using MakieGallery

empty!(MakieGallery.plotting_backends)
push!(MakieGallery.plotting_backends, "WGLMakie", "AbstractPlotting")

# ElectronDisplay.toggle_devtools(ElectronDisplay._window[])
database = MakieGallery.load_database()

filter!(database) do entry
    !("opengl" in entry.tags)
end
# ex = database[1];
# empty!(database)
# push!(database, ex)
tested_diff_path = joinpath(@__DIR__, "tested_different")
test_record_path = joinpath(@__DIR__, "test_recordings")
for path in (tested_diff_path, test_record_path)
    rm(path, force=true, recursive=true)
    mkpath(path)
end
examples = MakieGallery.record_examples(test_record_path)
examples
MakieGallery.run_comparison(test_record_path, tested_diff_path, maxdiff = 0.01)
MakieGallery.cr
MakieGallery.generate_preview(test_record_path, joinpath(@__DIR__, "index.html"))
AbstractPlotting.set_theme!(resolution=(500, 500))
s = scatter(rand(4), rand(4), rand(4), color = rand(4));
electrondisplay(s)
center!(s);
