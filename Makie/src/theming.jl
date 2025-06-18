#=
Conservative 7-color palette from Points of view: Color blindness, Bang Wong - Nature Methods
https://www.nature.com/articles/nmeth.1618?WT.ec_id=NMETH-201106
=#
function wong_colors(alpha = 1.0)
    colors = [
        RGB(0 / 255, 114 / 255, 178 / 255), # blue
        RGB(230 / 255, 159 / 255, 0 / 255), # orange
        RGB(0 / 255, 158 / 255, 115 / 255), # green
        RGB(204 / 255, 121 / 255, 167 / 255), # reddish purple
        RGB(86 / 255, 180 / 255, 233 / 255), # sky blue
        RGB(213 / 255, 94 / 255, 0 / 255), # vermilion
        RGB(240 / 255, 228 / 255, 66 / 255), # yellow
    ]
    return RGBAf.(colors, alpha)
end

function generate_default_palette(backgroundcolor = :white)
    bgc = to_color(backgroundcolor)
    return Attributes(
        color = wong_colors(1),
        patchcolor = map(c -> lerp(bgc, c, 0.8f0), wong_colors(1)),
        marker = [:circle, :utriangle, :cross, :rect, :diamond, :dtriangle, :pentagon, :xcross],
        linestyle = [nothing, :dash, :dot, :dashdot, :dashdotdot],
        side = [:left, :right]
    )
end

const DEFAULT_PALETTES = generate_default_palette()

const MAKIE_DEFAULT_THEME = Attributes(
    palette = DEFAULT_PALETTES,
    font = :regular,
    fonts = Attributes(
        regular = "TeX Gyre Heros Makie",
        bold = "TeX Gyre Heros Makie Bold",
        italic = "TeX Gyre Heros Makie Italic",
        bold_italic = "TeX Gyre Heros Makie Bold Italic",
    ),
    fontsize = 14,
    textcolor = :black,
    padding = Vec3f(0.05),
    figure_padding = 16,
    rowgap = 18,
    colgap = 18,
    backgroundcolor = :white,
    colormap = :viridis,
    marker = :circle,
    markersize = 9,
    markercolor = :black,
    markerstrokecolor = :black,
    markerstrokewidth = 0,
    markerfont = "TeX Gyre Heros Makie",
    linecolor = :black,
    linewidth = 1.5,
    linestyle = nothing,
    linecap = :butt,
    joinstyle = :miter,
    miter_limit = pi / 3,
    patchcolor = RGBf(0.4, 0.4, 0.4),
    patchstrokecolor = :black,
    patchstrokewidth = 0,
    size = (600, 450), # 4/3 aspect ratio
    visible = true,
    Axis = Attributes(),
    Axis3 = Attributes(),
    legend = Attributes(),
    axis_type = automatic,
    camera = automatic,
    limits = automatic,
    SSAO = Attributes(
        # enable = false,
        bias = 0.025f0,       # z threshold for occlusion
        radius = 0.5f0,       # range of sample positions (in world space)
        blur = Int32(2),      # A (2blur+1) by (2blur+1) range is used for blurring
        # N_samples = 64,       # number of samples (requires shader reload)
    ),
    inspectable = true,
    clip_planes = Vector{Plane3f}(),

    # Vec is equivalent to 36° right/east, 39° up/north from camera position
    # The order here is Vec3f(right of, up from, towards) viewer/camera
    light_direction = Vec3f(-0.45679495, -0.6293204, -0.6287243),
    camera_relative_light = true, # Only applies to default DirectionalLight
    light_color = RGBf(0.5, 0.5, 0.5),
    ambient = RGBf(0.45, 0.45, 0.45),

    # Note: this can be set too
    # lights = AbstractLight[
    #     AmbientLight(RGBf(0.55, 0.55, 0.55)),
    #     DirectionalLight(RGBf(0.8, 0.8, 0.8), Vec3f(2/3, 2/3, 1/3))
    # ],

    CairoMakie = Attributes(
        px_per_unit = 2.0,
        pt_per_unit = 0.75,
        antialias = :best,
        visible = true,
        start_renderloop = false,
        pdf_version = nothing
    ),

    GLMakie = Attributes(
        # Renderloop
        renderloop = automatic,
        pause_renderloop = false,
        vsync = false,
        render_on_demand = true,
        framerate = 30.0,
        px_per_unit = automatic,
        scalefactor = automatic,

        # GLFW window attributes
        float = false,
        focus_on_show = false,
        decorated = true,
        title = "Makie",
        fullscreen = false,
        debugging = false,
        monitor = nothing,
        visible = true,

        # Shader constants & Postproccessor
        oit = true,
        fxaa = true,
        ssao = false,
        # This adjusts a factor in the rendering shaders for order independent
        # transparency. This should be the same for all of them (within one rendering
        # pipeline) otherwise depth "order" will be broken.
        transparency_weight_scale = 1000.0f0,
        # maximum number of lights with shading = MultiLightShading
        max_lights = 64,
        max_light_parameters = 5 * 64
    ),

    WGLMakie = Attributes(
        framerate = 30.0,
        resize_to = nothing,
        # DEPRECATED in favor of resize_to
        # still needs to be here to gracefully deprecate it
        resize_to_body = nothing,
        px_per_unit = automatic,
        scalefactor = automatic
    ),

    RPRMakie = Attributes(
        iterations = 200,
        resource = automatic,
        plugin = automatic,
        max_recursion = 10
    )
)

