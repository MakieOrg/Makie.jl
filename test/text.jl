@testset "Glyph Collections" begin
    using Makie.FreeTypeAbstraction

    # Test whether Makie's padded signed distance field text matches 
    # FreeTypeAbstraction characters in terms of boundingbox
    str = "^_lg"
    chars = collect(str)
    font = Makie.defaultfont()
    
    scene = Scene()
    campixel!(scene)
    p = text!(scene, Point2f(30, 37), text = str, align = (:left, :baseline))
    glyph_collection = p.plots[1][1][][]
    
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
    origins = cumsum(20f0 * Float32[
        0,
        unit_extents[1].advance[1],
        unit_extents[2].advance[1],
        unit_extents[3].advance[1]
    ])

    @test glyph_collection isa Makie.GlyphCollection
    @test glyph_collection.glyphs == FreeTypeAbstraction.glyph_index.(font, chars)
    @test glyph_collection.fonts == [font for _ in 1:4]
    @test all(isapprox.(glyph_collection.origins, [Point3f(x, 0, 0) for x in origins], atol = 1e-10))
    @test glyph_collection.scales.sv == [Vec2f(p.fontsize[]) for _ in 1:4]
    @test glyph_collection.rotations.sv == [Quaternionf(0,0,0,1) for _ in 1:4]
    @test glyph_collection.colors.sv == [RGBAf(0,0,0,1) for _ in 1:4]
    @test glyph_collection.strokecolors.sv == [RGBAf(0,0,0,0) for _ in 1:4]
    @test glyph_collection.strokewidths.sv == Float32[0, 0, 0, 0]

    makie_hi_bb = Makie.height_insensitive_boundingbox.(glyph_collection.extents)
    makie_hi_bb_wa = Makie.height_insensitive_boundingbox_with_advance.(glyph_collection.extents)
    fta_hi_bb = FreeTypeAbstraction.height_insensitive_boundingbox.(unit_extents, Ref(font))
    fta_ha = FreeTypeAbstraction.hadvance.(unit_extents)
    @test makie_hi_bb == fta_hi_bb
    @test fta_ha == [bb.origin[1] + bb.widths[1] for bb in makie_hi_bb_wa]

    # Test quad data
    positions, char_offsets, quad_offsets, uvs, scales = Makie.text_quads(
        to_ndim(Point3f, p.position[], 0), glyph_collection,
        Vec2f(0), Makie.transform_func_obs(scene)[]
    )

    # Also doesn't work 
    # fta_offsets = map(fta_glyphs) do (img, extent)
    #     (extent.horizontal_bearing .- Makie.GLYPH_PADDING[]) * p.fontsize[] / 
    #         Makie.PIXELSIZE_IN_ATLAS[]
    # end
    # fta_scales = map(fta_glyphs) do (img, extent)
    #     (extent.scale .+ 2 * Makie.GLYPH_PADDING[]) * p.fontsize[] / 
    #         Makie.PIXELSIZE_IN_ATLAS[]
    # end
    
    fta_quad_offsets = map(chars) do c
        mini = FreeTypeAbstraction.metrics_bb(c, font, 20.0)[1] |> minimum
        Vec2f(mini .- Makie.GLYPH_PADDING[] * 20.0 / Makie.PIXELSIZE_IN_ATLAS[])
    end

    fta_scales = map(chars) do c
        mini = FreeTypeAbstraction.metrics_bb(c, font, 20.0)[1] |> widths
        Vec2f(mini .+ 2 * Makie.GLYPH_PADDING[] * 20.0 / Makie.PIXELSIZE_IN_ATLAS[])
    end

    @test all(isequal(to_ndim(Point3f, p.position[], 0f0)), positions)
    @test char_offsets == glyph_collection.origins
    @test quad_offsets == fta_quad_offsets
    @test scales  == fta_scales
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

    err = ArgumentError("The attribute `textsize` has been renamed to `fontsize` in Makie v0.19. Please change all occurrences of `textsize` to `fontsize` or revert back to an earlier version.")
    @test_throws err Label(Figure()[1, 1], "hi", textsize = 30)
    @test_throws err text(1, 2, text = "hi", textsize = 30)
end