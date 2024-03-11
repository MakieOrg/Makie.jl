################################################################################
#                            Attribute conversions                             #
################################################################################

convert_attribute(x, key::Key, ::Key) = convert_attribute(x, key)
convert_attribute(s::SceneLike, x, key::Key, ::Key) = convert_attribute(s, x, key)
convert_attribute(s::SceneLike, x, key::Key) = convert_attribute(x, key)
convert_attribute(x, key::Key) = x

convert_attribute(color, ::key"color") = to_color(color)

convert_attribute(colormap, ::key"colormap") = to_colormap(colormap)
convert_attribute(rotation, ::key"rotation") = to_rotation(rotation)
convert_attribute(font, ::key"font") = to_font(font)
convert_attribute(align, ::key"align") = to_align(align)

convert_attribute(p, ::key"highclip") = to_color(p)
convert_attribute(p::Nothing, ::key"highclip") = p
convert_attribute(p, ::key"lowclip") = to_color(p)
convert_attribute(p::Nothing, ::key"lowclip") = p
convert_attribute(p, ::key"nan_color") = to_color(p)

struct Palette
   colors::Vector{RGBA{Float32}}
   i::Ref{Int}
   Palette(colors) = new(to_color.(colors), zero(Int))
end
Palette(name::Union{String, Symbol}, n = 8) = Palette(categorical_colors(name, n))
function to_color(p::Palette)
    N = length(p.colors)
    p.i[] = p.i[] == N ? 1 : p.i[] + 1
    return p.colors[p.i[]]
end

to_color(c::Nothing) = c # for when color is not used
to_color(c::Real) = Float32(c)
to_color(c::Colorant) = convert(RGBA{Float32}, c)
to_color(c::Symbol) = to_color(string(c))
to_color(c::String) = parse(RGBA{Float32}, c)
to_color(c::AbstractArray) = to_color.(c)
to_color(c::AbstractArray{<: Colorant, N}) where N = convert(Array{RGBAf, N}, c)
to_color(p::AbstractPattern) = p
function to_color(c::Tuple{<: Any,  <: Number})
    col = to_color(c[1])
    return RGBAf(Colors.color(col), alpha(col) * c[2])
end

convert_attribute(b::Billboard{Float32}, ::key"rotations") = to_rotation(b.rotation)
convert_attribute(b::Billboard{Vector{Float32}}, ::key"rotations") = to_rotation.(b.rotation)
convert_attribute(r::AbstractArray, ::key"rotations") = to_rotation.(r)
convert_attribute(r::StaticVector, ::key"rotations") = to_rotation(r)
convert_attribute(r, ::key"rotations") = to_rotation(r)

convert_attribute(c, ::key"markersize", ::key"scatter") = to_2d_scale(c)
convert_attribute(c, ::key"markersize", ::key"meshscatter") = to_3d_scale(c)
to_2d_scale(x::Number) = Vec2f(x)
to_2d_scale(x::VecTypes) = to_ndim(Vec2f, x, 1)
to_2d_scale(x::Tuple{<:Number, <:Number}) = to_ndim(Vec2f, x, 1)
to_2d_scale(x::AbstractVector) = to_2d_scale.(x)

to_3d_scale(x::Number) = Vec3f(x)
to_3d_scale(x::VecTypes) = to_ndim(Vec3f, x, 1)
to_3d_scale(x::AbstractVector) = to_3d_scale.(x)


convert_attribute(x, ::key"uv_offset_width") = Vec4f(x)
convert_attribute(x::AbstractVector{Vec4f}, ::key"uv_offset_width") = x


convert_attribute(c::Number, ::key"glowwidth") = Float32(c)
convert_attribute(c::Number, ::key"strokewidth") = Float32(c)

convert_attribute(c, ::key"glowcolor") = to_color(c)
convert_attribute(c, ::key"strokecolor") = to_color(c)

####
## Line style conversions
####

convert_attribute(style, ::key"linestyle") = to_linestyle(style)
to_linestyle(::Nothing) = nothing
# add deprecation for old conversion
function convert_attribute(style::AbstractVector, ::key"linestyle")
    @warn "Using a `Vector{<:Real}` as a linestyle attribute is deprecated. Wrap it in a `Linestyle`."
    return to_linestyle(Linestyle(style))
end

"""
    Linestyle(value::Vector{<:Real})

A type that can be used as value for the `linestyle` keyword argument
of plotting functions to arbitrarily customize the linestyle.

The `value` is a vector of positions where the line flips from being drawn or not
and vice versa. The values of `value` are in units of linewidth.

For example, with `value = [0.0, 4.0, 6.0, 9.5]`
you start drawing at 0, stop at 4 linewidths, start again at 6, stop at 9.5,
then repeat with 0 and 9.5 being treated as the same position.
"""
struct Linestyle
    value::Vector{Float32}
end

to_linestyle(style::Linestyle) = Float32[x - style.value[1] for x in style.value]

# TODO only use NTuple{2, <: Real} and not any other container
const GapType = Union{Real, Symbol, Tuple, AbstractVector}

# A `Symbol` equal to `:dash`, `:dot`, `:dashdot`, `:dashdotdot`
to_linestyle(ls::Union{Symbol, AbstractString}) = line_pattern(ls, :normal)

function to_linestyle(ls::Tuple{<:Union{Symbol, AbstractString}, <: GapType})
    return line_pattern(ls[1], ls[2])
