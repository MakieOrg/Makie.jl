@recipe(Title, titletext, plot) do scene
    Theme(
        textsize=40,
        raw=true,
        font=theme(scene, :font),
        align = (:center, :bottom), 
    )
end

function convert_arguments(::Type{<:Title}, titletext::AbstractString, plot::Scene)
    @info "convert_argument called"
    (titletext, plot)
end
function AbstractPlotting.plot!(t::Title)
    @extract t (titletext, plot)
    
    plot = to_value(plot)
    pos = lift(pixelarea(plot)) do area
        x = widths(area)[1] ./ 2
        Vec2f0(x, 10) # offset 10px, to give it some space
    end
    
    @show typeof(t.parent)
    text!(t.parent,
        titletext,
        position = pos, 
        camera=campixel!,
        raw=true,
        )
end
