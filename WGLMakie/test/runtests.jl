using ImageMagick, FileIO, Electron
using WGLMakie, Makie, Test
using Pkg

struct ElectronDisplay <: Base.Multimedia.AbstractDisplay
    window::Electron.Window
end

function ElectronDisplay()
    w = Electron.Window()
    Electron.toggle_devtools(w)
    return ElectronDisplay(w)
end

Base.displayable(d::ElectronDisplay, ::MIME{Symbol("text/html")}) = true

function Base.display(ed::ElectronDisplay, app::App)
    d = JSServe.HTTPServer.BrowserDisplay()
    session_url = "/browser-display"
    old_app = JSServe.route!(d.server, Pair{Any,Any}(session_url, app))
    url = JSServe.online_url(d.server, "/browser-display")
    return Electron.load(ed.window, JSServe.URI(url))
end
Base.Multimedia.pushdisplay(ElectronDisplay())


path = normpath(joinpath(dirname(pathof(Makie)), "..", "ReferenceTests"))
Pkg.develop(PackageSpec(path = path))
using ReferenceTests

@testset "mimes" begin
    f, ax, pl = scatter(1:4)
    @testset for mime in WGLMakie.WEB_MIMES
        @test showable(mime(), f)
    end
    # I guess we explicitely don't say we can show those since it's highly Inefficient compared to html
    # See: https://github.com/MakieOrg/Makie.jl/blob/master/WGLMakie/src/display.jl#L66-L68=
    @test !showable("image/png", f)
    @test !showable("image/jpeg", f)
    # see https://github.com/MakieOrg/Makie.jl/pull/2167
    @test !showable("blaaa", f)
end

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
    "Test heatmap + image overlap",
    "heatmaps & surface",
    "OldAxis + Surface",
    "Order Independent Transparency",
    "Record Video",
    "fast pixel marker",
    "Animated surface and wireframe",
    "Array of Images Scatter",
    "Image Scatter different sizes",
    "scatter with stroke",
    "scatter with glow"
])

@testset "refimages" begin
    WGLMakie.activate!()
    ReferenceTests.mark_broken_tests(excludes)
    recorded_files, recording_dir = @include_reference_tests "refimages.jl"
    missing_images, scores = ReferenceTests.record_comparison(recording_dir)
    ReferenceTests.test_comparison(scores; threshold = 0.032)
end
