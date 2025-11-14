using Makie
using Makie.FreeTypeAbstraction


@testset "Texture atlas" begin
    atlas = Makie.get_texture_atlas()

    rendered = []
    Makie.font_render_callback!(atlas) do sd, uv
        push!(rendered, (sd, uv))
    end

    font = Makie.to_font("default")
    glyph = 'π'
    glyphindex = FreeTypeAbstraction.glyph_index(font, glyph)
    h = Makie.fast_stable_hash((glyphindex, FreeTypeAbstraction.fontname(font)))
    x = Makie.insert_glyph!(atlas, h, (glyphindex, font))

    uvoff = atlas.uv_rectangles[atlas.mapping[h]]
    ranges = Makie.sdf_uv_to_pixel(atlas, uvoff)
    rect = rendered[1][2]
    data = rendered[1][1]
    @test Makie.get_glyph_sdf(atlas, h) ≈ data
    @test Base.to_indices(atlas.data, (rect,)) == ranges

    bb, ext = FreeTypeAbstraction.metrics_bb(
        FreeTypeAbstraction.glyph_index(font, glyph),
        font, atlas.pix_per_glyph * atlas.downsample
    )
    downsampled_size = ceil.(Int, ext.scale ./ atlas.downsample .+ 2 * atlas.glyph_padding)
    @test downsampled_size == widths(rect)
end
