using Makie
using Makie.FreeTypeAbstraction


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
rendered

uvoff = atlas.uv_rectangles[atlas.mapping[h]]
ranges = Makie.sdf_uv_to_pixel(atlas, uvoff)
rect = rendered[1][2]
data = rendered[1][1]
Makie.get_glyph_data(atlas, h) ≈ data
Base.to_indices(atlas.data, (rect,)) == ranges
