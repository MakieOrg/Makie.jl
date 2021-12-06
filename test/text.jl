@testset "Glyph Collections" begin
    using Makie.FreeTypeAbstraction

    # Test whether Makie's padded signed distance field text matches 
    # FreeTypeAbstraction characters in terms of boundingbox
    str = "^_lg"
    chars = collect(str)
    font = Makie.defaultfont()
    
    scene = Scene()
    campixel!(scene)
    p = text!(scene, str, position = Point2f(30, 37), align = (:left, :baseline))
    glyph_collection = p.plots[1][1][]
    
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
    #     glyph_scale = p.textsize[] / 64
    #     cumsum(vcat(
    #         - glyph_scale * fta_glyphs[1][2].horizontal_bearing[1],
    #         [glyph_scale * fta_glyphs[i][2].advance[1] for i in 1:3]
    #     ))
    # end

    # This is just repeating code from Makie
    unit_extents = [FreeTypeAbstraction.get_extent(font, char) for char in chars]
    origins = cumsum(20f0 * Float32[
        -unit_extents[1].horizontal_bearing[1],
        unit_extents[1].advance[1],
        unit_extents[2].advance[1],
        unit_extents[3].advance[1]
    ])

    @test glyph_collection isa Makie.GlyphCollection
    @test glyph_collection.glyphs == chars
    @test glyph_collection.fonts == [font for _ in 1:4]
    @test glyph_collection.origins == [Point3f(x, 0, 0) for x in origins]
    @test glyph_collection.extents == unit_extents
    @test glyph_collection.scales.sv == [Vec2f(p.textsize[]) for _ in 1:4]
    @test glyph_collection.rotations.sv == [Quaternionf(0,0,0,1) for _ in 1:4]
    @test glyph_collection.colors.sv == [RGBAf(0,0,0,1) for _ in 1:4]
    @test glyph_collection.strokecolors.sv == [RGBAf(0,0,0,0) for _ in 1:4]
    @test glyph_collection.strokewidths.sv == Float32[0, 0, 0, 0]

    # Test quad data

    input_positions = [to_ndim(Point3f, p.position[], 0) + o for o in glyph_collection.origins]
    positions, offsets, uvs, scales = Makie.text_quads(
        input_positions, 
        glyph_collection.glyphs,
        glyph_collection.fonts,
        glyph_collection.scales
    )

    # Also doesn't work 
    # fta_offsets = map(fta_glyphs) do (img, extent)
    #     (extent.horizontal_bearing .- Makie.GLYPH_PADDING[]) * p.textsize[] / 
    #         Makie.PIXELSIZE_IN_ATLAS[]
    # end
    # fta_scales = map(fta_glyphs) do (img, extent)
    #     (extent.scale .+ 2 * Makie.GLYPH_PADDING[]) * p.textsize[] / 
    #         Makie.PIXELSIZE_IN_ATLAS[]
    # end
    
    fta_offsets = map(chars) do c
        mini = FreeTypeAbstraction.metrics_bb(c, font, 20.0)[1] |> minimum
        Vec2f(mini .- Makie.GLYPH_PADDING[] * 20.0 / Makie.PIXELSIZE_IN_ATLAS[])
    end

    fta_scales = map(chars) do c
        mini = FreeTypeAbstraction.metrics_bb(c, font, 20.0)[1] |> widths
        Vec2f(mini .+ 2 * Makie.GLYPH_PADDING[] * 20.0 / Makie.PIXELSIZE_IN_ATLAS[])
    end

    @test positions == input_positions
    @test offsets == fta_offsets
    @test scales  == fta_scales
end