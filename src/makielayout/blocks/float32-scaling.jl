#=
# Maybe parametrice this with the input target type (e.g. Int64, Float64, Int128)
struct Float32Scaling{TargetType}
    scale::Base.TwicePrecision{Float64}
    offset::Base.TwicePrecision{Float64}
end

function Float32Scaling{TargetType}(s::Real, o::Real) where {TargetType}
    return Float32Scaling{TargetType}(Base.TwicePrecision(s), Base.TwicePrecision(o))
end

"""
    update_scaling_factors(scaling::Float32Scaling, scaled_min::Real, scaled_max::Real)

Returns a new scaling if the scaled values fall outside the desired range.
Gets called with already scaled values, to be easily used with `finallimits`.
"""
function update_scaling_factors(scaling::Float32Scaling{T}, scaled_min::Real, scaled_max::Real) where {T}
    TW = Base.TwicePrecision{Float64}
    max_range = 100
    min_r, max_r = -max_range / 2, max_range / 2

    if (scaled_min > min_r) && (scaled_max < max_r)
        return scaling
    end
    # Recalculate the scale and offset to ensure the scaled values fall within the desired range
    mini, maxi = unscale_value(scaling, scaled_min), unscale_value(scaling, scaled_max)
    # The desired range is 100, but we always convert to a smaller target range
    # to less often change the scaling
    desired_range = TW(max_range / 10)
    offset = TW(mini) + (TW(maxi - mini) / TW(2))
    # Adjust the scale
    scale = TW(maxi - mini) / desired_range
    return Float32Scaling{T}(scale, offset)
end

function scale_value(scaling::Float32Scaling, value::Real)
    return Float32((value - scaling.offset) / scaling.scale)
end

function convert_to_target(::Type{T}, x::Base.TwicePrecision) where T
    convert(T, x)
end

function convert_to_target(::Type{T}, x::Base.TwicePrecision) where {T <: Integer}
    return round(T, Float64(x))
end

function unscale_value(scaling::Float32Scaling{T}, value::Real) where T
    # TODO, this should maybe not return Float64
    # The big question is, how do we make a lossless conversion from TwicePrecision back to Int64
    # But otherwise it will return TwicePrecision, which doesn't work well
    # since lots of math functions are not defined for it
    return convert_to_target(T, (value * scaling.scale) + scaling.offset)
end

struct Float32Conversion{T}
    scaling::Observable{Float32Scaling{T}}
end

function dim_conversion_type(::Type{T}) where {T <: Int64}
    return Float32Conversion{T}(Observable(Float32Scaling{T}(1.0, 0.0); ignore_equal_values=true))
end

MakieCore.can_axis_convert(::Type{<:Union{Lines, Scatter}}, ::AbstractVector{<:Int64}) = true

dim_conversion_type(::Type{T}) where {T} = Float32Conversion{T}(Observable(Float32Scaling{T}(1.0, 0.0); ignore_equal_values=true))
MakieCore.can_axis_convert(::Type{<:Union{Lines,Scatter}}, ::AbstractVector{<:Float64}) = true


function convert_axis_dim(conversion::Float32Conversion{T}, values::Observable) where {T}
    # TODO update minimum in connect! on limit change!
    scaling = update_scaling_factors(conversion.scaling[], extrema(values[])...)
    conversion.scaling[] = scaling
    return map(values, conversion.scaling) do vals, scaling
        return scale_value.(Ref(scaling), vals)
    end
end

function connect_conversion!(ax::Axis, conversion_obs::Observable, conversion::Float32Conversion, dim)
    on(ax.blockscene, ax.finallimits) do limits
        # Don't update if nothing plotted yet
        if isempty(ax.scene.plots)
            return
        end
        scaling = conversion.scaling[]
        # Get scaled extrema of the limits of the dimension
        mini, maxi = getindex.(extrema(limits), dim)
        # Calculate new scaling
        new_scaling = update_scaling_factors(scaling, mini, maxi)
        if new_scaling != scaling
            # Only update if the scaling changed
            # conversion.scaling[] = new_scaling
            # notify(conversion_obs)
        end
    end
end

function get_ticks(conversion::Float32Conversion, ticks, scale, formatter, vmin, vmax)
    if scale != identity
        error("$(scale) scale not supported for Float32Conversion")
    end
    f32scaling = conversion.scaling[]
    umin = unscale_value(f32scaling, vmin)
    umax = unscale_value(f32scaling, vmax)
    ticks, labels = get_ticks(ticks, scale, formatter, umin, umax)
    return scale_value.(Ref(f32scaling), ticks), labels
end
=#