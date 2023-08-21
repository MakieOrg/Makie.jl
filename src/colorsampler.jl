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

apply_scale(scale::AbstractObservable, x) = lift(apply_scale, scale, x)
apply_scale(::Union{Nothing,typeof(identity)}, x) = x  # noop
apply_scale(scale, x) = broadcast(scale, x)

function numbers_to_colors(numbers::Union{AbstractArray{<:Number},Number}, primitive)
    colormap = get_attribute(primitive, :colormap)::Vector{RGBAf}
    _colorrange = get_attribute(primitive, :colorrange)::Union{Nothing, Vec2f}
    colorscale = get_attribute(primitive, :colorscale)
    colorrange = if isnothing(_colorrange)
        # TODO, plot primitive should always expand automatic values
        numbers isa Number && error("Cannot determine a colorrange automatically for single number color value $numbers. Pass an explicit colorrange.")
        Vec2f(extrema_nan(numbers))
    else
        _colorrange
    end

    lowclip = get_attribute(primitive, :lowclip)::RGBAf
    highclip = get_attribute(primitive, :highclip)::RGBAf
    nan_color = get_attribute(primitive, :nan_color, RGBAf(0,0,0,0))::RGBAf

    return numbers_to_colors(numbers, colormap, colorscale, colorrange, lowclip, highclip, nan_color)
end

function numbers_to_colors(numbers::Union{AbstractArray{<:Number, N},Number},
                           colormap, colorscale, colorrange::Vec2,
                           lowclip::Union{Automatic,RGBAf},
                           highclip::Union{Automatic,RGBAf},
                           nan_color::RGBAf)::Union{Array{RGBAf, N},RGBAf} where {N}
    cmin, cmax = colorrange
    scaled_cmin = apply_scale(colorscale, cmin)
    scaled_cmax = apply_scale(colorscale, cmax)

    return map(numbers) do number
        scaled_number = apply_scale(colorscale, Float64(number))  # ints don't work in interpolated_getindex
        if isnan(scaled_number)
            return nan_color
        elseif !isnothing(lowclip) && scaled_number < scaled_cmin
            return lowclip
        elseif !isnothing(highclip) && scaled_number > scaled_cmax
            return highclip
        end
        return interpolated_getindex(
            colormap,
            scaled_number,
            (scaled_cmin, scaled_cmax))
    end
end

struct ColorMap{N,T<:AbstractArray{<:Number,N},T2<:AbstractArray{<:Number,N}}
    color::Observable{T}
    colormap::Observable{Vector{RGBAf}}
    scale::Observable{Function}
    mapping::Observable{Union{Nothing, Vector{Float64}}}
    colorrange::Observable{Vec{2,Float64}}

    lowclip::Observable{Union{Automatic, RGBAf}} # Defaults to first color in colormap
    highclip::Observable{Union{Automatic, RGBAf}} # Defaults to last color in colormap
    nan_color::Observable{RGBAf}

    categorical::Observable{Bool}

    # scaled attributes
    colorrange_scaled::Observable{Vec2f}
    color_scaled::Observable{T2}
end

function assemble_colors(::T, @nospecialize(color), @nospecialize(plot)) where {N, T<:AbstractArray{<:Number, N}}
    color_tight = convert(Observable{T}, color)
    colormap = Observable(RGBAf[]; ignore_equal_values=true)
    categorical = Observable(false)
    colorscale = convert(Observable{Function}, plot.colorscale)
    mapping = Observable{Union{Nothing, Vector{Float64}}}(nothing)

    function update_colors(cmap, a)
        colors = to_colormap(cmap)
        if a < 1.0
            colors = map(c -> RGBAf(Colors.color(c), alpha(c) * a), colors)
        end
        colormap[] = colors
        categorical[] = cmap isa PlotUtils.CategoricalColorGradient
        if colormap isa PlotUtils.ColorGradient
            mapping[] = cmap.values
        end
        return
    end
    onany(update_colors, plot, plot.colormap, plot.alpha)
    update_colors(plot.colormap[], plot.alpha[])

    lowclip = Observable{Union{Automatic,RGBAf}}(automatic; ignore_equal_values=true)
    on(plot, plot.lowclip; update=true) do lc
        lowclip[] = lc isa Automatic ? lc : to_color(lc)
        return
    end
    highclip = Observable{Union{Automatic,RGBAf}}(automatic; ignore_equal_values=true)
    on(plot, plot.highclip; update=true) do hc
        highclip[] = hc isa Automatic ? hc : to_color(hc)
        return
    end
    nan_color = lift(to_color, plot.nan_color)
    colorrange = Observable(Vec{2, Float64}(0); ignore_equal_values=true)

    colorrange = lift(color_tight, plot.colorrange; ignore_equal_values=true) do color, crange
        return crange isa Automatic ? Vec2{Float64}(distinct_extrema_nan(color)) : Vec2{Float64}(crange)
    end

    colorrange_scaled = lift(colorrange, colorscale; ignore_equal_values=true) do range, scale
        return Vec2f(apply_scale(scale, range))
    end
    color_scaled = lift(color_tight, colorscale) do color, scale
        return el32convert(apply_scale(scale, color))
    end
    return ColorMap{N, T, typeof(color_scaled[])}(
        color_tight,
        colormap,
        colorscale,
        mapping,
        colorrange,
        lowclip,
        highclip,
        nan_color,
        categorical,
        colorrange_scaled,
        color_scaled
    )
end

function to_color(c::ColorMap)
    return numbers_to_colors(c.color_scaled[], c.colormap[], identity, c.colorrange_scaled[], lowclip(c)[], highclip(c)[], c.nan_color[])
end

function assemble_colors(colortype, color, plot)
    return lift(plot, color, plot.alpha) do color, a
        if a < 1.0
            return broadcast(c-> RGBAf(Colors.color(c), Colors.alpha(c) * a), to_color(color))
        else
            return to_color(color)
        end
    end
end

function assemble_colors(::Number, color, plot)
    plot.colorrange[] isa Automatic && error("Cannot determine a colorrange automatically for single number color value. Pass an explicit colorrange.")

    cm = assemble_colors([color[]], lift(x -> [x], color), plot)
    return lift((args...)-> numbers_to_colors(args...)[1], cm.color_scaled, cm.colormap, identity, cm.colorrange_scaled, cm.lowclip, cm.highclip,
                      cm.nan_color)
end

highclip(cmap::ColorMap) = lift((cm, hc) -> hc isa Automatic ? last(cm) : hc, cmap.colormap, cmap.highclip)
lowclip(cmap::ColorMap) = lift((cm, hc) -> hc isa Automatic ? first(cm) : hc, cmap.colormap, cmap.lowclip)