end

function line_pattern(linestyle::Symbol, gaps::GapType)
    pattern = line_diff_pattern(linestyle, gaps)
    return isnothing(pattern) ? pattern : Float32[0.0; cumsum(pattern)]
end

"The linestyle patterns are inspired by the LaTeX package tikZ as seen here https://tex.stackexchange.com/questions/45275/tikz-get-values-for-predefined-dash-patterns."

function line_diff_pattern(ls::Symbol, gaps::GapType = :normal)
    if ls === :solid
        return nothing
    elseif ls === :dash
        return line_diff_pattern("-", gaps)
    elseif ls === :dot
        return line_diff_pattern(".", gaps)
    elseif ls === :dashdot
        return line_diff_pattern("-.", gaps)
    elseif ls === :dashdotdot
        return line_diff_pattern("-..", gaps)
    else
        error(
            """
            Unkown line style: $ls. Available linestyles are:
            :solid, :dash, :dot, :dashdot, :dashdotdot
            or a sequence of numbers enumerating the next transparent/opaque region.
            This sequence of numbers must be cumulative; 1 unit corresponds to 1 line width.
            """
        )
    end
end

function line_diff_pattern(ls_str::AbstractString, gaps::GapType = :normal)
    dot = 1
    dash = 3
    check_line_pattern(ls_str)

    dot_gap, dash_gap = convert_gaps(gaps)

    pattern = Float64[]
    for i in 1:length(ls_str)
        curr_char = ls_str[i]
        next_char = i == lastindex(ls_str) ? ls_str[firstindex(ls_str)] : ls_str[i+1]
        # push dash or dot
        if curr_char == '-'
            push!(pattern, dash)
        else
            push!(pattern, dot)
        end
        # push the gap (use dot_gap only between two dots)
        if (curr_char == '.') && (next_char == '.')
            push!(pattern, dot_gap)
        else
            push!(pattern, dash_gap)
        end
    end
    pattern
end

"Checks if the linestyle format provided as a string contains only dashes and dots"
function check_line_pattern(ls_str)
    isnothing(match(r"^[.-]+$", ls_str)) &&
        throw(ArgumentError("If you provide a string as linestyle, it must only consist of dashes (-) and dots (.)"))

    nothing
end

function convert_gaps(gaps::GapType)
    error_msg = "You provided the gaps modifier $gaps when specifying the linestyle. The modifier must be one of the symbols `:normal`, `:dense` or `:loose`, a real number or a tuple of two real numbers."
    if gaps isa Symbol
        gaps in [:normal, :dense, :loose] || throw(ArgumentError(error_msg))
        dot_gaps  = (normal = 2, dense = 1, loose = 4)
        dash_gaps = (normal = 3, dense = 2, loose = 6)

        dot_gap  = getproperty(dot_gaps, gaps)
        dash_gap = getproperty(dash_gaps, gaps)
    elseif gaps isa Real
        dot_gap = gaps
        dash_gap = gaps
    elseif length(gaps) == 2 && eltype(gaps) <: Real
        dot_gap, dash_gap = gaps
    else
        throw(ArgumentError(error_msg))
    end
    return (dot_gap = dot_gap, dash_gap = dash_gap)
end

convert_attribute(c::Tuple{<: Number, <: Number}, ::key"position") = Point2f(c[1], c[2])
convert_attribute(c::Tuple{<: Number, <: Number, <: Number}, ::key"position") = Point3f(c)
convert_attribute(c::VecTypes{N}, ::key"position") where N = Point{N, Float32}(c)

"""
    to_align(align[, error_prefix])

Converts the given align to a `Vec2f`. Can convert `VecTypes{2}` and two
component `Tuple`s with `Real` and `Symbol` elements.

To specify a custom error message you can add an `error_prefix` or use
`halign2num(value, error_msg)` and `valign2num(value, error_msg)` respectively.
"""
to_align(x::Tuple) = Vec2f(halign2num(x[1]), valign2num(x[2]))
to_align(x::VecTypes{2, <:Real}) = Vec2f(x)

function to_align(v, error_prefix::String)
    try
        return to_align(v)
    catch
        error(error_prefix)
    end
end

"""
    halign2num(align[, error_msg])

Attempts to convert a horizontal align to a Float32 and errors with `error_msg`
if it fails to do so.
"""
halign2num(v::Real, error_msg = "") = Float32(v)
function halign2num(v::Symbol, error_msg = "Invalid halign $v. Valid values are <:Real, :left, :center and :right.")
    if v === :left
        return 0.0f0
    elseif v === :center
        return 0.5f0
    elseif v === :right
        return 1.0f0
    else
        error(error_msg)
    end
end
function halign2num(v, error_msg = "Invalid halign $v. Valid values are <:Real, :left, :center and :right.")
    error(error_msg)
end

"""
    valign2num(align[, error_msg])

Attempts to convert a vertical align to a Float32 and errors with `error_msg`
if it fails to do so.
"""
valign2num(v::Real, error_msg = "") = Float32(v)
function valign2num(v::Symbol, error_msg = "Invalid valign $v. Valid values are <:Real, :bottom, :top, and :center.")
    if v === :top
        return 1f0
    elseif v === :bottom
        return 0f0
    elseif v === :center
        return 0.5f0
    else
        error(error_msg)
    end
