using ElectronDisplay
ElectronDisplay.CONFIG.showable = showable
ElectronDisplay.CONFIG.single_window = true
ElectronDisplay.CONFIG.focus = false
using ImageMagick
using WGLMakie, AbstractPlotting, JSServe, Test
using Pkg
display(scatter(1:4))


path = normpath(joinpath(dirname(pathof(AbstractPlotting)), "..", "test", "ReferenceTests"))
Pkg.develop(PackageSpec(path = path))
using ReferenceTests

excludes = Set([
    "Streamplot animation",
    "Transforming lines",
    "image scatter",
    "Stars"
])

database = ReferenceTests.load_database()
filter!(database) do (name, entry)
    !(entry.title in excludes) &&
    !(:Record in entry.used_functions)
end
files, recorded = ReferenceTests.record_tests(database)
recorded = ReferenceTests.basedir("recorded")
ReferenceTests.reference_tests(recorded; difference=0.4)
Base.summarysize(AbstractPlotting._current_default_theme) / 10^6
