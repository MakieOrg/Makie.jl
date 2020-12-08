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

display(scatter(rand(10), resolution=(600, 400)))

path = normpath(joinpath(dirname(pathof(AbstractPlotting)), "..", "test", "ReferenceTests"))
Pkg.develop(PackageSpec(path = path))
using ReferenceTests

excludes = Set([
    "Streamplot animation",
    "Transforming lines",
    "image scatter",
    "Line GIF"
])

database = ReferenceTests.load_database()
filter!(database) do (name, entry)
    !(entry.title in excludes)
end
files, recorded = ReferenceTests.record_tests(database)
recorded = ReferenceTests.basedir("recorded")
ReferenceTests.reference_tests(recorded; difference=0.04)
