# expand_dimensions would require conversion trait
function convert_arguments(::Type{<:Voxels}, chunk::Array{<:Real, 3})
    X, Y, Z = map(x -> EndPoints(Float32(-0.5 * x), Float32(0.5 * x)), size(chunk))
    return (X, Y, Z, chunk)
end

function convert_arguments(::Type{<:Voxels}, xs, ys, zs, chunk::Array{<:Real, 3})
    xi = Float32.(to_endpoints(xs, "x", Voxels))
    yi = Float32.(to_endpoints(ys, "y", Voxels))
    zi = Float32.(to_endpoints(zs, "z", Voxels))
    return (xi, yi, zi, chunk)
end

function convert_arguments(
        ::Type{<:Voxels}, xs::EndPoints, ys::EndPoints,
        zs::EndPoints, chunk::Array{<:Real, 3}
    )
    return (el32convert(xs), el32convert(ys), el32convert(zs), chunk)
end

function register_voxel_conversions!(attr)
    # maybe include UInt16 in the future?
    native_types = UInt8

    # For local updates we can update chunk data without causing an update of
    # the compute graph and instead trigger from updated_indices
    # ^ this must then resolve chunk_u8 immediately so nothing gets lost
    # Any normal update will trigger chunk, which resets indices here
    map!(attr, :chunk, :updated_indices) do chunk
        return (1:size(chunk, 1), 1:size(chunk, 2), 1:size(chunk, 3))
    end

    map!(attr, [:chunk, :updated_indices, :colorrange, :is_air], :value_limits) do chunk, (is, js, ks), colorrange, is_air
        colorrange !== automatic && return colorrange
        eltype(chunk) <: native_types && return (1, 255)

        mini, maxi = (Inf, -Inf)
        for k in ks, j in js, i in is
            elem = chunk[i, j, k]
            is_air(elem) && continue
            mini = min(mini, elem)
            maxi = max(maxi, elem)
        end
        if !(isfinite(mini) && isfinite(maxi) && isa(mini, Real))
            throw(ArgumentError("Voxel Chunk contains invalid data, resulting in invalid limits ($mini, $maxi)."))
        end
        return (mini, maxi)
    end

    return register_computation!(
        attr, [:value_limits, :is_air, :colorscale, :chunk, :updated_indices],
        [:chunk_u8]
    ) do (lims, is_air, scale, chunk, (is, js, ks)), changed, last

        # No conversions necessary so no new array necessary. Should still
        # propagate updates though
        if chunk isa Array{UInt8, 3}
            output = isnothing(last) ? ShaderAbstractions.Sampler(chunk, minfilter = :nearest) : last.chunk_u8

            # notify sampler
            if chunk === ShaderAbstractions.data(output)
                # in place update so we just need to tell the Sampler which
                # indices it needs to forward to Textures
                data = if is == axes(chunk, 1) && js == axes(chunk, 2) && ks == axes(chunk, 3)
                    chunk
                else
                    view(chunk, is, js, ks)
                end
                ShaderAbstractions.updater(output).update[] = (setindex!, (data, is, js, ks))
            else
                # array got replaced
                # ShaderAbstractions.update!(output, chunk) # errors :)
                ShaderAbstractions.setfield!(output, :data, chunk)
                Nx, Ny, Nz = size(chunk)
                ShaderAbstractions.updater(output).update[] = (setindex!, (chunk, 1:Nx, 1:Ny, 1:Nz))
            end

            return (output,)
        elseif chunk isa Sampler
            return (chunk,)
        else
            output = if isnothing(last)
                ShaderAbstractions.Sampler(Array{UInt8, 3}(undef, size(chunk)), minfilter = :nearest)
            else
                last.chunk_u8
            end

            mini, maxi = apply_scale(scale, lims)
            maxi = max(mini + 10eps(float(mini)), maxi)
            norm = 252.99998 / (maxi - mini)
            @inbounds for k in ks, j in js, i in is
                _update_voxel_data!(ShaderAbstractions.data(output), chunk, CartesianIndex(i, j, k), is_air, scale, mini, norm)
            end

            # notify sampler
            x = view(ShaderAbstractions.data(output), is, js, ks)
            ShaderAbstractions.updater(output).update[] = (setindex!, (x, is, js, ks))

            return (output,)
        end
    end
end

# TODO: Does have some overlap with the normal version...
function register_voxel_colormapping!(attr)
    # TODO: Is resolving this immediately fine?
    return if isnothing(attr[:color][])
        register_computation!(attr, [:colormap, :alpha, :lowclip, :highclip], [:voxel_colormap]) do (cmap, alpha, lowclip, highclip), changed, cached_load
            N = 253 + (lowclip === automatic) + (highclip === automatic)
            cm = add_alpha.(resample_cmap(cmap, N), alpha)
            if lowclip !== automatic
                cm = [to_color(lowclip); cm]
            end
            if highclip !== automatic
                cm = [cm; to_color(highclip)]
            end
            return (cm,)
        end
    else
        register_computation!(attr, [:color, :alpha], [:voxel_color]) do (color, alpha), changed, cached
            if color isa AbstractVector # one color per id
                output = Vector{RGBAf}(undef, 255)
                @inbounds for i in 1:min(255, length(color))
                    output[i] = add_alpha(to_color(color[i]), alpha)
                end
                for i in (min(255, length(color)) + 1):255
                    output[i] = RGBAf(0, 0, 0, 0)
                end
                return (output,)
            elseif color isa AbstractArray # image/texture
                output = add_alpha.(to_color.(color), alpha)
                return (output,)
            elseif color isa Colorant # static
                c = add_alpha(to_color(color), alpha)
                output = [c for _ in 1:255]
                return (output,)
            else
                error("Invalid color type $(typeof(color))")
            end
        end

    end
