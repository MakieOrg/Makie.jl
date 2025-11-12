using FreeTypeAbstraction: hadvance, leftinkbound, inkwidth, get_extent, ascender, descender

function justification2float(justification, halign)
    if justification === automatic
        if halign === :left || halign == 0
            return 0.0f0
        elseif halign === :right || halign == 1
            return 1.0f0
        elseif halign === :center || halign == 0.5
            return 0.5f0
        else
            return 0.5f0
        end
    else
        msg = "Invalid justification $justification. Valid values are <:Real, :left, :center and :right."
        return halign2num(justification, msg)
    end
end

# Backend data
Base.getindex(x::ScalarOrVector, i) = x.sv isa Vector ? x.sv[i] : x.sv
Base.lastindex(x::ScalarOrVector) = x.sv isa Vector ? length(x.sv) : 1
