using FileIO
using WGLMakie, Makie, Test
using WGLMakie.Bonito
using ReferenceTests
import Electron

@testset "mimes" begin
    Makie.inline!(true)
    f, ax, pl = scatter(1:4)
    @testset for mime in Makie.WEB_MIMES
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
    "image scatter",
    # missing transparency & image
    "Image on Surface Sphere",
    # Marker size seems wrong in some occasions:
    "Hbox",
    "UnicodeMarker",
    # Not sure, looks pretty similar to me! Maybe blend mode?
    "Test heatmap + image overlap",
    # "heatmaps & surface", # TODO: fix direct NaN -> nancolor conversion
    "Order Independent Transparency",
    "fast pixel marker",
    "Array of Images Scatter",
    "Image Scatter different sizes",
    "Textured meshscatter", # not yet implemented
    "3D Contour with 2D contour slices", # looks like a z-fighting issue
])
Makie.inline!(Makie.automatic)

edisplay = Bonito.use_electron_display(devtools=true)
@testset "refimages" begin
    WGLMakie.activate!()
    ReferenceTests.mark_broken_tests(excludes)
    recorded_files, recording_dir = @include_reference_tests WGLMakie "refimages.jl"
    missing_images, scores = ReferenceTests.record_comparison(recording_dir)
    ReferenceTests.test_comparison(scores; threshold = 0.05)
end

@testset "memory leaks" begin
    Makie.CURRENT_FIGURE[] = nothing
    app = App(nothing)
    display(edisplay, app)
    GC.gc(true);
    # Somehow this may take a while to get emptied completely
    Bonito.wait_for(() -> (GC.gc(true);isempty(run(edisplay.window, "Object.keys(WGL.plot_cache)")));timeout=20)
    wgl_plots = run(edisplay.window, "Object.keys(WGL.scene_cache)")
    @test isempty(wgl_plots)

    session = edisplay.browserdisplay.handler.session
    session_size = Base.summarysize(session) / 10^6
    texture_atlas_size = Base.summarysize(WGLMakie.TEXTURE_ATLAS) / 10^6
    @show session_size texture_atlas_size
    @test session_size / 10^6 < 6
    @test texture_atlas_size < 6
    s_keys = "Object.keys(Bonito.Sessions.SESSIONS)"
    Bonito.wait_for(() -> (GC.gc(true); 2 == length(run(edisplay.window, s_keys))); timeout=30)
    js_sessions = run(edisplay.window, "Bonito.Sessions.SESSIONS")
    js_objects = run(edisplay.window, "Bonito.Sessions.GLOBAL_OBJECT_CACHE")
    # @test Set([app.session[].id, app.session[].parent.id]) == keys(js_sessions)
    # we used Retain for global_obs, so it should stay as long as root session is open
    @test keys(js_objects) == Set([WGLMakie.TEXTURE_ATLAS.id])
end
