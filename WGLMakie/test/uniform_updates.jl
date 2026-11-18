@testset "Clip plane uniform updates: $(nameof(plotfun))" for plotfun in (scatter, mesh)
    points = Point2f[(x, y) for x in 0.1:0.1:0.9 for y in 0.1:0.1:0.9]
    plane = Plane3f(Point3f(0.5), Vec3f(1, 1, 0))
    data = plotfun === mesh ? Rect2f(0, 0, 1, 1) : points
    f, ax, plot = plotfun(data; color = :red, figure = (; size = (300, 250)))
    try
        display(edisplay, App(f))
        @test Bonito.wait_for(() -> events(f).window_open[]; timeout = 20) == :success
        @testset "Updates are decoded before plot-specific dispatch" begin
            checks = Bonito.evaljs_value(
                f.scene.current_screens[1].session, js"""
                (() => {
                    const plot = WGL.plot_cache[$(WGLMakie.js_uuid(plot))].plot_object;
                    const original = plot.update;
                    const compressed = {value: [1, 2, 3, 4], length: 8};
                    const plain = new Float32Array([1, 2, 3]);
                    const texture = [[3], plain];
                    const glyphs = {glyph_hashes: new Uint32Array([42])};
                    let received;
                    try {
                        plot.update = data => { received = Object.fromEntries(data); };
                        plot.update_callback([
                            ["uniform", compressed], ["buffer", {value: 2, length: 3}],
                            ["plain", plain], ["texture", texture],
                            ["glyph_data", glyphs], ["visible", false]
                        ]);
                        return [
                            received.uniform instanceof Float32Array && received.uniform.length === 32 &&
                                received.uniform.every((x, i) => x === (i % 4) + 1),
                            received.buffer instanceof Float32Array &&
                                Array.from(received.buffer).join() === "2,2,2",
                            received.plain === plain && received.texture === texture &&
                                received.glyph_data === glyphs && received.visible === false,
                            compressed.value.length === 4 && compressed.length === 8
                        ];
                    } finally {
                        plot.update = original;
                    }
                })()
                """
            )
            @test checks == [true, true, true, true]
        end
        unclipped = colorbuffer(f)
        for planes in ([plane], Plane3f[], fill(plane, 8), Plane3f[])
            plot.clip_planes[] = planes
            image = colorbuffer(f)
            if isempty(planes)
                @test image == unclipped
            else
                @test image != unclipped
            end
            uniforms = Bonito.evaljs_value(
                f.scene.current_screens[1].session, js"""
                (() => {
                    const uniforms = WGL.plot_cache[$(WGLMakie.js_uuid(plot))].material.uniforms;
                    return [uniforms.uniform_num_clip_planes.value,
                        uniforms.uniform_clip_planes.value.length];
                })()
                """
            )
            @test uniforms == [length(planes), 32]
        end
    finally
        display(edisplay, App(nothing))
    end
end

@testset "Compressed line attribute updates" begin
    points = Point2f[(0, 0), (0.5, 1), (1, 0)]
    widths = Float32[2, 4, 6]
    f, ax, plot = lines(points; linewidth = widths, color = :red, figure = (; size = (300, 250)))
    try
        display(edisplay, App(f))
        original = colorbuffer(f)
        plot.linewidth[] = fill(10.0f0, length(points))
        @test colorbuffer(f) != original
        plot.linewidth[] = widths
        @test colorbuffer(f) == original
    finally
        display(edisplay, App(nothing))
    end
end
