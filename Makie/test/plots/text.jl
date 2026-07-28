@testset "texture atlas" begin
    @testset "defaults" for arg in [(1024, 32), (2048, 64)]
        # Makes sure hashing and downloading default texture atlas works:
        atlas = Makie.get_texture_atlas(arg...)
        data = copy(atlas.data)
        len = length(atlas.mapping)
        # Make sure that all default glyphs are already in there
        Makie.render_default_glyphs!(atlas)
        # So no rendering & no change of data should happen in default glyphs are present!
        @test data == atlas.data
        @test length(atlas.mapping) == len

        @test haskey(Makie.TEXTURE_ATLASES, arg) # gets into global texture atlas cache
        @test Makie.TEXTURE_ATLASES[arg] === atlas
    end
end

@testset "glyph layout" begin
    using Makie.FreeTypeAbstraction

    # Test whether Makie's padded signed distance field text matches
    # FreeTypeAbstraction characters in terms of boundingbox
    str = "^_lg"
    chars = collect(str)
    font = Makie.defaultfont()

    scene = Scene()
    campixel!(scene)
    p = text!(scene, Point2f(30, 37), text = str, align = (:left, :baseline), fontsize = 20)

    # This doesn't work well because FreeTypeAbstraction doesn't quite scale
    # linearly
    # fta_glyphs = map(char -> renderface(font, char, 64), chars)
    # unit_extents = map(fta_glyphs) do (img, extent)
    #     FontExtent(
    #         extent.vertical_bearing * 20f0 / 64f0,
    #         extent.horizontal_bearing * 20f0 / 64f0,
    #         extent.advance * 20f0 / 64f0,
    #         extent.scale * 20f0 / 64f0
    #     )
    # end
    # origins = let
    #     glyph_scale = p.fontsize[] / 64
    #     cumsum(vcat(
    #         - glyph_scale * fta_glyphs[1][2].horizontal_bearing[1],
    #         [glyph_scale * fta_glyphs[i][2].advance[1] for i in 1:3]
    #     ))
    # end

    # This is just repeating code from Makie
    unit_extents = [FreeTypeAbstraction.get_extent(font, char) for char in chars]
    origins = cumsum(
        20.0f0 * Float32[
            0,
            unit_extents[1].advance[1],
            unit_extents[2].advance[1],
            unit_extents[3].advance[1],
        ]
    )

    @test p.glyph_indices[] == FreeTypeAbstraction.glyph_index.(font, chars)
    @test p.glyph_fonts[] == [font for _ in 1:4]
    @test all(isapprox.(p.glyph_origins[], [Point3f(x, 0, 0) for x in origins], atol = 1.0e-10))
    @test all(s -> s == Vec2f(p.fontsize[]), p.glyph_scales[])
    @test all(r -> r == Quaternionf(0, 0, 0, 1), p.glyph_rotations[])
    @test all(c -> c == RGBAf(0, 0, 0, 1), p.glyph_colors[])
    @test all(x -> x == RGBAf(0, 0, 0, 0), p.glyph_strokecolors[])
    @test all(x -> x == 0, p.glyph_strokewidths[])

    makie_hi_bb = Makie.height_insensitive_boundingbox.(p.glyph_extents[])
    makie_hi_bb_wa = Makie.height_insensitive_boundingbox_with_advance.(p.glyph_extents[])
    fta_hi_bb = FreeTypeAbstraction.height_insensitive_boundingbox.(unit_extents, Ref(font))
    fta_ha = FreeTypeAbstraction.hadvance.(unit_extents)
    @test makie_hi_bb == fta_hi_bb
    @test fta_ha == [bb.origin[1] + bb.widths[1] for bb in makie_hi_bb_wa]
    atlas = Makie.get_texture_atlas()
    # Test quad data
    positions = p.positions_transformed_f32c[]
    glyphs = p.plots[1]
    char_offsets = p.marker_offset[]
    quad_offsets = glyphs.quad_offset[]
    uvs = glyphs.sdf_uv[]
    scales = glyphs.quad_scale[]

    # Also doesn't work
    # fta_offsets = map(fta_glyphs) do (img, extent)
    #     (extent.horizontal_bearing .- atlas.glyph_padding) * p.fontsize[] /
    #         atlas.pix_per_glyph
    # end
    # fta_scales = map(fta_glyphs) do (img, extent)
    #     (extent.scale .+ 2 * atlas.glyph_padding) * p.fontsize[] /
    #         atlas.pix_per_glyph
    # end

    fta_quad_offsets = map(chars) do c
        mini = FreeTypeAbstraction.metrics_bb(c, font, 20.0)[1] |> minimum
        Vec2f(mini .- atlas.glyph_padding * 20.0 / atlas.pix_per_glyph)
    end

    fta_scales = map(chars) do c
        mini = FreeTypeAbstraction.metrics_bb(c, font, 20.0)[1] |> widths
        Vec2f(mini .+ 2 * atlas.glyph_padding * 20.0 / atlas.pix_per_glyph)
    end

    @test all(pos -> pos == p.arg1[], positions)
    @test char_offsets == p.glyph_origins[]
    @test quad_offsets == fta_quad_offsets
    @test scales == fta_scales
