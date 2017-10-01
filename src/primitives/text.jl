

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
    (x in (:hcenter, :vcenter)) && return 0.5
    (x in (:left, :bottom)) && return 0.0
    (x in (:right, :top)) && return 1.0
    0.0 # 0 default, or better to error?
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
