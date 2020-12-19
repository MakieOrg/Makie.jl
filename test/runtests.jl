using ElectronDisplay
ElectronDisplay.CONFIG.showable = showable
ElectronDisplay.CONFIG.single_window = true
ElectronDisplay.CONFIG.focus = false
using ImageMagick, FileIO
using WGLMakie, AbstractPlotting, JSServe, Test
using Pkg

# ImageIO seems broken on 1.6 ... and there doesn't
# seem to be a clean way anymore to force not to use a loader library?
filter!(x-> x !== :ImageIO, FileIO.sym2saver[:PNG])
filter!(x-> x !== :ImageIO, FileIO.sym2loader[:PNG])
AbstractPlotting.set_theme!(resolution=(400, 400))
# TODO fix bug where on first display content doesn't get resized correctly
# In JSServe
display(scatter(rand(10)))

path = normpath(joinpath(dirname(pathof(AbstractPlotting)), "..", "test", "ReferenceTests"))
Pkg.develop(PackageSpec(path = path))
using ReferenceTests
using ReferenceTests: nice_title
excludes = Set([
    "Streamplot animation",
    "Transforming lines",
    "image scatter",
    "Line GIF",
    "surface + contour3d",
    # Hm weird, looks like some internal JSServe error missing an Observable:
    "Errorbars x y low high",
    "Rangebars x y low high",
    # These are a bit sad, since it's just missing interpolations
    "FEM mesh 2D",
    "FEM polygon 2D",
    # missing transparency & image
    "Wireframe of a Surface",
    "Image on Surface Sphere",
    "Surface with image",
    # Marker size seems wrong in some occasions:
    "Hbox",
    "UnicodeMarker",
    # Not sure, looks pretty similar to me! Maybe blend mode?
    "Test heatmap + image overlap"
])

database = ReferenceTests.load_database()
filter!(database) do (name, entry)
    !(entry.title in excludes) &&
    nice_title(entry) !== "short_tests_83" &&
    nice_title(entry) !== "short_tests_78"
end
recorded = joinpath(@__DIR__, "recorded")
rm(recorded; force=true, recursive=true); mkdir(recorded)
ReferenceTests.record_tests(database; recording_dir=recorded)
ReferenceTests.reference_tests(recorded; difference=0.06)
WGLMakie.AbstractPlotting.inline!(false)
JSServe.browser_display()

display(scatter(1:4));
