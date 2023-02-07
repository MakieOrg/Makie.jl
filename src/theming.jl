#=
Conservative 7-color palette from Points of view: Color blindness, Bang Wong - Nature Methods
https://www.nature.com/articles/nmeth.1618?WT.ec_id=NMETH-201106
=#
function wong_colors(alpha = 1.0)
    colors = [
        RGB(0/255, 114/255, 178/255), # blue
        RGB(230/255, 159/255, 0/255), # orange
        RGB(0/255, 158/255, 115/255), # green
        RGB(204/255, 121/255, 167/255), # reddish purple
        RGB(86/255, 180/255, 233/255), # sky blue
        RGB(213/255, 94/255, 0/255), # vermillion
        RGB(240/255, 228/255, 66/255), # yellow
    ]
    return RGBAf.(colors, alpha)
end

const default_palettes = Attributes(
    color = wong_colors(1),
    patchcolor = wong_colors(0.8),
    marker = [:circle, :utriangle, :cross, :rect, :diamond, :dtriangle, :pentagon, :xcross],
    linestyle = [nothing, :dash, :dot, :dashdot, :dashdotdot],
    side = [:left, :right]
)

const minimal_default = Attributes(
    palette = default_palettes,
    font = :regular,
    fonts = Attributes(
        regular = "TeX Gyre Heros Makie",
        bold = "TeX Gyre Heros Makie Bold",
        italic = "TeX Gyre Heros Makie Italic",
        bold_italic = "TeX Gyre Heros Makie Bold Italic",
    ),
    fontsize = 16,
    textcolor = :black,
    padding = Vec3f(0.05),
    figure_padding = 16,
    rowgap = 24,
    colgap = 24,
    backgroundcolor = :white,
    colormap = :viridis,
    marker = :circle,
    markersize = 12,
    markercolor = :black,
    markerstrokecolor = :black,
    markerstrokewidth = 0,
    linecolor = :black,
    linewidth = 1.5,
    linestyle = nothing,
    patchcolor = RGBAf(0, 0, 0, 0.6),
    patchstrokecolor = :black,
    patchstrokewidth = 0,
    resolution = (800, 600), # 4/3 aspect ratio
    visible = true,
    axis = Attributes(),
    axis3d = Attributes(),
    legend = Attributes(),
    axis_type = automatic,
    camera = automatic,
    limits = automatic,
    SSAO = Attributes(
        # enable = false,
        bias = 0.025f0,       # z threshhold for occlusion
        radius = 0.5f0,       # range of sample positions (in world space)
        blur = Int32(2),      # A (2blur+1) by (2blur+1) range is used for blurring
        # N_samples = 64,       # number of samples (requires shader reload)
    ),
    ambient = RGBf(0.55, 0.55, 0.55),
    lightposition = :eyeposition,
    inspectable = true,

    CairoMakie = Attributes(
        px_per_unit = 1.0,
        pt_per_unit = 0.75,
        antialias = :best,
        visible = true,
        start_renderloop = false
    ),

    GLMakie = Attributes(
        # Renderloop
        renderloop = automatic,
        pause_renderloop = false,
        vsync = false,
        render_on_demand = true,
        framerate = 30.0,

        # GLFW window attributes
        float = false,
        focus_on_show = false,
        decorated = true,
        title = "Makie",
        fullscreen = false,
        debugging = false,
        monitor = nothing,
        visible = true,

        # Postproccessor
        oit = true,
        fxaa = true,
        ssao = false,
        # This adjusts a factor in the rendering shaders for order independent
        # transparency. This should be the same for all of them (within one rendering
        # pipeline) otherwise depth "order" will be broken.
        transparency_weight_scale = 1000f0
    ),

    WGLMakie = Attributes(
        framerate = 30.0
    ),

    RPRMakie = Attributes(
        iterations = 200,
        resource = automatic,
        plugin = automatic,
        max_recursion = 10
    )
)

const CURRENT_DEFAULT_THEME = deepcopy(minimal_default)

# Basically like deepcopy but while merging it into another Attribute dict
function merge_without_obs!(result::Attributes, theme::Attributes)
    dict = attributes(result)
    for (key, value) in theme
        if !haskey(dict, key)
            dict[key] = Observable{Any}(to_value(value)) # the deepcopy part for observables
        else
            current_value = result[key]
            if value isa Attributes && current_value isa Attributes
                # if nested attribute, we merge recursively
                merge_without_obs!(current_value, value)
            end
            # we're good! result already has a value, can ignore theme
        end
    end
    return result
end

function current_default_theme(; kw_args...)
    return merge_without_obs!(Attributes(kw_args), CURRENT_DEFAULT_THEME)
end

"""
    set_theme(theme; kwargs...)

Set the global default theme to `theme` and add / override any attributes given
as keyword arguments.
"""
function set_theme!(new_theme=Attributes(); kwargs...)
    empty!(CURRENT_DEFAULT_THEME)
    new_theme = merge!(deepcopy(new_theme), deepcopy(minimal_default))
    new_theme = merge!(Theme(kwargs), new_theme)
    merge!(CURRENT_DEFAULT_THEME, new_theme)
    return
end

"""
    with_theme(f, theme = Theme(); kwargs...)

Calls `f` with `theme` temporarily activated. Attributes in `theme`
can be overridden or extended with `kwargs`. The previous theme is always
restored afterwards, no matter if `f` succeeds or fails.

Example:

```julia
my_theme = Theme(resolution = (500, 500), color = :red)
with_theme(my_theme, color = :blue, linestyle = :dashed) do
    scatter(randn(100, 2))
end
```
"""
function with_theme(f, theme = Theme(); kwargs...)
    previous_theme = copy(CURRENT_DEFAULT_THEME)
    try
        set_theme!(theme; kwargs...)
        f()
    catch e
        rethrow(e)
    finally
        set_theme!(previous_theme)
    end
end

theme(::Nothing, key::Symbol) = theme(key)
function theme(key::Symbol; default=nothing)
    if haskey(CURRENT_DEFAULT_THEME, key)
        val = to_value(CURRENT_DEFAULT_THEME[key])
        if val isa Union{NamedTuple, Attributes}
            return val
        else
            Observable{Any}(val)
        end
    else
        return default
    end
end

"""
    update_theme!(with_theme::Theme; kwargs...)

Update the current theme incrementally. This means that only the keys given in `with_theme` or through keyword arguments are changed, 
the rest is left intact.  
Nested attributes are either also updated incrementally, or replaced if they are not attributes in the new theme.

# Example
To change de default colormap to `:greys`, you can pass that mapping as 
a keyword argument to `update_theme!` as demonstrated below.
```
update_theme!(colormap=:greys)
```

This can also be achieved by passing an object of types `Attributes` or `Theme` 
as the first and only positional argument:
```
update_theme!(Attributes(colormap=:greys))
update_theme!(Theme(colormap=:greys))
```
"""
function update_theme!(with_theme = Theme()::Attributes; kwargs...)
    new_theme = merge!(with_theme, Theme(kwargs))
    _update_attrs!(CURRENT_DEFAULT_THEME, new_theme)
    return
end

function _update_attrs!(attrs1, attrs2)
    for (key, value) in attrs2
        _update_key!(attrs1, key, value)
    end
end

function _update_key!(theme, key::Symbol, content)
    theme[key] = content
end

function _update_key!(theme, key::Symbol, content::Attributes)
    if haskey(theme, key) && theme[key] isa Attributes
        _update_attrs!(theme[key], content)
    else
        theme[key] = content
    end
    theme
end
