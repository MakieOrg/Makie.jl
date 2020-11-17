if Sys.iswindows()
    function _primary_resolution()
        # ccall((:GetSystemMetricsForDpi, :user32), Cint, (Cint, Cuint), 0, ccall((:GetDpiForSystem, :user32), Cuint, ()))
        # ccall((:GetSystemMetrics, :user32), Cint, (Cint,), 17)
        dc = ccall((:GetDC, :user32), Ptr{Cvoid}, (Ptr{Cvoid},), C_NULL)
        ntuple(2) do i
            Int(ccall((:GetDeviceCaps, :gdi32), Cint, (Ptr{Cvoid}, Cint), dc, (2 - i) + 117))
        end
    end
elseif Sys.isapple()
    function _primary_resolution()
        s = read(pipeline(`system_profiler SPDisplaysDataType`, `grep Resolution`)) |> String
        sarr = split(s)
        return parse.(Int, (sarr[2], sarr[4]))
    end
# elseif Sys.islinux()
#     function _primary_resolution()
#         s = read(pipeline(`xrandr`)) |> String
#         sp = split(s, '\n')
#         s1 = sp[4]
#     end
else
    # TODO implement linux
    _primary_resolution() = (1920, 1080) # everyone should have at least a hd monitor :D
end

"""
Returns the resolution of the primary monitor.
If the primary monitor can't be accessed, returns (1920, 1080) (full hd)
"""
function primary_resolution()
    # Since this is pretty low level and os specific + we can't test on all possible
    # computers, I assume we'll have bugs here. Let's not sweat about it too much,
    # we just use primary_resolution to have a good estimate for a default window resolution
    # if this fails, only thing happening will be a too small/big window when the user doesn't give any resolution.
    try
        _primary_resolution()
    catch e
        @warn("Could not retrieve primary monitor resolution. A default resolution of (1920, 1080) is assumed!
        Error: $(sprint(io->showerror(io, e))).")
        (1920, 1080)
    end
end

"""
Returns a reasonable resolution for the main monitor.
(right now just half the resolution of the main monitor)
"""
reasonable_resolution() = primary_resolution() .÷ 2

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
    backgroundcolor = :white,
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
    update_limits = true,
    axis = Attributes(),
    axis2d = Attributes(),
    axis3d = Attributes(),
    legend = Attributes(),
    axis_type = automatic,
    camera = automatic,
    limits = automatic,
    padding = Vec3f0(0.05),
    raw = false,
    SSAO = Attributes(
        # enable = false,
        bias = 0.025f0,       # z threshhold for occlusion
        radius = 0.5f0,       # range of sample positions (in world space)
        blur = Int32(2),      # A (2blur+1) by (2blur+1) range is used for blurring
        # N_samples = 64,       # number of samples (requires shader reload)
    ),
)

const _current_default_theme = deepcopy(minimal_default)

function current_default_theme(; kw_args...)
    return merge!(Attributes(kw_args), _current_default_theme)
end

function set_theme!(new_theme::Attributes)
    empty!(_current_default_theme)
    new_theme = merge!(new_theme, minimal_default)
    merge!(_current_default_theme, new_theme)
    return
end
function set_theme!(;kw_args...)
    set_theme!(Attributes(; kw_args...))
end
