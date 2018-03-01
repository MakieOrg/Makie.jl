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
