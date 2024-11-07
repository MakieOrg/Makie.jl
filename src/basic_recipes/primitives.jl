# TODO: Make this more generic

# Also check interfaces.jl for args triggering update!()
const SupportedPlots = Union{Scatter, Lines}

# TODO: Is NamedTuple even better tham just Dict?
function Base.setindex!(plot::SupportedPlots, value, idx::Integer)
    update!(plot; NamedTuple{(Symbol(:arg, idx),)}((value,))...)
    return value
end

function Base.setindex!(x::SupportedPlots, value, key::Symbol)
    argnames = MakieCore.argument_names(typeof(x), length(x.converted))
    idx = findfirst(isequal(key), argnames)
    if idx === nothing && !haskey(x.attributes, key)
        # update always does .val sets
        x.attributes[key] = convert(Observable, value)
    elseif idx === nothing
        update!(x; NamedTuple{(key,)}((value,))...)
    else
        update!(x; NamedTuple{(Symbol(:arg, idx),)}((value,))...)
    end
    return value
end

function Base.setindex!(x::SupportedPlots, obs::Observable, key::Symbol)
    argnames = MakieCore.argument_names(typeof(x), length(x.converted))
    idx = findfirst(isequal(key), argnames)
    # Old version also did attr_or_arg[] = obs[]
    if idx === nothing
        attributes(x)[key] = obs
    else
        update!(x; NamedTuple{(Symbol(:arg, idx),)}((obs[],))...)
    end
    # no on(update!(), obs) here because these are user added observables?
    # i.e. they can't be relevant to visualization w/o triggering something else that is
    return obs
end

# This is generic but collides with the fallback which needs to notify
# Observables to pass on updates
function update!(plot::SupportedPlots; kwargs...)
    kwarg_keys = Set(keys(kwargs))
    union!(plot.updated_inputs[], kwarg_keys)

    # Handle args
    # For a generic method we probably want a few extra (i.e. for recipes)
    arg_names = (:arg1, :arg2, :arg3, :arg4, :arg5, :arg6, :arg7, :arg8)

    for i in eachindex(plot.args)
        if in(arg_names[i], kwarg_keys)
            plot.args[i].val = kwargs[arg_names[i]]
        end
    end

    if :args in kwarg_keys
        if length(kwargs[:args]) != length(kwargs.args)
            error("Given args are a different size than `plot.args`: $(length(kwargs[:args])) != $(length(kwargs.args))")
        end
        for i in eachindex(plot.args)
            plot.args[i].val = kwargs[:args][i]
        end
    end

    # Handle Attributes
    for (k, v) in pairs(kwargs)
        (in(k, arg_names) || (k == :args)) && continue
        plot[k].val = v
    end

    #=
    # Generic Version
    Requirements:
    if resolve_update() is used/implemented:
      update()    must mark, must notify updated_inputs and must set values
      obs-update  must mark, must notify updated_inputs
    else
      update()    must trigger obs
      obs-update  must not trigger obs
    A possible solution is to trigger observables here, rather than only setting
    values, and have observable inputs mark + notify manually.
    Another possible solution is to have different update() methods for the two
    cases. (current solution)

    if in(:args, kwarg_keys) || any(in(kwarg_keys), arg_names)
        # args update together
        # TODO: also remove convert_arguments from resolve
        notify(plot.args[1])
    end

    for k in kwarg_keys
        (in(k, arg_names) || (k == :args)) && continue
        notify(plot[k])
    end
    =#

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
    arg_names = (:arg1, :arg2, :arg3, :arg4, :arg5, :arg6, :arg7, :arg8, :args)
    flagged = plot.updated_inputs[]

    # Arguments
    # TODO: are these names already defined somewhere?
    if any(in(flagged), arg_names)
        convert_arguments!(Scatter, plot.converted, plot.args)
        setdiff!(flagged, arg_names)
        push!(plot.updated_outputs[], :position)
    end

    # Attributes
    # Simple one arg conversions - convert_attribute
    for name in flagged
        # TODO: these should probably not have convert_attribute methods anymore?
        in(name, (:lowclip, :highclip, :colormap, :color, :colorrange, :calculated_colors)) && continue

        plot.computed[name] = convert_attribute(
            to_value(plot.attributes[name]), Key{name}(), Key{:scatter}())
        push!(plot.updated_outputs[], name)
    end


    # Multi arg conversions - calculated_attributes
    # color
    resolve_color_update!(plot)

    # marker_offset
    if (plot.attributes[:marker_offset][] === automatic) &&
        (in(:marker_offset, flagged) || in(:markersize, flagged))

        # @info "triggered"
        ms = plot.computed[:markersize]::Union{Vec2f, Vector{Vec2f}}
        plot.computed[:marker_offset] = to_2d_scale(-0.5f0 .* ms)
        push!(plot.updated_outputs[], :marker_offset)
    end

    # markerspace - why not just remove this? we don't auto it anyway?

    # Sanity checks
    @assert plot.computed[:marker_offset] !== automatic
    @assert plot.computed[:rotation] isa Union{Quaternionf, Vector{<:Quaternionf}} "$(plot.computed[:rotation])::$(typeof(plot.computed[:rotation]))"

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
    alpha::Float64 = plot.alpha[]
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
            cmap = to_colormap(plot.colormap[])::Vector{RGBAf}
            raw_cmap = to_colormap(plot.colormap[])::Vector{RGBAf}
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
                    plot.computed[k] = default(plot.computed[:colormap]::Vector{RGBAf})
                elseif k in flagged
                    plot.computed[k] = to_color(plot[k][])
                end
                push!(plot.updated_outputs[], k)
            end
        end

        if (:color in flagged)
            cs = ifelse(plot.color[] isa Real, [plot.color[]], plot.color[])::AbstractVector
            # TODO: Can't this be a collect(cs)?
            plot.computed[:color] = Vector{Float64}(cs) # TODO: is this ok? replacing _array_value_type
            push!(plot.updated_outputs[], :color)
        end

        colors = plot.computed[:color]::Vector{Float64}

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
        push!(plot.updated_outputs[], :color)

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

function resolve_updates!(plot::Lines)
    arg_names = (:arg1, :arg2, :arg3, :arg4, :arg5, :arg6, :arg7, :arg8, :args)
    flagged = plot.updated_inputs[]

    # Arguments
    # TODO: are these names already defined somewhere?
    if any(in(flagged), arg_names)
        convert_arguments!(Lines, plot.converted, plot.args)
        setdiff!(flagged, arg_names)
        push!(plot.updated_outputs[], :position)
    end

    # Attributes
    # Simple one arg conversions - convert_attribute
    for name in flagged
        # TODO: these should probably not have convert_attribute methods anymore?
        in(name, (:lowclip, :highclip, :colormap, :color, :colorrange, :calculated_colors)) && continue

        plot.computed[name] = convert_attribute(
            to_value(plot.attributes[name]), Key{name}(), Key{:scatter}())
        push!(plot.updated_outputs[], name)
    end


    # Multi arg conversions - calculated_attributes
    # color
    resolve_color_update!(plot)

    # Finally cleanup + trigger backend
    empty!(plot.updated_inputs[])
    foreach(notify, plot.converted)
    notify(plot.updated_outputs)

    return
end