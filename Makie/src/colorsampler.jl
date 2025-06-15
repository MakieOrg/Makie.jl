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
    colors::AbstractArray{T, N} where {T}
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
function interpolated_getindex(cmap::AbstractArray, value::Real, norm::VecTypes)
    cmin, cmax = norm
    cmin == cmax && error("Can't interpolate in a range where cmin == cmax. This can happen, for example, if a colorrange is set automatically but there's only one unique value present.")
    i01 = clamp((value - cmin) / (cmax - cmin), zero(value), one(value))
    return interpolated_getindex(cmap, i01)
end

"""
    interpolated_getindex(cmap::AbstractArray, value::AbstractFloat)

Like getindex, but accepts values between 0..1 for `value` and interpolates those to the full range of `cmap`.
"""
function interpolated_getindex(cmap::AbstractArray{T}, i01::AbstractFloat) where {T}
    isfinite(i01) || error("Looking up a non-finite or NaN value in a colormap is undefined.")
    i1len = (i01 * (length(cmap) - 1)) + 1
    down = floor(Int, i1len)
    up = ceil(Int, i1len)
    down == up && return cmap[down]
    interp_val = i1len - down
    downc, upc = cmap[down], cmap[up]
    return convert(T, downc * (one(interp_val) - interp_val) + upc * interp_val)
end

function nearest_getindex(cmap::AbstractArray, value::Real, norm::VecTypes)
    cmin, cmax = norm
    cmin == cmax && error("Can't interpolate in a range where cmin == cmax. This can happen, for example, if a colorrange is set automatically but there's only one unique value present.")
    i01 = clamp((value - cmin) / (cmax - cmin), zero(value), one(value))
    return nearest_getindex(cmap, i01)
end

function nearest_getindex(cmap::AbstractArray, i01::Real)
    idx = round(Int, i01 * (length(cmap) - 1)) + 1
    return cmap[idx]
end

function nearest_getindex(cmap::AbstractArray, value::Real, norm::VecTypes{2})
    cmin, cmax = norm
    cmin == cmax && error("Can't interpolate in a range where cmin == cmax. This can happen, for example, if a colorrange is set automatically but there's only one unique value present.")
    i01 = clamp((value - cmin) / (cmax - cmin), zero(value), one(value))
    return nearest_getindex(cmap, i01)
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

function Base.getindex(sampler::Sampler{2, <:AbstractVector{Vec2f}}, i)::RGBAf
    uv = sampler.values[i]
    colors = sampler.colors
    # indexing confirming to OpenGL uv indexing
    wsize = reverse(size(colors))
    wh = wsize .- 1
    x, y = round.(Int, Tuple(uv) .* wh) .+ 1
    c = colors[size(colors, 1) - (y - 1), x]
    return RGBAf(color(c), alpha(c) * sampler.alpha)
end

function sampler(
        cmap::Union{Symbol, String}, n::Int = 20;
        scaling = Scaling(), alpha = 1.0, interpolation = Linear
    )
    return sampler(cmap, LinRange(0, 1, n); scaling = scaling, alpha = alpha, interpolation = interpolation)
end

function sampler(
        cmap::Union{Symbol, String}, values::AbstractVector{<:AbstractFloat};
        scaling = Scaling(), alpha = 1.0, interpolation = Linear
    )

    cs = PlotUtils.get_colorscheme(cmap)

    colors = getindex.(Ref(cs), values)

    return Sampler(colors, values, alpha, interpolation, scaling)
end

function sampler(
        cmap::Vector{<:Colorant}, values::AbstractVector{<:AbstractFloat};
        scaling = Scaling(), alpha = 1.0, interpolation = Linear
    )
    return Sampler(RGBAf.(cmap), values, alpha, interpolation, scaling)
end

function sampler(
        cmap::AbstractVector, values, crange;
        alpha = 1.0, interpolation = Linear
    )
    return Sampler(to_color.(cmap), values, alpha, interpolation, Scaling(identity, crange))
end
# uv texture sampler
function sampler(
        cmap::Matrix{<:Colorant}, uv::AbstractVector{Vec2f};
        alpha = 1.0, interpolation = Linear
    )
    return Sampler(cmap, uv, alpha, interpolation, Scaling())
end

"""
    apply_scale(scale, x)

Applies the scale function / callable `scale` to each element of `x`.
If `scale` is an Observable then this returns an Observable via `lift`,
otherwise simply returns `broadcast(scale, x)`.
"""
apply_scale(scale::AbstractObservable, x) = lift(apply_scale, scale, x)
apply_scale(::Union{Nothing, typeof(identity)}, x) = x  # noop
apply_scale(scale, x) = broadcast(scale, x)

function numbers_to_colors(numbers::Union{AbstractArray{<:Number}, Number}, primitive)
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
    nan_color = get_attribute(primitive, :nan_color, RGBAf(0, 0, 0, 0))::RGBAf

    return numbers_to_colors(numbers, colormap, colorscale, colorrange, lowclip, highclip, nan_color, true)
end