end
function valign2num(v, error_msg = "Invalid valign $v. Valid values are <:Real, :bottom, :top, and :center.")
    error(error_msg)
end

"""
    angle2align(angle::Real)

Converts a given angle to an alignment by projecting the resulting direction on
a unit square and scaling the result to a 0..1 range appropriate for alignments.
"""
function angle2align(angle::Real)
    s, c = sincos(angle)
    scale = 1 / max(abs(s), abs(c))
    return Vec2f(0.5scale * c + 0.5, 0.5scale * s + 0.5)
end


const FONT_CACHE = Dict{String, NativeFont}()
const FONT_CACHE_LOCK = Base.ReentrantLock()

function load_font(filepath)
    font = FreeTypeAbstraction.try_load(filepath)
    if isnothing(font)
        error("Could not load font file \"$filepath\"")
    else
        return font
    end
end

"""
    to_font(str::String)

Loads a font specified by `str` and returns a `NativeFont` object storing the font handle.
A font can either be specified by a file path, such as "folder/with/fonts/font.otf",
or by a (partial) name such as "Helvetica", "Helvetica Bold" etc.
"""
function to_font(str::String)
    lock(FONT_CACHE_LOCK) do
        return get!(FONT_CACHE, str) do
            # load default fonts without font search to avoid latency
            if str == "default" || str == "TeX Gyre Heros Makie"
                return load_font(assetpath("fonts", "TeXGyreHerosMakie-Regular.otf"))
            elseif str == "TeX Gyre Heros Makie Bold"
                return load_font(assetpath("fonts", "TeXGyreHerosMakie-Bold.otf"))
            elseif str == "TeX Gyre Heros Makie Italic"
                return load_font(assetpath("fonts", "TeXGyreHerosMakie-Italic.otf"))
            elseif str == "TeX Gyre Heros Makie Bold Italic"
                return load_font(assetpath("fonts", "TeXGyreHerosMakie-BoldItalic.otf"))
            # load fonts directly if they are given as font paths
            elseif isfile(str)
                return load_font(str)
            end
            # for all other cases, search for the best match on the system
            fontpath = assetpath("fonts")
            font = FreeTypeAbstraction.findfont(str; additional_fonts=fontpath)
            if font === nothing
                @warn("Could not find font $str, using TeX Gyre Heros Makie")
                return to_font("TeX Gyre Heros Makie")
            end
            return font
        end
    end
end
to_font(x::Vector{String}) = to_font.(x)
to_font(x::NativeFont) = x
to_font(x::Vector{NativeFont}) = x

function to_font(fonts::Attributes, s::Symbol)
    if haskey(fonts, s)
        f = fonts[s][]
        if f isa Symbol
            error("The value for font $(repr(s)) was Symbol $(repr(f)), which is not allowed. The value for a font in the fonts collection cannot be another Symbol and must be resolvable via `to_font(x)`.")
        end
        return to_font(fonts[s][])
    end
    error("The symbol $(repr(s)) is not present in the fonts collection:\n$fonts.")
end

to_font(fonts::Attributes, x) = to_font(x)


"""
    rotation accepts:
    to_rotation(b, quaternion)
    to_rotation(b, tuple_float)
    to_rotation(b, vec4)
"""
to_rotation(s::Quaternionf) = s
to_rotation(s::Quaternion) = Quaternionf(s.data...)

function to_rotation(s::VecTypes{N}) where N
    if N == 4
        Quaternionf(s...)
    elseif N == 3
        rotation_between(Vec3f(0, 0, 1), to_ndim(Vec3f, s, 0.0))
    elseif N == 2
        rotation_between(Vec3f(0, 1, 0), to_ndim(Vec3f, s, 0.0))
    else
        error("The $N dimensional vector $s can't be converted to a rotation.")
    end
end

to_rotation(s::Tuple{VecTypes, Number}) = qrotation(to_ndim(Vec3f, s[1], 0.0), s[2])
to_rotation(angle::Number) = qrotation(Vec3f(0, 0, 1), angle)
to_rotation(r::AbstractVector) = to_rotation.(r)
to_rotation(r::AbstractVector{<: Quaternionf}) = r

convert_attribute(x, ::key"colorrange") = to_colorrange(x)
to_colorrange(x) = isnothing(x) ? nothing : Vec2f(x)

convert_attribute(x, ::key"fontsize") = to_fontsize(x)
to_fontsize(x::Number) = Float32(x)
to_fontsize(x::AbstractVector{T}) where T <: Number = el32convert(x)
to_fontsize(x::Vec2) = Vec2f(x)
to_fontsize(x::AbstractVector{T}) where T <: Vec2 = Vec2f.(x)

convert_attribute(x, ::key"linewidth") = to_linewidth(x)
to_linewidth(x) = Float32(x)
to_linewidth(x::AbstractVector) = el32convert(x)

# ColorBrewer colormaps that support only 8 colors require special handling on the backend, so we show them here.
const colorbrewer_8color_names = String.([
    :Accent,
    :Dark2,
    :Pastel2,
    :Set2
])

const plotutils_names = String.(union(
    keys(PlotUtils.ColorSchemes.colorschemes),
    keys(PlotUtils.COLORSCHEME_ALIASES),
    keys(PlotUtils.MISC_COLORSCHEMES)
))

const all_gradient_names = Set(vcat(plotutils_names, colorbrewer_8color_names))

