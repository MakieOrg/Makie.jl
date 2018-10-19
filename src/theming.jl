
const minimal_default = Attributes(
    font = "Dejavu Sans",
    backgroundcolor = RGBAf0(1,1,1,1),
    color = :black,
    colormap = :viridis,
    resolution = reasonable_resolution(),
    visible = true,
    scene = Attributes(
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
)

const _current_default_theme = copy(minimal_default)

function current_default_theme(; kw_args...)
    new_theme, rest = merge_attributes!(Attributes(kw_args), _current_default_theme)
    new_theme
end

function set_theme!(new_theme::Attributes)
    empty!(_current_default_theme)
    merge!(_current_default_theme, minimal_default, new_theme)
    return
end
function set_theme!(;kw_args...)
    set_theme!(Attributes(; kw_args...))
end
