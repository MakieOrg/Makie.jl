# used_attributes(::Type{<:Plot}, args...) = (limits,)

function convert_arguments(::Type{<:Voxel}, chunk::Array{<: Any, 3})
    return (Array{UInt8, 3}(undef, size(chunk)),)
end

function calculated_attributes!(::Type{<:Voxel}, plot)
    if !isnothing(plot.color[])
        cc = lift(plot, plot.color, plot.alpha) do color, a
            if color isa AbstractVector
                output = Vector{RGBAf}(undef, 255)
                @inbounds for i in 1:min(255, length(color))
                    c = to_color(color[i])
                    output[i] = RGBAf(Colors.color(c), Colors.alpha(c) * a)
                end
                for i in min(255, length(color))+1 : 255
                    output[i] = RGBAf(0,0,0,0)
                end
            elseif color isa AbstractArray
                output = similar(color, RGBAf)
                @inbounds for i in eachindex(color)
                    c = to_color(color[i])
                    output[i] = RGBAf(Colors.color(c), Colors.alpha(c) * a)
                end
            else
                c = to_color(color)
                output .= RGBAf(Colors.color(c), Colors.alpha(c) * a)
            end
            return output
        end
        attributes(plot.attributes)[:calculated_colors] = cc

    else

        # ...
        dummy_data = Observable(UInt8[1, 255])

        # Always sample N colors
        cmap = map(plot.colormap, plot.lowclip, plot.highclip) do cmap, lowclip, highclip
            cm = if cmap isa Vector && length(cmap) != 255
                resample_cmap(cmap, 253)
            else
                categorical_colors(cmap, 253)
            end
            lc = lowclip === automatic ? first(cm) : to_color(lowclip)
            hc = highclip === automatic ? last(cm) : to_color(highclip)
            return [lc; cm; hc]
        end

        # always use 1..N
        colorrange = Observable(Vec2f(1, 255))

        # Needs to happen in voxel id generation
        colorscale = Observable(identity)

        # We always treat nan as air, invalid
        nan_color = Observable(:transparent)

        # TODO: categorical?
        attributes(plot.attributes)[:calculated_colors] = ColorMapping(
            dummy_data[], dummy_data, cmap, colorrange, colorscale,
            plot.alpha, plot.lowclip, plot.highclip, nan_color
        )

    end

    return nothing
end

# TODO: document: update voxel id's and voxel id texture for the given indices or ranges
function local_update(plot::Voxel, is::Union{Integer, UnitRange}, js::Union{Integer, UnitRange}, ks::Union{Integer, UnitRange})
    to_range(i::Integer) = i:i
    to_range(r::UnitRange) = r

    mini, maxi = apply_scale(plot.colorscale[], plot.limits[])
    input = plot.args[1][]
    for k in ks, j in js, i in is
        idx = i + size(input, 1) * ((j-1) + size(input, 2) * (k-1))
        _update_chunk(plot.converted[1].val, input, idx, plot.is_air[], plot.colorscale[], mini, maxi)
    end
    plot._local_update[] = to_range.((is, js, ks))
    return nothing
end

Base.@propagate_inbounds function _update_voxel(
        output::Array{UInt8, 3}, input::Array{<: Any, 3}, i::Integer,
        is_air::Function, scale, mini::Real, maxi::Real,
    )

    @boundscheck checkbounds(Bool, output, i) && checkbounds(Bool, input, i)
    # Rescale data to UInt8 range for voxel ids
    c = 252.99998
    @inbounds begin
        x = input[i]
        if is_air(x)
            output[i] = 0x00
        else
            lin = clamp(c * (apply_scale(scale, x) - mini) / (maxi - mini) + 2, 1, 255)
            output[i] = trunc(UInt8, lin)
        end
    end
    return nothing
end

Base.@propagate_inbounds function _update_voxel(
        output::Array{UInt8, 3}, input::Array{UInt8, 3}, i::Integer,
        is_air::Function, scale, mini::Real, maxi::Real, has_low::Bool, has_high::Bool
    )
    @boundscheck checkbounds(Bool, output, i) && checkbounds(Bool, input, i)
    # If input data is in the same format we assume the user is directly specifying voxel ids
    @inbounds output[i] = input[i]
    return nothing
end

function plot!(plot::Voxel)
    # Disconnect automatic mapping
    # I want to avoid recalculating limits every time the input is updated.
    # Maybe this can be done with conversion kwargs...?
    input = plot.args[1]
    off(input, input.listeners[1][2])

    # Use new mapping that doesn't recalculate limits
    onany(plot, input, plot.limits, plot.colorrange, plot.is_air, plot.colorscale) do chunk, limits, colorrange, is_air, scale
        output = plot.converted[1]

        # maybe resize
        if size(chunk) != size(output.val)
            resize!(output.val, size(chunk))
        end

        # update voxel ids
        lims = colorrange === automatic ? limits : colorrange
        mini, maxi = apply_scale(scale, lims)
        @inbounds for i in eachindex(chunk)
            _update_voxel(output.val, chunk, i, is_air, scale, mini, maxi)
        end

        # trigger converted
        notify(output)

        return
    end

    # Initial limits
    if plot.limits[] === automatic
        mini, maxi = (Inf, -Inf)
        for elem in input.val
            plot.is_air[](elem) && continue
            mini = min(mini, elem)
            maxi = max(maxi, elem)
        end
        if !(isfinite(mini) && isfinite(maxi) && isa(mini, Real))
            throw(ArgumentError("Voxel Chunk contains invalid data, resulting in invalid limits ($mini, $maxi)."))
        end
        plot.limits[] = (mini, maxi)
    end

    return
end