end

@testset "old text syntax" begin
    text("text", position = Point2f(0, 0))
    text(["text"], position = [Point2f(0, 0)])
    text(["text", "text"], position = [Point2f(0, 0), Point2f(1, 1)])
    text(collect(zip(["text", "text"], [Point2f(0, 0), Point2f(1, 1)])))
    text(L"text", position = Point2f(0, 0))
    text([L"text"], position = [Point2f(0, 0)])
    text([L"text", L"text"], position = [Point2f(0, 0), Point2f(1, 1)])
    text(collect(zip([L"text", L"text"], [Point2f(0, 0), Point2f(1, 1)])))

    err = ArgumentError("`textsize` has been renamed to `fontsize` in Makie v0.19. Please change all occurrences of `textsize` to `fontsize` or revert back to an earlier version.")
    @test_throws err Label(Figure()[1, 1], "hi", textsize = 30)
    # @test_throws err text(1, 2, text = "hi", textsize = 30)
end

@testset "Text type changes" begin
    scene = Scene()
    for initial_text in ["test", rich("test"), L"test"]
        p = text!(scene, 0, 0, text = initial_text)
        @test begin
            for changed in ["test", rich("test"), L"test"]
                p.text = changed
                p.glyph_indices[]
            end
            true
        end

        p = text!(scene, 0, 0, text = [initial_text])
        @test begin
            for changed in ["test", rich("test"), L"test"]
                p.text = [changed]
                p.glyph_indices[]
            end
            true
        end
    end
end

@testset "glyph buffer reuse" begin
    scene = Scene()
    p = text!(scene, Point2f(0), text = "ab")
    glyphs = p.plots[1]
    indices, origins, colors = p.glyph_indices[], p.glyph_origins[], p.glyph_colors[]
    @test length(glyphs.sdf_uv[]) == 2

    p.text = "abcd"
    @test p.glyph_indices[] === indices
    @test p.glyph_origins[] === origins
    @test length(indices) == 4
    @test length(glyphs.sdf_uv[]) == 4

    p.color = :red
    @test p.glyph_colors[] === colors
    @test colors == fill(RGBAf(1, 0, 0, 1), 4)

    p2 = text!(scene, Point2f(0), text = L"\frac{1}{2}")
    @test length(p2.text_specs[]) == 1
    p2.fontsize = 30
    @test length(p2.text_specs[]) == 1
    @test length(p2.text_spec_block_indices[]) == 1
    @test length(p2.text_spec_bboxes[]) == 1
end

struct CountingHandler
    calls::Base.RefValue{Int}
end

function Makie.emit_text!(buffer, h::CountingHandler, str, attributes)
    h.calls[] += 1
    return false
end

@testset "placement does not relayout" begin
    handler = CountingHandler(Ref(0))
    scene = Scene(camera = campixel!)
    p = text!(scene, Point2f(100, 100), text = "ab\ncd", fontsize = 20, align = (:left, :bottom), text_handler = handler)
    p.glyph_origins[]
    layouts = handler.calls[]
    @test layouts == 1

    for (attribute, value) in [
            (:align, (:left, :top)),        # same justification, so no relayout
            (:rotation, Float32(pi / 4)),
            (:offset, Vec2f(5, 5)),
        ]
        setproperty!(p, attribute, value)
        p.glyph_origins[]
        @test handler.calls[] == layouts
    end

    p.align = (:right, :top) # justification follows halign, so this does relayout
    p.glyph_origins[]
    @test handler.calls[] == layouts + 1

    p.fontsize = 30
    p.glyph_origins[]
    @test handler.calls[] == layouts + 2
