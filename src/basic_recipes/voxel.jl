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

        # Always sample 255 colors
        cmap = map(plot.colormap) do cmap
            if cmap isa Vector && length(cmap) != 255
                return resample_cmap(cmap, 255)
            else
                return categorical_colors(cmap, 255)
            end
        end

        # always use 1..255
        colorrange = Observable(Vec2f(1, 255))

        # Needs to happen in voxel id generation
        colorscale = Observable(identity)

        # TODO: We can have this but it needs to be embedded into colormap
        lowclip = Observable(automatic)
        highclip = Observable(automatic)

        # We always treat nan as air, invalid
        nan_color = Observable(:transparent)

        # TODO: categorical?

        attributes(plot.attributes)[:calculated_colors] = ColorMapping(
            dummy_data[], dummy_data, cmap, colorrange, colorscale,
            plot.alpha, lowclip, highclip, nan_color
        )

    end

    return nothing
end

# TODO: document: update voxel id's and voxel id texture for the given indices or ranges
function update(plot::Voxel, is::Union{Integer, UnitRange}, js::Union{Integer, UnitRange}, ks::Union{Integer, UnitRange})
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

Base.@propagate_inbounds function _update_chunk(
        output::Array{UInt8, 3}, input::Array{<: Any, 3}, i::Integer,
        is_air::Function, scale, mini::Real, maxi::Real
    )
    @boundscheck checkbounds(Bool, output, i) && checkbounds(Bool, input, i)
    # Rescale data to UInt8 range for voxel ids
    @inbounds begin
        x = input[i]
        if is_air(x)
            output[i] = UInt8(0)
        else
            lin = clamp(254 * (apply_scale(scale, x) - mini) / (maxi - mini), 0, 254)
            output[i] = 0x01 + trunc(UInt8, lin)
        end
    end
    return nothing
end

Base.@propagate_inbounds function _update_chunk(
        output::Array{UInt8, 3}, input::Array{UInt8, 3}, i::Integer,
        is_air::Function, scale, mini::Real, maxi::Real
    )
    @boundscheck checkbounds(Bool, output, i) && checkbounds(Bool, input, i)
    # If input data is UInt8 we assume it to be voxel ids and directly pass it
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
    onany(plot, input, plot.limits, plot.is_air, plot.colorscale) do chunk, lims, is_air, scale
        output = plot.converted[1]

        # maybe resize
        if size(chunk) != size(output.val)
            resize!(output.val, size(chunk))
        end

        # if the input data is UInt8 we assume raw voxel ids being passed
        mini, maxi = apply_scale(scale, lims)
        @inbounds for i in eachindex(chunk)
            _update_chunk(output.val, chunk, i, is_air, scale, mini, maxi)
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