const CURRENT_DEFAULT_THEME = deepcopy(MAKIE_DEFAULT_THEME)
const THEME_LOCK = Base.ReentrantLock()

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

# Same as above, but second argument gets priority so, `merge_without_obs_reverse!(Attributes(a=22), Attributes(a=33)) -> Attributes(a=33)`
function merge_without_obs_reverse!(result::Attributes, priority::Attributes)
    result_dict = attributes(result)
    for (key, value) in priority
        if !haskey(result_dict, key)
            result_dict[key] = Observable{Any}(to_value(value)) # the deepcopy part for observables
        else
            current_value = result[key]
            if value isa Attributes && current_value isa Attributes
                # if nested attribute, we merge recursively
                merge_without_obs_reverse!(current_value, value)
            else
                result_dict[key] = Observable{Any}(to_value(value))
            end
        end
    end
    return result
end

# Use copy with no obs to quickly deepcopy
fast_deepcopy(attributes) = merge_without_obs!(Attributes(), attributes)


current_default_theme() = CURRENT_DEFAULT_THEME


"""
    set_theme!(theme; kwargs...)

Set the global default theme to `theme` and add / override any attributes given
as keyword arguments.
"""
function set_theme!(new_theme = Attributes(); kwargs...)
    lock(THEME_LOCK) do
        empty!(CURRENT_DEFAULT_THEME)
        new_theme = merge_without_obs!(fast_deepcopy(new_theme), MAKIE_DEFAULT_THEME)
        new_theme = merge!(Theme(kwargs), new_theme)
        merge!(CURRENT_DEFAULT_THEME, new_theme)
    end
    return
end

"""
    with_theme(f, theme = Theme(); kwargs...)

Calls `f` with `theme` temporarily activated. Attributes in `theme`
can be overridden or extended with `kwargs`. The previous theme is always
restored afterwards, no matter if `f` succeeds or fails.

Example:

```julia
my_theme = Theme(size = (500, 500), color = :red)
with_theme(my_theme, color = :blue, linestyle = :dashed) do
    scatter(randn(100, 2))
end
```
"""
function with_theme(f, theme = Theme(); kwargs...)
    return lock(THEME_LOCK) do
        previous_theme = fast_deepcopy(CURRENT_DEFAULT_THEME)
        try
            set_theme!(theme; kwargs...)
            f()
        catch e
            rethrow(e)
        finally
            set_theme!(previous_theme)
        end
    end
end

theme(::Nothing, key::Symbol; default = nothing) = theme(key; default)
theme(::Nothing) = CURRENT_DEFAULT_THEME
function theme(key::Symbol; default = nothing)
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
To change the default colormap to `:greys`, you can pass that attribute as
a keyword argument to `update_theme!` as demonstrated below.
```julia
update_theme!(colormap=:greys)
```

This can also be achieved by passing an object of types `Attributes` or `Theme`
as the first and only positional argument:
```julia
update_theme!(Attributes(colormap=:greys))
update_theme!(Theme(colormap=:greys))
```
"""
function update_theme!(with_theme = Attributes(); kwargs...)
    return lock(THEME_LOCK) do
        new_theme = merge!(with_theme, Attributes(kwargs))
        _update_attrs!(CURRENT_DEFAULT_THEME, new_theme)
        return
    end
end

function _update_attrs!(attrs1, attrs2)
    for (key, value) in attrs2
        _update_key!(attrs1, key, value)
    end
    return
end

function _update_key!(theme, key::Symbol, content)
    return theme[key] = content
end

function _update_key!(theme, key::Symbol, content::Attributes)
    if haskey(theme, key) && theme[key] isa Attributes
        _update_attrs!(theme[key], content)
    else
        theme[key] = content
    end
    return theme
end
