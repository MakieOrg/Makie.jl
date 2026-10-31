@testset "Glyph atlas arrival and deduplication" begin
    checks = run(
        edisplay.window, """
        (() => {
            const Atlas = WGL.get_texture_atlas().constructor;
            const atlas = new Atlas(4, 1, 0);
            const requests = [];
            let ready = 0;
            atlas.request_obs = {notify: hashes => requests.push(hashes)};
            const checks = [];
            checks.push(!atlas.ensure_glyphs(new Uint32Array([42, 42]), () => ready++));
            checks.push(!atlas.ensure_glyphs(new Uint32Array([42]), () => ready++));
            checks.push(requests.length === 1 && requests[0].length === 1 && requests[0][0] === 42);
            const batch = {42: [[0, 0, 0.25, 0.25], {array: new Float32Array([1])}, [1, 1], [0, 0]]};
            atlas.insert_glyphs(batch);
            checks.push(ready === 2 && atlas.waiters.length === 0 && atlas.requested.size === 0);
            atlas.insert_glyphs(batch);
            checks.push(ready === 2);
            checks.push(atlas.ensure_glyphs(new Uint32Array([42]), () => ready++));
            checks.push(ready === 2 && atlas.data[0] === 1);
            return checks;
        })()
        """
    )
    @test length(checks) == 7
    for check in checks
        @test check
    end
end

@testset "Glyph delivery across subsessions" begin
    WGLMakie.activate!(use_html_widgets = false)
    owner = Figure(size = (300, 200))
    Label(owner[1, 1], "Late glyphs Ωλ", fontsize = 30)
    visible = Figure(size = (300, 200))
    Label(visible[1, 1], "Late glyphs Ωλ", fontsize = 30)
    hidden = Ref{Bonito.Session}()
    app = App() do session
        hidden[] = Bonito.Session(session)
        # Render the first figure's initialization payload without mounting it.
        Bonito.session_dom(hidden[], App(owner))
        WGLMakie.serialize_scene(owner.scene)
        return visible
    end
    display(edisplay, app)
    try
        @test Bonito.wait_for(() -> events(visible).window_open[]; timeout = 20) == :success
        @test !events(owner).window_open[]
        @test run(
            edisplay.window, """
            (() => {
                const plots = Object.values(WGL.plot_cache).map(mesh => mesh.plot_object).filter(p => p.glyph_info?.scales);
                const atlas = WGL.get_texture_atlas();
                return plots.length > 0 && plots.every(p =>
                    Array.from(p.glyph_info.glyph_hashes).every(h => atlas.glyph_data.has(String(h))));
            })()
            """
        )

        @test run(
            edisplay.window, """
            (() => {
                const plot = Object.values(WGL.plot_cache).map(mesh => mesh.plot_object).find(p => p.glyph_info?.scales && p.glyph_info.glyph_hashes.length > 0);
                const heal = Object.getPrototypeOf(plot).heal_missing_glyphs;
                let reply;
                let updates = 0;
                const target = {
                    glyph_info: plot.glyph_info, mesh: {},
                    atlas: {ensure_glyphs: (hashes, ready) => { reply = ready; }},
                    update: () => { updates++; }
                };
                heal.call(target);
                target.glyph_info = {...target.glyph_info};
                reply(); // A newer text update superseded this response.
                if (updates !== 0) return false;
                heal.call(target);
                target.mesh = undefined;
                reply(); // The plot was disposed before the glyphs arrived.
                return updates === 0;
            })()
            """
        )

        # Lose the browser's glyph metadata, then exercise the real pull responder.
        @test run(
            edisplay.window, """
            (() => {
                const atlas = WGL.get_texture_atlas();
                const hashes = [...new Set(Object.values(WGL.plot_cache).map(mesh => mesh.plot_object)
                    .flatMap(p => Array.from(p.glyph_info?.glyph_hashes ?? [])))];
                hashes.forEach(h => atlas.glyph_data.delete(String(h)));
                atlas.test_glyph_ready = 0;
                atlas.ensure_glyphs(new Uint32Array(hashes), () => { atlas.test_glyph_ready++; });
                atlas.ensure_glyphs(new Uint32Array(hashes), () => { atlas.test_glyph_ready++; });
                return hashes.length > 0 && atlas.waiters.length === 2;
            })()
            """
        )
        @test Bonito.wait_for(; timeout = 20) do
            run(edisplay.window, "WGL.get_texture_atlas().test_glyph_ready === 2")
        end == :success
        @test run(edisplay.window, "WGL.get_texture_atlas().waiters.length === 0")
        @test run(edisplay.window, "WGL.get_texture_atlas().requested.size === 0")
        @test !isempty(colorbuffer(visible))
    finally
        run(edisplay.window, "delete WGL.get_texture_atlas().test_glyph_ready")
        close(hidden[])
        display(edisplay, App(nothing))
    end
end

@testset "Cached glyphs and raw atlas entries on fresh pages" begin
    figure = Figure(size = (300, 160))
    font = Makie.to_font("TeX Gyre Heros Makie")
    Label(figure[1, 1], "Redisplay Ωλ", fontsize = 30, font = font)
    reference = nothing
    for _ in 1:2
        server = Bonito.Server("127.0.0.1", 0)
        page = Bonito.HTTPServer.ElectronDisplay(;
            app = edisplay.window.app,
            options = Dict{String, Any}("show" => false, "webPreferences" => Dict("offscreen" => true, "backgroundThrottling" => false))
        )
        page.browserdisplay.server = server
        try
            if reference === nothing
                hashes, _ = Makie.get_glyph_data(Makie.get_texture_atlas(), Set{UInt32}(), collect("Redisplay Ωλ"), font)
                atlas_scene = Scene(size = (300, 160))
                scatter!(atlas_scene, fill(Point2f(0), length(hashes)), marker = hashes)
                display(page, App(atlas_scene))
                colorbuffer(atlas_scene)
            end
            display(page, App(figure))
            image = copy(colorbuffer(figure))
            if reference === nothing
                reference = image
                @test length(unique(image)) > 1
            else
                @test image == reference
            end
            sync = Bonito.get_metadata(page.browserdisplay.handler.session, :wglmakie_glyph_sync)
            @test !isempty(sync.bbox)
            @test any(bounds -> all(>(0), bounds[1]), values(sync.bbox))
        finally
            close(page)
            close(server)
        end
    end
end
