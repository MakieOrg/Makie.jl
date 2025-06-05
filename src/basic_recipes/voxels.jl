#=
Backend Implementation Notes
- lowclip, highclip are built into colormap
- colorrange should not be fetched, use static (1, 255)
- voxel_colormap is only defined if colormapping is used
- colors is only define dif 1:1 mapping is used

- x, y, z, chunk_u8 is output data

renamed _limtis -> value_limits
=#

# TODO: Bad workaround for now
MakieCore.argument_names(::Type{Voxels}, N::Integer) = (:x, :y, :z, :chunk)
conversion_trait(::Type{Voxels}, args...) = Voxels

function expand_dimensions(::Type{<: Voxels}, chunk::Array{<: Real, 3})
    X, Y, Z = map(x -> EndPoints(Float32(-0.5*x), Float32(0.5*x)), size(chunk))
    return (X, Y, Z, chunk)
end


function convert_arguments(::Type{<:Voxels}, xs, ys, zs, chunk::Array{<: Real, 3})
    xi = Float32.(to_endpoints(xs, "x", Voxels))
    yi = Float32.(to_endpoints(ys, "y", Voxels))
    zi = Float32.(to_endpoints(zs, "z", Voxels))
    return (xi, yi, zi, chunk)
end

function convert_arguments(::Type{<:Voxels}, xs::EndPoints, ys::EndPoints,
                           zs::EndPoints, chunk::Array{<: Real,3})
    return (el32convert(xs), el32convert(ys), el32convert(zs), chunk)
end

function register_voxel_conversions!(attr)

    register_computation!(attr, [:chunk, :colorrange, :is_air], [:value_limits]) do (chunk, colorrange, is_air), changed, cached
        colorrange !== automatic && return (colorrange,)

        mini, maxi = (Inf, -Inf)
        for elem in chunk
            is_air(elem) && continue
            mini = min(mini, elem)
            maxi = max(maxi, elem)
        end
        if !(isfinite(mini) && isfinite(maxi) && isa(mini, Real))
            throw(ArgumentError("Voxel Chunk contains invalid data, resulting in invalid limits ($mini, $maxi)."))
        end
        return ((mini, maxi),)
    end

    register_computation!(attr, [:value_limits, :is_air, :colorscale, :chunk],
            [:chunk_u8]) do (lims, is_air, scale, chunk), changed, last

        # No conversions necessary so no new array necessary. Should still
        # propagate updates though
        chunk isa Array{UInt8, 3} && return (chunk, )

        chunk_u8 = isnothing(last) ? Array{UInt8, 3}(undef, size(chunk)) : last.chunk_u8

        mini, maxi = apply_scale(scale, lims)
        maxi = max(mini + 10eps(float(mini)), maxi)
        @inbounds for i in eachindex(chunk)
            _update_voxel(chunk_u8, chunk, i, is_air, scale, mini, maxi)
        end

        return (chunk_u8,)
    end
end

# TODO: Does have some overlap with the normal version...
function register_voxel_colormapping!(attr)
    # TODO: Is resolving this immediately fine?
    if isnothing(attr[:color][])
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
                for i in min(255, length(color))+1 : 255
                    output[i] = RGBAf(0,0,0,0)
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
    register_computation!(attr, [:x, :y, :z], [:data_limits]) do (x, y, z), changed, last
        mini, maxi = Vec3.(x, y, z)
        return (Rect3d(mini, maxi .- mini),)
    end
    return
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

pack_voxel_uv_transform(uv_transform::Nothing) = nothing

function pack_voxel_uv_transform(uv_transform::Vector{Mat{2,3,Float32,6}})
    # first dim is continuous
    output = Matrix{Vec2f}(undef, 3, length(uv_transform))
    for i in eachindex(uv_transform)
        for j in 1:3
            output[j, i] = uv_transform[i][Vec(1,2), j]
        end
    end
    return output
end

function pack_voxel_uv_transform(uv_transform::Matrix{Mat{2,3,Float32,6}})
    # first dim is continuous
    output = Array{Vec2f, 3}(undef, 3, size(uv_transform)...)
    for i in axes(uv_transform, 2)
        for j in axes(uv_transform, 1)
            for k in 1:3
                output[k, j, i] = uv_transform[j, i][Vec(1,2), k]
            end
        end
    end
    return output
end

function uvmap_to_uv_transform(uvmap::Array)
    return map(uvmap) do (l, r, b, t)
        return (Point2f(l, b), Vec2f(r-l, t-b))
    end
end

# TODO: for CairoMakie

function voxel_size(p::Voxels)
    mini, maxi = extrema(data_limits(p))
    _size = size(p.chunk[])
    return Vec3f((maxi .- mini) ./ _size .- p.gap[])
end

function voxel_positions(p::Voxels)
    mini, maxi = extrema(data_limits(p))
    voxel_id = p.chunk_u8[]
    _size = size(voxel_id)
    step = (maxi .- mini) ./ _size
    return [
        Point3f(mini .+ step .* (i-0.5, j-0.5, k-0.5))
        for k in 1:_size[3] for j in 1:_size[2] for i in 1:_size[1]
        if voxel_id[i, j, k] !== 0x00
    ]
end

function voxel_colors(p::Voxels)
    voxel_id = p.chunk_u8[]
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
