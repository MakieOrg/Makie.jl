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

@testset "Glyph Collections" begin
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

    @test p.glyphindices[] == FreeTypeAbstraction.glyph_index.(font, chars)
    @test p.font_per_char[] == [font for _ in 1:4]
    @test all(isapprox.(p.glyph_origins[], [Point3f(x, 0, 0) for x in origins], atol = 1.0e-10))
    @test all(s -> s == Vec2f(p.fontsize[]), p.text_scales[])
    @test all(r -> r == Quaternionf(0, 0, 0, 1), p.text_rotation[])
    @test all(c -> c == RGBAf(0, 0, 0, 1), p.text_color[])
    @test all(x -> x == RGBAf(0, 0, 0, 0), p.text_strokecolor[])
    @test all(x -> x == 0, p.text_strokewidth[])

    makie_hi_bb = Makie.height_insensitive_boundingbox.(p.glyph_extents[])
    makie_hi_bb_wa = Makie.height_insensitive_boundingbox_with_advance.(p.glyph_extents[])
    fta_hi_bb = FreeTypeAbstraction.height_insensitive_boundingbox.(unit_extents, Ref(font))
    fta_ha = FreeTypeAbstraction.hadvance.(unit_extents)
    @test makie_hi_bb == fta_hi_bb
    @test fta_ha == [bb.origin[1] + bb.widths[1] for bb in makie_hi_bb_wa]
    atlas = Makie.get_texture_atlas()
    # Test quad data
    positions = p.positions_transformed_f32c[]
    char_offsets = p.marker_offset[]
    quad_offsets = p.quad_offset[]
    uvs = p.sdf_uv[]
    scales = p.quad_scale[]

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
                p.glyphindices[]
            end
            true
        end

        p = text!(scene, 0, 0, text = [initial_text])
        @test begin
            for changed in ["test", rich("test"), L"test"]
                p.text = [changed]
                p.glyphindices[]
            end
            true
        end
    end
end
