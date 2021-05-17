"""
    barplot(x, y; kwargs...)

Plots a barplot; `y` defines the height.  `x` and `y` should be 1 dimensional.

## Attributes
$(ATTRIBUTES)
"""
@recipe(BarPlot, x, y) do scene
    Attributes(;
        fillto = automatic,
        color = theme(scene, :patchcolor),
        colormap = theme(scene, :colormap),
        colorrange = automatic,
        dodge = automatic,
        n_dodge = automatic,
        x_gap = 0.2,
        dodge_gap = 0.03,
        marker = Rect,
        stack = automatic,
        strokewidth = theme(scene, :patchstrokewidth),
        strokecolor = theme(scene, :patchstrokecolor),
        width = automatic,
        direction = :y,
        visible = theme(scene, :visible),
        inspectable = theme(scene, :inspectable),
        cycle = [:color => :patchcolor],
    )
end

conversion_trait(::Type{<: BarPlot}) = PointBased()

function bar_rectangle(x, y, width, fillto)
    # y could be smaller than fillto...
    ymin = min(fillto, y)
    ymax = max(fillto, y)
    w = abs(width)
    return FRect(x - (w / 2f0), ymin, w, ymax - ymin)
end

flip(r::Rect2D) = Rect2D(reverse(origin(r)), reverse(widths(r)))

function xw_from_dodge(x, width, minimum_distance, x_gap, dodge, n_dodge, dodge_gap)
    width === automatic && (width = (1 - x_gap) * minimum_distance)
    if dodge === automatic
        i_dodge = 1
    elseif eltype(dodge) <: Integer
        i_dodge = dodge
    else
        ArgumentError("The keyword argument `dodge` currently supports only `AbstractVector{<: Integer}`") |> throw
    end
    n_dodge === automatic && (n_dodge = maximum(i_dodge))
    dodge_width = scale_width(dodge_gap, n_dodge)
    shifts = shift_dodge.(i_dodge, dodge_width, dodge_gap)
    return x .+ width .* shifts, width * dodge_width
end

function AbstractPlotting.plot!(p::BarPlot)

    in_y_direction = lift(p.direction) do dir
        if dir == :y
            true
        elseif dir == :x
            false
        else
            error("Invalid direction $dir. Options are :x and :y.")
        end
    end

    bars = lift(p[1], p.fillto, p.width, p.dodge, p.n_dodge, p.x_gap, p.dodge_gap, p.stack, in_y_direction) do xy, fillto, width, dodge, n_dodge, x_gap, dodge_gap, stack, in_y_direction
        
        x = first.(xy)
        y = last.(xy)

        minimum_distance = nothing
        # only really compute `minimum_distance` if `width` is `automatic`
        if width === automatic
            x_unique = unique(filter(isfinite, x))
            x_diffs = diff(sort(x_unique))
            minimum_distance = isempty(x_diffs) ? 1.0 : minimum(x_diffs)
        end

        # compute width of bars and x̂ (horizontal position after dodging)
        x̂, barwidth = xw_from_dodge(x, width, minimum_distance, x_gap, dodge, n_dodge, dodge_gap)

        # --------------------------------
        # ----------- Stacking -----------
        # --------------------------------

        if stack === automatic
            if fillto === automatic
                fillto = 0.0
            end
        elseif eltype(stack) <: Integer
            fillto === automatic || @warn "Ignore keyword fillto when keyword stack is provided"
            i_stack = stack
            
            from, to = stack_grouped_from_to(i_stack, y, (x = x̂,))
            y, fillto = to, from
        else
            ArgumentError("The keyword argument `stack` currently supports only `AbstractVector{<: Integer}`") |> throw
        end
        
        rects = @. bar_rectangle(x̂, y, barwidth, fillto)
        return in_y_direction ? rects : flip.(rects)
    end

    poly!(
        p, bars, color = p.color, colormap = p.colormap, colorrange = p.colorrange,
        strokewidth = p.strokewidth, strokecolor = p.strokecolor, visible = p.visible,
        inspectable = p.inspectable
    )
end

scale_width(dodge_gap, n_dodge) = (1 - (n_dodge - 1) * dodge_gap) / n_dodge

function shift_dodge(i, dodge_width, dodge_gap)
    (dodge_width - 1) / 2 + (i - 1) * (dodge_width + dodge_gap)
end

function stack_grouped_from_to(i_stack, y, grp)
	
	from = Array{Float64}(undef, length(y))
	to   = Array{Float64}(undef, length(y))
	
	groupby = StructArray((; grp..., is_pos = y .> 0))

	grps = StructArrays.finduniquesorted(groupby)
	
	for (grp, inds) in grps
		
		fromto = stack_from_to(i_stack[inds], y[inds])
		
		from[inds] .= fromto.from
		to[inds] .= fromto.to
	
	end
	
	(from = from, to = to)
end

function stack_from_to(i_stack, y)
	# save current order
	order = 1:length(y)
	# sort by i_stack
	perm = sortperm(i_stack)
	# restore original order
	inv_perm = sortperm(order[perm])
	
	from, to = stack_from_to_sorted(view(y, perm))

	(from = view(from, inv_perm), to = view(to, inv_perm))
end

function stack_from_to_sorted(y)
	to = cumsum(y)
	from = [0.0; to[firstindex(to):end-1]]
	
	(from = from, to = to)
end