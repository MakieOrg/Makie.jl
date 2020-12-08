using ElectronDisplay
ElectronDisplay.CONFIG.showable = showable
ElectronDisplay.CONFIG.single_window = true
ElectronDisplay.CONFIG.focus = false
using ImageMagick, FileIO
using WGLMakie, AbstractPlotting, JSServe, Test
using Pkg

@which AbstractPlotting.primary_resolution()
AbstractPlotting.minimal_default.resolution[] = (600, 400)
display(scatter(rand(10), resolution=(600, 400)))

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
ReferenceTests.reference_tests(recorded; difference=0.04)