"""
    available_gradients()

Prints all available gradient names.
"""
function available_gradients()
    println("Gradient Symbol/Strings:")
    for name in sort(collect(all_gradient_names))
        println("    ", name)
    end
end


to_colormap(cm, categories::Integer) = error("`to_colormap(cm, categories)` is deprecated. Use `Makie.categorical_colors(cm, categories)` for categorical colors, and `resample_cmap(cmap, ncolors)` for continous resampling.")

"""
    categorical_colors(colormaplike, categories::Integer)

Creates categorical colors and tries to match `categories`.
Will error if color scheme doesn't contain enough categories. Will drop the n last colors, if request less colors than contained in scheme.
"""
function categorical_colors(cols::AbstractVector{<: Colorant}, categories::Integer)
    if length(cols) < categories
        error("Not enough colors for number of categories. Categories: $(categories), colors: $(length(cols))")
    end
    return cols[1:categories]
end

function categorical_colors(cols::AbstractVector, categories::Integer)
    return categorical_colors(to_color.(cols), categories)
end

function categorical_colors(cs::Union{String, Symbol}, categories::Integer)
    cs_string = string(cs)
    if cs_string in all_gradient_names
        if haskey(ColorBrewer.colorSchemes, cs_string)
            return to_colormap(ColorBrewer.palette(cs_string, categories))
        else
            return categorical_colors(to_colormap(cs_string), categories)
        end
    else
        error(
            """
            There is no color gradient named $cs.
            See `available_gradients()` for the list of available gradients,
            or look at http://docs.makie.org/dev/generated/colors#Colormap-reference.
            """
        )
    end
end

"""
Reverses the attribute T upon conversion
"""
struct Reverse{T}
    data::T
end

to_colormap(r::Reverse) = reverse(to_colormap(r.data))
to_colormap(cs::ColorScheme) = to_colormap(cs.colors)



"""
    to_colormap(b::AbstractVector)

An `AbstractVector{T}` with any object that [`to_color`](@ref) accepts.
"""
to_colormap(cm::AbstractVector)::Vector{RGBAf} = map(to_color, cm)
to_colormap(cm::AbstractVector{<: Colorant}) = convert(Vector{RGBAf}, cm)

function to_colormap(cs::Tuple{<: Union{Reverse, Symbol, AbstractString}, Real})::Vector{RGBAf}
    cmap = to_colormap(cs[1])
    return RGBAf.(color.(cmap), alpha.(cmap) .* cs[2]) # We need to rework this to conform to the backend interface.
end

"""
    to_colormap(cs::Union{String, Symbol})::Vector{RGBAf}

A Symbol/String naming the gradient. For more on what names are available please see: `available_gradients()`.
For now, we support gradients from `PlotUtils` natively.
"""
function to_colormap(cs::Union{String, Symbol})::Vector{RGBAf}
    cs_string = string(cs)
    if cs_string in all_gradient_names
        if cs_string in colorbrewer_8color_names # special handling for 8 color only
            return to_colormap(ColorBrewer.palette(cs_string, 8))
        else
            # cs_string must be in plotutils_names
            return to_colormap(PlotUtils.get_colorscheme(Symbol(cs_string)))
        end
    else
        error(
            """
            There is no color gradient named $cs.
            See `Makie.available_gradients()` for the list of available gradients,
            or look at http://docs.makie.org/dev/generated/colors#Colormap-reference.
            """
        )
    end
end

# Handle inbuilt PlotUtils types
function to_colormap(cg::PlotUtils.ColorGradient)::Vector{RGBAf}
    # We sample the colormap using cg[val]. This way, we get a concrete representation of
    # the underlying gradient, like it being categorical or using a log scale.
    # 256 is just a high enough constant, without being too big to slow things down.
    return to_colormap(getindex.(Ref(cg), LinRange(first(cg.values), last(cg.values), 256)))
end

# Enum values: `IsoValue` `Absorption` `MaximumIntensityProjection` `AbsorptionRGBA` `AdditiveRGBA` `IndexedAbsorptionRGBA`
function convert_attribute(value, ::key"algorithm")
    if isa(value, RaymarchAlgorithm)
        return Int32(value)
    elseif isa(value, Int32) && value in 0:5
        return value
    elseif value == 7
        return value # makie internal contour implementation
    else
        error("$value is not a valid volume algorithm. Please have a look at the docstring of `to_volume_algorithm` (in the REPL, `?to_volume_algorithm`).")
    end
end

# Symbol/String: iso, absorption, mip, absorptionrgba, indexedabsorption
function convert_attribute(value::Union{Symbol, String}, k::key"algorithm")
    vals = Dict(
        :iso => IsoValue,
        :absorption => Absorption,
        :mip => MaximumIntensityProjection,
        :absorptionrgba => AbsorptionRGBA,
        :indexedabsorption => IndexedAbsorptionRGBA,
        :additive => AdditiveRGBA,
    )
    convert_attribute(get(vals, Symbol(value)) do
        error("$value is not a valid volume algorithm. It must be one of $(keys(vals))")
    end, k)
end

