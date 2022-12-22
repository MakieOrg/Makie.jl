@enum Interpolation Linear Nearest

struct Scaling{F, R}
    # a function to scale a value by, e.g. log10, sqrt etc
    scaling_function::F
    # If nothing, no scaling applied!
    range::R
end

Scaling() = Scaling(identity, nothing)

const NoScaling = Scaling{typeof(identity), Nothing}

struct Sampler{N, V} <: AbstractArray{RGBAf, 1}
    # the colors to sample from!
    colors::AbstractArray{T, N} where T
    # or an array of values, which are used to index into colors via interpolation!
    values::V
    # additional alpha that gets multiplied
    alpha::Float64
    # interpolation method for sampling
    interpolation::Interpolation
    scaling::Scaling
end

Base.size(sampler::Sampler) = size(sampler.values)

"""
    interpolated_getindex(cmap::AbstractArray, value::AbstractFloat, norm = (0.0, 1.0))

Like getindex, but accepts values between 0..1 and interpolates those to the full range.
You can use `norm`, to change the range of 0..1 to whatever you want.
"""
function interpolated_getindex(cmap::AbstractArray, value::Number, norm::VecTypes)
    cmin, cmax = norm
    cmin == cmax && error("Can't interpolate in a range where cmin == cmax. This can happen, for example, if a colorrange is set automatically but there's only one unique value present.")
    i01 = clamp((value - cmin) / (cmax - cmin), zero(value), one(value))
    return interpolated_getindex(cmap, i01)
end

"""
    interpolated_getindex(cmap::AbstractArray, value::AbstractFloat)

Like getindex, but accepts values between 0..1 for `value` and interpolates those to the full range of `cmap`.
"""
function interpolated_getindex(cmap::AbstractArray{T}, i01::AbstractFloat) where T
    isfinite(i01) || error("Looking up a non-finite or NaN value in a colormap is undefined.")
    i1len = (i01 * (length(cmap) - 1)) + 1
    down = floor(Int, i1len)
    up = ceil(Int, i1len)
    down == up && return cmap[down]
    interp_val = i1len - down
    downc, upc = cmap[down], cmap[up]
    return convert(T, downc * (one(interp_val) - interp_val) + upc * interp_val)
end

function nearest_getindex(cmap::AbstractArray, value::AbstractFloat)
    idx = round(Int, i01 * (length(cmap) - 1)) + 1
    return cmap[idx]
end

"""
    apply_scaling(value::Number, scaling::Scaling)

Scales a number to the range 0..1.
"""
function apply_scaling(value::Number, scaling::NoScaling)::Float64
    return Float64(value)
end

function apply_scaling(value::Number, scaling::Scaling)::Float64
    value_scaled = scaling.scaling_function(value)
    scaling.range === nothing && return value_scaled
    cmin, cmax = scaling.range
    clamped = clamp((value_scaled - cmin) / (cmax - cmin), zero(value), one(value))
    return isfinite(clamped) ? clamped : zero(clamped)
end

function Base.getindex(sampler::Sampler, i)::RGBAf
    value = sampler.values[i]
    scaled = apply_scaling(value, sampler.scaling)
    c = if sampler.interpolation == Linear
        interpolated_getindex(sampler.colors, scaled)
    else
        nearest_getindex(sampler.colors, scaled)
    end
    return RGBAf(color(c), alpha(c) * sampler.alpha)
end

function Base.getindex(sampler::Sampler{2, <: AbstractVector{Vec2f}}, i)::RGBAf
    uv = sampler.values[i]
    colors = sampler.colors
    # indexing confirming to OpenGL uv indexing
    wsize = reverse(size(colors))
    wh = wsize .- 1
    x, y = round.(Int, Tuple(uv) .* wh) .+ 1
    c = colors[size(colors, 1) - (y - 1), x]
    return RGBAf(color(c), alpha(c) * sampler.alpha)
end

function sampler(cmap::Union{Symbol, String}, n::Int = 20;
                 scaling=Scaling(), alpha=1.0, interpolation=Linear)
    return sampler(cmap, LinRange(0, 1, n); scaling = scaling, alpha = alpha, interpolation = interpolation)
end

function sampler(cmap::Union{Symbol, String}, values::AbstractVector{<: AbstractFloat};
                 scaling=Scaling(), alpha=1.0, interpolation=Linear)

    cs = PlotUtils.get_colorscheme(cmap)

    colors = getindex.(Ref(cs), values)

    return Sampler(colors, values, alpha, interpolation, scaling)
end

function sampler(cmap::Vector{<: Colorant}, values::AbstractVector{<: AbstractFloat};
                 scaling=Scaling(), alpha=1.0, interpolation=Linear)
    return Sampler(RGBAf.(cmap), values, alpha, interpolation, scaling)
end

function sampler(cmap::AbstractVector, values, crange;
                 alpha=1.0, interpolation=Linear)
    return Sampler(to_color.(cmap), values, alpha, interpolation, Scaling(identity, crange))
end
# uv texture sampler
function sampler(cmap::Matrix{<: Colorant}, uv::AbstractVector{Vec2f};
                 alpha=1.0, interpolation=Linear)
    return Sampler(cmap, uv, alpha, interpolation, Scaling())
end


function numbers_to_colors(numbers::AbstractArray{<:Number}, primitive)
    colormap = get_attribute(primitive, :colormap)::Vector{RGBAf}
    colorrange = get_attribute(primitive, :colorrange)::Union{Nothing, Vec2f}
    colorscale = get_attribute(primitive, :colorscale)
    cmin, cmax = if isnothing(colorrange)
        # TODO, plot primitive should always expand automatic values
        colorscale.(Vec2f(extrema_nan(numbers)))
    else
        colorscale.(colorrange)
    end

    lowclip = get_attribute(primitive, :lowclip)
    highclip = get_attribute(primitive, :highclip)
    nan_color = get_attribute(primitive, :nan_color, RGBAf(0,0,0,0))

    return map(numbers) do number
        scaled_number = colorscale(Float64(number))  # ints don't work in interpolated_getindex
        if isnan(scaled_number)
            return nan_color
        elseif !isnothing(lowclip) && scaled_number < cmin
            return lowclip
        elseif !isnothing(highclip) && scaled_number > cmax
            return highclip
        end
        return interpolated_getindex(
            colormap,
            scaled_number, 
            (cmin, cmax))
    end
end
