using ElectronDisplay
ElectronDisplay.CONFIG.showable = showable
ElectronDisplay.CONFIG.single_window = true
using WGLMakie, AbstractPlotting, JSServe, Test
using MakieGallery

# ElectronDisplay.toggle_devtools(ElectronDisplay._window[])
tests_wgl_makie = Set(Symbol.([
    "arc_1",
    "arrows_3d",
    "available_markers",
    "barplot_1",
    "colored_mesh",
    "colored_triangle",
    "colored_triangle_1",
    "customize_axes",
    "errorbar",
    "fem_mesh_2d",
    "fem_mesh_3d",
    "fem_polygon_2d",
    "fluctuation_3d",
    "heatmap_1",
    "image_1",
    "image_on_geometry__earth_",
    "image_on_geometry__moon_",
    "image_on_surface_sphere",
    "linesegments___colors",
    "line_function",
    "load_mesh",
    "marker_offset",
    "marker_sizes",
    "marker_sizes___marker_colors",
    "merged_color_mesh",
    "meshscatter_function",
    "normals_of_a_cat",
    "polygons",
    "poly_and_colormap",
    "scatter_1",
    "scatter_colormap",
    "simple_meshscatter",
    "sphere_mesh",
    "stepper_demo",
    "test_10",
    "test_11",
    "test_12",
    "test_13",
    "test_14",
    "test_15",
    "test_16",
    "test_18",
    "test_19",
    "test_20",
    "test_21",
    "test_22",
    "test_3",
    "test_31",
    "test_4",
    "test_8",
    "test_9",
    "test_heatmap___image_overlap",
    "textured_mesh",
    "text_annotation",
    "tutorial_adding_to_a_scene",
    "tutorial_adjusting_scene_limits",
    "tutorial_barplot",
    "tutorial_basic_theming",
    "tutorial_heatmap",
    "tutorial_linesegments",
    "tutorial_markersize",
    "tutorial_plot_transformation",
    "tutorial_simple_line",
    "tutorial_simple_scatter",
    "tutorial_title",
    "unicode_marker",
    "viridis_meshscatter",
    "viridis_scatter",
    "wireframe_of_a_mesh",
]))

database = MakieGallery.load_database()
filter!(database) do entry
    entry.unique_name in tests_wgl_makie
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
MakieGallery.run_comparison(test_record_path, tested_diff_path, maxdiff = 0.091)