#=
The below is the output from:
```julia
# The bezier markers should not look out of place when used together with text
# where both markers and text are given the same size, i.e. the marker and fontsizes
# should correspond approximately in a visual sense.

# All the basic bezier shapes are approximately built in a 1 by 1 square centered
# around the origin, with slight deviations to match them better to each other.

# An 'x' of DejaVu sans is only about 55pt high at 100pt font size, so if the marker
# shapes are just used as is, they look much too large in comparison.
# To me, a factor of 0.75 looks ok compared to both uppercase and lowercase letters of Dejavu.
size_factor = 0.75
DEFAULT_MARKER_MAP[:rect] = scale(BezierSquare, size_factor)
DEFAULT_MARKER_MAP[:diamond] = scale(rotate(BezierSquare, pi/4), size_factor)
DEFAULT_MARKER_MAP[:hexagon] = scale(bezier_ngon(6, 0.5, pi/2), size_factor)
DEFAULT_MARKER_MAP[:cross] = scale(BezierCross, size_factor)
DEFAULT_MARKER_MAP[:xcross] = scale(BezierX, size_factor)
DEFAULT_MARKER_MAP[:utriangle] = scale(BezierUTriangle, size_factor)
DEFAULT_MARKER_MAP[:dtriangle] = scale(BezierDTriangle, size_factor)
DEFAULT_MARKER_MAP[:ltriangle] = scale(BezierLTriangle, size_factor)
DEFAULT_MARKER_MAP[:rtriangle] = scale(BezierRTriangle, size_factor)
DEFAULT_MARKER_MAP[:pentagon] = scale(bezier_ngon(5, 0.5, pi/2), size_factor)
DEFAULT_MARKER_MAP[:octagon] = scale(bezier_ngon(8, 0.5, pi/2), size_factor)
DEFAULT_MARKER_MAP[:star4] = scale(bezier_star(4, 0.25, 0.6, pi/2), size_factor)
DEFAULT_MARKER_MAP[:star5] = scale(bezier_star(5, 0.28, 0.6, pi/2), size_factor)
DEFAULT_MARKER_MAP[:star6] = scale(bezier_star(6, 0.30, 0.6, pi/2), size_factor)
DEFAULT_MARKER_MAP[:star8] = scale(bezier_star(8, 0.33, 0.6, pi/2), size_factor)
DEFAULT_MARKER_MAP[:vline] = scale(scale(BezierSquare, (0.2, 1.0)), size_factor)
DEFAULT_MARKER_MAP[:hline] = scale(scale(BezierSquare, (1.0, 0.2)), size_factor)
DEFAULT_MARKER_MAP[:+] = scale(BezierCross, size_factor)
DEFAULT_MARKER_MAP[:x] = scale(BezierX, size_factor)
DEFAULT_MARKER_MAP[:circle] = scale(BezierCircle, size_factor)
```
We have to write this out to make sure we rotate/scale don't generate slightly different values between Julia versions.
This would create different hashes, making the caching in the texture atlas fail!
See: https://github.com/MakieOrg/Makie.jl/pull/3394
=#