function numbers_to_colors(
        numbers::Union{AbstractArray{<:Number, N}, Number},
        colormap, colorscale, colorrange::Vec2,
        lowclip::Union{Automatic, RGBAf}, highclip::Union{Automatic, RGBAf},
        nan_color::RGBAf, interpolate
    )::Union{Array{RGBAf, N}, RGBAf} where {N}

    cmin, cmax = colorrange
    scaled_cmin, scaled_cmax = extrema(apply_scale(colorscale, (cmin, cmax)))

    return map(numbers) do number
        scaled_number = apply_scale(colorscale, Float64(number))  # ints don't work in interpolated_getindex
        if isnan(scaled_number)
            return nan_color
        elseif lowclip !== automatic && scaled_number < scaled_cmin
            return lowclip
        elseif highclip !== automatic && scaled_number > scaled_cmax
            return highclip
        end
        if interpolate
            return interpolated_getindex(colormap, scaled_number, (scaled_cmin, scaled_cmax))
        else
            return nearest_getindex(colormap, scaled_number, (scaled_cmin, scaled_cmax))
        end
    end
end

"""
    ColorMappingType

* categorical: there are n categories, and n colors are assigned to each category
* banded: there are ranges edge_start..edge_end, inside which values are mapped to one color
* continuous: colors are mapped continuously to values
"""
@enum ColorMappingType categorical banded continuous


struct ColorMapping{N, T <: AbstractArray{<:Number, N}, T2 <: AbstractArray{<:Number, N}}
    # The pure color values from the plot this colormapping is associated to
    # Will be always an array of numbers
    color::Observable{T}
    colormap::Observable{Vector{RGBAf}}
    raw_colormap::Observable{Vector{RGBAf}} # the above is scaled (when coming from cgrad), this is not

    # Scaling function that gets applied to color
    scale::Observable{Function}

    # The 0-1 scaled values from crange, which describe the colormapping
    mapping::Observable{Union{Nothing, Vector{Float64}}}
    colorrange::Observable{Vec{2, Float64}}

    lowclip::Observable{Union{Automatic, RGBAf}} # Defaults to first color in colormap
    highclip::Observable{Union{Automatic, RGBAf}} # Defaults to last color in colormap
    nan_color::Observable{RGBAf}

    color_mapping_type::Observable{ColorMappingType}

    # scaled attributes
    colorrange_scaled::Observable{Vec2f}
    color_scaled::Observable{T2}
end

function ColorMapping(args::Union{Observable, Computed}...)
    obs = map(x -> x isa Computed ? ComputePipeline.get_observable!(x) : x, args)
    return ColorMapping(obs...)
end

"""
    Categorical(colormaplike)

Accepts all colormap values that the `colormap` attribute of a plot accepts.
Will make sure to map one value to one color and create the correct Colorbar for the plot.

Example:
```julia
fig, ax, pl = barplot(1:3; color=1:3, colormap=Makie.Categorical(:viridis))
```

!!! warning
    This feature might change outside breaking releases, since the API is not yet finalized
"""
struct Categorical
    values::Any
end
Base.getindex(c::Categorical, i) = c.values[i]
Base.size(c::Categorical) = size(c.values)

_array_value_type(::Categorical) = Vector{eltype(values)}
_array_value_type(A::AbstractArray{<:Number}) = typeof(A)
_array_value_type(r::AbstractRange) = Vector{eltype(r)} # use vector instead, to have a few less types to worry about

to_colormap(x::Categorical) = to_colormap(x.values)
_to_colormap(x::Categorical) = to_colormap(x.values)
_to_colormap(x::PlotUtils.ColorGradient) = to_colormap(x.colors)
_to_colormap(x) = to_colormap(x)


colormapping_type(@nospecialize(colormap)) = continuous
colormapping_type(::PlotUtils.CategoricalColorGradient) = banded
colormapping_type(::Categorical) = categorical


