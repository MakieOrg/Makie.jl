"""
    waterfall(x, y; kwargs...)

Plots a [waterfall chart](https://en.wikipedia.org/wiki/Waterfall_chart) to visualize individual
positive and negative components that add up to a net result as a barplot with stacked bars next
to each other.
"""
@recipe Waterfall (x, y) begin
    color = @inherit patchcolor
    dodge=automatic
    n_dodge=automatic
    gap=0.2
    dodge_gap=0.03
    width=automatic
    cycle=[:color => :patchcolor]
    stack=automatic
    show_direction=false
    marker_pos=:utriangle
    marker_neg=:dtriangle
    direction_color= @inherit backgroundcolor
    show_final=false
    final_color=plot_color(:grey90, 0.5)
    final_gap=automatic
    final_dodge_gap=0
end

conversion_trait(::Type{<:Waterfall}) = PointBased()

function Makie.plot!(p::Waterfall)
    function stack_bars(xy, dodge, stack)
        x, y = first.(xy), last.(xy)
        if stack === automatic
            stack = dodge === automatic ? :x : :dodge
        end
        i_dodge = dodge === automatic ? ones(Int, length(x)) : dodge
        i_stack, i_group = stack === :dodge ? (i_dodge, x) : (x, i_dodge)
        xy = similar(xy)
        fillto = similar(x)
        final = similar(xy)
        groupby = StructArray(; grp=i_group)
        for (grp, inds) in StructArrays.finduniquesorted(groupby)
            _fromto = stack_from_to_final(i_stack[inds], y[inds])
            fillto[inds] .= _fromto.from
            xy[inds] .= Point2f.(x[inds], _fromto.to)
            final[inds] .= Point2f.(x[inds], _fromto.final)
        end
        return (xy=xy, fillto=fillto, final=final)
    end

    fromto = lift(stack_bars, p, p[1], p.dodge, p.stack)

    if p.show_final[]
        final_gap = p.final_gap[] === automatic ? p.dodge[] == automatic ? 0 : p.gap : p.final_gap
        barplot!(
            p,
            lift(x -> x.final, p, fromto);
            dodge=p.dodge,
            color=p.final_color,
            dodge_gap=p.final_dodge_gap,
            gap=final_gap,
        )
    end

    bar_attrs = copy(p.attributes)
    delete!(bar_attrs, :direction_color)
    delete!(bar_attrs, :marker_pos)
    delete!(bar_attrs, :final_color)
    delete!(bar_attrs, :final_dodge_gap)
    delete!(bar_attrs, :show_direction)
    delete!(bar_attrs, :final_gap)
    delete!(bar_attrs, :show_final)
    delete!(bar_attrs, :marker_neg)

    barplot!(
        p,
        lift(x -> x.xy, p, fromto);
        bar_attrs...,
        fillto=lift(x -> x.fillto, p, fromto),
        stack=automatic,
    )

    if p.show_direction[]
        function direction_markers(
            fromto,
            marker_pos,
            marker_neg,
            width,
            gap,
            dodge,
            n_dodge,
            dodge_gap,
        )
            xs = first(
                compute_x_and_width(first.(fromto.xy), width, gap, dodge, n_dodge, dodge_gap)
            )
            MarkerType = promote_type(typeof(marker_pos), typeof(marker_neg))
            DataType = eltype(fromto.xy)
            shapes = MarkerType[]
            xy = DataType[]
            for i in eachindex(xs)
                y = last(fromto.xy[i])
                fillto = fromto.fillto[i]
                if fillto > y
                    push!(xy, (xs[i], (y + fillto) / 2))
                    push!(shapes, marker_neg)
                elseif fillto < y
                    push!(xy, (xs[i], (y + fillto) / 2))
                    push!(shapes, marker_pos)
                end
            end
            return (xy=xy, shapes=shapes)
        end

        markers = lift(
            direction_markers,
            p,
            fromto,
            p.marker_pos,
            p.marker_neg,
            p.width,
            p.gap,
            p.dodge,
            p.n_dodge,
            p.dodge_gap,
        )

        scatter!(
            p,
            lift(x -> x.xy, p, markers);
            marker=lift(x -> x.shapes, p, markers),
            color=p.direction_color)
    end

    return p
end

function stack_from_to_final(i_stack, y)
    order = 1:length(y) # save current order
    perm = sortperm(i_stack) # sort by i_stack
    inv_perm = sortperm(order[perm]) # restore original order
    from, to = stack_from_to_sorted(view(y, perm))
    return (from=view(from, inv_perm), to=view(to, inv_perm), final=last(to))
end