const DEFAULT_MARKER_MAP = Dict(:+ => BezierPath([Makie.MoveTo([0.1245, 0.375]),
                                                  Makie.LineTo([0.1245, 0.1245]),
                                                  Makie.LineTo([0.375, 0.1245]),
                                                  Makie.LineTo([0.375, -0.12449999999999999]),
                                                  Makie.LineTo([0.1245, -0.1245]),
                                                  Makie.LineTo([0.12450000000000003, -0.375]),
                                                  Makie.LineTo([-0.12449999999999997, -0.375]),
                                                  Makie.LineTo([-0.12449999999999999, -0.12450000000000003]),
                                                  Makie.LineTo([-0.375, -0.12450000000000006]),
                                                  Makie.LineTo([-0.375, 0.12449999999999994]),
                                                  Makie.LineTo([-0.12450000000000003, 0.12449999999999999]),
                                                  Makie.LineTo([-0.12450000000000007, 0.37499999999999994]),
                                                  Makie.ClosePath()]),
                                :diamond => BezierPath([Makie.MoveTo([0.4464931614186469,
                                                                      -5.564531862779532e-17]),
                                                        Makie.LineTo([2.10398220755128e-17,
                                                                      0.4464931614186469]),
                                                        Makie.LineTo([-0.4464931614186469,
                                                                      5.564531862779532e-17]),
                                                        Makie.LineTo([-2.10398220755128e-17,
                                                                      -0.4464931614186469]),
                                                        Makie.ClosePath()]),
                                :star4 => BezierPath([Makie.MoveTo([2.7554554183166277e-17,
                                                                    0.44999999999999996]),
                                                      Makie.LineTo([-0.13258251920342445,
                                                                    0.13258251920342445]),
                                                      Makie.LineTo([-0.44999999999999996,
                                                                    5.5109108366332553e-17]),
                                                      Makie.LineTo([-0.13258251920342445,
                                                                    -0.13258251920342445]),
                                                      Makie.LineTo([-8.266365659379842e-17,
                                                                    -0.44999999999999996]),
                                                      Makie.LineTo([0.13258251920342445,
                                                                    -0.13258251920342445]),
                                                      Makie.LineTo([0.44999999999999996,
                                                                    -1.1021821673266511e-16]),
                                                      Makie.LineTo([0.13258251920342445, 0.13258251920342445]),
                                                      Makie.ClosePath()]),
                                :star8 => BezierPath([Makie.MoveTo([2.7554554183166277e-17,
                                                                    0.44999999999999996]),
                                                      Makie.LineTo([-0.09471414797008038, 0.2286601772904396]),
                                                      Makie.LineTo([-0.31819804608821867,
                                                                    0.31819804608821867]),
                                                      Makie.LineTo([-0.2286601772904396, 0.09471414797008038]),
                                                      Makie.LineTo([-0.44999999999999996,
                                                                    5.5109108366332553e-17]),
                                                      Makie.LineTo([-0.2286601772904396,
                                                                    -0.09471414797008038]),
                                                      Makie.LineTo([-0.31819804608821867,
                                                                    -0.31819804608821867]),
                                                      Makie.LineTo([-0.09471414797008038,
                                                                    -0.2286601772904396]),
                                                      Makie.LineTo([-8.266365659379842e-17,
                                                                    -0.44999999999999996]),
                                                      Makie.LineTo([0.09471414797008038, -0.2286601772904396]),
                                                      Makie.LineTo([0.31819804608821867,
                                                                    -0.31819804608821867]),
                                                      Makie.LineTo([0.2286601772904396, -0.09471414797008038]),
                                                      Makie.LineTo([0.44999999999999996,
                                                                    -1.1021821673266511e-16]),
                                                      Makie.LineTo([0.2286601772904396, 0.09471414797008038]),
                                                      Makie.LineTo([0.31819804608821867, 0.31819804608821867]),
                                                      Makie.LineTo([0.09471414797008038, 0.2286601772904396]),
                                                      Makie.ClosePath()]),
                                :star6 => BezierPath([Makie.MoveTo([2.7554554183166277e-17,
                                                                    0.44999999999999996]),
                                                      Makie.LineTo([-0.11249999999999999, 0.1948557123541832]),
                                                      Makie.LineTo([-0.3897114247083664, 0.22499999999999998]),
                                                      Makie.LineTo([-0.22499999999999998,
                                                                    2.7554554183166277e-17]),
                                                      Makie.LineTo([-0.3897114247083664,
                                                                    -0.22499999999999998]),
                                                      Makie.LineTo([-0.11249999999999999,
                                                                    -0.1948557123541832]),
                                                      Makie.LineTo([-8.266365659379842e-17,
                                                                    -0.44999999999999996]),
                                                      Makie.LineTo([0.11249999999999999, -0.1948557123541832]),
                                                      Makie.LineTo([0.3897114247083664, -0.22499999999999998]),
                                                      Makie.LineTo([0.22499999999999998,
                                                                    -5.5109108366332553e-17]),
                                                      Makie.LineTo([0.3897114247083664, 0.22499999999999998]),
                                                      Makie.LineTo([0.11249999999999999, 0.1948557123541832]),
                                                      Makie.ClosePath()]),
                                :rtriangle => BezierPath([Makie.MoveTo([0.485, -8.909305463796994e-17]),
                                                          Makie.LineTo([-0.24249999999999994, 0.36375]),
                                                          Makie.LineTo([-0.2425000000000001,
                                                                        -0.36374999999999996]),
                                                          Makie.ClosePath()]),
                                :x => BezierPath([Makie.MoveTo([-0.1771302486872301, 0.35319983720268056]),
                                                  Makie.LineTo([1.39759596452057e-17, 0.17606958851545035]),
                                                  Makie.LineTo([0.17713024868723018, 0.3531998372026805]),
                                                  Makie.LineTo([0.3531998372026805, 0.17713024868723012]),
                                                  Makie.LineTo([0.17606958851545035, -1.025465786723834e-17]),
                                                  Makie.LineTo([0.3531998372026805, -0.17713024868723015]),
                                                  Makie.LineTo([0.17713024868723015, -0.3531998372026805]),
                                                  Makie.LineTo([1.1151998010815531e-17, -0.17606958851545035]),
                                                  Makie.LineTo([-0.17713024868723015, -0.3531998372026805]),
                                                  Makie.LineTo([-0.35319983720268044, -0.17713024868723018]),
                                                  Makie.LineTo([-0.17606958851545035,
                                                                -1.4873299788782892e-17]),
                                                  Makie.LineTo([-0.3531998372026805, 0.1771302486872301]),
                                                  Makie.ClosePath()]),
                                :circle => BezierPath([Makie.MoveTo([0.3525, 0.0]),
                                                       EllipticalArc([0.0, 0.0], 0.3525, 0.3525, 0.0, 0.0,
                                                                     6.283185307179586), Makie.ClosePath()]),
                                :pentagon => BezierPath([Makie.MoveTo([2.2962128485971897e-17, 0.375]),
                                                         Makie.LineTo([-0.35664620250463486,
                                                                       0.11588137596845627]),
                                                         Makie.LineTo([-0.22041946649551392,
                                                                       -0.30338137596845627]),
                                                         Makie.LineTo([0.22041946649551392,
                                                                       -0.30338137596845627]),
                                                         Makie.LineTo([0.35664620250463486,
                                                                       0.11588137596845627]),
                                                         Makie.ClosePath()]),
                                :vline => BezierPath([Makie.MoveTo([0.063143668438509, -0.315718342192545]),
                                                      Makie.LineTo([0.063143668438509, 0.315718342192545]),
                                                      Makie.LineTo([-0.063143668438509, 0.315718342192545]),
                                                      Makie.LineTo([-0.063143668438509, -0.315718342192545]),
                                                      Makie.ClosePath()]),
                                :cross => BezierPath([Makie.MoveTo([0.1245, 0.375]),
                                                      Makie.LineTo([0.1245, 0.1245]),
                                                      Makie.LineTo([0.375, 0.1245]),
                                                      Makie.LineTo([0.375, -0.12449999999999999]),
                                                      Makie.LineTo([0.1245, -0.1245]),
                                                      Makie.LineTo([0.12450000000000003, -0.375]),
                                                      Makie.LineTo([-0.12449999999999997, -0.375]),
                                                      Makie.LineTo([-0.12449999999999999,
                                                                    -0.12450000000000003]),
                                                      Makie.LineTo([-0.375, -0.12450000000000006]),
                                                      Makie.LineTo([-0.375, 0.12449999999999994]),
                                                      Makie.LineTo([-0.12450000000000003,
                                                                    0.12449999999999999]),
                                                      Makie.LineTo([-0.12450000000000007,
                                                                    0.37499999999999994]),
                                                      Makie.ClosePath()]),
                                :xcross => BezierPath([Makie.MoveTo([-0.1771302486872301,
                                                                     0.35319983720268056]),
                                                       Makie.LineTo([1.39759596452057e-17,
                                                                     0.17606958851545035]),
                                                       Makie.LineTo([0.17713024868723018, 0.3531998372026805]),
                                                       Makie.LineTo([0.3531998372026805, 0.17713024868723012]),
                                                       Makie.LineTo([0.17606958851545035,
                                                                     -1.025465786723834e-17]),
                                                       Makie.LineTo([0.3531998372026805,
                                                                     -0.17713024868723015]),
                                                       Makie.LineTo([0.17713024868723015,
                                                                     -0.3531998372026805]),
                                                       Makie.LineTo([1.1151998010815531e-17,
                                                                     -0.17606958851545035]),
                                                       Makie.LineTo([-0.17713024868723015,
                                                                     -0.3531998372026805]),
                                                       Makie.LineTo([-0.35319983720268044,
                                                                     -0.17713024868723018]),
                                                       Makie.LineTo([-0.17606958851545035,
                                                                     -1.4873299788782892e-17]),
                                                       Makie.LineTo([-0.3531998372026805, 0.1771302486872301]),
                                                       Makie.ClosePath()]),
                                :rect => BezierPath([Makie.MoveTo([0.315718342192545, -0.315718342192545]),
                                                     Makie.LineTo([0.315718342192545, 0.315718342192545]),
                                                     Makie.LineTo([-0.315718342192545, 0.315718342192545]),
                                                     Makie.LineTo([-0.315718342192545, -0.315718342192545]),
                                                     Makie.ClosePath()]),
                                :ltriangle => BezierPath([Makie.MoveTo([-0.485, 2.969768487932331e-17]),
                                                          Makie.LineTo([0.2425, -0.36375]),
                                                          Makie.LineTo([0.24250000000000005, 0.36375]),
                                                          Makie.ClosePath()]),
                                :dtriangle => BezierPath([Makie.MoveTo([-0.0, -0.485]),
                                                          Makie.LineTo([0.36375, 0.24250000000000002]),
                                                          Makie.LineTo([-0.36375, 0.24250000000000002]),
                                                          Makie.ClosePath()]),
                                :utriangle => BezierPath([Makie.MoveTo([0.0, 0.485]),
                                                          Makie.LineTo([-0.36375, -0.24250000000000002]),
                                                          Makie.LineTo([0.36375, -0.24250000000000002]),
                                                          Makie.ClosePath()]),
                                :star5 => BezierPath([Makie.MoveTo([2.7554554183166277e-17,
                                                                    0.44999999999999996]),
                                                      Makie.LineTo([-0.12343490123748782,
                                                                    0.16989357054233553]),
                                                      Makie.LineTo([-0.4279754430055618, 0.13905765116214752]),
                                                      Makie.LineTo([-0.19972187340259556,
                                                                    -0.06489357054233552]),
                                                      Makie.LineTo([-0.2645033597946167, -0.3640576511621475]),
                                                      Makie.LineTo([-3.8576373077105933e-17,
                                                                    -0.21000000000000002]),
                                                      Makie.LineTo([0.2645033597946167, -0.3640576511621475]),
                                                      Makie.LineTo([0.19972187340259556,
                                                                    -0.06489357054233552]),
                                                      Makie.LineTo([0.4279754430055618, 0.13905765116214752]),
                                                      Makie.LineTo([0.12343490123748782, 0.16989357054233553]),
                                                      Makie.ClosePath()]),
                                :octagon => BezierPath([Makie.MoveTo([2.2962128485971897e-17, 0.375]),
                                                        Makie.LineTo([-0.2651650384068489,
                                                                      0.2651650384068489]),
                                                        Makie.LineTo([-0.375, 4.5924256971943795e-17]),
                                                        Makie.LineTo([-0.2651650384068489,
                                                                      -0.2651650384068489]),
                                                        Makie.LineTo([-6.888638049483202e-17, -0.375]),
                                                        Makie.LineTo([0.2651650384068489,
                                                                      -0.2651650384068489]),
                                                        Makie.LineTo([0.375, -9.184851394388759e-17]),
                                                        Makie.LineTo([0.2651650384068489, 0.2651650384068489]),
                                                        Makie.ClosePath()]),
                                :hline => BezierPath([Makie.MoveTo([0.315718342192545, -0.063143668438509]),
                                                      Makie.LineTo([0.315718342192545, 0.063143668438509]),
                                                      Makie.LineTo([-0.315718342192545, 0.063143668438509]),
                                                      Makie.LineTo([-0.315718342192545, -0.063143668438509]),
                                                      Makie.ClosePath()]),
                                :hexagon => BezierPath([Makie.MoveTo([2.2962128485971897e-17, 0.375]),
                                                        Makie.LineTo([-0.32475952059030533, 0.1875]),
                                                        Makie.LineTo([-0.32475952059030533, -0.1875]),
                                                        Makie.LineTo([-6.888638049483202e-17, -0.375]),
                                                        Makie.LineTo([0.32475952059030533, -0.1875]),
                                                        Makie.LineTo([0.32475952059030533, 0.1875]),
                                                        Makie.ClosePath()]))

