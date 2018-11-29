#=
Conservative 7-color palette from Points of view: Color blindness, Bang Wong - Nature Methods
https://www.nature.com/articles/nmeth.1618?WT.ec_id=NMETH-201106
=#

const wong_colors = [
    RGB(230/255, 159/255, 0/255),
    RGB(86/255, 180/255, 233/255),
    RGB(0/255, 158/255, 115/255),
    RGB(240/255, 228/255, 66/255),
    RGB(0/255, 114/255, 178/255),
    RGB(213/255, 94/255, 0/255),
    RGB(204/255, 121/255, 167/255),
]

const default_palettes = Attributes(
    color = wong_colors,
    marker = [:circle, :xcross, :utriangle, :diamond, :dtriangle, :star8, :pentagon, :rect],
    linestyle = [nothing, :dash, :dot, :dashdot, :dashdotdot],
    side = [:left, :right]
)

const minimal_default = Attributes(
    palette = default_palettes,
    font = "Dejavu Sans",
    backgroundcolor = RGBAf0(1,1,1,1),
    color = :black,
    colormap = :viridis,
    marker = Circle,
    markersize = 0.1,
    linestyle = nothing,
    resolution = reasonable_resolution(),
    visible = true,
    clear = true,
    show_axis = true,
    show_legend = false,
    scale_plot = true,
    center = true,
    axis = Attributes(),
    legend = Attributes(),
    axis_type = automatic,
    camera = automatic,
    limits = automatic,
    padding = Vec3f0(0.1),
    raw = false
)

const _current_default_theme = Attributes(; minimal_default...) # make a copy. TODO overload copy?

function current_default_theme(; kw_args...)
    new_theme, rest = merge_attributes!(Attributes(kw_args), _current_default_theme)
    merge!(new_theme, rest)
end

function set_theme!(new_theme::Attributes)
    empty!(_current_default_theme)
    new_theme, rest = merge_attributes!(new_theme, minimal_default)
    merge!(_current_default_theme, new_theme, rest)
    return
end
function set_theme!(;kw_args...)
    set_theme!(Attributes(; kw_args...))
end
