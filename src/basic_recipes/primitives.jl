function update!(plot::Scatter; kwargs...)
    kwarg_keys = Set(keys(kwargs))
    union!(plot.updated_inputs[], kwarg_keys)

    # TODO: Args make this plot specific. Can we avoid that?
    # Handle args
    if any(in(kwarg_keys), (:x, :y, :z))
        # TODO: How should we verify these, especially in recipes with more
        #       variations? (E.g. text with text vs position vs GlyphCollection)
        in(:x, kwarg_keys) && (plot.args[1].val = kwargs[:x])
        in(:y, kwarg_keys) && (plot.args[2].val = kwargs[:y])
        in(:z, kwarg_keys) && (plot.args[3].val = kwargs[:z])
    end

    if :position in kwarg_keys
        length(plot.args) == 1 || error("Cannot set position with x, y[, z]-like plot arguments")
        plot.args[1] = kwargs[:position]
    end

    # Handle Attributes
    for (k, v) in pairs(kwargs)
        in(k, (:x, :y, :z, :position)) && continue
        plot[k].val = v
    end

    notify(plot.updated_inputs)
    return
end

# TODO: nospecialize this?
function convert_arguments!(::Type{T}, output, args) where {T}
    temp = convert_arguments(T, to_value.(args)...)
    for i in eachindex(output)
        output[i].val = temp[i]
    end
    return
end

function resolve_updates!(plot::Scatter)
    flagged = plot.updated_inputs[]

    # Arguments
    # TODO: are these names already defined somewhere?
    if any(in(flagged), (:x, :y, :z, :position))
        convert_arguments!(Scatter, plot.converted, plot.args)
        foreach(k -> delete!(flagged, k), (:x, :y, :z, :position))
        push!(plot.updated_outputs[], :position)
    end

    # Attributes
    # Simple one arg conversions - convert_attribute
    for name in flagged
        # TODO: these should probably not have convert_attribute methods anymore?
        in(name, (:lowclip, :highclip, :colormap, :color, :colorrange, :calculated_colors)) && continue

        plot.computed[name] = convert_attribute(
            to_value(plot.attributes[name]), Key(name), Key(:scatter))
        push!(plot.updated_outputs[], name)
    end


    # Multi arg conversions - calculated_attributes
    # color
    resolve_color_update!(plot)

    # marker_offset
    if (plot.attributes[:marker_offset][] === automatic) &&
        (in(:marker_offset, flagged) || in(:markersize, flagged))

        @info "triggered"
        ms = plot.computed[:markersize]
        plot.computed[:marker_offset] = to_2d_scale(-0.5f0 .* ms)
        push!(plot.updated_outputs[], :marker_offset)
    end
    @assert plot.computed[:marker_offset] !== automatic

    # markerspace - why not just remove this? we don't auto it anyway?

    # Finally cleanup + trigger backend
    
    # TODO:
    # If we let tasks do this we could skip work e.g. if the plot is invisible.
    # BUT if multiple tasks work on the same inputs we could run into issues 
    # with who gets to clear.
    empty!(plot.updated_inputs[])

    # TODO: testing only?
    foreach(notify, plot.converted) 

    # TODO: 
    # For a select few attributes (Textures) the backend needs to know that they
    # changed so the changes can propagate to GPU memory.
    # This probably doesn't need to be an Observable though. (The backend 
    # probably calls this function, so it knows when it's done.)
    notify(plot.updated_outputs)

    return
end

