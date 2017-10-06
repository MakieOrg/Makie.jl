function text_model(font, pivot)
    pv = GeometryTypes.Vec3f0(pivot[1], pivot[2], 0)
    if font.rotation != 0.0
        rot = Float32(deg2rad(font.rotation))
        rotm = GLAbstraction.rotationmatrix_z(rot)
        return GLAbstraction.translationmatrix(pv)*rotm*GLAbstraction.translationmatrix(-pv)
    else
        eye(GeometryTypes.Mat4f0)
    end
end

function align_offset(startpos, lastpos, atlas, rscale, font, align)
    xscale, yscale = GLVisualize.glyph_scale!('X', rscale)
    xmove = (lastpos-startpos)[1] + xscale
    if isa(align, GeometryTypes.Vec)
        return -Vec2f0(xmove, yscale) .* align
    elseif align == :top
        return -Vec2f0(xmove/2f0, yscale)
    elseif align == :right
        return -Vec2f0(xmove, yscale/2f0)
    else
        error("Align $align not known")
    end
end


function alignment2num(x::Symbol)
    (x in (:hcenter, :vcenter)) && return 0.5f0
    (x in (:left, :bottom)) && return 0.0f0
    (x in (:right, :top)) && return 1.0f0
    0.0f0 # 0 default, or better to error?
end

function alignment2num(font::Plots.Font)
    Vec2f0(map(alignment2num, (font.halign, font.valign)))
end

pointsize(font) = font.pointsize * 2



function glvisualize_text(position, text, kw_args)
    text_align = alignment2num(text.font)
    startpos = Vec2f0(position)
    atlas = GLVisualize.get_texture_atlas()
    font = GLVisualize.defaultfont()
    rscale = kw_args[:relative_scale]

    position = GLVisualize.calc_position(text.str, startpos, rscale, font, atlas)
    offset = GLVisualize.calc_offset(text.str, rscale, font, atlas)
    alignoff = align_offset(startpos, last(position), atlas, rscale, font, text_align)

    map!(position, position) do pos
        pos .+ alignoff
    end
    kw_args[:position] = position
    kw_args[:offset] = offset
    kw_args[:scale_primitive] = true
    visualize(text.str, Style(:default), kw_args)
end



isnewline(x) = x == '\n'

type Text
    data
    text
    atlas
    cursors
    # default values
    font
    scale
    offset
    color
    startposition
    lineheight
end

immutable Sprite{N, T} <: Particle
    position::Point{N, T}
    offset::Vec{2, T}
    scale::Vec{2, T}
    uv::Vec{4, T}
    color::Vec{4, T}
end

function Sprite{N, T}(char, position::Point{N, T}, text)
    Sprite(
        char, position, text.scale, text.offset,
        text.color, text.font, text.atlas
    )
end
function Sprite{N, T}(
        char, position::Point{N, T}, scale, offset, color,
        font = defaultfont(),  atlas = get_texture_atlas()
    )
    Sprite{N, T}(
        position,
        glyph_bearing!(atlas, char, font, scale) + offset,
        glyph_scale!(atlas, char, font, scale),
        glyph_uv_width!(atlas, char, font),
        color
    )
end

function nextposition(sprite::Sprite, char, text)
    advance_x, advance_y = glyph_advance!(text.atlas, char, text.font, text.scale)
    position = sprite.position
    if isnewline(char)
        return Point2f0(text.startposition[1], position[2] - advance_y * text.lineheight) #reset to startx
    else
        return position + Point2f0(advance_x, 0)
    end
end

function printat(text::Text, idx::Integer, char::Char)
    position = if checkbounds(Bool, text.data, idx)
        sprite = text.data[idx]
        nextposition(sprite, text.text[idx], text)
    else
        text.startposition
    end
    nextsprite = Sprite(char, position, text)
    idx += 1
    insert!(text.data, idx, nextsprite)
    insert!(text.text, idx, char)
    idx
end

function printat(text::Text, idx::Int, str::String)
    sprite = text.data[idx]
    position = sprite.position
    for char in str
        char == '\r' && continue # stupid windows!
        idx = printat(text, idx, char)
    end
    idx
end

function Base.print(text::Text, char::Union{Char, String})
    map!(text.cursors, text.cursors) do idx
        idx = printat(text, idx, char)
        return idx
    end
    nothing
end
Base.String(text::Text) = join(text.text)