end

@testset "per block placement attributes" begin
    scene = Scene(camera = campixel!)

    # PolarAxis starts its tick labels out like this
    p = text!(scene, Point2f[], text = String[], align = Point2f[], offset = Point2f[])
    @test p.glyph_origins[] == Point3f[]
    @test p.resolved_justification[] == Float32[]

    p2 = text!(
        scene, [Point2f(0, 0), Point2f(100, 0)], text = ["ab", "cd"],
        align = [(:left, :bottom), (:right, :top)], rotation = [0.0, pi / 2], offset = [Vec2f(0), Vec2f(5, 5)]
    )
    origins, rotations = p2.glyph_origins[], p2.glyph_rotations[]
    @test length(origins) == 4
    @test rotations[1:2] == fill(Quaternionf(0, 0, 0, 1), 2)
    @test rotations[3:4] == fill(convert(Quaternionf, to_rotation(pi / 2)), 2)

    # the first glyph lays out at the layout frame's origin, and (:left, :bottom)
    # shifts the block so the frame's lower left corner lands on the anchor
    box = p2.block_bboxes[][1]
    @test origins[1] == Point3f(-minimum(box)[1], -minimum(box)[2], 0)
    @test p2.marker_offset[][3:4] == origins[3:4] .+ Point3f(5, 5, 0)
end

@testset "attribute vectors are per string" begin
    scene = Scene(camera = campixel!)

    p = text!(scene, [Point2f(0, 0), Point2f(100, 0)], text = ["ab", "cde"], color = [:red, :blue])
    @test p.glyph_colors[] == [fill(RGBAf(1, 0, 0, 1), 2); fill(RGBAf(0, 0, 1, 1), 3)]

    err = "Expected a scalar or one value per string (1), got 4."
    @test_throws err text!(scene, Point2f(0, 0), text = "abcd", color = [:red, :green, :blue, :black])
    @test_throws err text!(scene, Point2f(0, 0), text = "abcd", strokewidth = [1, 2, 3, 4])
    @test_throws err text!(scene, Point2f(0, 0), text = "abcd", fontsize = [10, 20, 30, 40])

    # `color` feeds text layout so it errors while plotting, the other two only
    # once the value is pulled
    path = [Point2f(0, 0), Point2f(100, 0)]
    for (attribute, value) in [(:color, [:red, :green]), (:strokecolor, [:red, :green]), (:strokewidth, [1, 2])]
        @test_throws "`pathtext` takes a single $attribute, got 2 values." begin
            p = pathtext!(scene, path; text = "ab", space = :pixel, attribute => value)
            getproperty(only(p.plots), attribute)[]
        end
    end

    # rich text is the supported way to style parts of one string
    p = pathtext!(scene, path; text = rich("a", rich("b", color = :red)), space = :pixel)
    @test only(p.plots).color[] == [RGBAf(0, 0, 0, 1), RGBAf(1, 0, 0, 1)]
end

@testset "pathtext color" begin
    scene = Scene(camera = campixel!)
    path = [Point2f(0, 0), Point2f(100, 0)]

    plain = pathtext!(scene, path; text = "abc", color = :red, space = :pixel)
    @test only(plain.plots).color[] == RGBAf(1, 0, 0, 1)

    # rich text takes the plot's color for the parts it doesn't style itself
    styled = pathtext!(scene, path; text = rich("ab", rich("c", color = :blue)), color = :red, space = :pixel)
    @test only(styled.plots).color[] == [RGBAf(1, 0, 0, 1), RGBAf(1, 0, 0, 1), RGBAf(0, 0, 1, 1)]

    # a number is colormapped rather than rejected
    mapped = pathtext!(
        scene, path; text = "abc", space = :pixel,
        color = 0.5, colormap = [:red, :red], colorrange = (0, 1)
    )
    @test only(mapped.plots).color[] == RGBAf(1, 0, 0, 1)

    # alpha is folded in once, like `text` does it
    faded = pathtext!(scene, path; text = "abc", color = :red, alpha = 0.5, space = :pixel)
    @test only(faded.plots).computed_color[] == RGBAf(1, 0, 0, 0.5)