function _colormapping(
        color_tight::Observable{V},
        @nospecialize(colors_obs),
        @nospecialize(colormap),
        @nospecialize(colorrange),
        @nospecialize(colorscale),
        @nospecialize(alpha),
        @nospecialize(lowclip),
        @nospecialize(highclip),
        @nospecialize(nan_color),
        color_mapping_type
    ) where {V <: AbstractArray{T, N}} where {N, T}
    map_colors = Observable(RGBAf[]; ignore_equal_values = true)
    raw_colormap = Observable(RGBAf[]; ignore_equal_values = true)
    mapping = Observable{Union{Nothing, Vector{Float64}}}(nothing; ignore_equal_values = true)
    colorscale = convert(Observable{Function}, colorscale)
    colorscale.ignore_equal_values = true

    function update_colors(cmap, a)
        colors = to_colormap(cmap)
        raw_colors = _to_colormap(cmap) # dont do the scaling from cgrad
        if a < 1.0
            colors = map(c -> RGBAf(Colors.color(c), Colors.alpha(c) * a), colors)
            raw_colors = map(c -> RGBAf(Colors.color(c), Colors.alpha(c) * a), raw_colors)
        end
        map_colors[] = colors
        raw_colormap[] = raw_colors
        if cmap isa PlotUtils.ColorGradient
            mapping[] = cmap.values
        end
        return
    end

    onany(update_colors, colormap, alpha)
    update_colors(colormap[], alpha[])

    _lowclip = Observable{Union{Automatic, RGBAf}}(automatic; ignore_equal_values = true)
    on(lowclip; update = true) do lc
        _lowclip[] = lc isa Union{Nothing, Automatic} ? automatic : to_color(lc)
        return
    end
    _highclip = Observable{Union{Automatic, RGBAf}}(automatic; ignore_equal_values = true)
    on(highclip; update = true) do hc
        _highclip[] = hc isa Union{Nothing, Automatic} ? automatic : to_color(hc)
        return
    end

    colorrange = lift(color_tight, colorrange; ignore_equal_values = true) do color, crange
        return crange isa Automatic ? Vec2{Float64}(distinct_extrema_nan(color)) : Vec2{Float64}(crange)
    end

    colorrange_scaled = lift(colorrange, colorscale; ignore_equal_values = true) do range, scale
        return Vec2f(extrema(apply_scale(scale, range)))
    end

    color_scaled = Observable(el32convert(apply_scale(colorscale[], color_tight[])))
    onany(color_tight, colorscale) do color, scale
        scaled = el32convert(apply_scale(scale, color))
        # If they're exactly the same we assume the user called notify
        # So we trigger an update...
        # If they're `== && !==`, we assume it's staying the same
        if color_scaled[] === scaled || color_scaled[] != scaled
            color_scaled[] = scaled
        end
    end
    CT = ColorMapping{N, V, typeof(color_scaled[])}

    return CT(
        color_tight,
        map_colors,
        raw_colormap,
        colorscale,
        mapping,
        colorrange,
        _lowclip,
        _highclip,
        lift(to_color, nan_color),
        color_mapping_type,
        colorrange_scaled,
        color_scaled
    )
end

function ColorMapping(
        color::AbstractArray{<:Number, N},
        @nospecialize(colors_obs),
        @nospecialize(colormap),
        @nospecialize(colorrange),
        @nospecialize(colorscale),
        @nospecialize(alpha),
        @nospecialize(lowclip),
        @nospecialize(highclip),
        @nospecialize(nan_color),
        color_mapping_type = lift(colormapping_type, colormap; ignore_equal_values = true)
    ) where {N}

    T = _array_value_type(color)
    color_tight = Observable{T}(color)

    args = map([colors_obs, colormap, colorrange, colorscale, alpha, lowclip, highclip, nan_color, color_mapping_type]) do x
        x isa Computed ? ComputePipeline.get_observable!(x) : x
    end

    # We need to copy, to check for changes
    # Since users may reuse the array when pushing updates
    on(args[1]) do new_colors
        if color_tight[] === new_colors || color_tight[] != new_colors
            color_tight[] = new_colors
        end
    end
    # color_tight.ignore_equal_values = true

    return _colormapping(color_tight, args...)
end

function assemble_colors(c::AbstractArray{<:Number}, @nospecialize(color), @nospecialize(plot))
    # CairoMakie uses this with strokecolor as colors too...
    keys = [:colormap, :colorrange, :colorscale, :alpha, :lowclip, :highclip, :nan_color]
    obs = ComputePipeline.get_observable!.(getproperty.(Ref(plot), keys))
    return ColorMapping(c, color, obs...)
end

function to_color(c::ColorMapping)
    return numbers_to_colors(
        c.color_scaled[], c.colormap[], identity, c.colorrange_scaled[],
        lowclip(c)[], highclip(c)[], c.nan_color[], c.color_mapping_type[] == continuous
    )
end

function Base.get(c::ColorMapping, value::Number)
    return numbers_to_colors(
        [value], c.colormap[], c.scale[], c.colorrange_scaled[],
        lowclip(c)[], highclip(c)[], c.nan_color[], c.color_mapping_type[] == continuous
    )[1]
end

function assemble_colors(colortype, color, plot)
    return lift(plot, color, plot.alpha) do color, a
        if a < 1.0
            return broadcast(c -> RGBAf(Colors.color(c), Colors.alpha(c) * a), to_color(color))
        else
            return to_color(color)
        end
    end
end

function assemble_colors(::Number, color, plot)
    plot.colorrange[] isa Automatic && error("Cannot determine a colorrange automatically for single number color value. Pass an explicit colorrange.")
    cm = assemble_colors([color[]], lift(x -> [x], color), plot)
    return lift(
        cm.color_scaled, cm.colormap, identity, cm.colorrange_scaled,
        cm.lowclip, cm.highclip, cm.nan_color, cm.color_mapping_type
    ) do vals, cm, cs, cr, lw, hc, nc, ct
        return numbers_to_colors(vals, cm, cs, cr, lw, hc, nc, ct == continuous)[1]
    end
end

highclip(cmap::ColorMapping) = lift((cm, hc) -> hc isa Automatic ? last(cm) : hc, cmap.colormap, cmap.highclip)
lowclip(cmap::ColorMapping) = lift((cm, hc) -> hc isa Automatic ? first(cm) : hc, cmap.colormap, cmap.lowclip)