end

function calculated_attributes!(::Type{Voxels}, plot::Plot)
    attr = plot.attributes
    register_voxel_conversions!(attr)
    register_voxel_colormapping!(attr)
    map!(attr, [:x, :y, :z], :data_limits) do x, y, z
        mini, maxi = Vec3.(x, y, z)
        return Rect3d(mini, maxi .- mini)
    end
    return
end

Base.@propagate_inbounds function _update_voxel_data!(
        output::Array{UInt8, 3}, input::Array, i,
        is_air::Function, scale, mini::Real, norm::Real
    )
    @boundscheck checkbounds(Bool, output, i) && checkbounds(Bool, input, i)
    # Rescale data to UInt8 range for voxel ids
    # 0 is reserved for invisible voxels
    # 1, 255 are reserved for lowclip and highclip (any outside mini..maxi should map to those)
    # 2..254 are valid ids for colormapping (mini..maxi should map to those)
    @inbounds begin
        x = input[i]
        if is_air(x)
            output[i] = 0x00
        else
            scaled = apply_scale(scale, x)
            lin = norm * (scaled - mini)
            idf = clamp(lin + 2, 1, 255)
            output[i] = trunc(UInt8, idf)
        end
    end
    return nothing
end

@deprecate local_update local_update! false

"""
    local_update!(p::Voxels, data, is, js, ks)

Updates a section of the voxel chunk to the given `data`. This will result in
localized backend updates, i.e. avoid updating/uploading the full array.

The `data` can be a singular value, an array or view matching the size set by the
indices `is`, `js` and `ks`, or an array of the same size as the initial voxel
plot data. In that case the indices will also index `data`.

The indices can be integers, `OneTo` (i.e. `axes()`), unit ranges (`i:j`), or `Colon()`.

```
f,a,p = voxels(rand(10, 10, 10))
Makie.local_update(p, 1.0, 5:10, 3:8, 5:10)
```
"""
function local_update!(plot::Voxels{Tuple{X, Y, Z, C}}, value, _is, _js, _ks) where {X, Y, Z, C}
    to_range(N, i::Integer) = i:i
    to_range(N, r::UnitRange) = r
    to_range(N, r::Base.OneTo) = 1:last(r)
    to_range(N, ::Colon) = 1:N
    to_range(N, x::Any) = throw(ArgumentError("Indices can't be converted to a range representation ($x)"))


    # This is quite fragile...
    # - plot.chunk must not be marked dirty, so that it does not trigger a
    #   recomputation/reset of updated_indices
    # - updated_indices must be changed and marked dirty, so they get pulled into
    #   limit & chunk_u8 computations
    # - chunk_u8 must be pulled immediately, so the local update resolves and does
    #   not get overwritten by another. It should also be resolved beforehand to
    #   make sure everything is initialized and no update is queued
    plot.chunk_u8[]
    chunk = plot.chunk[]::C
    ranges = to_range.(size(chunk), (_is, _js, _ks))
    if chunk === value
        # already updated, no need to copy
    elseif size(value) == size(chunk) # copy section of external buffer
        chunk[ranges...] .= view(value, ranges)
    else # copy value, view, array
        chunk[ranges...] .= value
    end
    plot.attributes[:updated_indices].value[] = ranges
    ComputePipeline.mark_dirty!(plot.updated_indices)
    plot.chunk_u8[]
    return
end

pack_voxel_uv_transform(uv_transform::Nothing) = nothing

function pack_voxel_uv_transform(uv_transform::Vector{Mat{2, 3, Float32, 6}})
    # first dim is continuous
    output = Matrix{Vec2f}(undef, 3, length(uv_transform))
    for i in eachindex(uv_transform)
        for j in 1:3
            output[j, i] = uv_transform[i][Vec(1, 2), j]
        end
    end
    return output
end

function pack_voxel_uv_transform(uv_transform::Matrix{Mat{2, 3, Float32, 6}})
    # first dim is continuous
    output = Array{Vec2f, 3}(undef, 3, size(uv_transform)...)
    for i in axes(uv_transform, 2)
        for j in axes(uv_transform, 1)
            for k in 1:3
                output[k, j, i] = uv_transform[j, i][Vec(1, 2), k]
            end
        end
    end
    return output
end

function uvmap_to_uv_transform(uvmap::Array)
    return map(uvmap) do (l, r, b, t)
        return (Point2f(l, b), Vec2f(r - l, t - b))
    end
end

# for CairoMakie

function voxel_size(p::Voxels)
    mini, maxi = extrema(data_limits(p))
    _size = size(p.chunk[])
    return Vec3f((maxi .- mini) ./ _size .- p.gap[])
end

function voxel_positions(p::Voxels)
    mini, maxi = extrema(data_limits(p))
    voxel_id = p.chunk_u8[].data::Array{UInt8, 3}
    _size = size(voxel_id)
    step = (maxi .- mini) ./ _size
    return [
        Point3f(mini .+ step .* (i - 0.5, j - 0.5, k - 0.5))
            for k in 1:_size[3] for j in 1:_size[2] for i in 1:_size[1]
            if voxel_id[i, j, k] !== 0x00
    ]
end

function voxel_colors(p::Voxels)
    voxel_id = p.chunk_u8[].data::Array{UInt8, 3}
    uv_map = p.uvmap[]
    if !isnothing(uv_map)
        @warn "Voxel textures are not implemented in this backend!"
    elseif haskey(p, :voxel_colormap)
        color = p.voxel_colormap[]
    else
        color = p.voxel_color[]
    end

    return [color[id] for id in voxel_id if id !== 0x00]
end