end

@testset "pathtext draws glyphs directly" begin
    scene = Scene(camera = campixel!)
    font = Makie.defaultfont()
    p = pathtext!(scene, [Point2f(0, 100), Point2f(300, 100)], text = "ab", fontsize = 20, space = :pixel)

    glyphs = only(p.plots)
    @test glyphs isa Makie.Glyphs
    @test glyphs.glyphindices[] == FreeTypeAbstraction.glyph_index.(font, ['a', 'b'])
    @test glyphs.scale[] == fill(Vec2f(20), 2)
    # the positions are the glyph origins, so nothing is left for marker_offset
    @test glyphs.marker_offset[] == fill(Point3f(0), 2)

    positions = glyphs.positions[]
    @test positions[1] ≈ Point2f(0, 100)
    @test positions[2][1] ≈ 20 * Makie.GlyphExtent(font, 'a').hadvance
end

@testset "text boundingboxes" begin
    @testset "empty string" begin
        scene = Scene(camera = campixel!)
        p = text!(scene, 30, 50, text = "")
        @test Makie.raw_glyph_boundingboxes(p) == Rect2d[]
        @test Makie.fast_glyph_boundingboxes(p) == Rect3d[]
        @test Makie.glyph_boundingboxes(p) == Rect2d[]
        @test length(Makie.fast_string_boundingboxes(p)) == 1
        @test Makie.fast_string_boundingboxes(p)[1] ≈ Rect3d(Point3d(NaN), Vec3d(0))
        @test Makie.string_boundingboxes(p) == [Rect3d(Point3d(30, 50, 0), Vec3d(0))]
        @test Makie.full_boundingbox(p) == Rect3d(Point3d(30, 50, 0), Vec3d(0))
    end

    @testset "single string" begin
        scene = Scene(camera = campixel!)
        p = text!(scene, 30, 50, text = "val")

        charbbs = [Rect2d(0, -3.0519999265670776, 7.0, 16.309999465942383), Rect2d(0, -3.0519999265670776, 7.783999919891357, 16.309999465942383), Rect2d(0, -3.0519999265670776, 3.1080000400543213, 16.309999465942383)]
        @test all(Makie.raw_glyph_boundingboxes(p) .≈ charbbs)
        charbbs = [Rect3d(0.0, 1.1920928955078125e-7, 0, 7.0, 16.309999465942383, 0), Rect3d(7.0, 1.1920928955078125e-7, 0.0, 7.783999919891357, 16.309999465942383, 0.0), Rect3d(14.784000396728516, 1.1920928955078125e-7, 0.0, 3.1080000400543213, 16.309999465942383, 0.0)]
        @test all(Makie.fast_glyph_boundingboxes(p) .≈ charbbs)
        @test all(Makie.glyph_boundingboxes(p) .≈ [bb + Point3d(30, 50, 0) for bb in charbbs])

        @test all(Makie.fast_string_boundingboxes(p) .≈ [Rect3d(0.0, 1.1920928955078125e-7, 0.0, 17.892000436782837, 16.309999465942383, 0.0)])
        @test all(Makie.string_boundingboxes(p) .≈ [Rect3d(30.0, 50.00000011920929, 0.0, 17.892000436782837, 16.309999465942383, 0.0)])

        @test Makie.full_boundingbox(p) ≈ Rect3d(30.0, 50.00000011920929, 0.0, 17.892000436782837, 16.309999465942383, 0.0)
    end

    @testset "multi string" begin
        scene = Scene(camera = campixel!)
        p = text!(scene, [30, 100, 50], [50, 20, 100], text = ["val", "b", ""])

        charbbs = [Rect2d(0.0, -3.0519999265670776, 7.0, 16.309999465942383), Rect2d(0.0, -3.0519999265670776, 7.783999919891357, 16.309999465942383), Rect2d(0.0, -3.0519999265670776, 3.1080000400543213, 16.309999465942383), Rect2d(0.0, -3.0519999265670776, 7.783999919891357, 16.309999465942383)]
        @test all(Makie.raw_glyph_boundingboxes(p) .≈ charbbs)
        charbbs = [Rect3d(0.0, 1.1920928955078125e-7, 0.0, 7.0, 16.309999465942383, 0.0), Rect3d(7.0, 1.1920928955078125e-7, 0.0, 7.783999919891357, 16.309999465942383, 0.0), Rect3d(14.784000396728516, 1.1920928955078125e-7, 0.0, 3.1080000400543213, 16.309999465942383, 0.0), Rect3d(0.0, 1.1920928955078125e-7, 0.0, 7.783999919891357, 16.309999465942383, 0.0)]
        @test all(Makie.fast_glyph_boundingboxes(p) .≈ charbbs)
        charbbs = [charbbs[1] + Point3d(30, 50, 0), charbbs[2] + Point3d(30, 50, 0), charbbs[3] + Point3d(30, 50, 0), charbbs[4] + Point3d(100, 20, 0)]
        @test all(Makie.glyph_boundingboxes(p) .≈ charbbs)

        stringbbs = [Rect3d(0.0, 1.1920928955078125e-7, 0.0, 17.892000436782837, 16.309999465942383, 0.0), Rect3d(0.0, 1.1920928955078125e-7, 0.0, 7.783999919891357, 16.309999465942383, 0.0), Rect3d(NaN, NaN, NaN, 0.0, 0.0, 0.0)]
        @test all(Makie.fast_string_boundingboxes(p) .≈ stringbbs)
        stringbbs = [Rect3d(30.0, 50.00000011920929, 0.0, 17.892000436782837, 16.309999465942383, 0.0), Rect3d(100.0, 20.00000011920929, 0.0, 7.783999919891357, 16.309999465942383, 0.0), Rect3d(50.0, 100.0, 0.0, 0.0, 0.0, 0.0)]
        @test all(Makie.string_boundingboxes(p) .≈ stringbbs)

        @test Makie.full_boundingbox(p) ≈ Rect3d(30.0, 20.00000011920929, 0.0, 77.78399991989136, 79.99999988079071, 0.0)
    end
