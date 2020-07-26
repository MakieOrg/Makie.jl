using ElectronDisplay
ElectronDisplay.CONFIG.showable = showable
ElectronDisplay.CONFIG.single_window = true
ElectronDisplay.CONFIG.focus = false
using WGLMakie, AbstractPlotting, JSServe, Test
using MakieGallery


exclude_tests = Set(Symbol.([
    "streamplot_animation",
    "transforming_lines",
    "image_scatter",
    "test_38",
    "line_gif",
    "stars", # glow missing
    "orthographic_camera", #HM!?
    "hbox_1",# pixel size marker wrong size?!
    "electrostatic_repulsion", # quite a bit brigher..weird
    "errorbars_x_y_low_high", # something weird with image compare
    "errorbars_xy_error",
    "errorbars_xy_low_high",
]))

abstractplotting_test_dir = joinpath(dirname(pathof(AbstractPlotting)), "..", "test", "reference_image_tests")
abstractplotting_tests = joinpath.(abstractplotting_test_dir, readdir(abstractplotting_test_dir))
database = MakieGallery.load_database(abstractplotting_tests)

filter!(database) do entry
    return !(entry.unique_name in exclude_tests)
end

tested_diff_path = joinpath(@__DIR__, "tested_different")
test_record_path = joinpath(@__DIR__, "test_recordings")
for path in (tested_diff_path, test_record_path)
    try
        if isdir(path)
            rm(path, force=true, recursive=true)
        end
        mkpath(path)
    catch e
    end
end
examples = MakieGallery.record_examples(test_record_path)
path = MakieGallery.download_reference("v0.6.3")
MakieGallery.run_comparison(test_record_path, tested_diff_path,
                            joinpath(dirname(path), "test_recordings"),
                            maxdiff=0.091)