function default_marker_map()
    return DEFAULT_MARKER_MAP
end

"""
    available_marker_symbols()

Displays all available marker symbols.
"""
function available_marker_symbols()
    println("Marker Symbols:")
    for (k, v) in default_marker_map()
        println("    :", k)
    end
end

"""
    FastPixel()

Use

```julia
scatter(..., marker=FastPixel())
```

For significant faster plotting times for large amount of points.
Note, that this will draw markers always as 1 pixel.
"""
struct FastPixel end

"""
Vector of anything that is accepted as a single marker will give each point it's own marker.
Note that it needs to be a uniform vector with the same element type!
"""
to_spritemarker(marker::AbstractVector) = map(to_spritemarker, marker)
to_spritemarker(marker::AbstractVector{Char}) = marker # Don't dispatch to the above!
to_spritemarker(x::FastPixel) = x
to_spritemarker(x::Circle) = x
to_spritemarker(::Type{<: Circle}) = Circle
to_spritemarker(::Type{<: Rect}) = Rect
to_spritemarker(x::Rect) = x
to_spritemarker(b::BezierPath) = b
to_spritemarker(b::Polygon) = BezierPath(b)
to_spritemarker(b) = error("Not a valid scatter marker: $(typeof(b))")
to_spritemarker(x::Shape) = x