end

@testset "Rich Text equality" begin
    for (a, b, c) in [
            (rich("A", rich("B", color = :gray)), rich("A", rich("B", color = :gray)), rich("A", rich("B", color = :green))),
            (
                rich("Chemists use notations like ", left_subsup("92", "238"), "U or PO", subsup("4", "3−")),
                rich("Chemists use notations like ", left_subsup("92", "238"), "U or PO", subsup("4", "3−")),
                rich("Chemists use notations like ", "U or PO", subsup("4", "3−")),
            ),
            (
                rich(
                    "H", subscript("2"), "O is the formula for ",
                    rich("water", color = :cornflowerblue, font = :italic)
                ),
                rich(
                    "H", subscript("2"), "O is the formula for ",
                    rich("water", color = :cornflowerblue, font = :italic)
                ),
                rich(
                    "H", subscript("2"), "O is the formula for ",
                    rich("water", color = :cornflowerblue, font = :bold)
                ),

            ),
        ]
        @test a == b
        @test a != c
        @test hash(a) == hash(b)
        @test hash(b) != hash(c)
        @test length(unique([a, b, c])) == 2
    end
end

@testset "align validation" begin
    @test_throws "Text align must be a two-element tuple, got :center" text(1, 2, align = :center)
    @test_throws "Vertical text align must be a Real or :top, :bottom, :center, :baseline. Got :centr" text(1, 2, align = (1, :centr))
    @test_throws "Horizontal text align must be a Real or :left, :right, :center. Got :centr" text(1, 2, align = (:centr, 1))
    @test_throws "Text align must be a two-element tuple, got :center" text(1:2, 3:4, text = ["A", "B"], align = [:center, :center])
    @test_throws "Vertical text align must be a Real or :top, :bottom, :center, :baseline. Got :centr" text(1:2, 3:4, text = ["A", "B"], align = [(:center, :centr), (:center, :center)])

    @test text(1, 2, align = (:center, :baseline)) isa Makie.FigureAxisPlot
    @test text(1, 2, align = Vec2f(0, 0)) isa Makie.FigureAxisPlot
    @test text(1:2, 3:4, text = ["A", "B"], align = [Vec2f(0, 0), Vec2f(1, 1)]) isa Makie.FigureAxisPlot
end