# This should hopefully do everything ColorMapping does...
function resolve_color_update!(plot)

    @inline function add_alpha(color, alpha)
        return RGBAf(Colors.color(color), alpha * Colors.alpha(color))
    end
    
    flagged = plot.updated_inputs[]
    alpha = plot.alpha[]
    alpha_matters = alpha < 1.0

    # colors are values for colormap
    if plot.color[] isa Union{Real, AbstractVector{<: Real}}

        # TODO: Should nan_color consider alpha?
        if :nan_color in flagged
            plot.computed[:nan_color] = to_color(plot[:nan_color][])
            push!(plot.updated_outputs[], :nan_color)
        end

        # TODO: Is this needed?
        if :colorscale in flagged
            plot.computed[:colorscale] = plot.colorscale[]
            push!(plot.updated_outputs[], :colorscale)
        end

        # TODO: Is this needed?
        if :colormap in flagged
            plot.computed[:color_mapping_type] = colormapping_type(plot.colormap[])
            push!(plot.updated_outputs[], :color_mapping_type)
        end

        # TODO: Do we use both?
        if (:colormap in flagged) || (:colorscale in flagged) || (:alpha in flagged)
            cmap = to_colormap(plot.colormap[])
            raw_cmap = to_colormap(plot.colormap[])
            if alpha_matters
                plot.computed[:colormap] = add_alpha.(cmap)
                plot.computed[:raw_colormap] = add_alpha.(raw_cmap)
            else
                plot.computed[:colormap] = cmap
                plot.computed[:raw_colormap] = raw_cmap
            end

            if plot.colormap[] isa PlotUtils.ColorGradient
                plot.computed[:mapping] = plot.colormap[].values
                push!(plot.updated_outputs[], :mapping)
            end
            push!(plot.updated_outputs[], :colormap)
            push!(plot.updated_outputs[], :raw_colormap)
        end

        for (k, default) in zip((:lowclip, :highclip), (first, last))
            if (k in flagged) || (:colormap in flagged)
                if plot[k][] === automatic
                    plot.computed[k] = default(plot.computed[:colormap])
                elseif k in flagged
                    plot.computed[k] = to_color(plot[k][])
                end
                push!(plot.updated_outputs[], k)
            end
        end

        if (:color in flagged)
            cs = ifelse(plot.color[] isa Real, [plot.color[]], plot.color[])
            # TODO: Can't this be a collect(cs)?
            plot.computed[:color] = _array_value_type(cs)(cs)
            push!(plot.updated_outputs[], :color)
        end
                
        colors = plot.computed[:color]

        # TODO: Probably cheaper to merge the two colorrange steps
        # TODO: Do we need both outputs?
        if (:color in flagged) || (:colorrange in flagged)
            if plot.colorrange[] === automatic
                plot.computed[:colorrange] = Vec2{Float64}(distinct_extrema_nan(colors))
            else
                plot.computed[:colorrange] = Vec2{Float64}(plot.colorrange[])
            end
            push!(plot.updated_outputs[], :colorrange)
        end
        if (:color in flagged) || (:colorrange in flagged) || (:colorscale in flagged)
            plot.computed[:colorrange_scaled] = Vec2f(apply_scale(
                plot.colorscale[], plot.computed[:colorrange]
            ))
            push!(plot.updated_outputs[], :colorrange_scaled)
        end

        # Note: probably should be separate from color update since colors can
        #       be a larger array?
        if (:color in flagged) || (:colorscale in flagged)
            plot.computed[:color_scaled] = el32convert(apply_scale(plot.colorscale[], colors))
            push!(plot.updated_outputs[], :color_scaled)
        end

    else # colors are actually colors

        if alpha_matters
            plot.computed[:color] = broadcast(plot.color[]) do convertible_color
                return add_alpha(to_color(convertible_color), alpha)
            end
        else
            plot.computed[:color] = to_color(plot.color[])
        end

    end

    return
end

#=
On `text!()`:

Text is the most complicated primitive...

Can act like recipe (linesegments + text)
-> probably need a native_text()

Multiple input types:
- GlyphCollection -> converted    
- text -> GlyphCollection -> converted
- point-like -> position attribute
- (x, y, z)-like -> point-like -> position attribute
Maybe not a big problem?

update!(::Text)
    if any(in(flagged), (:x, :y, :z, :position))
        plot.position.val = convert_arguments(Text, ...)[1]
        if is_positional(plot.args)
            plot.args[1].val = plot.position[]
        end
    end
    if text in flagged
        plot.text.val = convert_arguments(Text, kwargs[:text])[1]
        if is_text_like(plot.args)
            plot.args[1].val = plot.text[]
        end
    end

resolve_update!()
    plot.converted = layout_text(...)
    plot.computed[:position] = plot.position[]

=#