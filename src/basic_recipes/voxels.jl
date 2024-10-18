function Makie.convert_arguments(T::Type{<:Voxels}, chunk::Array{<: Real, 3})
    X, Y, Z = map(x-> (-0.5*x, 0.5*x), size(chunk))
    return convert_arguments(T, X, Y, Z, chunk)
end

function convert_arguments(T::Type{<:Voxels}, xs, ys, zs, chunk::Array{<: Real, 3})
    xi = Float32.(to_endpoints(xs))
    yi = Float32.(to_endpoints(ys))
    zi = Float32.(to_endpoints(zs))
    return convert_arguments(T, xi, yi, zi, chunk)
end

function convert_arguments(::Type{<:Voxels}, xs::EndPoints, ys::EndPoints, zs::EndPoints,
                           chunk::Array{<:Real,3})
    return (xs, ys, zs, Array{UInt8, 3}(undef, to_ndim(Vec3{Int}, size(chunk), 1)...))
end

function convert_arguments(::Type{<:Voxels}, xs::EndPoints, ys::EndPoints,
                           zs::EndPoints, chunk::Array{UInt8,3})
    return (xs, ys, zs, chunk)
end

function calculated_attributes!(::Type{<:Voxels}, plot)
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
                output = [RGBAf(Colors.color(c), Colors.alpha(c) * a) for _ in 1:255]
            end
            return output
        end
        attributes(plot.attributes)[:calculated_colors] = cc

    else

        # ...
        dummy_data = Observable(UInt8[1, 255])

        # Always sample N colors
        cmap = lift(plot, plot.colormap, plot.lowclip, plot.highclip) do cmap, lowclip, highclip
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

"""
    local_update(p::Voxels, i, j, k)

Updates a section of the Voxel plot given by indices i, j, k (Integer, UnitRange
or Colon()) according to the data present in `p.args[end]`.

This is used to avoid updating the whole chunk with a pattern such as
```
p.args[end].val[20:30, 7:10, 8] = new_data
local_update(plot, 20:30, 7:10, 8)
```
"""
function local_update(plot::Voxels, is, js, ks)
    to_range(N, i::Integer) = i:i
    to_range(N, r::UnitRange) = r
    to_range(N, ::Colon) = 1:N
    to_range(N, x::Any) = throw(ArgumentError("Indices can't be converted to a range representation ($x)"))

    _size = size(plot.converted[end].val)
    is, js, ks = to_range.(_size, (is, js, ks))

    mini, maxi = apply_scale(plot.colorscale[], plot._limits[])
    input = plot.args[end][]
    for k in ks, j in js, i in is
        idx = i + _size[1] * ((j-1) + _size[2] * (k-1))
        _update_voxel(plot.converted[end].val, input, idx, plot.is_air[], plot.colorscale[], mini, maxi)
    end
    plot._local_update[] = (is, js, ks)
    return nothing
end

Base.@propagate_inbounds function _update_voxel(
        output::Array{UInt8, 3}, input::Array, i::Integer,
        is_air::Function, scale, mini::Real, maxi::Real
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
        is_air::Function, scale, mini::Real, maxi::Real
    )
    return nothing
end

function plot!(plot::Voxels)
    # Internal attribute for keeping track of `extrema(chunk)`.
    plot.attributes[:_limits] = Observable((0.0, 1.0))
    # Internal attribute for communicating updates to the backend.
    plot.attributes[:_local_update] = Observable((0:0, 0:0, 0:0))

    # Disconnect automatic mapping
    # I want to avoid recalculating limits every time the input is updated.
    # Maybe this can be done with conversion kwargs...?
    off(plot.args[end], plot.args[end].listeners[1][2])

    # If a UInt8 Array is passed we don't do any mapping between plot.args and
    # plot.converted. Instead we just set plot.converted = plot.args in
    # convert_arguments
    if eltype(plot.args[end][]) == UInt8
        plot._limits[] = (1, 255)
        return plot
    end


    # Use new mapping that doesn't recalculate limits
    onany(plot, plot._limits, plot.is_air, plot.colorscale) do lims, is_air, scale
        # _limits always triggers after plot.args[1]
        chunk = plot.args[end][]
        output = plot.converted[end]

        # TODO: Julia doesn't allow this
        # maybe resize
        # if size(chunk) != size(output.val)
        #     resize!(output.val, size(chunk))
        # end

        # update voxel ids
        mini, maxi = apply_scale(scale, lims)
        maxi = max(mini + 10eps(float(mini)), maxi)
        @inbounds for i in eachindex(chunk)
            _update_voxel(output.val, chunk, i, is_air, scale, mini, maxi)
        end

        # trigger converted
        notify(output)

        return
    end

    # Initial limits
    lift!(plot, plot._limits, plot.args[end], plot.colorrange) do data, colorrange
        if colorrange !== automatic
            return colorrange
        end

        mini, maxi = (Inf, -Inf)
        for elem in data
            plot.is_air[](elem) && continue
            mini = min(mini, elem)
            maxi = max(maxi, elem)
        end
        if !(isfinite(mini) && isfinite(maxi) && isa(mini, Real))
            throw(ArgumentError("Voxel Chunk contains invalid data, resulting in invalid limits ($mini, $maxi)."))
        end
        return (mini, maxi)
    end

    return plot
end

function voxel_size(p::Voxels)
    mini = minimum.(to_value.(p.converted[1:3]))
    maxi = maximum.(to_value.(p.converted[1:3]))
    _size = size(p.converted[4][])
    return Vec3f((maxi .- mini) ./ _size .- convert_attribute(p.gap[], key"gap"(), key"voxels"()))
end

function voxel_positions(p::Voxels)
    mini = minimum.(to_value.(p.converted[1:3]))
    maxi = maximum.(to_value.(p.converted[1:3]))
    voxel_id = p.converted[4][]
    _size = size(voxel_id)
    step = (maxi .- mini) ./ _size
    return [
        Point3f(mini .+ step .* (i-0.5, j-0.5, k-0.5))
        for k in 1:_size[3] for j in 1:_size[2] for i in 1:_size[1]
        if voxel_id[i, j, k] !== 0x00
    ]
end

function voxel_colors(p::Voxels)
    voxel_id = p.converted[4][]
    colormapping = p.calculated_colors[]
    uv_map = p.uvmap[]
    if !isnothing(uv_map)
        @warn "Voxel textures are not implemented in this backend!"
    elseif colormapping isa ColorMapping
        color = colormapping.colormap[]
    else
        color = colormapping
    end

    return [color[id] for id in voxel_id if id !== 0x00]
end