function to_spritemarker(str::String)
    error("Using strings for multiple char markers is deprecated. Use `collect(string)` or `['x', 'o', ...]` instead. Found: $(str)")
end

"""
    to_spritemarker(b, marker::Char)

Any `Char`, including unicode
"""
to_spritemarker(marker::Char) = marker

"""
Matrix of AbstractFloat will be interpreted as a distancefield (negative numbers outside shape, positive inside)
"""
to_spritemarker(marker::Matrix{<: AbstractFloat}) = el32convert(marker)

"""
Any AbstractMatrix{<: Colorant} or other image type
"""
to_spritemarker(marker::AbstractMatrix{<: Colorant}) = marker

"""
A `Symbol` - Available options can be printed with `available_marker_symbols()`
"""
function to_spritemarker(marker::Symbol)
    if haskey(default_marker_map(), marker)
        return to_spritemarker(default_marker_map()[marker])
    else
        @warn("Unsupported marker: $marker, using ● instead. Available options can be printed with available_marker_symbols()")
        return '●'
    end
end




convert_attribute(value, ::key"marker", ::key"scatter") = to_spritemarker(value)
convert_attribute(value, ::key"isovalue", ::key"volume") = Float32(value)
convert_attribute(value, ::key"isorange", ::key"volume") = Float32(value)
convert_attribute(value, ::key"gap", ::key"voxels") = ifelse(value <= 0.01, 0f0, Float32(value))

function convert_attribute(value::Symbol, ::key"marker", ::key"meshscatter")
    if value === :Sphere
        return normal_mesh(Sphere(Point3f(0), 1f0))
    else
        error("Unsupported marker: $(value)")
    end
end

function convert_attribute(value::AbstractGeometry, ::key"marker", ::key"meshscatter")
    return normal_mesh(value)
end

convert_attribute(value, ::key"diffuse") = Vec3f(value)
convert_attribute(value, ::key"specular") = Vec3f(value)

convert_attribute(value, ::key"backlight") = Float32(value)


# SAMPLER overloads

convert_attribute(s::ShaderAbstractions.Sampler{RGBAf}, k::key"color") = s
function convert_attribute(s::ShaderAbstractions.Sampler{T,N}, k::key"color") where {T,N}
    return ShaderAbstractions.Sampler(el32convert(s.data); minfilter=s.minfilter, magfilter=s.magfilter,
                                      x_repeat=s.repeat[1], y_repeat=s.repeat[min(2, N)],
                                      z_repeat=s.repeat[min(3, N)],
                                      anisotropic=s.anisotropic, color_swizzel=s.color_swizzel)
end

function el32convert(x::ShaderAbstractions.Sampler{T,N}) where {T,N}
    T32 = float32type(T)
    T32 === T && return x
    data = el32convert(x.data)
    return ShaderAbstractions.Sampler{T32,N,typeof(data)}(data, x.minfilter, x.magfilter,
                                       x.repeat,
                                       x.anisotropic,
                                       x.color_swizzel,
                                       ShaderAbstractions.ArrayUpdater(data, x.updates.update))
end

to_color(sampler::ShaderAbstractions.Sampler) = el32convert(sampler)

assemble_colors(::ShaderAbstractions.Sampler, color, plot) = Observable(el32convert(color[]))

# BUFFER OVERLOAD

GeometryBasics.collect_with_eltype(::Type{T}, vec::ShaderAbstractions.Buffer{T}) where {T} = vec
