"""
    polar(r, θ; kwargs...)

Generates a polar plot from given r and θ.

## Attributes
$(ATTRIBUTES)
"""
@recipe(Polar, r, θ) do scene
    Attributes(
        rticks = 4,
        tticks = 8,
        tlabeloffset = 0.1,
        inspectable = true,
        visible = true,
        transparency = false,
    )
end

function plot!(plot::Polar)

    rdata = to_value(plot[1])
    θdata = to_value(plot[2])
    
    rmax = maximum(rdata)
    num_rticks = to_value(plot.rticks)
    rborder = rmax * 1.10

    num_θticks = to_value(plot.tticks)

    if num_θticks == 8
        θs = 0:π/4:2π
    elseif num_θticks == 1
        θs = [0]
    else
        θs = range(0, 2π, length = num_θticks)
    end

    # Draw concentric circles for r ticks and their labels
    if num_rticks == 1
        lines!(plot, Circle(Point2f(0), rmax), color = :lightgray)
        text!("$(round(rmax, digits=1))", position = (rmax, 0), align = (:left, :bottom))
    elseif num_rticks > 1
        rs = range(0, maximum(rdata), length = num_rticks)
        for r in rs
            lines!(plot, Circle(Point2f(0), r), color = :lightgray)
        end    
        
        for r in rs
            text!("$(round(r, digits=1))", position = (r, 0), align = (:left, :bottom))
        end
    end

    lines!(plot, Circle(Point2f(0), rborder), color = :lightgray)
    
    # Draw radial lines for θ ticks
    radiallines = zeros(Point2f, 2 * length(θs))

    for (i, θ) in enumerate(θs)
        radiallines[i*2] = Point2f(rborder * cos(θ), rborder * sin(θ))
    end

    linesegments!(plot, radiallines, color = :lightgray)

    for θ in θs[1 : end-1]
        offset = rborder * to_value(plot.tlabeloffset)
        xpos = (rborder + offset) * cos(θ)
        ypos = (rborder + offset) * sin(θ)
        if num_θticks == 8
            text!(plot, "$(Int64(θ * 180/π))°", position = (xpos, ypos), align = (:center, :center))
        else
            text!(plot, "$(round(θ * 180/π))°", position = (xpos, ypos), align = (:center, :center))
        end
    end

    lines!(plot, rdata .* cos.(θdata), rdata .* sin.(θdata))
    plot
end
